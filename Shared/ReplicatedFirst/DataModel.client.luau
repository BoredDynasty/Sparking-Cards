--!strict

-- DataModel.client.luau

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

if RunService:IsStudio() then
	-- peace of mind for me :)
	script.Disabled = true
	script:Destroy()
end

ReplicatedFirst:RemoveDefaultLoadingScreen()
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

game.Loaded:Wait()

local player = Players.LocalPlayer :: Player

local loadingUI = ReplicatedFirst:WaitForChild("Loading"):Clone() :: ScreenGui
loadingUI.Parent = player.PlayerGui :: PlayerGui

local loadingCanvas = loadingUI:WaitForChild("CanvasGroup") :: CanvasGroup
local background = loadingCanvas:WaitForChild("Background") :: Frame

local statusBar = background:WaitForChild("Status")
local textIndicator = statusBar:FindFirstChild("StatusText") :: TextLabel
local status = statusBar:FindFirstChildOfClass("TextButton") :: TextButton
local skipButton = statusBar:FindFirstChild("Skip") :: TextButton
local loader = background:FindFirstChild("LoaderImage") :: ImageLabel -- the spinning wheel

local connection: RBXScriptConnection? = nil

local BATCH_SIZE = 50
local MAX_PARALLEL_LOADS = 8

local visited = {}

local function gatherAssets(root: Instance, assets: { Instance })
	for _, inst in root:GetChildren() do
		if not visited[inst] then
			visited[inst] = true
			assets[#assets + 1] = inst
			gatherAssets(inst, assets)
		end
	end
end

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
	debug.profilebegin("PreloadAssets")
	local startTime = os.clock()

	textIndicator.Text = ("%s"):format(tostring(game.PlaceId)) or "hi"

	-- Combine assets into one table
	local pre_allocated = 3000
	local assets = table.create(pre_allocated) :: { Instance } -- pre-allocate approximate size
	-- for a more accurate maxAssets count, make it asynchronous
	-- gatherAssets(player, assets)
	gatherAssets(ReplicatedStorage, assets)

	local maxAssets = #assets
	local loadedCount = 0

	skipButton.MouseButton1Click:Once(skipPreloading)

	local circle = 360
	connection = RunService.RenderStepped:Connect(function(deltaTime: number)
		loader.Rotation += circle * deltaTime
	end)

	-- split into batches
	local batches = {}
	for i = 1, maxAssets, BATCH_SIZE do
		local batch = table.create(BATCH_SIZE)

		for j = i, math.min(i + BATCH_SIZE - 1, maxAssets) do
			batch[#batch + 1] = assets[j]
		end

		batches[#batches + 1] = batch
	end

	local activeThreads = 0
	local completed = Instance.new("BindableEvent")
	-- process batches simultaneously
	for _, batch in ipairs(batches) do
		while activeThreads >= MAX_PARALLEL_LOADS do
			RunService.Heartbeat:Wait()
		end

		activeThreads += 1
		task.spawn(function()
			local success, err = pcall(ContentProvider.PreloadAsync, ContentProvider, batch)
			if not success or err ~= nil then
				warn(err)
			end
			loadedCount += #batch
			---task.defer(function()
			status.Text = string.format("Loaded: %d/%d", loadedCount, maxAssets)
			---end)

			activeThreads -= 1
			if loadedCount >= maxAssets then
				completed:Fire()
			end
		end)
	end

	-- Wait for all batches to complete
	completed.Event:Wait()
	completed:Destroy()

	status.Text = "Finalizing..."
	local rawEndTime = os.clock() - startTime
	local endTime = ("%.2f seconds"):format(rawEndTime)
	print("Loaded in: " .. tostring(endTime))

	loadingUI:Destroy()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	table.clear(assets)
	table.clear(batches)
	table.clear(visited)
	assets, batches = nil, nil

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	debug.profileend()
end

preload()
