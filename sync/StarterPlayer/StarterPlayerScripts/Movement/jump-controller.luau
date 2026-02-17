--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local MovementConfig = require(ReplicatedStorage.Structures.MovementConfig)
local emit_dust = require(StarterPlayer.StarterPlayerScripts.Gameplay["emit-dust"])

local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local trove = require(ReplicatedStorage.Packages.trove)

-- jump-controller.luau

local controller = {}

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

local _trove = trove.new()
controller._trove = _trove

local character_trove = _trove:Extend()

local last_jump_drain = 0

local front_flip_animation_id = 91746815516834
local last_front_flip_frame_offset = 1 / 60
local is_space_held = false

local function is_airborne_state(state: Enum.HumanoidStateType): boolean
	return state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall
end

local function setupCharacter(new_character: Model)
	character_trove:Clean()
	character = new_character
	humanoid = character:WaitForChild("Humanoid") :: Humanoid

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local front_flip_animation = Instance.new("Animation")
	front_flip_animation.AnimationId = ("rbxassetid://%d"):format(front_flip_animation_id)

	local front_flip_track = (animator :: Animator):LoadAnimation(front_flip_animation)
	front_flip_track.Priority = Enum.AnimationPriority.Action
	front_flip_track.Looped = false

	local front_flip_token = 0
	local front_flip_active = false

	local function is_airborne(): boolean
		return is_airborne_state(humanoid:GetState())
	end

	local function stop_front_flip()
		front_flip_token += 1
		front_flip_active = false
		front_flip_track:AdjustSpeed(1)
		front_flip_track:Stop(0.1)
	end

	local function hold_front_flip_last_frame()
		if front_flip_track.Length <= 0 then
			return
		end

		if not front_flip_track.IsPlaying then
			front_flip_track:Play(0.05, 1, 0)
		end

		front_flip_track.TimePosition = math.max(front_flip_track.Length - last_front_flip_frame_offset, 0)
		front_flip_track:AdjustSpeed(0)
	end

	local function schedule_front_flip_freeze(token: number)
		task.spawn(function()
			while token == front_flip_token and front_flip_track.Length <= 0 do
				task.wait()
			end

			if token ~= front_flip_token then
				return
			end

			local track_length = front_flip_track.Length
			if track_length <= 0 then
				return
			end

			task.wait(track_length)

			if token ~= front_flip_token then
				return
			end

			if is_airborne() and is_space_held and front_flip_active then
				hold_front_flip_last_frame()

				return
			end

			stop_front_flip()
		end)
	end

	local function start_front_flip()
		if front_flip_active then
			return
		end

		front_flip_active = true
		front_flip_token += 1
		local token = front_flip_token

		front_flip_track:Stop(0)
		front_flip_track.TimePosition = 0
		front_flip_track:Play(0.05, 1, 1)

		schedule_front_flip_freeze(token)
	end

	character_trove:Add(function()
		stop_front_flip()
		front_flip_animation:Destroy()
	end)

	local default_jump_power = humanoid.JumpPower
	local default_jump_height = humanoid.JumpHeight

	local was_jumping_enabled = humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)

	character_trove:Connect(character:GetAttributeChangedSignal("Stamina"), function()
		local current_stamina = character:GetAttribute("Stamina") :: number or 0
		if current_stamina < MovementConfig.Jump.StaminaCost then
			humanoid.JumpPower = 0
			humanoid.JumpHeight = 0

			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		else
			humanoid.JumpPower = default_jump_power
			humanoid.JumpHeight = default_jump_height

			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, was_jumping_enabled)
		end
	end)

	character_trove:Connect(UserInputService.JumpRequest, function()
		if humanoid.Health <= 0 then
			return
		end

		if not character.PrimaryPart then
			return
		end

		if time() - last_jump_drain < 0.2 then
			return
		end

		local state = humanoid:GetState()
		if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then
			return
		end

		local current_stamina = character:GetAttribute("Stamina") :: number or 0
		if current_stamina < MovementConfig.Jump.StaminaCost then
			return
		end

		last_jump_drain = time()

		-- Apply jump cost
		local new_stamina = math.max(0, current_stamina - MovementConfig.Jump.StaminaCost)
		character:SetAttribute("Stamina", new_stamina)
	end)

	character_trove:Connect(UserInputService.InputBegan, function(input, game_processed_event)
		if game_processed_event then
			return
		end

		if input.KeyCode ~= Enum.KeyCode.Space then
			return
		end

		is_space_held = true

		if humanoid.Health <= 0 then
			return
		end

		if is_airborne() then
			start_front_flip()
		end
	end)

	character_trove:Connect(UserInputService.InputEnded, function(input)
		if input.KeyCode ~= Enum.KeyCode.Space then
			return
		end

		is_space_held = false
		stop_front_flip()
	end)

	character_trove:Connect(humanoid.StateChanged, function(_old_state, new_state)
		if is_airborne_state(new_state) and is_space_held then
			start_front_flip()
		end

		if new_state ~= Enum.HumanoidStateType.Landed then
			return
		end

		stop_front_flip()

		-- TODO) do camera shake & sound

		local primary_part = character.PrimaryPart
		if not primary_part then
			return
		end

		local coordinate = primary_part.CFrame * CFrame.new(0, -humanoid.HipHeight - 4, 0)

		for i = 1, 20 do
			emit_dust.emit(coordinate)
		end
	end)
end

if character then
	setupCharacter(character)
end

player.CharacterAdded:Connect(setupCharacter)

return controller
