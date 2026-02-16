--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local MovementConfig = require(ReplicatedStorage.Structures.MovementConfig)

local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local trove = require(ReplicatedStorage.Packages.trove)

-- jump-controller.luau

local controller = {}

local player = playerMarshaller.get()
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

local _trove = trove.new()
controller._trove = _trove

local character_trove = _trove:Extend()

local _dust = fetchAsset("FootstepDust")

local last_jump_drain = 0

local function setupCharacter(new_character: Model)
	character_trove:Clean()
	character = new_character
	humanoid = character:WaitForChild("Humanoid") :: Humanoid

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

	character_trove:Connect(humanoid.StateChanged, function(o, new_state)
		if new_state ~= Enum.HumanoidStateType.Landed then
			return
		end

		-- TODO) do camera shake & sound

		local primary_part = character.PrimaryPart
		if not primary_part then
			return
		end

		local dust = _dust:Clone() :: BasePart
		dust.CFrame = primary_part.CFrame * CFrame.new(0, -humanoid.HipHeight - 4, 0)
		dust.CanCollide = false
		dust.CanQuery = false
		dust.CanTouch = false
		dust.Parent = workspace

		local emitter = dust:FindFirstChildOfClass("ParticleEmitter")
		if not emitter then
			print("no particle emitter?")

			return
		end

		emitter:Emit(3)

		task.delay(1 / 2, function()
			if not dust then
				return
			end

			dust:Destroy()
		end)
	end)
end

if character then
	setupCharacter(character)
end

player.CharacterAdded:Connect(setupCharacter)

return controller
