--!strict

--# selene: allow(incorrect_standard_library_use)

local downloadPlaceAsset = require("./lib/download-place-asset")
local fs = require("@lune/fs") -- library for manipulating files

local placeId = 6125133811

local content = downloadPlaceAsset(placeId)
fs.writeFile("game/DataModel/lobby.rbxl", content)
