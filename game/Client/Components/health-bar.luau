--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local audio = require(ReplicatedStorage.Modules.audio)
local spr = require(ReplicatedStorage.Modules.spr)

-- health-bar.luau

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:FindFirstChild("Humanoid") :: Humanoid

local health_gui = playerGui:WaitForChild("Healthbar")
local health_canvas = health_gui.CanvasGroup

audio:AddSFX("bass-1", 136403006365380)

local main_bar = health_canvas.MainBar

local decrease = main_bar.Decrease
local main = main_bar.Main
local max_size = main.Size.X.Scale

local function onHealthUpdate(health: number)
	local health_percent = health / humanoid.MaxHealth

	main.Visible = false

	spr.stop(decrease)
	spr.stop(main)

	spr.target(decrease, 0.6, 5, {
		Size = UDim2.fromScale(health_percent * max_size, 0.381),
	})
	spr.completed(decrease, function()
		main.Visible = true
		spr.target(main, 0.9, 5, {
			Size = UDim2.fromScale(health_percent * max_size, 0.381),
		})
	end)

	audio:ConfigureSFX("bass-1", {
		volume = health_percent,
	})
	audio:PlaySFX("bass-1")
end

health_canvas.PlayerName.Text = "@" .. player.Name

humanoid.HealthChanged:Connect(onHealthUpdate)

return {}
