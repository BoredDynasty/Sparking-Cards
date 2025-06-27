--!strict

--[[
   orion
   combat framework for Sparking Cards
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService") -- Added for input handling

local CombatStructure = require(ReplicatedStorage.Structures.CombatStructure)
-- Assuming states.luau is in Shared/Replicated/Combat/
-- If states.luau is in Shared/Replicated/Structures, the path should be ReplicatedStorage.Structures.states
local states = require(ReplicatedStorage.Combat.states)

local orion = {}
orion.RegisteredAttacks = {} -- Stores data for all registered attacks
orion.PlayerStates = {}      -- Stores the current combat state of each player
orion.PlayerCooldowns = {} -- Stores cooldowns for player attacks

-- Placeholder for RemoteEvents - these should be defined in ReplicatedStorage
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") or Instance.new("Folder", ReplicatedStorage)
remoteEvents.Name = "RemoteEvents"
local executeAttackEvent = remoteEvents:FindFirstChild("Orion_ExecuteAttack") or Instance.new("RemoteEvent", remoteEvents)
executeAttackEvent.Name = "Orion_ExecuteAttack"
local playerStateChangedEvent = remoteEvents:FindFirstChild("Orion_PlayerStateChanged") or Instance.new("RemoteEvent", remoteEvents)
playerStateChangedEvent.Name = "Orion_PlayerStateChanged"


-- Core API Functions

function orion.RegisterAttack(attackName: string, attackData: table)
	-- Validate attackData structure (optional but recommended)
	if not attackData.Type or not attackData.Input then
		warn("Orion: Attempted to register attack with missing Type or Input:", attackName)
		return
	end
	orion.RegisteredAttacks[attackName] = attackData
	print("Orion: Registered attack -", attackName)
end

function orion.ExecuteAttack(player: Player, attackName: string)
	local character = player.Character
	if not character or not character:FindFirstChild("Humanoid") or character:FindFirstChildOfClass("Humanoid").Health <= 0 then
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
	if orion.PlayerCooldowns[player.UserId] and orion.PlayerCooldowns[player.UserId][attackName] and tick() < orion.PlayerCooldowns[player.UserId][attackName] then
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
		local sound = Instance.new("Sound")
		sound.SoundId = attackData.SoundId
		sound.Parent = character.PrimaryPart or character
		sound:Play()
		game.Debris:AddItem(sound, sound.TimeLength) -- Clean up sound
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

function orion.HandleDamage(sourcePlayer: Player, targetPlayer: Player, damageAmount: number, attackName: string)
	local targetCharacter = targetPlayer.Character
	if not targetCharacter then return end

	local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid or targetHumanoid.Health <= 0 then return end

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

	print("Orion:", sourcePlayer.Name, "damaged", targetPlayer.Name, "for", finalDamage, "HP with", attackName or "Unknown Attack")
	targetHumanoid:TakeDamage(finalDamage)

	if targetHumanoid.Health <= 0 then
		print("Orion:", targetPlayer.Name, "was defeated by", sourcePlayer.Name)
		-- Handle defeat logic (e.g., respawn, rewards for sourcePlayer)
		orion.SetPlayerState(targetPlayer, states.Defeated) -- Example state
	else
		-- Handle knockback (SERVER-SIDE)
		if attackData and attackData.Knockback then
			print("Orion: Applying knockback to", targetPlayer.Name)
			local knockbackForce = attackData.Knockback.Force or CombatStructure.Knockback.DamageScale * finalDamage
			local knockbackDuration = attackData.Knockback.Duration or CombatStructure.Knockback.Duration

			local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
			if targetRoot then
				local direction = (targetRoot.Position - (sourcePlayer.Character.PrimaryPart.Position)).Unit
				local bv = Instance.new("BodyVelocity")
				bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
				bv.Velocity = direction * knockbackForce + Vector3.new(0, knockbackForce * 0.5, 0) -- Add some upward force
				bv.Parent = targetRoot
				game.Debris:AddItem(bv, knockbackDuration)
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
	if orion.PlayerStates[player.UserId] == state then return end -- No change

	orion.PlayerStates[player.UserId] = state
	print("Orion:", player.Name, "state changed to:", state)
	-- Fire remote event to update client-side visuals for the state (e.g., blocking animation, stun effect)
	playerStateChangedEvent:FireClient(player, state)
	-- If multiple clients need to know (e.g. for other players' animations), use :FireAllClients()
	-- or :FireClient(otherPlayer, player, state) for each otherPlayer
end

function orion.GetPlayerState(player: Player)
	return orion.PlayerStates[player.UserId] or states.Idle
end

-- SERVER-SIDE: Handler for client attack requests
local function onServerExecuteAttack(player: Player, attackName: string)
	-- Add server-side validation if needed (e.g., sanity checks)
	print("Orion Server: Received attack request from", player.Name, "for", attackName)
	orion.ExecuteAttack(player, attackName)
end

-- CLIENT-SIDE: Input Handling
local function setupClientInput()
	if not Players.LocalPlayer then return end -- Should not happen in a LocalScript context but good check

	local function onInputBegan(input: InputObject, gameProcessedEvent: boolean)
		if gameProcessedEvent then return end

		local player = Players.LocalPlayer
		if not player or not player.Character or orion.GetPlayerState(player) == states.Defeated then return end

		-- Iterate through registered attacks to find a match for the input
		for attackName, attackData in pairs(orion.RegisteredAttacks) do
			if attackData.Type == "M1" and input.UserInputType == Enum.UserInputType.MouseButton1 then
				print("Client: M1 input detected for", attackName)
				executeAttackEvent:FireServer(attackName)
				return -- Process only one M1 attack per click
			elseif attackData.Input == input.KeyCode and (attackData.Type == "Skill" or attackData.Type == "Ultimate") then
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
