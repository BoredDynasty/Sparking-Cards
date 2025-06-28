--!strict
--[[
	orionServer.server.luau
	This script is responsible for:
	1. Initializing the Orion combat framework on the server.
	2. Loading and registering all defined attacks from the attacks framework folder.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local orion = require(ReplicatedStorage.Combat.orion)
local Maid = require(ReplicatedStorage.Utility.Maid)

local serverMaid = Maid.new()

-- Wait for Orion to be fully loaded and its functions available
-- This is important if orion.luau might be deferred or takes time to initialize its own dependencies.
if not orion.RegisterAttack or not orion.InitServer then
	warn("orionServer: Orion module not fully loaded or key functions (RegisterAttack, InitServer) missing. Waiting...")
	repeat
		task.wait()
	until orion.RegisterAttack and orion.InitServer
	warn("orionServer: Orion module now loaded.")
end

orion.InitServer() -- Initialize the Orion framework on the server

-- Load and register attacks
local attacksFolder = ReplicatedStorage.Combat.framework:FindFirstChild("attacks")

if attacksFolder then
	for _, attackModule in ipairs(attacksFolder:GetChildren()) do
		if attackModule:IsA("ModuleScript") then
			local success, result = pcall(require, attackModule)
			if success then
				if type(result) == "table" then
					-- Check if it's a list of attacks or a single attack definition
					if result.Name and type(result.Name) == "string" then -- Single attack definition
						orion.RegisterAttack(result.Name, result :: orion.AttackData)
					elseif #result > 0 then -- List of attacks
						for _, attackData in ipairs(result) do
							if type(attackData) == "table" and attackData.Name then
								orion.RegisterAttack(attackData.Name, attackData :: orion.AttackData)
							else
								warn("orionServer: Invalid attack data structure in module", attackModule.Name)
							end
						end
					else
						warn("orionServer: Attack module", attackModule.Name, "did not return a valid attack or list of attacks.")
					end
				else
					warn("orionServer: Attack module", attackModule.Name, "did not return a table.")
				end
			else
				warn("orionServer: Failed to require attack module", attackModule.Name, "-", result)
			end
		end
	end
	print("orionServer: Finished loading and registering attacks.")
else
	warn("orionServer: Attacks folder not found at Shared/Replicated/Combat/framework/attacks/")
end


-- Cleanup when the script is destroyed (e.g. server shutdown)
script.Destroying:Connect(function()
	serverMaid:Destroy()
	if orion and orion.Destroy then
		orion:Destroy() -- Call Orion's own cleanup if it has one
	end
	print("orionServer: Cleaned up.")
end)

print("orionServer.server.luau has finished execution.")
