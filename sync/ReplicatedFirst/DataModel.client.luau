--!strict

-- DataModel.client.luau

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
--[[
if RunService:IsStudio() then
	-- peace of mind for me :)
	script.Disabled = true
	script:Destroy()
end
--]]
ReplicatedFirst:RemoveDefaultLoadingScreen()
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

game.Loaded:Wait()

local player = Players.LocalPlayer :: Player

local loadingUI = ReplicatedFirst.Loading:Clone() :: ScreenGui
loadingUI.Parent = player.PlayerGui :: PlayerGui

local loadingCanvas = loadingUI:FindFirstChild("CanvasGroup") :: CanvasGroup
local background = loadingCanvas:FindFirstChild("Background") :: Frame

local statusBar = background:FindFirstChild("Status") :: Frame
local textIndicator = statusBar:FindFirstChild("StatusText") :: TextLabel
local status = statusBar:FindFirstChildOfClass("TextButton") :: TextButton
local skipButton = statusBar:FindFirstChild("Skip") :: TextButton
local loader = background:FindFirstChild("LoaderImage") :: ImageLabel -- the spinning wheel

local connection = nil

local BATCH_SIZE, MAX_PARALLEL_LOADS = 12, 32

local function skipPreloading()
	loadingUI:Destroy()
	if connection then
		connection:Disconnect()
	end

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end

local function preload()
	if RunService:IsStudio() then
		skipPreloading()

		return
	end
	debug.profilebegin("PreloadAssets")
	local start_time = os.clock()

	textIndicator.Text = ("%s"):format(tostring(game.PlaceId)) or "hi"

	-- Combine assets into one table
	local pre_allocated = 3000
	local assets = table.create(pre_allocated) :: { Instance } -- pre-allocate approximate size

	local descendant_index = 1

	-- for a more accurate maxAssets count, make it asynchronous
	for i, asset in ipairs(player:GetDescendants()) do
		table.insert(assets, asset)

		descendant_index += 1
	end
	for i, asset in ipairs(ReplicatedStorage:GetDescendants()) do
		table.insert(assets, asset)

		descendant_index += 1
	end

	-- trim excess if over-allocated
	if descendant_index <= pre_allocated then
		table.move(assets, 1, descendant_index - 1, 1, assets)
	end

	local max_assets = #assets
	local loaded_count = 0

	skipButton.MouseButton1Click:Once(skipPreloading)

	local circle = 360
	connection = RunService.RenderStepped:Connect(function(deltaTime: number)
		loader.Rotation += circle * deltaTime
	end)

	-- split into batches
	local batches = {} :: { { Instance } }
	for i = 1, max_assets, BATCH_SIZE do
		-- better variable names pls
		local end_index = math.min(i + BATCH_SIZE - 1, max_assets)

		local batch = table.create(BATCH_SIZE) :: { Instance }

		local asset = table.move(assets, i, end_index, 1, batch)

		table.insert(batches, asset)

		--[[
			local batch = table.create(BATCH_SIZE) :: { Instance }

			for j = i, math.min(i + BATCH_SIZE - 1, max_assets) do
				table.insert(batch, assets[j])
			end

			table.insert(batches, batch)
		]]
	end

	local active_threads = 0
	local completed = Instance.new("BindableEvent")
	-- process batches simultaneously
	for _, batch in ipairs(batches) do
		while active_threads >= MAX_PARALLEL_LOADS do
			RunService.Heartbeat:Wait()
		end

		active_threads += 1

		task.spawn(function()
			local ok, err = pcall(ContentProvider.PreloadAsync, ContentProvider, batch)
			if not ok or err ~= nil then
				warn(err)
			end

			loaded_count += #batch
			---task.defer(function()
			status.Text = string.format("Loaded: %d/%d", loaded_count, max_assets)
			---end)

			active_threads -= 1
			if loaded_count >= max_assets then
				completed:Fire()
			end
		end)
	end

	-- Wait for all batches to complete
	completed.Event:Wait()
	completed:Destroy()

	status.Text = "Finalizing..."
	local end_time = string.format("%.2f", os.clock() - start_time)
	print(`Loaded in {end_time}s.`) -- lets hope we don't get a negative number

	loadingUI:Destroy()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	table.clear(assets)
	table.clear(batches)
	assets, batches = nil, nil

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

	debug.profileend()
end

preload()
