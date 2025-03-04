--!nonstrict

-- DataModel.client.lua

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

ReplicatedFirst:RemoveDefaultLoadingScreen()
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

local player = Players.LocalPlayer

local loadingUI = ReplicatedFirst.Loading:Clone()
loadingUI.Parent = player.PlayerGui

local background = loadingUI.CanvasGroup.Background

local textIndicator = background.Status.StatusText
local status = textIndicator.Parent:FindFirstChildOfClass("TextButton")
local str = "[ ID ]"

if RunService:IsStudio() then
	textIndicator.Text = "[ TEST ]"
else
	textIndicator.Text = string.gsub(str, "[ ID ]", game.JobId)
end

local startTime = os.clock()

local assetsRequired = #player:GetDescendants() + #ReplicatedStorage:GetDescendants()
local assetsLoaded = 0

local preload_Thread = task.spawn(function()
	debug.profilebegin("preload-Thread")
	for _, object in pairs(player:GetDescendants()) do
		ContentProvider:PreloadAsync({ object })
		task.wait()
		assetsLoaded += 1
	end
	for _, object in pairs(ReplicatedStorage:GetDescendants()) do
		ContentProvider:PreloadAsync({ object })
		task.wait()
		assetsLoaded += 1
	end
end)

local function votedSkip()
	status.Text = "Skipped..."
	task.wait(2)
	loadingUI:Destroy()
end

background.Status.TextButton.MouseButton1Click:Once(votedSkip)

local success, result = coroutine.resume(preload_Thread)

local function getResult()
	local _result = false
	if success == true and _result == "preloaded_Players" and "preloaded_Storage" then
		_result = true
	end
	return result
end

if coroutine.status(preload_Thread) == "dead" or getResult() then
	if assetsLoaded >= assetsRequired then
		debug.profileend()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Captures, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.SelfView, true)

		local publicOffset, publicSize = Vector2.new(442, 152), Vector2.new(36, 36)
		-- local privateOffset, privateSize = Vector2.new(442, 194), Vector2.new(36, 36)

		local loadTime = os.clock() - startTime
		local roundedLoadTime = math.round(loadTime * 10000) / 10000 -- four decimal places
		print("Game loaded in: " .. roundedLoadTime .. " seconds.")
		print("Number of instances loaded: " .. #game.Workspace:GetDescendants())
		local sendAnalytic = ReplicatedStorage.RemoteEvents:WaitForChild("SendAnalytic")
		task.delay(20, function() -- wait for the server to load
			game.Loaded:Wait()
			local customFields = {
				[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = `Load Time (unrounded): {loadTime}`,
				[Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = `Load Time (rounded): {roundedLoadTime}`,
			}
			sendAnalytic:FireServer("GameLoaded", loadTime, customFields)
		end)

		local imgServer = status.public

		--imgServer.ImageRectOffset = privateOffset
		--imgServer.ImageRectSize = privateSize
		imgServer.ImageRectOffset = publicOffset
		imgServer.ImageRectSize = publicSize
		--end
		status.Text = "Loaded!"
		task.wait(2)
		loadingUI:Destroy()
	end
end
