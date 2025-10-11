--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TextPlus = require(ReplicatedStorage.Utility.TextPlus)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local spr = require(ReplicatedStorage.Modules.spr)

-- Letterbox.luau

local letterbox = {}

local state = observer.new(false)
letterbox.state = state

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

function letterbox:on(): { andThen: (text: string, area: ("Top" | "Bottom")?) -> () }?
	if letterbox.state:Get() == true then
		return nil
	end

	letterbox.state:Set(true)

	spr.target(gui.Top, 0.8, 1.5, {
		Position = UDim2.fromScale(0.5, 0),
	})
	spr.target(gui.Bottom, 0.8, 1.5, {
		Position = UDim2.fromScale(0.5, 1),
	})
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
	if letterbox.state:Get() == false then
		return
	end
	letterbox.state:Set(false)

	spr.target(gui.Top, 0.8, 1.5, {
		Position = UDim2.fromScale(0.5, -1),
	})
	spr.target(gui.Bottom, 0.8, 1.5, {
		Position = UDim2.fromScale(0.5, 1.5),
	})
end

return letterbox
