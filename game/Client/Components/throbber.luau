--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local pop = require("../Interface/pop")
local promise = require(ReplicatedStorage.Packages.promise)
local trove = require(ReplicatedStorage.Packages.trove).new()

-- throbber.luau
-- for indicating preloads

local templates = ReplicatedStorage:WaitForChild("Interfaces") :: Folder

local __call = function(element: GuiObject, signal: SignalPlus.Signal<>)
	return promise.new(function()
		local loaderTemplates = templates:FindFirstChild("Loaders") :: Folder
		local loader = loaderTemplates:WaitForChild("Basic"):Clone() :: ImageLabel

		loader.Visible = true
		loader.Parent = element
		loader.Position = UDim2.fromScale(0.5, 0.5)
		pop(loader)

		local circle = 360

		local tween = TweenPlus(loader, { Rotation = circle }, { RepeatCount = math.huge, Time = 1 })
		tween:Start()

		trove:Add(loader)
		trove:Add(signal)

		signal:Once(function()
			pop(loader)

			task.delay(5, function()
				trove:Remove(loader)
				trove:Remove(signal)
				tween:Destroy()
			end)
		end)
	end)
end

return setmetatable({
	_trove = trove,
}, { __call = __call })
