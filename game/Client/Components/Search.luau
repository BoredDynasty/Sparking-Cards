--!strict

local Search = {}

type searchInterface = TextBox & {
	UICorner: UICorner,
	Frame: Frame & {
		UICorner: UICorner,
		UIStroke: UIStroke,
	},
	Remove: ImageButton,
	SearchIcon: ImageLabel,
}

-- local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenPlus = require(ReplicatedStorage.Utility.TweenPlus)

-- local player = Players.LocalPlayer
-- local PlayerGui = player.PlayerGui

function Search:selected(interface: searchInterface)
	interface.Frame.UIStroke.Thickness = 0
	interface.SearchIcon.ImageTransparency = 1
	task.wait()
	TweenPlus(interface.Frame.UIStroke, {
		Thickness = 2,
	}, {
		Time = 1,
		EasingDirection = "Out",
		EasingStyle = "Back",
	}):Start()
	TweenPlus(interface.Remove, {
		ImageTransparency = 0.5,
	}, {
		Time = 1,
		EasingDirection = "Out",
		EasingStyle = "Sine",
	}):Start()
end

function Search:deselected(interface: searchInterface)
	interface.Frame.UIStroke.Thickness = 1
	interface.SearchIcon.ImageTransparency = 0
	task.wait()
	TweenPlus(interface.Frame.UIStroke, {
		Thickness = 0,
	}, {
		Time = 1,
		EasingDirection = "Out",
		EasingStyle = "Back",
	}):Start()
	TweenPlus(interface.Remove, {
		ImageTransparency = 1,
	}, {
		Time = 1,
		EasingDirection = "Out",
		EasingStyle = "Sine",
	}):Start()
end

function Search:inference(interface: searchInterface, t: string)
	interface.PlaceholderText = t
	TweenPlus(interface.Remove, {
		ImageTransparency = 0,
	}, {
		Time = 1,
		EasingDirection = "Out",
		EasingStyle = "Sine",
	}):Start()
end

return Search
