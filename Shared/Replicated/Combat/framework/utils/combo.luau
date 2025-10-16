--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- combo.luau
-- a module for keeping track of combos

-- using ./data.luau

local data_module = require("./data")
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local promise = require(ReplicatedStorage.Packages.promise)

local combo_module = {
	COMBO_RESET_TIME = 2, -- seconds
}

export type ComboData = {
	CurrentCombo: number,
	LastHitTime: number,
	MaxCombo: number,
}

function combo_module.new(player: playerMarshaller.player, MaxCombo: number?)
	return promise.new(function()
		data_module.arbitrary[player].ComboData = {
			CurrentCombo = 0,
			LastHitTime = 0,
			MaxCombo = MaxCombo or 0,
		} :: ComboData
	end)
end

function combo_module.incrementCombo(player: playerMarshaller.player): ComboData
	local combo_data: ComboData = data_module:Fetch(player):expect().ComboData

	local currentTime = os.clock()

	if currentTime - combo_data.LastHitTime > combo_module.COMBO_RESET_TIME then
		combo_data.CurrentCombo = 1
	else
		combo_data.CurrentCombo += 1
	end

	combo_data.LastHitTime = currentTime

	if combo_data.CurrentCombo > combo_data.MaxCombo then
		combo_data.MaxCombo = combo_data.CurrentCombo
	end

	return combo_data
end
function combo_module.resetCombo(player: playerMarshaller.player): ComboData
	local combo_data: ComboData = data_module:Fetch(player):expect().ComboData

	combo_data.CurrentCombo = 0
	combo_data.LastHitTime = 0

	return combo_data
end

-- listen every once in a while to reset combos for players who haven't attacked in a while
local lastCheck: number = 0.0
local checkInterval = 0.1 -- seconds

RunService.Heartbeat:Connect(function(dt: number)
	lastCheck += dt :: number
	if lastCheck < checkInterval then
		return
	end

	debug.profilebegin("check_combo")

	lastCheck = 0

	for _, player in ipairs(playerMarshaller.all()) do
		local success, combo_data: ComboData? = pcall(function()
			return data_module:Fetch(player):expect().ComboData
		end)

		if success and combo_data then
			local currentTime = os.clock()

			if
				combo_data.CurrentCombo > 0
				and currentTime - combo_data.LastHitTime > combo_module.COMBO_RESET_TIME
			then
				combo_data.CurrentCombo = 0
				combo_data.LastHitTime = 0
			end
		end
	end

	debug.profileend()
end)

return combo_module
