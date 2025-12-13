--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local compute_level = require(ReplicatedStorage.ClientModules["compute-level"])
local future = require(ReplicatedStorage.Packages.future)

-- advance-level.luau

-- a level up sequence.

local events = ReplicatedStorage:FindFirstChild("Events") :: Folder
local get_profile = events:WaitForChild("GetProfile") :: RemoteFunction

local function expectProfile()
	local fut = future.new(function()
		return get_profile:InvokeServer()
	end)

	return fut:Await()
end

local rankOrder: { string } = {
	"Bronze I",
	"Iron II",
	"Gold III",
	"Platinum IV",
	"Emerald V",
	"Master VI",
	"Elite VII",
	"Ruby VIII",
	"Prismatic IX",
	"Sparking X",
}

local function onLevelUp()
	local now = tick()

	local profile = expectProfile()
	local current_level = profile.Data.Level

	local current_level_index = compute_level.rankNameToNumber(current_level)

	if not current_level_index then
		warn("no rank index")
		return
	end

	local previous_level = rankOrder[current_level_index - 1]

	local prexix = "Lv."

	local previous_to_display = prexix .. previous_level
	local current_to_display = prexix .. current_level

	local rightwards_arrow_code = utf8.char(0x27A1)

	local text_to_display = [[
   <font size = '10' color='rgb(135, 135, 135)'>
   ]] .. previous_to_display .. " " .. rightwards_arrow_code .. " " .. current_to_display .. [[
   </font>
   ]]
end
