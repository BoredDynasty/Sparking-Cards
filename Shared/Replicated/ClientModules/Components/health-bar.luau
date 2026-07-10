--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local audio = require(ReplicatedStorage.Modules.audio)
local counter = require(ReplicatedStorage.ClientModules.markdown["text-counter"])
local fetchProfile = require(ReplicatedStorage.ClientModules.Utilities.fetchProfile)
local spr = require(ReplicatedStorage.Modules.spr)

-- health-bar.luau
-- inspired by this twitter post:
-- https://x.com/Calamity_Corp/status/2072110255849554163
-- TODO) make it more like the one in the twitter post.

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:FindFirstChild("Humanoid") :: Humanoid

local health_gui = playerGui:WaitForChild("Healthbar")
local health_canvas = health_gui.CanvasGroup

local main_bar = health_canvas.Frame.Healthbar
local health_label = health_canvas.Frame.Health

local max_size = main_bar.Size.X.Scale

local function onHealthUpdate(health: number)
	local health_percent = health / humanoid.MaxHealth

	local new_size = UDim2.new(max_size * health_percent, 0, main_bar.Size.Y.Scale, 0)
	spr.target(main_bar, 0.8, 5, { Size = new_size })

	-- for now, we wont use a counter.
	health_label.Text = math.floor(health) .. "/" .. math.floor(humanoid.MaxHealth)
end

local function onPrismUpdate(prisms: number)
	local prisms_label = health_canvas.Frame.Prisms
	prisms_label.Text = "$" .. prisms
end

humanoid.HealthChanged:Connect(onHealthUpdate)
-- every few seconds, update the prism count
local function updatePrisms()
	local profile = fetchProfile(player)
	if profile then
		local prisms = profile.Data.prisms
		onPrismUpdate(prisms)
	end
end

task.spawn(function()
	repeat
		updatePrisms()
		task.wait(5)
	until false
end)

return {}
