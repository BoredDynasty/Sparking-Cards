--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packet = require(ReplicatedStorage.Packet)
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local impact = require(ReplicatedStorage.Combat.framework.effects.impact)
local observer = require(ReplicatedStorage.Utility.observer)
local trove = require(ReplicatedStorage.Packages.trove)

-- throw.luau

export type throw = {
	direction: Vector3,
	speed: number, -- studs/s -- studs per second
	character: characterMarshaller.Character,
}

local castParams = RaycastParams.new()
castParams.FilterType = Enum.RaycastFilterType.Exclude
local MAX_THROW_DURATION = 3

return function(parameters: throw)
	local character = parameters.character
	local humanoid = character.Humanoid
	local rootPart = character.HumanoidRootPart

	local startTime = os.clock()

	-- disable character control
	humanoid.PlatformStand = true

	local _trove = trove.new()
	local connection = nil
	connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		local elaspedTime = os.clock() - startTime

		-- check if max duration exceeded
		if elaspedTime > MAX_THROW_DURATION then
			_trove:Clean()
			return
		end

		-- Move character
		local movement = parameters.direction * parameters.speed * deltaTime
		-- check for obstacles
		castParams.FilterDescendantsInstances = { character }
		local castResult = workspace:Raycast(rootPart.Position, movement, castParams)
		if castParams then
			_trove:Clean()
			Packet.ReplicateAnimation.sendToAll({ identification = "" }) -- TODO) add throw anim
			impact({
				position = castResult.Position,
				direction = parameters.direction,
				magnitude = 2,
				duration = 0.5,
			})
			return
		end
		rootPart.CFrame += movement
	end)
	_trove:Add(connection)
	local connectionobserver = observer.new(connection)
	connectionobserver.Changed:Connect(function()
		if connection and connection.Connected then
			_trove:Clean()
			task.defer(_trove.Destroy, _trove)
			task.defer(connectionobserver.Destroy, connectionobserver)
		end
	end)
end
