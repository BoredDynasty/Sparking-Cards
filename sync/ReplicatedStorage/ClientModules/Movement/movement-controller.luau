--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local trove = require(ReplicatedStorage.Packages.trove)

-- movement-controller.luau

local controller = {}

local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

local _trove = trove.new()

export type MovementController = {
	Update: (number?) -> ...unknown,
	_trove: typeof(trove.new())?,
}

local movement_controllers = {} :: { MovementController }

function controller:Add(module: ModuleScript)
	local ok, result: MovementController = pcall(require, module)

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

local died_conn = nil
local function onCharacterAdded(new_character: Model)
	if died_conn then
		died_conn:Disconnect()
	end

	local humanoid = new_character:WaitForChild("Humanoid") :: Humanoid

	died_conn = humanoid.Died:Connect(function()
		for i, movement_controller in ipairs(movement_controllers) do
			if movement_controller._trove then
				movement_controller._trove:Clean()
			end
		end
	end)
end

player.CharacterAdded:Connect(onCharacterAdded)

return controller
