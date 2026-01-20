--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- letterbox.luau

local module = {
	-- letterbox images
	--[[
      https://create.roblox.com/store/asset/110246564937802/3
   ]]
	letterbox_1 = Content.fromAssetId(110246564937802),
	--[[
      https://create.roblox.com/store/asset/81501465181307/4
   ]]
	letterbox_2 = Content.fromAssetId(81501465181307),
}

local player = playerMarshaller.get()
local playerGui = player.PlayerGui

local letterbox_gui = playerGui:FindFirstChild("letterbox") :: letterbox_gui

export type letterbox_gui = ScreenGui & {
	CanvasGroup: CanvasGroup & {
		ImageLabel: ImageLabel,
	},
}

export type version = "letterbox_1" | "letterbox_2"

function module:On(version: version?)
	-- implementation
	version = version or "letterbox_1"

	local tweens = table.create(2) :: { TweenPlus.Tween }

	table.insert(
		tweens,
		TweenPlus(letterbox_gui.CanvasGroup, {
			GroupTransparency = 0,
		}, {
			Time = 0.25,
		})
	)
	table.insert(
		tweens,
		TweenPlus(letterbox_gui.CanvasGroup.ImageLabel, {
			ImageTransparency = 0,
		}, {
			Time = 0.25,
		})
	)

	for i, tween in ipairs(tweens) do
		tween:Start()
	end

	local content = module[string.lower(version)] :: Content?

	if content then
		letterbox_gui.CanvasGroup.ImageLabel.ImageContent = content
	end
end

function module:Off()
	-- implementation

	local tweens = table.create(2) :: { TweenPlus.Tween }

	table.insert(
		tweens,
		TweenPlus(letterbox_gui.CanvasGroup, {
			GroupTransparency = 1,
		}, {
			Time = 0.25,
		})
	)
	table.insert(
		tweens,
		TweenPlus(letterbox_gui.CanvasGroup.ImageLabel, {
			ImageTransparency = 1,
		}, {
			Time = 0.25,
		})
	)

	for i, tween in ipairs(tweens) do
		tween:Start()
	end

	letterbox_gui.CanvasGroup.ImageLabel.ImageContent = Content.none
end

return module
