--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local space = require(ReplicatedStorage.Modules.Serialization.space)
local trove = require(ReplicatedStorage.Packages.trove)

-- footsteps.luau

local player = playerMarshaller.get()
local character = characterMarshaller.get(player)

local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

local state = observer.new(humanoid:GetState())
local previousMaterial = observer.new("Air")

local sounds = SoundService:WaitForChild("Footsteps") :: Folder & { Sound }

local _trove = trove.new()

_trove:Connect(humanoid.Running :: RBXScriptSignal, function(speed)
	state:Set(humanoid:GetState())
end)

local function getMaterial()
	local floorMaterial = humanoid.FloorMaterial
	floorMaterial = floorMaterial or Enum.Material.Air
	local str = floorMaterial.Name
	return str
end

state:Watch(function(newState, oldState)
	local connection = nil

	if newState == Enum.HumanoidStateType.Running then
		local material = getMaterial()

		if previousMaterial and material ~= previousMaterial:Get() then
			previousMaterial:Set(material)

			local sound = sounds:FindFirstChild(material) :: Sound?

			if sound then
				sound.PlaybackSpeed = humanoid.WalkSpeed / 14
				sound.Playing = true
			end
		end

		-- footstep dust
		local dust = fetchAsset("FootstepDust") :: BasePart
		dust.Parent = character
		dust.CFrame = rootPart.CFrame * CFrame.new(0, -3, 0)

		local particle = dust:FindFirstChildOfClass("ParticleEmitter") :: ParticleEmitter

		local lastPosition = observer.new(rootPart.CFrame * CFrame.new(0, -3, 0))
		local distance = observer.new(0)

		local PARTICLES_PER_STUD = 1

		particle.Enabled = false

		if dust and particle then
			connection = _trove:Connect(RunService.Stepped :: RBXScriptSignal, function(deltaTime: number)
				local position = rootPart.CFrame * CFrame.new(0, -3, 0)

				local displacement = space.toVector3(position) - space.toVector3(lastPosition:Get())
				distance:Calculate(function(current)
					return math.abs(current + displacement.Magnitude)
				end)

				lastPosition:Set(position)

				local n = math.floor(distance:Get() * PARTICLES_PER_STUD * deltaTime)

				dust.CFrame = position

				particle:Emit(n)
			end)
		end
	else
		for _, sound: Sound in sounds:GetChildren() :: { Sound } do
			sound.Playing = false
		end
		if connection then
			_trove:Remove(connection)
		end
	end
end)

return {
	state = state,
	_trove = _trove,
}
