--!strict

--[[
   orion
   combat framework for Sparking Cards
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService") -- Added for input handling

local CombatStructure = require(ReplicatedStorage.Structures.CombatStructure)
local audio = require(script.Parent.Parent.Modules.audio)
local playerMarshaller = require(script.Parent.Parent.Utility.playerMarshaller)
local statemachine = require(script.Parent.Parent.Utility.statemachine)
local states = require(ReplicatedStorage.Combat.states) -- Assuming states.new() creates a statemachine instance
local Packet = require(ReplicatedStorage.Packet)
local clientcast = require(ReplicatedStorage.ClientModules.clientcast) -- For client-side use
local Maid = require(ReplicatedStorage.Utility.Maid)

local orion = {}
orion.RegisteredAttacks = {} -- Stores data for all registered attacks
orion.PlayerStates = {} -- Key: Player.UserId, Value: statemachine.StateMachineType
orion.PlayerCooldowns = {} -- Key: Player.UserId, Value: { [attackName: string]: tick }
orion._audio = audio.new()
orion._maid = Maid.new() -- Maid for cleaning up global connections for Orion itself

-- Type for AttackData (will be expanded)
export type AttackData = {
	Name: string,
	Type: "M1" | "Skill" | "Ultimate" | "WeaponAbility" | string, -- M1, Skill, Ultimate, or custom types
	InputType: "Action" | "KeyCode" | "UserInputType", -- How input is specified
	InputAction: string?, -- e.g., "PrimaryAttack", "Ability1" (if InputType is "Action")
	KeyCode: Enum.KeyCode?, -- (if InputType is "KeyCode")
	UserInputType: Enum.UserInputType?, -- (if InputType is "UserInputType")

	Damage: number,
	Cooldown: number,
	Range: number?, -- General purpose range, specific use depends on attack

	AnimationId: string?, -- Asset ID for server-side animation
	SoundId: string?, -- Asset ID for server-side sound

	-- Client-side Hit Detection (using clientcast)
	HitboxProvider: ((player: Player, attackData: AttackData) -> clientcast.HitboxConfig)?,
	ActiveDuration: number?, -- How long clientcast hitbox is active

	-- Callbacks
	OnExecuteServer: ((player: Player, attackData: AttackData, targetInfo: table?) -> ())?,
	OnExecuteClient: ((player: Player, attackData: AttackData, maid: Maid.Maid) -> ())?, -- For predictive effects
	OnHitServer: ((sourcePlayer: Player, targetPlayer: Player, damageAmount: number, attackData: AttackData) -> ())?,
	OnHitClient: ((sourcePlayer: Player, targetPosition: Vector3, attackData: AttackData, maid: Maid.Maid) -> ())?, -- For impact effects
	OnBlockServer: ((sourcePlayer: Player, targetPlayer: Player, attackData: AttackData) -> ())?,

	-- Visuals & Effects
	VisualEffectClient: ((player: Player, attackData: AttackData, maid: Maid.Maid) -> ())?, -- Main client effect
	VisualEffectServer: ((player: Player, attackData: AttackData, maid: Maid.Maid) -> ())?, -- Main server effect / replication

	-- Knockback (example structure, can be expanded)
	Knockback = {
		Force: number,
		Duration: number,
		Mode: "Directional" | "Omni"?, -- Directional from attacker, Omni away from impact
	}?,

	-- Other potential fields
	StaminaCost: number?,
	SpecialCost: number?,
	RequiresTarget: boolean?,
	MaxCombo: number?, -- For M1 sequences
	NextComboAttack: string?, -- Name of the next attack in a combo chain
	IsProjectile: boolean?,
	ProjectileSpeed: number?,
	ProjectileModule: ModuleScript?, -- For custom projectile logic
	-- Add more as needed
}


local function validateCharacter(player: playerMarshaller.player?)
	if not player or not player.Character then
		return false
	end
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	return true
end

-- Core API Functions

function orion.RegisterAttack(attackName: string, attackData: AttackData)
	-- Validate attackData structure (optional but recommended)
	if not attackData.Type or not attackData.Name then
		warn("Orion: Attempted to register attack with missing Type or Name:", attackName)
		return
	end
	attackData.Name = attackName -- Ensure name consistency
	orion.RegisteredAttacks[attackName] = attackData
	print("Orion: Registered attack -", attackName)
end

-- Server-side M1 Combo Tracking
local serverPlayerComboData = {} -- [playerId] = { currentAttackName = "attackName", count = 1, lastAttackTime = tick() }
local SERVER_COMBO_WINDOW_DURATION = COMBO_WINDOW_DURATION + 0.2 -- Allow slightly more time on server for latency

-- SERVER-SIDE: Handles the validated request to execute an attack's server logic
function orion.ExecuteServerAttackLogic(player: playerMarshaller.player, attackName: string, equippedIdentifier: string?, targetInfo: table?)
	if not validateCharacter(player) then
		return
	end

	local attackData = orion.RegisteredAttacks[attackName]
	if not attackData then
		warn("Orion Server: Attempted to execute unregistered attack by", player.Name, "-", attackName)
		return
	end

	-- Check Player State (e.g., cannot attack if stunned or already attacking)
	local currentPlayerState = orion.GetPlayerState(player)
	if currentPlayerState:getCurrentState() == states.Attacking or currentPlayerState:getCurrentState() == states.Stunned then
		-- print("Orion Server:", player.Name, "cannot attack while in state:", currentPlayerState:getCurrentState())
		return
	end

	-- M1 Combo Validation (Server-Side)
	if attackData.Type == "M1" then
		local cardLibrary = require(ReplicatedStorage.Combat.CardLibrary) -- Corrected path
		local cardInfo = equippedIdentifier and cardLibrary[equippedIdentifier]

		if not cardInfo then
			warn("Orion Server: Could not find card info for", equippedIdentifier or "Unknown Identifier", "during M1 combo validation.")
			serverPlayerComboData[player.UserId] = nil -- Clear combo on error
			return -- Reject attack if card info is missing
		end

		local currentServerCombo = serverPlayerComboData[player.UserId]
		local baseM1FromCard = cardInfo.Moveset and cardInfo.Moveset.M1

		if currentServerCombo
			and (tick() - currentServerCombo.lastAttackTime < SERVER_COMBO_WINDOW_DURATION)
			and currentServerCombo.count < (cardInfo.MaxCombo or 1) -- Use MaxCombo from CardLibrary
		then
			-- Try to continue combo
			local lastAttackData = orion.RegisteredAttacks[currentServerCombo.currentAttackName]
			if not lastAttackData or lastAttackData.NextComboAttack ~= attackName then
				-- Invalid combo progression (e.g., client sent wrong attack or skipped)
				-- Allow if it's the base M1 for the weapon (resets combo)
				if attackName == baseM1FromCard then
					-- print("Orion Server: Resetting M1 combo for", player.Name, "due to unexpected sequence, but allowing base M1.")
					serverPlayerComboData[player.UserId] = { count = 1, currentAttackName = attackName, lastAttackTime = tick() }
				else
					warn("Orion Server: Invalid M1 combo sequence for", player.Name, ". Expected:", lastAttackData and lastAttackData.NextComboAttack or "N/A", "Got:", attackName, "Base M1:", baseM1FromCard or "N/A")
					return -- Reject invalid combo step
				end
			else
				-- Valid combo continuation
				currentServerCombo.count += 1
				currentServerCombo.currentAttackName = attackName
				currentServerCombo.lastAttackTime = tick()
				-- print("Orion Server: Valid M1 combo continuation for", player.Name, "to", attackName, "Count:", currentServerCombo.count)
			end
		else
			-- Not a continuation or timed out, check if it's the base M1
			if attackName == baseM1FromCard then
				serverPlayerComboData[player.UserId] = { count = 1, currentAttackName = attackName, lastAttackTime = tick() }
				-- print("Orion Server: Starting/Restarting M1 combo for", player.Name, "with", attackName)
			else
				warn("Orion Server: Invalid M1 combo start for", player.Name, ". Expected base M1:", baseM1FromCard or "N/A", "Got:", attackName)
				return -- Not the base M1 and not a valid combo
			end
		end
	else
		-- Not an M1 attack, clear server combo data for this player
		serverPlayerComboData[player.UserId] = nil
	end

	-- Check Cooldowns (Authoritative server check)
	-- For M1s, cooldown is typically on the first attack of the chain. Skills have their own.
	local cooldownKey = attackName
	if attackData.Type == "M1" then
		-- If CardLibrary defines a specific cooldown for M1s, or if the base M1 attack has a cooldown field.
		-- For simplicity, let's assume the first M1 in a chain holds the primary cooldown for the M1 sequence.
		-- This means attackData.Cooldown for combo pieces might be 0 or very small,
		-- while the base M1 (e.g., FrostGauntlet_M1_1) has the actual M1 sequence cooldown.
		-- Here, we check cooldown for the *specific attack being executed*.
		-- A more robust system might check cooldown on the *base* M1 if this is part of a chain.
		-- For now, each attack has its own cooldown field.
	end

	if orion.PlayerCooldowns[player.UserId]
		and orion.PlayerCooldowns[player.UserId][cooldownKey] -- Check cooldown for the specific attack or its base
		and tick() < orion.PlayerCooldowns[player.UserId][cooldownKey]
	then
		-- print("Orion Server:", player.Name, "attack", cooldownKey, "is on cooldown.")
		return
	end

	-- Set Cooldown for this specific attack
	if attackData.Cooldown and attackData.Cooldown > 0 then
		if not orion.PlayerCooldowns[player.UserId] then
			orion.PlayerCooldowns[player.UserId] = {}
		end
		orion.PlayerCooldowns[player.UserId][cooldownKey] = tick() + attackData.Cooldown
	end

	print("Orion Server:", player.Name, "is executing attack:", attackName)
	-- Use "start_attack" event for state transition. Pass attackName for potential state-specific logic.
	-- The state machine's onEnter for "Attacking" can use these params.
	local stateParams = {
		attackName = attackName,
		equippedIdentifier = equippedIdentifier,
		duration = attackData.ActiveDuration
	}
	-- Correctly use an event name from states.lua to transition to Attacking
	-- Assuming 'start_attack' is the event defined in Idle (and other relevant states) to go to Attacking state.
	orion.SetPlayerState(player, "start_attack", stateParams)


	local character = player.Character

	-- Trigger animation (server-side for replication to other clients)
	if attackData.AnimationId then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		if animator then
			local animation = ReplicatedStorage.Assets.Animations:FindFirstChild(attackData.AnimationId) -- Example path
			if animation and animation:IsA("Animation") then
				local track = animator:LoadAnimation(animation)
				track:Play()
				-- TODO: Better animation handling, perhaps tie to attack duration or specific events
				track.Stopped:Connect(function()
					if orion.GetPlayerState(player):getCurrentState() == states.Attacking then
						orion.SetPlayerState(player, states.Idle)
					end
				end)
			else
				warn("Orion Server: Animation not found or not an Animation instance:", attackData.AnimationId)
			end
		end
	else
		task.delay(attackData.ActiveDuration or 0.1, function()
			if orion.GetPlayerState(player):getCurrentState() == states.Attacking then
				orion.SetPlayerState(player, states.Idle)
			end
		end)
	end

	-- Trigger sound (server-side for authority or replicate via effect notif)
	if attackData.SoundId then
		-- Option 1: Play directly on server (less responsive for attacker)
		-- orion._audio:write_miscellaneous(orion._audio, { sound_1 = attackData.SoundId })
		-- orion._audio:read_miscellaneous(orion._audio, "sound_1")
		-- task.wait()
		-- orion._audio:remove(orion._audio, "sound_1")
		-- Option 2: Send as an effect to clients
		Packet.Orion_PlayEffectNotif.sendToAllClients({
			effectName = "PlaySound",
			effectParams = { customData = { soundId = attackData.SoundId }, sourcePlayerId = player.UserId },
		})
	end

	-- Server-side OnExecute callback
	if attackData.OnExecuteServer then
		attackData.OnExecuteServer(player, attackData, targetInfo)
	end

	-- Server-side visual effects (e.g., for replication or server-owned elements)
	if attackData.VisualEffectServer then
		local vfxMaid = Maid.new()
		attackData.VisualEffectServer(player, attackData, vfxMaid)
		-- Assuming VisualEffectServer cleans up its own long-term effects or uses the maid
		-- For short term, could auto-clean after ActiveDuration
		task.delay(attackData.ActiveDuration or 2, function()
			vfxMaid:Destroy()
		end)
	end
end

-- CLIENT-SIDE: Player requests to execute an attack
function orion.RequestExecuteAttack(attackName: string, equippedIdentifier: string, targetInfo: table?)
	local player = Players.LocalPlayer
	if not validateCharacter(player) then
		-- print("Orion Client: Character invalid for attack request.")
		return
	end

	local attackData = orion.RegisteredAttacks[attackName]
	if not attackData then
		warn("Orion Client: Attempted to execute unregistered attack -", attackName)
		return
	end

	-- Client-side Cooldown Check (for responsiveness)
	if orion.PlayerCooldowns[player.UserId]
		and orion.PlayerCooldowns[player.UserId][attackName]
		and tick() < orion.PlayerCooldowns[player.UserId][attackName]
	then
		-- print("Orion Client:", player.Name, "attack", attackName, "is on cooldown.")
		-- TODO: Play cooldown error sound/visual
		return
	end

	-- Client-side Player State Check
	local currentPlayerState = orion.GetPlayerState(player)
	if currentPlayerState:getCurrentState() == states.Attacking or currentPlayerState:getCurrentState() == states.Stunned then
		-- print("Orion Client:", player.Name, "cannot attack while in state:", currentPlayerState:getCurrentState())
		return
	end

	-- Set client-side cooldown immediately for responsiveness
	if attackData.Cooldown and attackData.Cooldown > 0 then
		if not orion.PlayerCooldowns[player.UserId] then
			orion.PlayerCooldowns[player.UserId] = {}
		end
		orion.PlayerCooldowns[player.UserId][attackName] = tick() + attackData.Cooldown
	end

	-- Predictive client-side effects & state change
	-- orion.SetPlayerState(player, states.Attacking) -- Server will confirm state

	local attackMaid = Maid.new()

	if attackData.OnExecuteClient then
		attackData.OnExecuteClient(player, attackData, attackMaid)
	end
	if attackData.VisualEffectClient then
		attackData.VisualEffectClient(player, attackData, attackMaid)
	end

	-- Client-side Hitbox Creation (using clientcast)
	if attackData.HitboxProvider then
		local hitboxConfig = attackData.HitboxProvider(player, attackData)
		if hitboxConfig then
			hitboxConfig.Duration = attackData.ActiveDuration or hitboxConfig.Duration or 0.5 -- Ensure duration
			local hitbox = clientcast.new(hitboxConfig)
			attackMaid:GiveTask(hitbox) -- Add hitbox to maid for cleanup

			hitbox.HitDetected:Connect(function(hitResult)
				local targetPart = hitResult.Part
				local targetModel = targetPart:FindFirstAncestorWhichIsA("Model")
				local targetPlayer = targetModel and Players:GetPlayerFromCharacter(targetModel)

				if targetPlayer and targetPlayer ~= player then -- Check if it's another player
					print("Orion Client: Hit detected on", targetPlayer.Name, "by", attackName)
					Packet.Orion_ClientHitNotif.sendToServer({
						targetInstanceId = targetPlayer.Character.PrimaryPart.InstanceId, -- Example, send ID of HRP or Model
						hitPosition = hitResult.Position,
						attackName = attackName,
						weaponIdentifier = equippedIdentifier,
						-- validationRaycastData = { ... } -- If clientcast provides specific validation data
					})
				elseif targetModel then -- Hit a non-player model part
					-- Handle hitting environment objects if needed
					-- print("Orion Client: Hit detected on environment part", targetPart.Name, "by", attackName)
					-- Potentially send a different notification for environment interaction
				end
			end)
			hitbox:Start()
		end
	end

	-- Send request to server
	Packet.Orion_ExecuteAttackRequest.sendToServer({
		attackName = attackName,
		equippedIdentifier = equippedIdentifier,
		targetInfo = targetInfo,
	})

	-- Clean up client-side attack effects after duration
	task.delay(attackData.ActiveDuration or 0.5, function()
		attackMaid:Destroy()
	end)
end


-- SERVER-SIDE: Handles damage and related effects after a hit is validated
function orion.HandleDamage(
	sourcePlayer: Player,
	targetPlayer: Player,
	damageAmount: number,
	attackName: string
)
	local targetCharacter = targetPlayer.Character
	if not validateCharacter(targetPlayer) then -- Validate targetPlayer too
		return
	end
	local sourceCharacter = sourcePlayer.Character -- Should be valid if they initiated attack

	local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid or targetHumanoid.Health <= 0 then
		return
	end

	local attackData = orion.RegisteredAttacks[attackName]
	if not attackData then
		warn("Orion Server: HandleDamage called for unregistered attack:", attackName)
		return
	end

	local finalDamage = damageAmount

	-- Apply blocking modifier
	local targetState = orion.GetPlayerState(targetPlayer):getCurrentState()
	if targetState == states.Blocking then
		local damageAbsorption = CombatStructure.Blocking.DamageAbsorbtion or 0.6
		finalDamage = finalDamage * (1 - damageAbsorption)
		print("Orion Server:", targetPlayer.Name, "blocked, damage reduced to", finalDamage)
		if attackData.OnBlockServer then
			attackData.OnBlockServer(sourcePlayer, targetPlayer, attackData)
		end
		-- TODO: Notify client about block for feedback (sound, visual)
		Packet.Orion_PlayEffectNotif.sendToAllClients({ -- Or specific clients
			effectName = "BlockedHit",
			effectParams = {
				sourcePlayerId = sourcePlayer.UserId,
				targetPlayerId = targetPlayer.UserId,
				position = targetCharacter.PrimaryPart.Position,
			}
		})
	end

	print(
		"Orion Server:",
		sourcePlayer.Name,
		"damaged",
		targetPlayer.Name,
		"for",
		finalDamage,
		"HP with",
		attackName
	)
	targetHumanoid:TakeDamage(finalDamage)

	-- Server-side OnHit callback (after damage, before death/knockback)
	if attackData.OnHitServer then
		attackData.OnHitServer(sourcePlayer, targetPlayer, finalDamage, attackData)
	end

	-- Client-side OnHit notification (for impact effects)
	Packet.Orion_PlayEffectNotif.sendToAllClients({ -- Or just relevant clients
		effectName = "GenericImpact", -- Client will map this to a specific effect via attackData
		effectParams = {
			customData = { attackName = attackName }, -- So client can get more OnHitClient details
			sourcePlayerId = sourcePlayer.UserId,
			targetPlayerId = targetPlayer.UserId,
			position = targetCharacter.PrimaryPart.Position, -- Or actual hit position if available
		}
	})

	if targetHumanoid.Health <= 0 then
		print("Orion Server:", targetPlayer.Name, "was defeated by", sourcePlayer.Name)
		orion.SetPlayerState(targetPlayer, "died") -- Event to transition to Defunct state
		-- Handle other defeat logic (e.g., rewards for sourcePlayer)
	else
		-- Handle knockback (SERVER-SIDE)
		if attackData.Knockback and sourceCharacter and sourceCharacter.PrimaryPart then
			print("Orion Server: Applying knockback to", targetPlayer.Name)
			local knockbackForce = attackData.Knockback.Force
				or CombatStructure.Knockback.DamageScale * finalDamage
			local knockbackDuration = attackData.Knockback.Duration or CombatStructure.Knockback.Duration

			local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
			if targetRoot then
				local direction: Vector3
				if attackData.Knockback.Mode == "Omni" and attackData.Knockback.SourcePosition then
					direction = (targetRoot.Position - attackData.Knockback.SourcePosition).Unit
				else -- Default Directional from attacker
					direction = (targetRoot.Position - sourceCharacter.PrimaryPart.Position).Unit
				end

				local bv = Instance.new("BodyVelocity")
				bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
				bv.Velocity = direction * knockbackForce + Vector3.new(0, knockbackForce * 0.5, 0) -- Add some upward force
				bv.Parent = targetRoot
				Debris:AddItem(bv, knockbackDuration)

				-- Event to transition to Stunned state, params for duration
				orion.SetPlayerState(targetPlayer, "got_stunned", { duration = knockbackDuration })
				-- The Stunned state's onEnter should handle the timer to transition back to Idle
			end
		end
	end
end

function orion.SetPlayerState(player: Player, eventName: string, stateParams: table?)
	local playerState = orion.GetPlayerState(player)
	-- We don't check if playerState:getCurrentState() == eventName because eventName is an action, not a state.
	-- However, we might want to check if the transition is valid from the current state.
	-- The statemachine's :transition() method already handles this implicitly.

	local success = playerState:transition(eventName, stateParams) -- Pass params to state's onEnter/onExit
	if success then
		local newStateName = playerState:getCurrentState() -- Get the actual new state name after transition
		print("Orion:", player.Name, "state changed to:", newStateName, "(via event:", eventName .. ")")
		Packet.Orion_PlayerStateChangedNotif.sendToAllClients({ -- Consider sending only to relevant clients
			playerId = player.UserId,
			newState = newStateName, -- Send the actual resulting state
			stateParams = stateParams,
		})
	else
		warn("Orion: Failed to transition", player.Name, "from state", playerState:getCurrentState(), "with event:", eventName)
	end
end

function orion.GetPlayerState(player: playerMarshaller.player)
	local userId = player.UserId
	if not orion.PlayerStates[userId] then
		orion.PlayerStates[userId] = states.new(player) -- Assuming states.new() initializes the state machine
		-- Example: orion.PlayerStates[userId]:addState(states.Idle, { transitions = { basic_attack = states.Attacking }})
		-- This setup should happen in states.lua or when states.new is called.
	end
	return orion.PlayerStates[userId]
end

-- SERVER-SIDE: Handler for client attack requests from Bytenet
local function onExecuteAttackRequest(player: playerMarshaller.player, data: typeof(Packet.Orion_ExecuteAttackRequest.value))
	print("Orion Server: Received Orion_ExecuteAttackRequest from", player.Name, "for", data.attackName)
	-- Add more server-side validation if needed (e.g., sanity checks on equippedIdentifier)
	orion.ExecuteServerAttackLogic(player, data.attackName, data.equippedIdentifier, data.targetInfo)
end

-- SERVER-SIDE: Handler for client hit notifications from Bytenet
local function onClientHitNotif(player: playerMarshaller.player, data: typeof(Packet.Orion_ClientHitNotif.value))
	print("Orion Server: Received Orion_ClientHitNotif from", player.Name, "for attack", data.attackName)

	local targetInstance = game:GetInstanceFromId(data.targetInstanceId) -- Get instance by ID
	local targetCharacter = targetInstance and targetInstance:FindFirstAncestorWhichIsA("Model")
	local targetPlayer = targetCharacter and Players:GetPlayerFromCharacter(targetCharacter)

	if not targetPlayer or targetPlayer == player then
		-- print("Orion Server: Invalid target in ClientHitNotif or self-hit.")
		return
	end

	local attackData = orion.RegisteredAttacks[data.attackName]
	if not attackData then
		warn("Orion Server: ClientHitNotif for unregistered attack:", data.attackName)
		return
	end

	-- Basic validation: Check distance (example)
	local sourcePos = player.Character and player.Character.PrimaryPart and player.Character.PrimaryPart.Position
	if not sourcePos then return end -- Attacker character gone?

	local distance = (sourcePos - data.hitPosition).Magnitude
	local expectedRange = attackData.Range or CombatStructure.DefaultAttackRange or 10 -- Define DefaultAttackRange

	if distance > expectedRange * 1.2 then -- Allow some leeway for lag
		warn("Orion Server: Hit validation failed for", player.Name, "- distance too far.", distance, ">", expectedRange)
		return
	end

	-- TODO: Add more validation: Line of sight, timing, anti-cheat checks
	-- if data.validationRaycastData then ... end

	print("Orion Server: ClientHitNotif validated for", player.Name, "hitting", targetPlayer.Name)
	orion.HandleDamage(player, targetPlayer, attackData.Damage, data.attackName)
end


-- CLIENT-SIDE: Input Handling (Example, to be integrated into main client script)
local function setupClientInput()
	-- This function is illustrative. Actual input handling will be in Client.client.luau
	-- and will call orion.RequestExecuteAttack with the correct attackName.
	if not Players.LocalPlayer then return end

	local function onInputBegan(input: InputObject, gameProcessedEvent: boolean)
		if gameProcessedEvent then return end
		local player = Players.LocalPlayer
		if not validateCharacter(player) then return end

		-- This logic needs to be smarter, using keybindlink and CardLibrary
		-- For now, a placeholder:
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			-- Determine M1 attackName based on equipped card/weapon
			-- local m1AttackName = determine_m1_attack_name_from_equipped()
			-- orion.RequestExecuteAttack(m1AttackName, "current_weapon_id", { targetPosition = player:GetMouse().Hit.p })
		elseif input.KeyCode == Enum.KeyCode.E then
			-- Determine E skill attackName
			-- local eSkillAttackName = determine_e_skill_attack_name_from_equipped()
			-- orion.RequestExecuteAttack(eSkillAttackName, "current_weapon_id")
		end
	end
	-- UserInputService.InputBegan:Connect(onInputBegan) -- Connect in Client.client.luau
end

-- CLIENT-SIDE: Handler for player state changes from Bytenet
local function onPlayerStateChangedNotif(data: typeof(Packet.Orion_PlayerStateChangedNotif.value))
	local localPlayer = Players.LocalPlayer
	local targetPlayer = playerMarshaller.getByUserId(data.playerId)

	if not targetPlayer then return end

	-- Update local representation of player states
	-- Note: Direct state machine transition on client might be complex if server is fully authoritative.
	-- Client might just use this for visual/audio cues.
	local playerState = orion.GetPlayerState(targetPlayer) -- Ensures state machine exists
	-- For simplicity, let's assume the client just notes the state for its own predictive logic / visuals
	-- playerState:_forceSetState(data.newState) -- If statemachine had such a method

	print("Orion Client:", targetPlayer.Name, "received state update:", data.newState, data.stateParams)

	if targetPlayer == localPlayer then
		-- Handle local player state changes (e.g., update UI, play local sounds/VFX)
		if data.newState == states.Stunned then
			-- Play stun visual effect on self
		end
	else
		-- Handle remote player state changes (e.g., show stun effect on other player)
	end

	-- Actual state transition logic for client's own character might be better handled
	-- by server commands if strict authority is needed, or client can predictively
	-- transition and correct if server sends a different overriding state.
	-- For now, this notification is mainly for other players' states or simple feedback.
end

-- CLIENT-SIDE: Handler for generic effect playing
local function onPlayEffectNotif(data: typeof(Packet.Orion_PlayEffectNotif.value))
	print("Orion Client: Received Orion_PlayEffectNotif for effect", data.effectName)
	local effectName = data.effectName
	local params = data.effectParams
	local player = Players.LocalPlayer
	local maid = Maid.new() -- Effects should be temporary

	-- Example: Generic Impact effect based on attackName
	if effectName == "GenericImpact" and params.customData and params.customData.attackName then
		local attackData = orion.RegisteredAttacks[params.customData.attackName]
		if attackData and attackData.OnHitClient then
			local sourcePlayer = params.sourcePlayerId and playerMarshaller.getByUserId(params.sourcePlayerId)
			-- Call OnHitClient, ensuring targetPosition is available from params
			attackData.OnHitClient(sourcePlayer or player, params.position or Vector3.new(), attackData, maid)
		end
	elseif effectName == "PlaySound" and params.customData and params.customData.soundId then
		-- Play sound locally
		orion._audio:write_miscellaneous(orion._audio, { effect_sound = params.customData.soundId })
		orion._audio:read_miscellaneous(orion._audio, "effect_sound")
		task.delay(2, function() orion._audio:remove(orion._audio, "effect_sound") maid:Destroy() end) -- Clean up sound & maid
		return -- Maid is handled for this specific case
	elseif effectName == "BlockedHit" then
		-- Play block sparks, sound at params.position
		print("Orion Client: BlockedHit effect at", params.position)
	end
	-- TODO: Create a registry for client-side effect handlers
	-- local effectHandler = ClientEffectRegistry[effectName]
	-- if effectHandler then effectHandler(params, maid) end

	task.delay(2, function() maid:Destroy() end) -- Default cleanup for maid
end


-- Initialization
function orion.InitServer()
	-- Initialize player states and cooldowns for existing players
	for _, p in ipairs(Players:GetPlayers()) do
		orion.PlayerStates[p.UserId] = states.new(p)
		orion.PlayerCooldowns[p.UserId] = {}
	end

	orion._maid:GiveTask(Players.PlayerAdded:Connect(function(p)
		orion.PlayerStates[p.UserId] = states.new(p)
		orion.PlayerCooldowns[p.UserId] = {}
		print("Orion Server: Player", p.Name, "initialized.")
	end))

	orion._maid:GiveTask(Players.PlayerRemoving:Connect(function(p)
		orion.PlayerStates[p.UserId] = nil
		orion.PlayerCooldowns[p.UserId] = nil
		print("Orion Server: Player", p.Name, "removed.")
	end))

	-- Connect to Bytenet packets
	orion._maid:GiveTask(Packet.Orion_ExecuteAttackRequest.listen(onExecuteAttackRequest))
	orion._maid:GiveTask(Packet.Orion_ClientHitNotif.listen(onClientHitNotif))

	print("Orion Combat Framework Initialized on Server.")
end

function orion.InitClient()
	if not Players.LocalPlayer then
		warn("Orion Client: No LocalPlayer found during InitClient.")
		return
	end

	-- Initialize for existing players (primarily for LocalPlayer's own state tracking)
	for _, p in ipairs(Players:GetPlayers()) do
		if not orion.PlayerStates[p.UserId] then -- Check if already initialized by a potential earlier call or server join
			orion.PlayerStates[p.UserId] = states.new(p)
		end
		if p == Players.LocalPlayer and not orion.PlayerCooldowns[p.UserId] then
			orion.PlayerCooldowns[p.UserId] = {} -- Cooldowns are client-authoritative for prediction, server re-checks
		end
	end

	orion._maid:GiveTask(Players.PlayerAdded:Connect(function(p)
		if not orion.PlayerStates[p.UserId] then
			orion.PlayerStates[p.UserId] = states.new(p)
		end
		if p == Players.LocalPlayer and not orion.PlayerCooldowns[p.UserId] then
			orion.PlayerCooldowns[p.UserId] = {}
		end
		print("Orion Client: Player", p.Name, "added.")
	end))

	orion._maid:GiveTask(Players.PlayerRemoving:Connect(function(p)
		if orion.PlayerStates[p.UserId] then
			orion.PlayerStates[p.UserId]:Destroy() -- Assuming statemachine has a Destroy method
			orion.PlayerStates[p.UserId] = nil
		end
		if p == Players.LocalPlayer then
			orion.PlayerCooldowns[p.UserId] = nil
		end
		print("Orion Client: Player", p.Name, "removed.")
	end))

	-- Connect to Bytenet packets
	orion._maid:GiveTask(Packet.Orion_PlayerStateChangedNotif.listen(onPlayerStateChangedNotif))
	orion._maid:GiveTask(Packet.Orion_PlayEffectNotif.listen(onPlayEffectNotif))

	-- setupClientInput() -- Input handling should be managed by the main Client.client.luau script
	print("Orion Combat Framework Initialized on Client.")
end

-- Make sure to call orion:Destroy() when the game ends or the framework is no longer needed
function orion:Destroy()
	self._maid:Destroy()
	for _, stateMachine in pairs(self.PlayerStates) do
		if stateMachine.Destroy then -- Check if statemachine has a destroy method
			stateMachine:Destroy()
		end
	end
	table.clear(self.RegisteredAttacks)
	table.clear(self.PlayerStates)
	table.clear(self.PlayerCooldowns)
	print("Orion Combat Framework Destroyed.")
end

return orion
		result = false
	end
	local humanoid = character.Character.Humanoid :: Humanoid
	if not humanoid or humanoid.Health <= 0 then
		result = false
	end
end

-- Core API Functions

function orion.RegisterAttack(attackName: string, attackData: {})
	-- Validate attackData structure (optional but recommended)
	if not attackData.Type or not attackData.Input then
		warn("Orion: Attempted to register attack with missing Type or Input:", attackName)
		return
	end
	orion.RegisteredAttacks[attackName] = attackData
	print("Orion: Registered attack -", attackName)
end

function orion.ExecuteAttack(player: playerMarshaller.player, attackName: string)
	local character = player.Character
	if not validateCharacter(player) then
		return
	end

	local attackData = orion.RegisteredAttacks[attackName]
	if not attackData then
		warn("Orion: Attempted to execute unregistered attack by", player.Name, "-", attackName)
		return
	end

	-- Check Player State (e.g., cannot attack if stunned or already attacking)
	local currentPlayerState = orion.GetPlayerState(player)
	if currentPlayerState == states.Attacking or currentPlayerState == states.Stunned then
		-- print("Orion:", player.Name, "cannot attack while in state:", currentPlayerState)
		return
	end

	-- Check Cooldowns
	if
		orion.PlayerCooldowns[player.UserId]
		and orion.PlayerCooldowns[player.UserId][attackName]
		and tick() < orion.PlayerCooldowns[player.UserId][attackName]
	then
		-- print("Orion:", player.Name, "attack", attackName, "is on cooldown.")
		return
	end

	-- Set Cooldown
	if attackData.Cooldown and attackData.Cooldown > 0 then
		if not orion.PlayerCooldowns[player.UserId] then
			orion.PlayerCooldowns[player.UserId] = {}
		end
		orion.PlayerCooldowns[player.UserId][attackName] = tick() + attackData.Cooldown
	end

	print("Orion:", player.Name, "is executing attack:", attackName)
	orion.SetPlayerState(player, states.Attacking)

	-- Trigger animation (server-side)
	if attackData.AnimationId then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		if animator then
			-- This assumes AnimationId is a string path to an Animation instance
			-- or an rbxassetid if animations are uploaded to Roblox
			local animation = ReplicatedStorage.Assets.Animations:FindFirstChild(attackData.AnimationId) -- Example path
			if animation and animation:IsA("Animation") then
				local track = animator:LoadAnimation(animation)
				track:Play()
				-- Consider stopping the track after its duration or on state change
				track.Stopped:Wait() -- simple way to wait, might need adjustment
				if orion.GetPlayerState(player) == states.Attacking then -- if still attacking after animation
					orion.SetPlayerState(player, states.Idle)
				end
			else
				warn("Orion: Animation not found or not an Animation instance:", attackData.AnimationId)
			end
		end
	else
		-- If no animation, set state to idle after a short delay (e.g. for instant attacks)
		task.delay(0.1, function()
			if orion.GetPlayerState(player) == states.Attacking then
				orion.SetPlayerState(player, states.Idle)
			end
		end)
	end

	-- Trigger sound (can be done on client via remote event for responsiveness, or server for authority)
	if attackData.SoundId then
		-- Example: Play sound on server
		orion._audio:write_miscellaneous(orion._audio, { sound_1 = attackData.SoundId })
		orion._audio:read_miscellaneous(orion._audio, "sound_1")
		task.wait()
		orion._audio:remove(orion._audio, "sound_1")
	end

	-- Hitbox detection and damage application (SERVER-SIDE)
	-- This is a critical part and will need robust implementation.
	-- For now, let's assume a simple proximity check if no specific hitbox logic is provided.
	if attackData.Hitbox then
		-- Placeholder for more complex hitbox logic (e.g., raycasting, part checks)
		-- This would ideally be in orion.Utils.CheckHitbox(player, attackData)
		print("Orion: Checking hitbox for", attackName)
		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			if otherPlayer ~= player and otherPlayer.Character then
				local distance = (character.PrimaryPart.Position - otherPlayer.Character.PrimaryPart.Position).Magnitude
				if distance < (attackData.Range or 5) then -- Default range of 5 if not specified
					print("Orion:", attackName, "hit", otherPlayer.Name)
					orion.HandleDamage(player, otherPlayer, attackData.Damage or 10, attackName) -- Default damage 10
				end
			end
		end
	end

	-- Trigger visual effects (could be client-side via remote event)
	if attackData.VisualEffect then
		-- attackData.VisualEffect(player, attackData) -- This would need to be a function
		print("Orion: Triggering visual effect for", attackName)
	end

	-- Trigger cutscene (likely client-side via remote event)
	if attackData.Cutscene then
		print("Orion: Triggering cutscene", attackData.Cutscene)
	end

	-- After attack logic (e.g., return to idle if no animation or animation finished)
	-- This is partially handled by animation track.Stopped, but may need refinement
end

function orion.HandleDamage(
	sourcePlayer: Player,
	targetPlayer: Player,
	damageAmount: number,
	attackName: string
)
	local targetCharacter = targetPlayer.Character
	if not targetCharacter then
		return
	end

	local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid or targetHumanoid.Health <= 0 then
		return
	end

	local attackData = orion.RegisteredAttacks[attackName] -- May be nil if damage is from other source
	local finalDamage = damageAmount

	-- Apply blocking modifier
	if orion.GetPlayerState(targetPlayer) == states.Blocking then
		local damageAbsorption = CombatStructure.Blocking.DamageAbsorbtion or 0.6
		finalDamage = finalDamage * (1 - damageAbsorption)
		print("Orion:", targetPlayer.Name, "blocked, damage reduced to", finalDamage)
		if attackData and attackData.OnBlock then
			-- attackData.OnBlock(sourcePlayer, targetPlayer, attackData) -- This would be a function
			print("Orion: OnBlock event for", attackName)
		end
	end

	print(
		"Orion:",
		sourcePlayer.Name,
		"damaged",
		targetPlayer.Name,
		"for",
		finalDamage,
		"HP with",
		attackName or "Unknown Attack"
	)
	targetHumanoid:TakeDamage(finalDamage)

	if targetHumanoid.Health <= 0 then
		print("Orion:", targetPlayer.Name, "was defeated by", sourcePlayer.Name)
		-- Handle defeat logic (e.g., respawn, rewards for sourcePlayer)
		orion.SetPlayerState(targetPlayer, states.Defeated) -- Example state
	else
		-- Handle knockback (SERVER-SIDE)
		if attackData and attackData.Knockback then
			print("Orion: Applying knockback to", targetPlayer.Name)
			local knockbackForce = attackData.Knockback.Force
				or CombatStructure.Knockback.DamageScale * finalDamage
			local knockbackDuration = attackData.Knockback.Duration or CombatStructure.Knockback.Duration

			local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
			if targetRoot then
				local direction: Vector3 = (targetRoot.Position - sourcePlayer.Character.PrimaryPart.Position).Unit
				local bv = Instance.new("BodyVelocity")
				bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
				bv.Velocity = direction * knockbackForce + Vector3.new(0, knockbackForce * 0.5, 0) -- Add some upward force
				bv.Parent = targetRoot
				Debris:AddItem(bv, knockbackDuration)
				orion.SetPlayerState(targetPlayer, states.Stunned) -- Apply stun during knockback
				task.delay(knockbackDuration, function()
					if orion.GetPlayerState(targetPlayer) == states.Stunned then
						orion.SetPlayerState(targetPlayer, states.Idle)
					end
				end)
			end
		end
	end

	if attackData and attackData.OnHit then
		-- attackData.OnHit(sourcePlayer, targetPlayer, finalDamage, attackData) -- This would be a function
		print("Orion: OnHit event for", attackName)
	end
end

function orion.SetPlayerState(player: Player, state: string)
	if orion.PlayerStates[player.UserId] == state then
		return
	end -- No change

	orion.PlayerStates[player.UserId]:transition(state)
	print("Orion:", player.Name, "state changed to:", state)
	-- Fire remote event to update client-side visuals for the state (e.g., blocking animation, stun effect)
	playerStateChangedEvent:FireClient(player, state)
	-- If multiple clients need to know (e.g. for other players' animations), use :FireAllClients()
	-- or :FireClient(otherPlayer, player, state) for each otherPlayer
end

function orion.GetPlayerState(player: playerMarshaller.player)
	local state = orion.PlayerStates[player.UserId]
	if not state then
		orion.PlayerStates[player.UserId] = states.new(player)
	end
	return state
end

-- SERVER-SIDE: Handler for client attack requests
local function onServerExecuteAttack(player: playerMarshaller.player, attackName: string)
	-- Add server-side validation if needed (e.g., sanity checks)
	print("Orion Server: Received attack request from", player.Name, "for", attackName)
	orion.ExecuteAttack(player, attackName)
end

-- CLIENT-SIDE: Input Handling
local function setupClientInput()
	if not Players.LocalPlayer then
		return
	end -- Should not happen in a LocalScript context but good check

	local function onInputBegan(input: InputObject, gameProcessedEvent: boolean)
		if gameProcessedEvent then
			return
		end

		local player = Players.LocalPlayer
		if not player or not player.Character or orion.GetPlayerState(player) == states.Defeated then
			return
		end

		-- Iterate through registered attacks to find a match for the input
		for attackName, attackData in pairs(orion.RegisteredAttacks) do
			if attackData.Type == "M1" and input.UserInputType == Enum.UserInputType.MouseButton1 then
				print("Client: M1 input detected for", attackName)
				executeAttackEvent:FireServer(attackName)
				return -- Process only one M1 attack per click
			elseif
				attackData.Input == input.KeyCode
				and (attackData.Type == "Skill" or attackData.Type == "Ultimate")
			then
				print("Client:", attackData.Type, "input (", input.KeyCode.Name, ") detected for", attackName)
				executeAttackEvent:FireServer(attackName)
				return -- Process one skill/ultimate per key press
			end
			-- Add more complex input checks if needed (e.g., key combinations)
		end
	end
	UserInputService.InputBegan:Connect(onInputBegan)

	-- Handle player state changes from server (for visual feedback)
	playerStateChangedEvent.OnClientEvent:Connect(function(newState: string)
		local localPlayer = Players.LocalPlayer
		if localPlayer then
			orion.PlayerStates[localPlayer.UserId] = newState -- Keep client state somewhat synced for its own logic
			print("Client:", localPlayer.Name, "received state update:", newState)
			-- Here, you would trigger client-side visual changes based on state
			-- e.g., if newState == states.Blocking, play blocking animation locally
			-- if newState == states.Stunned, play stun animation/effect
		end
	end)
end

-- Initialization
function orion.InitServer()
	Players.PlayerAdded:Connect(function(player)
		orion.PlayerStates[player.UserId] = states.Idle
		orion.PlayerCooldowns[player.UserId] = {}
		print("Orion: Player", player.Name, "initialized on server.")
	end)
	Players.PlayerRemoving:Connect(function(player)
		orion.PlayerStates[player.UserId] = nil
		orion.PlayerCooldowns[player.UserId] = nil
		print("Orion: Player", player.Name, "removed from server.")
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		orion.PlayerStates[player.UserId] = states.Idle
		orion.PlayerCooldowns[player.UserId] = {}
	end

	executeAttackEvent.OnServerEvent:Connect(onServerExecuteAttack)
	print("Orion Combat Framework Initialized on Server.")
end

function orion.InitClient()
	-- Request initial states for all players or rely on PlayerAdded on client
	for _, player in ipairs(Players:GetPlayers()) do
		orion.PlayerStates[player.UserId] = states.Idle -- Initial assumption
	end

	Players.PlayerAdded:Connect(function(player)
		orion.PlayerStates[player.UserId] = states.Idle
		print("Orion: Player", player.Name, "added on client.")
	end)
	Players.PlayerRemoving:Connect(function(player)
		orion.PlayerStates[player.UserId] = nil
		print("Orion: Player", player.Name, "removed on client.")
	end)

	setupClientInput()
	print("Orion Combat Framework Initialized on Client.")
end

-- This module will be required by both server and client scripts.
-- The InitServer() or InitClient() should be called appropriately.
-- For example, a server script would do:
-- local orion = require(ReplicatedStorage.Combat.orion)
-- orion.InitServer()
--
-- A LocalScript would do:
-- local orion = require(ReplicatedStorage.Combat.orion)
-- orion.InitClient()

return orion
