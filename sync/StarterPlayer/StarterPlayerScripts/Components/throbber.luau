--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local future = require(ReplicatedStorage.Packages.future)
local pop = require("../Interface/pop")

-- throbber.luau
-- for indicating preloads

local templates = ReplicatedStorage:WaitForChild("Interfaces") :: Folder

local __call = function(element: GuiObject, signal: SignalPlus.Signal<>)
	return future.new(function()
		if typeof(element) ~= "GuiObject" then
			return false
		end

		local loaderTemplates = templates:FindFirstChild("Loaders") :: Folder
		local loader = loaderTemplates:WaitForChild("Basic"):Clone() :: ImageLabel

		loader.Visible = true
		loader.Parent = element
		loader.Position = UDim2.fromScale(0.5, 0.5)
		pop(loader)

		local circle = 360

		local tween = TweenPlus(loader, { Rotation = circle }, { RepeatCount = math.huge, Time = 1 })
		tween:Start()

		signal:Once(function()
			pop(loader)

			task.delay(5, function()
				loader:Destroy()
				signal:Destroy()
				tween:Destroy()
			end)
		end)

		return "indicating preload!"
	end)
end

return __call
