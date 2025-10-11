--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local DisplayOrder = require(script.Parent.Parent.Interface.displayorder)
local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local pop = require("../Interface/pop")
local promise = require(ReplicatedStorage.Packages.promise)
local trove = require(ReplicatedStorage.Packages.trove).new()

-- throbber.luau
-- for indicating preloads

local templates = ReplicatedStorage:WaitForChild("Interfaces") :: Folder

return function(element: GuiObject, signal: SignalPlus.Signal<>)
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
	trove:Add(tween)

	signal:Once(function()
		pop(loader)

		trove:Clean()
	end)
end
