--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")

local tablekit = require(ReplicatedStorage.Packages.tablekit)

-- spin.luau

local module = {}

local objects = {} :: ObjectList

type Object = {
	object: BasePart,
	speed: number,
	frame_rate: number,
	angle: number,
	y_axis: number,
	_accum: number, -- accumulated time since last frame
}
type ObjectList = { Object }

function module:SpinObject(object: BasePart, speed: number, frame_rate: number)
	local data = {
		object = object,
		speed = speed,
		frame_rate = frame_rate,
		angle = 0,
		y_axis = 0,
		_accum = 0,
	}

	table.insert(objects, data)
end

function module:Start()
	local conn = RunService.Heartbeat:Connect(function(deltaTime)
		if tablekit.IsEmpty(objects :: any) then
			return
		end

		for _, data in ipairs(objects) do
			data._accum += deltaTime
			local frame_interval = 1 / data.frame_rate

			while data._accum >= frame_interval do
				data._accum -= frame_interval

				local current_time = os.clock()
				data.angle += data.speed * frame_interval
				data.y_axis = math.sin(current_time * 3) / 2

				local radii = math.rad(data.angle)
				local coordinate = CFrame.new(0, data.y_axis, 0) * CFrame.Angles(0, radii, 0)

				data.object.CFrame *= coordinate
			end
		end
	end)

	return {
		Destroy = function()
			conn:Disconnect()
		end,
	}
end

return module
