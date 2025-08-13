--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local audio = require(ReplicatedStorage.Modules.audio)
local lucide = require(ReplicatedStorage.Packages.lucide)
local promise = require(ReplicatedStorage.Packages.promise)
local statemachine = require(ReplicatedStorage.Utility.statemachine)

-- Navi.luau

-- all navigation rails must follow the same design principle.

local navi = {
	compiled = {},
}
navi.__index = navi

local templates = (ReplicatedStorage.Interfaces :: Folder).Navi :: Folder

export type button = {
	name: string,
	icon: string,
}

export type buttonRendering = TextButton & {
	Icon: ImageLabel,
}

export type signals = {
	[TextButton]: SignalPlus.Signal<boolean, string>, -- toggled, signalname
}

function navi._createState(name: string): statemachine.State
	return {
		activated = {
			onEnter = function()
				print(name .. " has been activated")
			end,
			onExit = function()
				print(name .. " has been de-activated")
			end,
			transitions = {
				deactivated = "deactivated",
			},
		},
		deactivated = {
			onEnter = function()
				-- print(name .. " has been de-activated")
			end,
			onExit = function()
				-- print(name .. " has been activated")
			end,
			transitions = {
				activated = "activated",
			},
		},
	}
end

function navi.create(rail: Frame, defaultBtn: button?)
	defaultBtn = defaultBtn or {
		name = "Home",
		icon = "rbxassetid://10723407389",
	}
	local name = defaultBtn.name
	local railDescriptor = rail:GetFullName()
	local states = navi._createState(name)
	local self = setmetatable({
		rail = rail,
		railDescriptor = railDescriptor,
		buttons = {
			[name] = {
				state = states,
			},
		},
	}, navi)
	navi.compiled[railDescriptor] = self
	return self, railDescriptor
end

function navi:newButton(name: string, icon: string): button
	local newButton = {
		name = name,
		icon = icon,
	}
	self.buttons[name] = {
		state = navi._createState(name),
	}
	return newButton
end

function navi:render(): signals
	local signals = table.create(#self.buttons + 1)
	for name, button: button in pairs(self.buttons) do
		print("Rendering button:", name)
		-- Here you would add the actual rendering logic for each button
		local buttonTemplate: buttonRendering = templates.ButtonTemplate:Clone() :: buttonRendering
		buttonTemplate.Name = name
		buttonTemplate.Icon.ImageContent = Content.fromAssetId(button.icon)
		buttonTemplate.Parent = self.rail

		signals[buttonTemplate] = SignalPlus()

		buttonTemplate.MouseButton1Click:Connect(function()
			print("Button clicked:", name)
			audio:SFX("click")
			self.buttons[name].state:transition("activated")
			for _, otherButton in self.buttons do
				if otherButton ~= button then
					otherButton.state:transition("deactivated")
				end
			end
			promise.retryWithDelay(function()
				button.signal:Fire(true, name)
			end, 3, 3)
		end)
		buttonTemplate.MouseEnter:Connect(function()
			audio:SFX("hover")
			TweenPlus(buttonTemplate.Icon, {
				Rotation = 5,
			}, {
				Time = 0.4,
				Easing = Enum.EasingStyle.Back,
				Direction = Enum.EasingDirection.Out,
			}):Start()
		end)
		buttonTemplate.MouseLeave:Connect(function()
			TweenPlus(buttonTemplate.Icon, {
				Rotation = 0,
			}, {
				Time = 0.4,
				Easing = Enum.EasingStyle.Back,
				Direction = Enum.EasingDirection.Out,
			}):Start()
		end)
	end
	return signals
end

return navi
