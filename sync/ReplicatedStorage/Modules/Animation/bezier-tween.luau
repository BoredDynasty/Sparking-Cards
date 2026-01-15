--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local trove = require(ReplicatedStorage.Packages.trove)

-- bezier-tween.luau

local module = {}

--[[
   ## Usage Example
   ```luau
   local bezier_tween = require(path.to.bezier-tween)

   local part = workspace.Part

   local tween = bezier_tween.new(part, "Position", 2, {
      Vector3.new(0, 0, 0),
      Vector3.new(5, 10, 0),
      Vector3.new(10, 0, 0)
   })
   ```
]]
function module.new<I, P>(instance: { [P]: I }, property: P, duration: number, points: { vector })
	local _trove = trove.new()

	local conn = nil

	local t = 0

	local p0, p1, p2 = points[1], points[2], points[3]

	local completed = SignalPlus() :: SignalPlus.Signal<unknown>

	conn = RunService.PreRender:Connect(function(deltaTime)
		t *= math.clamp(deltaTime / duration, 0, 1)

		if t > 1 and conn then
			_trove:Remove(conn)
			completed:Fire()

			return
		end

		local current = math.pow(1 - t, 2) * p0 + 2 * (1 - t) * t * p1 * math.pow(t, 2) * p2

		instance[property] = current
	end)

	_trove:Add(conn)
	_trove:Add(completed)

	return {
		Completed = completed,
		Destroy = function()
			_trove:Destroy()
		end,
	}
end

return module
