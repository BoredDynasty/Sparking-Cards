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

function navi.new(rail: Frame, defaultBtn: button?)
	defaultBtn = defaultBtn or {
		name = "Home",
		icon = "rbxassetid://10723407389",
	}
	local name = defaultBtn.name
	local railDescriptor = rail:GetFullName()
	local states = navi._createState(name)
	local tbl = {
		rail = rail,
		name = name,
		railDescriptor = railDescriptor,
		buttons = {
			[name] = {
				state = states,
			},
		},
	}
	table.insert(navi.compiled, tbl)
end

function navi:render(): signals
	local signals = {}
	for _, button in ipairs(navi.compiled) do
		print("Rendering button:", button.name)
		-- Here you would add the actual rendering logic for each button
		local buttonTemplate: buttonRendering = templates.ButtonTemplate:Clone() :: buttonRendering
		buttonTemplate.Name = button.name
		--buttonTemplate.Icon.Image = Content.none  -- filter out the prefix
		buttonTemplate.Parent = button.rail

		signals[button.name] = SignalPlus()

		buttonTemplate.MouseButton1Click:Connect(function()
			print("Button clicked:", button.name)
			audio:SFX("click")
			button.state:transition("activated")
			for _, otherButton in ipairs(navi.compiled) do
				if otherButton ~= button then
					otherButton.state:transition("deactivated")
				end
			end
			promise.retryWithDelay(function()
				button.signal:Fire(true, button.name)
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
