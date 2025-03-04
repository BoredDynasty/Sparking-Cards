--[=[
	@class DataStoreClass
-]=]
local DataStoreClass = {}
DataStoreClass.__index = DataStoreClass

-- // Datastores

local DataStoreService = game:GetService("DataStoreService")
local CardsData = DataStoreService:GetDataStore("Cards")
local RankData = DataStoreService:GetDataStore("Rank")
local ExperiencePoints = DataStoreService:GetDataStore("ExperiencePoints")
local PlayerRelated = DataStoreService:GetDataStore("PlayerRelated")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GlobalSettings = require(ReplicatedStorage.GlobalSettings)
local Timer = require(ReplicatedStorage.Modules.Timer)
local Util = require(script.Util)

local DataSavedRE = ReplicatedStorage.RemoteEvents.DataSaved

--[[
Multipliers
1. Untitled
2. Chaos Indefinite
3. Chaotic Coloring
4. Absolute Sparking
--]]

--[[
Abilities
1. Charge
2. Ultimate
3. Fusion Coil
4. Supernatural Radiation
]]

--[=[
	Starts up the Data System when a new player joins.

	@function PlayerAdded
		@within DataStoreClass
		@param player Player
--]=]
function DataStoreClass.PlayerAdded(player: Player) -- Setup DataSystem
	local leaderstats = Instance.new("Folder")
	leaderstats.Parent = player
	leaderstats.Name = "leaderstats"
	--
	local success, data = nil, nil

	local Cards = Instance.new("IntValue")
	Cards.Name = "Cards"
	Cards.Parent = leaderstats
	success, data = pcall(function()
		return CardsData:GetAsync(`player:{player.UserId}`)
	end)
	data = data :: {}
	if not success or data == nil then
		data = { BaseValue = 10 }
		warn(`Could not get data for {player.Name}`)
	elseif success or data then
		pcall(function()
			CardsData:SetAsync(`player:{player.UserId}`, data)
		end)
	end

	Cards.Value = data.BaseValue
	--
	local Rank = Instance.new("StringValue")
	Rank.Name = "Rank"
	Rank.Parent = leaderstats
	Rank.Value = RankData:GetAsync(`player:{player.UserId}`) or GlobalSettings.StartingRankValue
	RankData:SetAsync(player.UserId, Rank.Value)

	local EXP = Instance.new("IntValue")
	EXP.Name = "ExperiencePoints"
	EXP.Parent = leaderstats
	EXP.Value = ExperiencePoints:GetAsync(`player:{player.UserId}`) or GlobalSettings.StartingExperienceValue
	ExperiencePoints:SetAsync(`player:{player.UserId}`, EXP.Value)

	success, data = pcall(function()
		return PlayerRelated:GetAsync(`player:{player.UserId}`)
	end)

	if not success or data == nil then
		-- Init because theres no data
		data = { Cards = 0, lastLogin = 0 }
	end

	if Util.getDailyRewards(data.lastLogin) then
		-- Reset the daily streak
		data.Cards = data.Cards + 5
		leaderstats.Cards.Value = leaderstats.Cards.Value + data.Cards
		CardsData:SetAsync(`player:{player.UserId}`, leaderstats.Cards.Value)
		print(`Player has been awarded {data.Cards} Cards for logging in today!`)
		data.lastLogin = os.time() -- Update last login time to now
	end

	-- Save updated data
	pcall(function()
		PlayerRelated:SetAsync(`player:{player.UserId}`, {
			Cards = data.Cards,
			lastLogin = data.lastLogin,
			options = {
				clockTime = 12,
			},
			combatBindings = {
				attack = Enum.KeyCode.MouseLeftButton, -- melee
				special_One = Enum.KeyCode.MouseRightButton, -- any
				special_Two = Enum.KeyCode.Q, -- ultimate
				special_Three = Enum.KeyCode.E, -- primary
			},
		})
	end)

	DataSavedRE:FireClient(player, `You have been awarded {data.Cards} Cards for logging in today!`)
	local timePlayedKey = "time-played-store"
	local timePlayed_Data = PlayerRelated:GetAsync(timePlayedKey)
	if not timePlayed_Data then
		task.spawn(function()
			local timer = Timer.new()
			timer:Start()
			PlayerRelated:SetAsync(timePlayedKey, {
				player,
				timer.elapsedTime,
			})
			while true do
				task.wait(1)
				PlayerRelated:SetAsync(timePlayedKey, {
					player,
					timer.elapsedTime,
				})
			end
			player.AncestryChanged:Once(function() -- as if the player left
				timer:Stop() -- Stop the timer when the player leaves
				-- or else itll cause lag
			end)
		end)
	end

	return leaderstats
end

local function saveData(player, send: boolean)
	if send == true then
		DataSavedRE:FireClient(player)
	end
	pcall(function()
		CardsData:SetAsync(`player:{player.UserId}`, player.leaderstats.Cards.Value)
		RankData:SetAsync(`player:{player.UserId}`, player.leaderstats.Rank.Value)
		ExperiencePoints:SetAsync(`player:{player.UserId}`, player.leaderstats.ExperiencePoints.Value)
	end)
	return "Saved!"
end

--[=[
	@function SaveData
		@within DataStoreClass
		@param player Player
--]=]
function DataStoreClass.SaveData(player: Player)
	saveData(player, true)
end

function DataStoreClass.PlayerRemoving(player: Player)
	saveData(player, false)
end

function DataStoreClass.GetStore(storeName: string)
	return DataStoreService:GetDataStore(storeName)
end

local function saveAllData() -- Saves All Data
	pcall(function()
		DataSavedRE:FireAllClients("all")
		for _, player: Player in pairs(Players:GetChildren()) do
			saveData(player, false)
		end
	end)
end

--[=[
	@function getPlayerStats
		@within DataStoreClass
		@return Folder?
--]=]
function DataStoreClass:getPlayerStats(): IntValue
	return Players.LocalPlayer:WaitForChild("leaderstats").Cards
end

--[=[
	@function StartBindToClose
		@within DataStoreClass
		@param custom any
--]=]
function DataStoreClass.StartBindToClose(custom: () -> ()) -- If the game is being shutdown, it saves all player data. This cannot work in the Studio.
	if not RunService:IsStudio() then
		if not custom then
			game:BindToClose(saveAllData)
		else
			custom()
			game:BindToClose(saveAllData)
		end
	else
		print("Studio Mode")
	end
end

return DataStoreClass
