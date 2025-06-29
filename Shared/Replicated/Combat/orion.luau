--!strict

--[[
   orion
   Core combat framework logic for Sparking Cards.
   Handles attack registration, server-side execution validation, state management,
   damage application, and network communication for combat events.
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService") -- For requiring CombatModuleManager
local UserInputService = game:GetService("UserInputService")

local CombatStructure = require(ReplicatedStorage.Structures.CombatStructure)
local audio = require(ReplicatedStorage.Modules.audio) -- Adjusted path
local PlayerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local StateManager = require(ReplicatedStorage.Combat.states) -- Updated to use the refined states module
local Packet = require(ReplicatedStorage.Packet)
local ClientCast = require(ReplicatedStorage.ClientModules.clientcast) -- For client-side use
local Maid = require(ReplicatedStorage.Utility.Maid)
-- local CardLibrary = require(ReplicatedStorage.Combat.CardLibrary) -- Moved to ExecuteServerAttackLogic for M1 combo check

-- Forward declare CombatModuleManager due to potential circular dependencies if it requires Orion early.
-- Actual require will be done in InitServer.
local CombatModuleManager: any --typeof(require(ServerScriptService.Server.CombatModuleManager))


-- Define types for clarity
type Player = PlayerMarshaller.player
type StateMachineType = ReturnType<typeof(StateManager.new)>
type TargetInfoParams = { targetPosition: Vector3?, targetInstanceId: number? } -- Matches CombatModuleManager definition

export type AttackData = {
	Name: string,
	Type: "M1" | "Skill" | "Ultimate" | "Support" | "WeaponAbility" | string,
	InputType: "Action" | "KeyCode" | "UserInputType",
	InputAction: string?,
	KeyCode: Enum.KeyCode?,
	UserInputType: Enum.UserInputType?,

	Damage: number,
	Cooldown: number,
	Range: number?,

	AnimationId: string?,
	SoundId: string?,

	HitboxProvider: ((player: Player, attackData: AttackData) -> ClientCast.HitboxConfig)?,
	ActiveDuration: number?, -- How long clientcast hitbox is active or server attack logic considers "active"

	-- Callbacks
	OnExecuteServer: ((player: Player, attackData: AttackData, targetInfo: TargetInfoParams?) -> ())?,
	OnExecuteClient: ((player: Player, attackData: AttackData, maid: Maid.Maid) -> ())?,
	OnHitServer: ((sourcePlayer: Player, targetPlayer: Player, damageAmount: number, attackData: AttackData) -> ())?,
	OnHitClient: ((sourcePlayer: Player, targetPosition: Vector3, attackData: AttackData, maid: Maid.Maid) -> ())?,
	OnBlockServer: ((sourcePlayer: Player, targetPlayer: Player, attackData: AttackData) -> ())?,

	VisualEffectClient: ((player: Player, attackData: AttackData, maid: Maid.Maid) -> ())?,
	VisualEffectServer: ((player: Player, attackData: AttackData, maid: Maid.Maid) -> ())?,

	Knockback: {
		Force: number,
		Duration: number,
		Mode: "Directional" | "Omni"?,
		SourcePosition: Vector3?, -- Used if Mode is Omni
	}?,

	StaminaCost: number?,
	SpecialCost: number?,
	RequiresTarget: boolean?,
	MaxCombo: number?,
	NextComboAttack: string?,
	IsProjectile: boolean?,
	ProjectileSpeed: number?,
	ProjectileModule: ModuleScript?,
}

local orion = {}
orion.RegisteredAttacks = {} ---@type { [string]: AttackData }
orion.PlayerStates = {} ---@type { [number]: StateMachineType } -- Key: Player.UserId
orion.PlayerCooldowns = {} ---@type { [number]: { [string]: number } } -- Key: Player.UserId, Value: { [attackName]: tick }
orion._audio = audio.new()
orion._maid = Maid.new()

local function validateCharacter(player: Player?)
	if not player or not player.Character then
		return false
	end
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	return true
end

function orion.RegisterAttack(attackName: string, attackData: AttackData)
	if not attackData.Type or not attackData.Name then
		warn("Orion: Attempted to register attack with missing Type or Name:", attackName)
		return
	end
	if not attackData.OnExecuteServer then
		warn("Orion: Attack", attackName, "registered without an OnExecuteServer callback. This attack will do nothing on the server.")
	end
	attackData.Name = attackName -- Ensure name consistency
	orion.RegisteredAttacks[attackName] = attackData
	print("Orion: Registered attack -", attackName)
end

local serverPlayerComboData: { [number]: { currentAttackName: string, count: number, lastAttackTime: number } } = {}
local SERVER_COMBO_WINDOW_DURATION: number = 0.8 + 0.2 -- Client window + latency buffer

function orion.ExecuteServerAttackLogic(player: Player, attackName: string, equippedIdentifier: string?, targetInfo: TargetInfoParams?)
	if not validateCharacter(player) then
		return
	end

	local attackData = orion.RegisteredAttacks[attackName]
	if not attackData then
		warn("Orion Server: Attempted to execute unregistered attack by", player.Name, "-", attackName)
		return
	end

	local playerStateMachine = orion.GetPlayerState(player)
	local currentState = playerStateMachine:getCurrentState()

	if currentState == StateManager.ATTACKING or currentState == StateManager.STUNNED or currentState == StateManager.CHANNELING then
		-- print("Orion Server:", player.Name, "cannot attack while in state:", currentState)
		return
	end

	-- M1 Combo Validation (Server-Side)
	if attackData.Type == "M1" then
		local CardLibrary = require(ReplicatedStorage.Combat.CardLibrary) -- Require here to avoid potential init order issues
		local cardInfo = equippedIdentifier and CardLibrary[equippedIdentifier]

		if not cardInfo then
			warn("Orion Server: Could not find card info for", equippedIdentifier or "Unknown Identifier", "during M1 combo validation for player", player.Name)
			serverPlayerComboData[player.UserId] = nil
			return
		end

		local currentServerCombo = serverPlayerComboData[player.UserId]
		local baseM1FromCard = cardInfo.Moveset and cardInfo.Moveset.M1

		if not baseM1FromCard then
			warn("Orion Server: Card", equippedIdentifier, "has no base M1 defined in Moveset for player", player.Name)
			serverPlayerComboData[player.UserId] = nil
			return
		end

		if currentServerCombo
			and (tick() - currentServerCombo.lastAttackTime < SERVER_COMBO_WINDOW_DURATION)
			and currentServerCombo.count < (attackData.MaxCombo or cardInfo.MaxCombo or 1) -- Prefer AttackData.MaxCombo if set
		then
			local lastAttackData = orion.RegisteredAttacks[currentServerCombo.currentAttackName]
			if not lastAttackData or lastAttackData.NextComboAttack ~= attackName then
				if attackName == baseM1FromCard then
					serverPlayerComboData[player.UserId] = { count = 1, currentAttackName = attackName, lastAttackTime = tick() }
				else
					warn("Orion Server: Invalid M1 combo sequence for", player.Name, ". Expected:", lastAttackData and lastAttackData.NextComboAttack or "N/A", "Got:", attackName, "Base M1:", baseM1FromCard)
					return
				end
			else
				currentServerCombo.count += 1
				currentServerCombo.currentAttackName = attackName
				currentServerCombo.lastAttackTime = tick()
			end
		else
			if attackName == baseM1FromCard then
				serverPlayerComboData[player.UserId] = { count = 1, currentAttackName = attackName, lastAttackTime = tick() }
			else
				warn("Orion Server: Invalid M1 combo start for", player.Name, ". Expected base M1:", baseM1FromCard, "Got:", attackName)
				return
			end
		end
	else
		serverPlayerComboData[player.UserId] = nil
	end

	-- Cooldown Check
	local cooldownKey = attackName -- Cooldown is per specific attack
	if orion.PlayerCooldowns[player.UserId]
		and orion.PlayerCooldowns[player.UserId][cooldownKey]
		and tick() < orion.PlayerCooldowns[player.UserId][cooldownKey]
	then
		return
	end

	if attackData.Cooldown and attackData.Cooldown > 0 then
		if not orion.PlayerCooldowns[player.UserId] then
			orion.PlayerCooldowns[player.UserId] = {}
		end
		orion.PlayerCooldowns[player.UserId][cooldownKey] = tick() + attackData.Cooldown
	end

	-- print("Orion Server:", player.Name, "is executing attack:", attackName)

	local stateParams: StateManager.AttackingParams = {
		attackName = attackName,
		duration = attackData.ActiveDuration or 0.5, -- Default duration if not specified
	}
	orion.SetPlayerState(player, "start_attack", stateParams)

	local character = player.Character
	if not character then return end -- Should be caught by validateCharacter

	-- Animation (server-side for replication)
	if attackData.AnimationId then
		local humanoid: Humanoid? = character:FindFirstChildOfClass("Humanoid")
		local animator: Animator? = humanoid and humanoid:FindFirstChildOfClass("Animator")
		if animator then
			-- Assuming AnimationId is a full rbxassetid string or a name of an Animation in a predefined location
			local animationInstance: Animation?
			if attackData.AnimationId:match("^rbxasset") then
				animationInstance = Instance.new("Animation")
				animationInstance.AnimationId = attackData.AnimationId
			else
				-- Example path, adjust as needed
				local animsFolder = ReplicatedStorage:FindFirstChild("Assets", true) and ReplicatedStorage.Assets:FindFirstChild("Animations", true)
				animationInstance = animsFolder and animsFolder:FindFirstChild(attackData.AnimationId) :: Animation?
			end

			if animationInstance and animationInstance:IsA("Animation") then
				local track = animator:LoadAnimation(animationInstance)
				track:Play()
				-- Auto-transition to Idle after animation is a common pattern, but might be attack-specific.
				-- Consider if OnExecuteServer should manage this transition for more control.
				track.Stopped:Connect(function()
					if orion.GetPlayerState(player):getCurrentState() == StateManager.ATTACKING then
						orion.SetPlayerState(player, "finish_attack")
					end
				end)
				if animationInstance.AnimationId == attackData.AnimationId then animationInstance:Destroy() end -- Clean up temp instance
			else
				warn("Orion Server: Animation not found or not an Animation instance:", attackData.AnimationId)
				-- Fallback if animation fails but attack should still have a duration
				task.delay(attackData.ActiveDuration or 0.1, function()
					if orion.GetPlayerState(player):getCurrentState() == StateManager.ATTACKING then
						orion.SetPlayerState(player, "finish_attack")
					end
				end)
			end
		end
	else
		-- If no animation, transition based on ActiveDuration
		task.delay(attackData.ActiveDuration or 0.1, function()
			if orion.GetPlayerState(player):getCurrentState() == StateManager.ATTACKING then
				orion.SetPlayerState(player, "finish_attack")
			end
		end)
	end

	-- Sound (replicated via effect notification)
	if attackData.SoundId then
		local soundParams: Packet.EffectParams = {
			customData = { soundId = attackData.SoundId },
			sourcePlayerId = player.UserId,
		}
		Packet.Orion_PlayEffectNotif.sendToAllClients({ -- Consider sendToPlayersInSphere if sound is localized
			effectName = "PlaySound",
			effectParams = soundParams,
		})
	end

	-- Execute the core attack logic from the combat module
	if attackData.OnExecuteServer then
		-- Pass `player`, `attackData`, and `targetInfo`
		-- The type of `targetInfo` here should match what `OnExecuteServer` expects.
		-- It's currently defined as `TargetInfoParams?` which is `{ targetPosition: Vector3?, targetInstanceId: number? }?`
		pcall(attackData.OnExecuteServer, player, attackData, targetInfo)
	else
		-- This case should have been warned during registration, but good to note.
		-- print("Orion Server: No OnExecuteServer defined for attack:", attackName)
	end

	-- Server-side visual effects (if any)
	if attackData.VisualEffectServer then
		local vfxMaid = Maid.new()
		pcall(attackData.VisualEffectServer, player, attackData, vfxMaid)
		task.delay(attackData.ActiveDuration or 2, function()
			vfxMaid:Destroy()
		end)
	end
end

function orion.RequestExecuteAttack(attackName: string, equippedIdentifier: string, targetInfo: TargetInfoParams?)
	local player = Players.LocalPlayer
	if not player then return end -- Should not happen in client script
	if not validateCharacter(player) then return end

	local attackData = orion.RegisteredAttacks[attackName]
	if not attackData then
		warn("Orion Client: Attempted to execute unregistered attack -", attackName)
		return
	end

	if orion.PlayerCooldowns[player.UserId]
		and orion.PlayerCooldowns[player.UserId][attackName]
		and tick() < orion.PlayerCooldowns[player.UserId][attackName]
	then
		return -- Client-side cooldown check for responsiveness
	end

	local playerStateMachine = orion.GetPlayerState(player)
	local currentState = playerStateMachine:getCurrentState()
	if currentState == StateManager.ATTACKING or currentState == StateManager.STUNNED or currentState == StateManager.CHANNELING then
		return
	end

	if attackData.Cooldown and attackData.Cooldown > 0 then
		if not orion.PlayerCooldowns[player.UserId] then
			orion.PlayerCooldowns[player.UserId] = {}
		end
		orion.PlayerCooldowns[player.UserId][attackName] = tick() + attackData.Cooldown
	end

	local attackMaid = Maid.new()

	if attackData.OnExecuteClient then
		pcall(attackData.OnExecuteClient, player, attackData, attackMaid)
	end
	if attackData.VisualEffectClient then
		pcall(attackData.VisualEffectClient, player, attackData, attackMaid)
	end

	if attackData.HitboxProvider then
		local hitboxConfig = attackData.HitboxProvider(player, attackData)
		if hitboxConfig then
			hitboxConfig.Duration = attackData.ActiveDuration or hitboxConfig.Duration or 0.5
			local hitbox = ClientCast.new(hitboxConfig)
			attackMaid:GiveTask(hitbox)

			hitbox.HitDetected:Connect(function(hitResult: ClientCast.HitResult)
				local targetPart = hitResult.Part
				local targetModel = targetPart:FindFirstAncestorWhichIsA("Model")
				local targetPlayer = targetModel and Players:GetPlayerFromCharacter(targetModel)

				if targetPlayer and targetPlayer ~= player then
					local hitNotifData: typeof(Packet.Orion_ClientHitNotif.value) = {
						targetInstanceId = targetPlayer.Character and targetPlayer.Character.PrimaryPart and targetPlayer.Character.PrimaryPart.InstanceId or 0,
						hitPosition = hitResult.Position,
						attackName = attackName,
						weaponIdentifier = equippedIdentifier,
						-- validationRaycastData = { ... } -- If clientcast provides specific validation data
					}
					Packet.Orion_ClientHitNotif.sendToServer(hitNotifData)
				end
			end)
			hitbox:Start()
		end
	end

	local requestData: typeof(Packet.Orion_ExecuteAttackRequest.value) = {
		attackName = attackName,
		equippedIdentifier = equippedIdentifier,
		targetInfo = targetInfo, -- This should be serializable by bytenet
	}
	Packet.Orion_ExecuteAttackRequest.sendToServer(requestData)

	task.delay(attackData.ActiveDuration or 0.5, function()
		attackMaid:Destroy()
	end)
end

function orion.HandleDamage(sourcePlayer: Player, targetPlayer: Player, damageAmount: number, attackName: string)
	local targetCharacter = targetPlayer.Character
	if not validateCharacter(targetPlayer) then return end
	local sourceCharacter = sourcePlayer.Character

	local targetHumanoid: Humanoid? = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid or targetHumanoid.Health <= 0 then return end

	local attackData = orion.RegisteredAttacks[attackName]
	if not attackData then
		warn("Orion Server: HandleDamage called for unregistered attack:", attackName)
		return
	end

	local finalDamage = damageAmount

	if orion.GetPlayerState(targetPlayer):getCurrentState() == StateManager.BLOCKING then
		local damageAbsorption = CombatStructure.Blocking.DamageAbsorbtion or 0.6 -- From config
		finalDamage = finalDamage * (1 - damageAbsorption)
		if attackData.OnBlockServer then
			pcall(attackData.OnBlockServer, sourcePlayer, targetPlayer, attackData)
		end
		local blockEffectParams: Packet.EffectParams = {
			sourcePlayerId = sourcePlayer.UserId,
			targetPlayerId = targetPlayer.UserId,
			position = targetCharacter and targetCharacter.PrimaryPart and targetCharacter.PrimaryPart.Position or targetPlayer.Character and targetPlayer.Character.HumanoidRootPart.Position,
		}
		Packet.Orion_PlayEffectNotif.sendToAllClients({
			effectName = "BlockedHit",
			effectParams = blockEffectParams,
		})
	end

	targetHumanoid:TakeDamage(finalDamage)
	-- print("Orion Server:", sourcePlayer.Name, "damaged", targetPlayer.Name, "for", finalDamage, "HP with", attackName)

	-- Trigger passives after damage application
	if CombatModuleManager then -- Ensure manager is loaded
		pcall(CombatModuleManager.TriggerPassive_OnPlayerDealtDamage, sourcePlayer, targetPlayer, finalDamage, attackData)
		pcall(CombatModuleManager.TriggerPassive_OnPlayerDamaged, targetPlayer, sourcePlayer, finalDamage, attackData)
	end

	if attackData.OnHitServer then
		pcall(attackData.OnHitServer, sourcePlayer, targetPlayer, finalDamage, attackData)
	end

	local impactEffectParams: Packet.EffectParams = {
		customData = { attackName = attackName },
		sourcePlayerId = sourcePlayer.UserId,
		targetPlayerId = targetPlayer.UserId,
		position = targetCharacter and targetCharacter.PrimaryPart and targetCharacter.PrimaryPart.Position or targetPlayer.Character and targetPlayer.Character.HumanoidRootPart.Position,
	}
	Packet.Orion_PlayEffectNotif.sendToAllClients({
		effectName = "GenericImpact",
		effectParams = impactEffectParams,
	})

	if targetHumanoid.Health <= 0 then
		orion.SetPlayerState(targetPlayer, "died")
	else
		if attackData.Knockback and sourceCharacter and sourceCharacter.PrimaryPart then
			local knockbackForce = attackData.Knockback.Force or (CombatStructure.Knockback.DamageScale and CombatStructure.Knockback.DamageScale * finalDamage or 10)
			local knockbackDuration = attackData.Knockback.Duration or CombatStructure.Knockback.Duration or 0.3

			local targetRoot: BasePart? = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart") :: BasePart?
			if targetRoot then
				local direction: Vector3
				if attackData.Knockback.Mode == "Omni" and attackData.Knockback.SourcePosition then
					direction = (targetRoot.Position - attackData.Knockback.SourcePosition).Unit
				else
					direction = (targetRoot.Position - sourceCharacter.PrimaryPart.Position).Unit
				end

				local bv = Instance.new("BodyVelocity")
				bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
				bv.Velocity = direction * knockbackForce + Vector3.new(0, knockbackForce * 0.3, 0) -- Reduced upward force a bit
				bv.Parent = targetRoot
				Debris:AddItem(bv, knockbackDuration)

				local stunParams: StateManager.StunnedParams = { duration = knockbackDuration }
				orion.SetPlayerState(targetPlayer, "got_stunned", stunParams)
				-- Stun recovery timer is now handled in SetPlayerState if new state is Stunned
			end
		end
	end
end

function orion.SetPlayerState(player: Player, eventName: string, stateParams: table?)
	local playerStateMachine = orion.GetPlayerState(player)
	local success = playerStateMachine:transition(eventName, stateParams)

	if success then
		local newStateName = playerStateMachine:getCurrentState()
		-- print("Orion:", player.Name, "state changed to:", newStateName, "(via event:", eventName .. ")")

		local notifData: typeof(Packet.Orion_PlayerStateChangedNotif.value) = {
			playerId = player.UserId,
			newState = newStateName,
			stateParams = stateParams, -- Assumes stateParams is serializable by bytenet
		}
		Packet.Orion_PlayerStateChangedNotif.sendToAllClients(notifData)

		-- Handle timed state recovery (e.g., for stun)
		if newStateName == StateManager.STUNNED and stateParams and typeof(stateParams.duration) == "number" and stateParams.duration > 0 then
			task.delay(stateParams.duration, function()
				-- Check if player is still in the same stunned state before recovering
				-- This prevents recovery if another event (e.g., death, another stun) occurred.
				local currentSM = orion.PlayerStates[player.UserId]
				if currentSM and currentSM:getCurrentState() == StateManager.STUNNED then
					orion.SetPlayerState(player, "recover_from_stun")
				end
			end)
		end
	else
		warn("Orion: Failed to transition", player.Name, "from state", playerStateMachine:getCurrentState(), "with event:", eventName)
	end
end

function orion.GetPlayerState(player: Player): StateMachineType
	local userId = player.UserId
	if not orion.PlayerStates[userId] then
		orion.PlayerStates[userId] = StateManager.new(player)
	end
	return orion.PlayerStates[userId]
end

local function onExecuteAttackRequest(player: Player, data: typeof(Packet.Orion_ExecuteAttackRequest.value))
	-- Ensure targetInfo is passed correctly; bytenet might make it a non-optional empty table if sent as nil.
	local targetInfoForLogic: TargetInfoParams? = nil
	if data.targetInfo and next(data.targetInfo) ~= nil then
		targetInfoForLogic = data.targetInfo :: TargetInfoParams
	end
	orion.ExecuteServerAttackLogic(player, data.attackName, data.equippedIdentifier, targetInfoForLogic)
end

local function onClientHitNotif(player: Player, data: typeof(Packet.Orion_ClientHitNotif.value))
	local targetInstance = game:GetInstanceFromId(data.targetInstanceId)
	local targetCharacter = targetInstance and targetInstance:FindFirstAncestorWhichIsA("Model")
	local targetPlayerOther = targetCharacter and Players:GetPlayerFromCharacter(targetCharacter)

	if not targetPlayerOther then return end
	local targetPlayer = PlayerMarshaller.get(targetPlayerOther) -- Marshall the target player
	if not targetPlayer or targetPlayer == player then return end

	local attackData = orion.RegisteredAttacks[data.attackName]
	if not attackData then return end

	local sourcePos = player.Character and player.Character.PrimaryPart and player.Character.PrimaryPart.Position
	if not sourcePos then return end

	local distance = (sourcePos - data.hitPosition).Magnitude
	local expectedRange = attackData.Range or CombatStructure.DefaultAttackRange or 15 -- Increased default slightly

	if distance > expectedRange * 1.3 then -- Increased leeway slightly
		warn("Orion Server: Hit validation failed for", player.Name, "- distance too far.", distance, ">", expectedRange)
		return
	end
	-- TODO: More validation like Line of Sight, timing, etc.

	orion.HandleDamage(player, targetPlayer, attackData.Damage, data.attackName)
end

local function onPlayerStateChangedNotif(data: typeof(Packet.Orion_PlayerStateChangedNotif.value))
	local localPlayer = Players.LocalPlayer
	local targetPlayerInstance = PlayerMarshaller.getByUserId(data.playerId) -- This gets our PlayerType
	if not targetPlayerInstance then return end

	local targetPlayer = PlayerMarshaller.get(targetPlayerInstance) -- ensure it's the correct type for GetPlayerState

	-- print("Orion Client:", targetPlayer.Name, "received state update:", data.newState, data.stateParams)

	-- Client might use this for visual cues or updating its local understanding of other players' states.
	-- For the local player, the server's state notification is authoritative, but the client
	-- might have already predictively entered a state (e.g., Attacking).
	-- The actual state machine on the client for the local player is mostly for prediction and input locking.
	-- Server's `SetPlayerState` is the source of truth that gets replicated.

	-- If it's the local player, and the server is forcing a state (like Stunned),
	-- the client's own state machine should reflect that to prevent actions.
	-- This part can be tricky. For now, this notification is mainly for visual/audio feedback.
	if targetPlayer == localPlayer then
		if data.newState == StateManager.STUNNED then
			-- Client can play stun VFX/SFX on self
		end
		-- Potentially force client state machine to sync if server dictates a non-predictable state
		-- local clientSM = orion.GetPlayerState(localPlayer)
		-- if clientSM:getCurrentState() ~= data.newState then
		--    clientSM:_forceSetState(data.newState) -- If such a method existed on statemachine
		-- end
	else
		-- Handle remote player state changes (e.g., show stun effect on other player model)
	end
end

local function onPlayEffectNotif(data: typeof(Packet.Orion_PlayEffectNotif.value))
	-- print("Orion Client: Received Orion_PlayEffectNotif for effect", data.effectName)
	local effectName = data.effectName
	local params = data.effectParams :: Packet.EffectParams -- Cast to the documented type
	local player = Players.LocalPlayer
	if not player then return end

	local maid = Maid.new() -- Effects are often temporary

	if effectName == "GenericImpact" and params.customData and params.customData.attackName then
		local attackData = orion.RegisteredAttacks[params.customData.attackName]
		if attackData and attackData.OnHitClient then
			local sourcePlayerInstance = params.sourcePlayerId and PlayerMarshaller.getByUserId(params.sourcePlayerId)
			local sourcePlayer = sourcePlayerInstance and PlayerMarshaller.get(sourcePlayerInstance)

			pcall(attackData.OnHitClient, sourcePlayer or player, params.position or Vector3.new(), attackData, maid)
		end
	elseif effectName == "PlaySound" and params.customData and params.customData.soundId then
		orion._audio:write_miscellaneous(orion._audio, { effect_sound = params.customData.soundId })
		orion._audio:read_miscellaneous(orion._audio, "effect_sound")
		task.delay(3, function() -- Increased delay slightly for sound to play out
			if orion._audio then -- Check if audio module still exists (e.g. during cleanup)
				orion._audio:remove(orion._audio, "effect_sound")
			end
			maid:Destroy()
		end)
		return -- Maid is handled for this specific case
	elseif effectName == "BlockedHit" then
		-- print("Orion Client: BlockedHit effect at", params.position)
		-- TODO: Client-side visual/audio for block
	end
	-- TODO: Implement a client-side effect registry: ClientEffectRegistry[effectName](params, maid)

	task.delay(3, function() maid:Destroy() end) -- Default cleanup for other effects
end

function orion.InitServer()
	-- Require CombatModuleManager here to avoid cyclic dependencies at script load time
	CombatModuleManager = require(ServerScriptService.Server.CombatModuleManager)

	for _, pInstance in ipairs(Players:GetPlayers()) do
		local p = PlayerMarshaller.get(pInstance)
		orion.PlayerStates[p.UserId] = StateManager.new(p)
		orion.PlayerCooldowns[p.UserId] = {}
	end

	orion._maid:GiveTask(Players.PlayerAdded:Connect(function(pInstance: RobloxPlayer)
		local p = PlayerMarshaller.get(pInstance)
		orion.PlayerStates[p.UserId] = StateManager.new(p)
		orion.PlayerCooldowns[p.UserId] = {}
		-- print("Orion Server: Player", p.Name, "initialized.")
	end))

	orion._maid:GiveTask(Players.PlayerRemoving:Connect(function(pInstance: RobloxPlayer)
		local p = PlayerMarshaller.get(pInstance)
		if orion.PlayerStates[p.UserId] and orion.PlayerStates[p.UserId].Destroy then
			orion.PlayerStates[p.UserId]:Destroy()
		end
		orion.PlayerStates[p.UserId] = nil
		orion.PlayerCooldowns[p.UserId] = nil
		-- print("Orion Server: Player", p.Name, "removed.")
	end))

	orion._maid:GiveTask(Packet.Orion_ExecuteAttackRequest.listen(onExecuteAttackRequest))
	orion._maid:GiveTask(Packet.Orion_ClientHitNotif.listen(onClientHitNotif))

	print("Orion Combat Framework Initialized on Server.")
end

function orion.InitClient()
	local localPlayerInstance = Players.LocalPlayer
	if not localPlayerInstance then
		warn("Orion Client: No LocalPlayer found during InitClient.")
		return
	end
	local localPlayer = PlayerMarshaller.get(localPlayerInstance)

	for _, pInstance in ipairs(Players:GetPlayers()) do
		local p = PlayerMarshaller.get(pInstance)
		if not orion.PlayerStates[p.UserId] then
			orion.PlayerStates[p.UserId] = StateManager.new(p)
		end
		if p == localPlayer and not orion.PlayerCooldowns[p.UserId] then
			orion.PlayerCooldowns[p.UserId] = {}
		end
	end

	orion._maid:GiveTask(Players.PlayerAdded:Connect(function(pInstance: RobloxPlayer)
		local p = PlayerMarshaller.get(pInstance)
		if not orion.PlayerStates[p.UserId] then
			orion.PlayerStates[p.UserId] = StateManager.new(p)
		end
		if p == localPlayer and not orion.PlayerCooldowns[p.UserId] then
			orion.PlayerCooldowns[p.UserId] = {}
		end
	end))

	orion._maid:GiveTask(Players.PlayerRemoving:Connect(function(pInstance: RobloxPlayer)
		local p = PlayerMarshaller.get(pInstance)
		if orion.PlayerStates[p.UserId] and orion.PlayerStates[p.UserId].Destroy then
			orion.PlayerStates[p.UserId]:Destroy()
		end
		orion.PlayerStates[p.UserId] = nil
		if p == localPlayer then
			orion.PlayerCooldowns[p.UserId] = nil
		end
	end))

	orion._maid:GiveTask(Packet.Orion_PlayerStateChangedNotif.listen(onPlayerStateChangedNotif))
	orion._maid:GiveTask(Packet.Orion_PlayEffectNotif.listen(onPlayEffectNotif))

	print("Orion Combat Framework Initialized on Client.")
end

function orion:Destroy()
	self._maid:Destroy()
	for _, stateMachine in pairs(self.PlayerStates) do
		if stateMachine and stateMachine.Destroy then
			stateMachine:Destroy()
		end
	end
	table.clear(self.RegisteredAttacks)
	table.clear(self.PlayerStates)
	table.clear(self.PlayerCooldowns)
	print("Orion Combat Framework Destroyed.")
end

return orion
