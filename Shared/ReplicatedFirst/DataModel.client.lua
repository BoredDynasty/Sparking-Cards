--!nonstrict

-- DataModel.client.lua

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundManager = require(ReplicatedStorage.Modules.SoundManager)

ReplicatedFirst:RemoveDefaultLoadingScreen()
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

local player = Players.LocalPlayer

local loadingUI = ReplicatedFirst:WaitForChild("Loading"):Clone() :: ScreenGui
loadingUI.Parent = player.PlayerGui :: PlayerGui

local background = loadingUI.CanvasGroup.Background :: Frame

local textIndicator = background.Status.StatusText :: TextLabel
local status = textIndicator.Parent:FindFirstChildOfClass("TextButton") :: TextButton
local str = "[ ID ]"

local skipped = false

local clientAssets = player:GetChildren()
local assetsLoaded = 0

local function preloadAsync()
	--
	task.wait(1.5)
	if not game.Loaded then
		game.Loaded:Wait()
	end

	ContentProvider:PreloadAsync({ 12385329420 })

	local audio = SoundManager.Play(12385329420, nil)

	-- We can reduce loading time by placing in a seperate thread.
	for _, object in pairs(clientAssets) do
		assetsLoaded += 1
		textIndicator.Text = string.gsub(str, "[ ID ]", assetsLoaded .. "/" .. #clientAssets)
		ContentProvider:PreloadAsync(object:GetChildren())
		if skipped then
			break
		end
	end
	--
	local assetNumber = 0
	local _, err
	_, err = pcall(function()
		ContentProvider:PreloadAsync({ ReplicatedStorage }, function(asset)
			if err then
				skipped = true
				warn(err)
			end
			if not skipped then
				assetNumber += 1
				textIndicator.Text = `{assetNumber}`
				status.Text = `Preloading: {asset.Name}`
			end
		end)
	end)
	audio:Destroy()
	print("Finished Loading")
end

local loadingTask = task.spawn(preloadAsync)

status.MouseButton1Click:Once(function()
	skipped = true
	task.cancel(loadingTask)
	loadingUI:Destroy()
end)
task.delay(60, function()
	skipped = true
	task.cancel(loadingTask)
	loadingUI:Destroy()
	print("Loading timed out.")
end)
