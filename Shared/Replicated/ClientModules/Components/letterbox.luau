--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local spr = require(ReplicatedStorage.Modules.spr)

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

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local letterbox_gui = playerGui.Letterbox

export type version = "letterbox_1" | "letterbox_2"

function module:On(version: version?)
	-- implementation
	version = version or "letterbox_1"

	spr.target(letterbox_gui.CanvasGroup, 1, 1 / 0.25, {
		GroupTransparency = 0,
	})
	spr.target(letterbox_gui.CanvasGroup.ImageLabel, 1, 1 / 0.25, {
		ImageTransparency = 0,
	})

	local content = module[string.lower(version)] :: Content?

	if content then
		letterbox_gui.CanvasGroup.ImageLabel.ImageContent = content
	end
end

function module:Off()
	-- implementation

	spr.target(letterbox_gui.CanvasGroup, 1, 1 / 0.25, {
		GroupTransparency = 0,
	})

	spr.target(letterbox_gui.CanvasGroup.ImageLabel, 1, 1 / 0.25, {
		ImageTransparency = 1,
	})

	task.wait(0.25)

	letterbox_gui.CanvasGroup.ImageLabel.ImageContent = Content.none
end

return module
