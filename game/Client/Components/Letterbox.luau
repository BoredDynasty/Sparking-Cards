--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TextPlus = require(ReplicatedStorage.Utility.TextPlus)
local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local statemachine = require(ReplicatedStorage.Utility.statemachine)

-- Letterbox.luau

local letterbox = {}

local states = {
	active = {
		name = "active",
		onEnter = function()
			--
		end,
		onExit = function()
			--
		end,
		transitions = {
			inactive = "inactive",
		},
	},
	inactive = {
		name = "inactive",
		onEnter = function()
			--
		end,
		onExit = function()
			--
		end,
		transitions = {
			active = "active",
		},
	},
}

local _statemachine = statemachine.new(states, "inactive")

letterbox.statemachine = _statemachine

local player = playerMarshaller.get()
local playerGui = player.PlayerGui

local gui = playerGui:FindFirstChild("Letterbox") :: Letterbox

export type Letterbox = ScreenGui & {
	Top: Frame & {
		TextDisplay: Frame,
	},
	Bottom: Frame & {
		TextDisplay: Frame,
	},
}

function letterbox:on()
	if letterbox.statemachine:getCurrentState() == "active" then
		return
	end
	letterbox.statemachine:transition("active")
	local tweens = table.create(2) :: { TweenPlus.Tween? }
	table.insert(
		tweens,
		TweenPlus(gui.Top, {
			Position = UDim2.fromScale(0.5, 0),
		}, {
			Time = 0.6,
			EasingStyle = "Back",
			EasingDirection = "Out",
		})
	)
	table.insert(
		tweens,
		TweenPlus(gui.Bottom, {
			Position = UDim2.fromScale(0.5, 1),
		}, {
			Time = 0.6,
			EasingStyle = "Back",
			EasingDirection = "Out",
		})
	)
	for _, tween in ipairs(tweens) :: { TweenPlus.Tween } do
		tween:Start()
	end
	-- chainable
	return {
		andThen = function(text: string, area: ("Top" | "Bottom")?)
			area = area or "Top"
			assert(gui[area], `There is no {area} in the letterbox gui.`)
			TextPlus.Create(gui[area].TextDisplay, `{text}`, {
				Font = Font.new(
					"rbxasset://fonts/families/Montserrat.json", -- Family.
					Enum.FontWeight.Regular, -- Weight.
					Enum.FontStyle.Normal -- Style.
				),
				Size = 12.5,
				Color = Color3.fromHex("#ffffff"),
				XAlignment = "Left",
				YAlignment = "Center",
				LineSorting = true,
				WordSorting = true,
				Dynamic = true,
			})
		end,
	}
end

function letterbox:off()
	if letterbox.statemachine:getCurrentState() == "inactive" then
		return
	end
	letterbox.statemachine:transition("inactive")
	local tweens = table.create(2) :: { TweenPlus.Tween? }
	table.insert(
		tweens,
		TweenPlus(gui.Top, {
			Position = UDim2.fromScale(0.5, -1),
		}, {
			Time = 0.6,
			EasingStyle = "Back",
			EasingDirection = "In",
		})
	)
	table.insert(
		tweens,
		TweenPlus(gui.Bottom, {
			Position = UDim2.fromScale(0.5, 2),
		}, {
			Time = 0.6,
			EasingStyle = "Back",
			EasingDirection = "In",
		})
	)
	for _, tween in ipairs(tweens) :: { TweenPlus.Tween } do
		tween:Start()
	end
end

return letterbox
