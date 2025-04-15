--!strict

-- DataModel.client.lua

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

ReplicatedFirst:RemoveDefaultLoadingScreen()
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

repeat
	task.wait(1)
until game:IsLoaded()

local player = Players.LocalPlayer :: Player

local loadingUI = ReplicatedFirst:WaitForChild("Loading"):Clone() :: ScreenGui
loadingUI.Parent = player.PlayerGui :: PlayerGui

local loadingCanvas = loadingUI:FindFirstChild("CanvasGroup") :: CanvasGroup
local background = loadingCanvas:FindFirstChild("Background") :: Frame

local statusBar = background:WaitForChild("Status")
local textIndicator = statusBar:FindFirstChild("StatusText") :: TextLabel
local status = statusBar:FindFirstChildOfClass("TextButton") :: TextButton
local skipButton = statusBar:FindFirstChild("Skip") :: TextButton
local loader = background:FindFirstChild("LoaderImage") :: ImageLabel -- the spinning wheel

local connection: RBXScriptConnection | nil

local BATCH_SIZE = 60
local MAX_PARALLEL_LOADS = 12

local function skipPreloading()
	loadingUI:Destroy()
	if connection then
		connection:Disconnect()
	end

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

	status.Text = "Skipped."
end

local function preload()
	local startTime = os.clock()

	textIndicator.Text = tostring(game.PlaceVersion) or "hi"

	-- Combine assets into one table
	local assets = {}
	task.spawn(function()
		for _, asset in ipairs(player.PlayerGui:GetChildren()) do
			table.insert(assets, asset)
		end
	end)
	task.spawn(function()
		for _, asset in ipairs(ReplicatedStorage:GetDescendants()) do
			table.insert(assets, asset)
		end
	end)
	local completed = Instance.new("BindableEvent")
	completed.Parent = ReplicatedFirst

	local maxAssets = #assets
	local loadedCount = 0

	skipButton.MouseButton1Click:Once(skipPreloading)

	connection = RunService.Heartbeat:Connect(function()
		loader.Rotation = loader.Rotation + 10
	end)

	-- split assets into batches
	local batches = {}
	for i = 1, #assets, BATCH_SIZE do
		local batch = {}
		for j = i, math.min(i + BATCH_SIZE - 1, #assets) do
			table.insert(batch, assets[j])
		end
		table.insert(batches, batch)
	end

	local activeThreads = 0

	-- process batches in parallel hehe
	for _, batch in ipairs(batches) do
		while activeThreads >= MAX_PARALLEL_LOADS do
			task.wait()
		end

		activeThreads += 1
		task.spawn(function()
			pcall(function()
				ContentProvider:PreloadAsync(batch)
			end)

			loadedCount += #batch
			status.Text = string.format("Loaded: %d/%d", loadedCount, maxAssets)

			activeThreads -= 1
			if activeThreads == 0 and loadedCount >= maxAssets then
				completed:Fire()
			end
		end)
	end

	-- Wait for all batches to complete
	completed.Event:Wait()
	completed:Destroy()

	status.Text = "Loading..."
	local endTime = math.round((os.clock() - startTime) * 10000) / 10000
	print("Loaded in: " .. tostring(endTime))

	loadingUI:Destroy()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	table.clear(assets)

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end

if connection then
	connection:Disconnect()
	connection = nil
end

preload()
