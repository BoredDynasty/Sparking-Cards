--!nonstrict

--# selene: allow(incorrect_standard_library_use)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local DisplayOrder = require(script.Parent.Parent.Interface.displayorder)
local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
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
	loader.Position = DisplayOrder.canvasPositions.middle
	pop(loader)

	local circle = 360

	trove:Connect(RunService.Heartbeat, function(deltaTime)
		circle -= deltaTime * 360
		if circle <= 0 then
			circle = 360
		end
		loader.Rotation = circle
	end)

	trove:Add(loader)
	trove:Add(signal)

	trove:AddPromise(promise.new(function()
		signal:Once(function()
			pop(loader)

			trove:Clean()
		end)
	end))
end
