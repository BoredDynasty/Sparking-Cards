--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local letterbox = require(StarterPlayer.StarterPlayerScripts.Components.letterbox)
local observer = require(ReplicatedStorage.Utility.observer)
local pop = require(StarterPlayer.StarterPlayerScripts.Interface.pop)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local transition = require(StarterPlayer.StarterPlayerScripts.Interface.transition)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- spectate.luau

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait() :: typemarshaller.Character
local humanoid = character:FindFirstChildOfClass("Humanoid")

local camera = workspace.CurrentCamera

local player_gui = player.PlayerGui

local spectate_gui = player_gui.Spectate

local next_button = spectate_gui.Container.Next
local back_button = spectate_gui.Container.Back
local label = spectate_gui.Container.TextLabel

local spectating = observer.new(false)
local current_index = observer.new(1)

local player_list = table.create(#Players:GetPlayers(), player)
-- dont worry about what we put in the 2nd arguement :]

local function updatePlayerList()
	-- wipe off existing

	table.clear(player_list)

	for i, other_player in ipairs(Players:GetPlayers()) do
		if other_player ~= player then
			table.insert(player_list, other_player)
		end
	end
end

local function updateSpectator()
	if #Players:GetPlayers() <= 1 then
		return
	end

	local new_player = player_list[current_index:Get()]
	local new_character = new_player.Character :: typemarshaller.Character

	if new_player then
		label.Text = "@" .. new_player.DisplayName

		local new_humanoid = new_character:FindFirstChild("Humanoid") :: Humanoid
		if new_character and new_humanoid then
			camera.CameraSubject = new_humanoid
		end
	end
end

local module = {}

function module:Next()
	if current_index:Get() < #player_list then
		current_index:Map(function(current)
			return current + 1
		end)
	else
		current_index:Set(1)
	end

	updateSpectator()
end

function module:Back()
	if current_index:Get() > 1 then
		current_index:Map(function(current)
			return current - 1
		end)
	else
		current_index:Set(#player_list)
	end

	updateSpectator()
end

function module:On()
	transition:Circle({
		duration = 2,
	})

	updatePlayerList()
	updateSpectator()

	spectate_gui.Container.Visible = true

	letterbox:On()

	-- if we want, we can set the index to 1.
end

function module:Stop()
	camera.CameraSubject = humanoid
	spectate_gui.Container.Visible = false

	letterbox:Off()

	-- if we want, we can set the index to 1.
end

shadow(next_button)
shadow(back_button)

next_button.Activated:Connect(function()
	pop(next_button, 1.8)

	module:Next()
end)
back_button.Activated:Connect(function()
	pop(back_button, 1.8)

	module:Back()
end)

Players.PlayerAdded:Connect(updatePlayerList)

return module
