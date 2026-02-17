--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local future = require(ReplicatedStorage.Packages.future)
local pop = require("../Interface/pop")
local spr = require(ReplicatedStorage.Modules.spr)

-- throbber.luau
-- for indicating preloads

local templates = ReplicatedStorage.Interfaces

return function(element: GuiObject, signal: SignalPlus.Signal<>)
	local loaderTemplates = templates.Loaders
	local loader = loaderTemplates.Basic:Clone()

	loader.Visible = true
	loader.Parent = element
	loader.Position = UDim2.fromScale(0.5, 0.5)

	pop(loader)

	local circle = 360

	spr.target(loader, 0, 1 / 1, {
		Rotation = circle,
	})

	signal:Once(function()
		pop(loader)

		task.delay(5, function()
			loader:Destroy()
			signal:Destroy()
			spr.stop(loader, "Rotation")
		end)
	end)
end
