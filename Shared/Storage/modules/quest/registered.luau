--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- registered.luau
-- all the registered quests in-game.

local directory = ReplicatedStorage.ClientModules["quest-modules"]

return {
	{
		name = "Take a Hike",
		module = directory:FindFirstChild("take-a-hike") :: ModuleScript,
	},
} :: {
	{
		module: ModuleScript,
		name: string,
	}
}
