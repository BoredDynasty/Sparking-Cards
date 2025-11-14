--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local trove = require(ReplicatedStorage.Packages.trove)

-- movement-controller.luau

local controller = {}

local _trove = trove.new()

export type MovementController = {
	Update: (number?) -> ...unknown,
	_trove: typeof(trove.new())?,
}

local movement_controllers = table.create(10) :: { MovementController }

function controller:Add(module: ModuleScript)
	local ok, result = pcall(require, module)

	if ok then
		table.insert(movement_controllers, result)
	else
		warn("Failed to require movement module: ", result, module.Name)
	end
end

function controller:GetControllers()
	return movement_controllers
end

function controller:Start()
	_trove:Connect(RunService.Heartbeat, function(deltaTime: number)
		debug.profilebegin("movement-update")

		for i, movement_controller in ipairs(movement_controllers) do
			if movement_controller.Update then
				movement_controller:Update(deltaTime)
			end
		end

		debug.profileend()
	end)
end

return controller
