--!strict

-- DataModel.client.luau

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

ReplicatedFirst:RemoveDefaultLoadingScreen()
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

repeat
	task.wait(1)
until game:IsLoaded()

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

local connection: RBXScriptConnection | nil

local BATCH_SIZE = 12
local MAX_PARALLEL_LOADS = bit32.lshift(8, 1)
-- 8 ^ 2 replaced with bitwise left shift (8 << 1 = 16)

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

	textIndicator.Text = ("%s"):format(tostring(game.PlaceId)) or "hi"

	-- Combine assets into one table
	local pre_allocated = 2000
	local assets = table.create(pre_allocated) -- pre-allocate approximate size
	-- for a more accurate maxAssets count, make it asynchronous
	for _, asset in ipairs(player:GetDescendants()) do
		table.insert(assets, asset)
	end
	for _, asset in ipairs(ReplicatedStorage:GetDescendants()) do
		table.insert(assets, asset)
	end
	local completed = Instance.new("BindableEvent")
	completed.Parent = ReplicatedFirst

	local maxAssets = #assets
	local loadedCount = 0

	skipButton.MouseButton1Click:Once(skipPreloading)

	local renderTask = task.spawn(function()
		local circle = 360
		connection = RunService.RenderStepped:Connect(function(deltaTime: number)
			task.wait()
			loader.Rotation += circle * deltaTime
		end)
	end)

	-- split assets into batches
	local batches: { ((({ any }?) & { any } & { any })?) & ({ any }?) & { any } & { any } } = {}
	for i = 1, #assets, BATCH_SIZE do
		local batch = {}
		for j = i, math.min(i + BATCH_SIZE - 1, #assets) do
			table.insert(batch, assets[j])
		end
		table.insert(batches, batch)
	end

	local activeThreads = 0
	local success, err = nil, nil
	-- process batches in parallel hehe
	for _, batch in ipairs(batches) do
		while activeThreads >= MAX_PARALLEL_LOADS do
			task.wait()
		end

		activeThreads += 1
		task.spawn(function()
			success, err = pcall(function()
				ContentProvider:PreloadAsync(batch)
			end)
			if not success or err ~= nil then
				warn(err)
				local banner = background:FindFirstChild("Banner") :: ImageLabel
				local errorImage = "86354301652315"
				local assetPrefix = "rbxassetid://"
				banner.Image = assetPrefix .. errorImage
				local concatenated_batch: string
				for k, v in pairs(batch) do
					concatenated_batch = concatenated_batch .. k .. ":" .. v .. "\n"
					-- concatenate key/value pairs, with a newline in-between
				end
				status.Text = "Couldn't download batch: "
					.. table.concat(
						table.create(#batch, function(i)
							return tostring(batch[i])
						end),
						", "
					)
				print("Couldn't download batch: ", concatenated_batch)
				-- Update status image to indicate error
				local statusImage = statusBar:FindFirstChild("statusImage") :: ImageLabel
				local statusImg = "10747384394"
				statusImage.Image = assetPrefix .. statusImg
			end
			loadedCount += #batch
			status.Text = string.format("Loaded: %d/%d", loadedCount, maxAssets or #assets)

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
	local rawEndTime = os.clock() - startTime
	local endTime = ("%.2f seconds"):format(rawEndTime)
	print("Loaded in: " .. tostring(endTime))

	loadingUI:Destroy()
	if connection then
		connection:Disconnect()
		connection = nil
		task.cancel(renderTask)
	end
	table.clear(assets)
	table.clear(batches)

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end

preload()
