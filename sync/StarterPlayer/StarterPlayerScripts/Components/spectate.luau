--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local audio = require(ReplicatedStorage.Modules.audio)
local letterbox = require(StarterPlayer.StarterPlayerScripts.Components.letterbox)
local observer = require(ReplicatedStorage.Utility.observer)
local pop = require(StarterPlayer.StarterPlayerScripts.Interface.pop)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local spr = require(ReplicatedStorage.Modules.spr)
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

local spectating = observer.new(false) :: observer.Observer<boolean>
local current_index = observer.new(1) :: observer.Observer<number>

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
		print("too little players in-game to spectate!")

		return
	end

	local i = current_index:Get()

	local new_player = player_list[i]
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

	spectating:Set(true)

	-- if we want, we can set the index to 1.
end

function module:Stop()
	camera.CameraSubject = humanoid
	spectate_gui.Container.Visible = false

	letterbox:Off()

	spectating:Set(true)

	-- if we want, we can set the index to 1.
end

function module:IsSpectating()
	return spectating:Get()
end

shadow(next_button)
shadow(back_button)

local current_button = observer.new() :: observer.Observer<TextButton>

next_button.Activated:Connect(function()
	pop(next_button, 1.8)

	audio:PlaySFX("click")

	current_button:Set(next_button)

	module:Next()
end)
back_button.Activated:Connect(function()
	pop(back_button, 1.8)

	audio:PlaySFX("click")

	current_button:Set(back_button)

	module:Back()
end)

current_button:Watch(function(new_button, old_button)
	if new_button then
		spr.target(new_button, 0.8, 7, {
			Size = UDim2.fromScale(0.343, 0.916),
		})
	end

	if old_button then
		spr.target(old_button, 0.8, 7, {
			Size = UDim2.fromScale(0.137, 0.916),
		})
	end
end)

Players.PlayerAdded:Connect(updatePlayerList)

return module
