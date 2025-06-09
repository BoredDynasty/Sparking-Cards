--!nonstrict

--# selene: allow(incorrect_standard_library_use)

local downloadPlaceAsset = require("./lib/download-place-asset")
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local placeId = 6125133811

local content = downloadPlaceAsset(placeId)
local game = roblox.deserializePlace(content)

local ReplicatedStorage = game:GetService("ReplicatedStorage") :: ReplicatedStorage

fs.writeFile("/game/Workspace.rbxm", roblox.serializeModel(game.Workspace))
fs.writeFile(`/Shared/Replicated/Assets.rbxm`, roblox.serializeModel(ReplicatedStorage.Assets))
