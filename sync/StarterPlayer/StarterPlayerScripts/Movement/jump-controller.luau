--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local MovementConfig = require(ReplicatedStorage.Structures.MovementConfig)
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local trove = require(ReplicatedStorage.Packages.trove)

-- jump-controller.luau

local controller = {}

local player = playerMarshaller.get()
local character = characterMarshaller.get(player)

local humanoid = character:WaitForChild("Humanoid") :: Humanoid

local _trove = trove.new()
controller._trove = _trove

local _dust = fetchAsset("FootstepDust")

local function onJumpRequest()
	-- negated the stamina

	_trove:Connect(UserInputService.JumpRequest, function()
		if humanoid.Health <= 0 then
			return
		end

		if not character.PrimaryPart then
			return
		end

		if humanoid:GetState() == Enum.HumanoidStateType.Jumping then
			return
		end

		if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
			return
		end

		local current_stamina = character:GetAttribute("Stamina") :: number or 0
		if current_stamina < MovementConfig.Jump.StaminaCost then
			return
		end

		-- TODO) do a camera shake on land

		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

		local new_stamina = current_stamina - MovementConfig.Jump.StaminaCost

		character:SetAttribute("Stamina", new_stamina)
		character:SetAttribute("AntiRegenerate", true)

		task.delay(0.5, function()
			if not character then
				return
			end

			character:SetAttribute("AntiRegenerate", false)
		end)
	end)
end

local function onLanded()
	_trove:Connect(humanoid.StateChanged, function(o, new_state)
		if new_state ~= Enum.HumanoidStateType.Landed then
			return
		end

		-- TODO) do camera shake & sound

		local primary_part = character.PrimaryPart
		if not primary_part then
			return
		end

		local dust = _dust:Clone() :: BasePart
		dust.CFrame = primary_part.CFrame * CFrame.new(0, -humanoid.HipHeight - 2, 0)
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

onJumpRequest()
onLanded()

return controller
