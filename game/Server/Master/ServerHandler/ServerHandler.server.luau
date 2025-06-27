--!nonstrict

-- ServerHandler.server.luau

print(script.Name)

local LogService = game:GetService("LogService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cmdr = require(ReplicatedStorage.Packages:WaitForChild("cmdr"))
local GameAnalytics = require(ReplicatedStorage.Packages["gameanalytics-sdk"])
local Items = require(ReplicatedStorage.Market.Items)
local MatchHandler = require(ReplicatedStorage.Modules.MatchHandler)
local Packet = require(ReplicatedStorage.Packet)
local ProfileStore = require(ReplicatedStorage.Packages.profilestore)
local dictionary = require(ReplicatedStorage.Utility.dictionary)
local lucide = require(ReplicatedStorage.Packages.lucide)
local profileMarshaller = require(ReplicatedStorage.Datastore.profileMarshaller)
local profilestore = require(ReplicatedStorage.Packages.profilestore)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local safeteleport = require(ReplicatedStorage.Modules.safeteleport)

-- local ActorGroup = require(ReplicatedStorage.Utility.ActorGroup)

local remoteEvents = ReplicatedStorage.RemoteEvents
local assets = ReplicatedStorage:FindFirstChild("Assets") :: Folder

local productFunctions = {} :: { (receipt: (any | string)?, player: Player) -> boolean }

print("GameAnalytics is enabled.")

local gameAnalyticsConfig = {
	enableInfoLog = false,
	enableVerboseLog = false,
	availableResourceCurrencies = { "BigCards" },
	build = "0.1.0",
	availableGamepasses = { "Extra Cards" },
	automaticSendBusinessEvents = true,
	reportErrors = true,
	useCustomId = true, -- Corrected key name
	gameKey = "4e689e435634bbfe9892f625af5c51bf",
	secretKey = "1a5289ebbc7daa44accc4d5deb256833263c512a",
}
local resourceItemTypes = {
	"Weapons",
	"Boosters",
	"IAP",
	"Gameplay",
}

local serverStartTime = os.clock()

Cmdr:RegisterDefaultCommands() -- This loads the default set of commands that Cmdr comes with. (Optional)

-- selene:allow(mixed_table)
GameAnalytics:initialize(gameAnalyticsConfig)
GameAnalytics:configureAvailableResourceItemTypes(resourceItemTypes)
-- GameAnalytics:initServer(gameAnalyticsConfig.gameKey, gameAnalyticsConfig.secretKey)

local playerStore = ProfileStore.New("player-related", profilestructure)

type profileType = { [Player]: typeof(playerStore:StartSessionAsync({})) }
local profiles = profileMarshaller.server

--[[
	This is only for if I want to write
	data to the profiles while testing.
]]
--[[
if RunService:IsStudio() then
	playerStore = playerStore.Mock
end
--]]
-- This product Id gives the player more cards (cards as in money)
productFunctions[1904591683] = function(receipt: any | string?, player: Player)
	local profile = profiles[player]
	if not profile then
		print("Profile not found for player: " .. player.Name)
		return false -- indicate a failed purchase
	end
	local Card_int = profile.Data["Big-Cards"] :: number
	if Card_int and player then
		Card_int += 50
		local resourceEventParams = {
			flowType = GameAnalytics.EGAResourceFlowType.Source,
			currency = "BigCards",
			amount = 50,
			itemType = "IAP", -- In-App Purchase
		}
		print(receipt)
		GameAnalytics:addResourceEvent(player.UserId, resourceEventParams)
	end
	return true -- indicate a successful purchase
end

productFunctions[1906572512] = function(receipt: any | string?, player: Player)
	print(`Donated Successfully: {player.Name}.`)

	print(receipt) -- debug
	return true
end

LogService.MessageOut:Connect(function(message: string, messageType: Enum.MessageType)
	if messageType == Enum.MessageType.MessageError then
		GameAnalytics:addErrorEvent({
			message = message,
			severity = GameAnalytics.EGAErrorSeverity.error,
		})
	elseif messageType == Enum.MessageType.MessageWarning then
		GameAnalytics:addErrorEvent({
			message = message,
			severity = GameAnalytics.EGAErrorSeverity.warning,
		})
	elseif messageType == Enum.MessageType.MessageInfo then
		GameAnalytics:addErrorEvent({
			message = message,
			severity = GameAnalytics.EGAErrorSeverity.info,
		})
	elseif messageType == Enum.MessageType.MessageOutput then
		GameAnalytics:addErrorEvent({
			message = message,
			severity = GameAnalytics.EGAErrorSeverity.debug,
		})
	end
end)

local ServerAsset = assets:WaitForChild("Server"):Clone() :: Model
ServerAsset.Parent = game.Workspace

local function processReceipt(receiptInfo: { PlayerId: number, ProductId: number })
	local userId = receiptInfo.PlayerId :: number
	local productId = receiptInfo.ProductId :: number

	local player = Players:GetPlayerByUserId(userId) :: Player
	if player then
		-- Get the handler function associated with the developer product ID and attempt to run it
		local handler = productFunctions[productId]
		local success, result = pcall(handler, receiptInfo, player)
		if success then
			-- The user has received their benefits
			-- Return "PurchaseGranted" to confirm the transaction
			return Enum.ProductPurchaseDecision.PurchaseGranted
		else
			warn("Failed to process receipt: ", receiptInfo, result)
		end
	end

	-- The user's benefits couldn't be awarded
	-- Return "NotProcessedYet" to try again next time the user joins
	return Enum.ProductPurchaseDecision.NotProcessedYet
end
local function enterMatch(player: Player?)
	print("player entered match")
	if not player then
		return
	end
	MatchHandler.AddPlayerToQueue(player)
end

local function cancelMatch(player: Player)
	print("cancel match")
	if not player then
		return
	end
	MatchHandler.RemovePlayerFromQueue(player)
end

local function onPlayerAdded(player: Player)
	-- Start profile session with timeout
	local profile = playerStore:StartSessionAsync(`player:{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	if not profile or profile == nil then
		player:Kick("Roblox Servers on fire. It's best to rejoin.")
		return
	end
	-- Set up profile
	profile:AddUserId(player.UserId)
	profile:Reconcile()
	task.wait(1)
	profile:Save()

	-- Handle session end
	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		player:Kick("Session Locked, rejoin")
	end)

	if (player.Parent == Players) or player:FindFirstAncestor("Players") then
		profiles[player] = profile
		print("Data Loaded for " .. player.DisplayName, unpack(profile.Data))
		profile.Data.LastLogin = os.time()
		profile:Reconcile()
		profile:Save()
	else
		profile:EndSession()
		warn("Data not loaded for " .. player.DisplayName .. ", session ended.")
		return
	end

	-- for the client to mess around with
	local editConfig = Instance.new("BindableEvent")
	editConfig.Parent = player
	editConfig.Name = "EditConfig"
	local toggleShiftLock = Instance.new("BindableEvent")
	toggleShiftLock.Parent = player
	toggleShiftLock.Name = "ToggleShiftLock"
	print("yay, installed bindable events to player")

	local character: Model = player.Character or player.CharacterAdded:Wait()
	character:SetAttribute("Stamina", 100)
	character:SetAttribute("MaxStamina", 100)

	GameAnalytics:PlayerJoined(player)

	-- Optimize character cleanup
	player.CharacterRemoving:Connect(function(char: Model)
		task.defer(function()
			if char and char.Parent then
				char:Destroy()
			end
		end)
	end)
end

-- just in case the players have joined the server before the script loaded
for _, player in ipairs(Players:GetPlayers()) do
	if player.Parent == Players then
		task.spawn(onPlayerAdded, player)
	end
end

ProfileStore.OnError:Connect(function(error_message, store_name, profile_key)
	print(`DataStore error (Store:{store_name};Key:{profile_key}): {error_message}`)
end)

local function onPlayerRemoving(player: Player)
	GameAnalytics:PlayerRemoved(player)
	local profile = profiles[player]
	if profile ~= nil then
		profile:Save()
		print("saving data for: " .. player.DisplayName)
		profile:EndSession()
		print("ending session for: " .. player.DisplayName)
	else
		print("couldn't save in time for " .. player.DisplayName)
	end
	task.defer(player.Destroy, player)
end

local function purchaseCard(player: Player, cardName: string)
	local profile = profiles[player]
	if not profile then
		Packet.sendNotification.sendTo({
			"Error",
			"Profile not found for player: " .. player.Name,
		}, player)
		warn("Profile not found for player: " .. player.Name)
		return
	end
	if not Items[cardName] then
		Packet.sendNotification.sendTo({
			"Error",
			"Card does not exist.",
		}, player)
		warn("Card does not exist: " .. cardName)
		return
	end

	print("Purchasing card: " .. cardName .. " for player: " .. player.Name)

	local resourceEventParams = {
		flowType = GameAnalytics.EGAResourceFlowType.Sink,
		currency = "BigCards",
		amount = 1,
		itemType = "Weapons",
		itemId = cardName .. " Card",
	}
	GameAnalytics:addResourceEvent(player.UserId, resourceEventParams)
	local cards = profile.Data["Big-Cards"]
	if cards and cards >= math.ceil(Items[cardName].Price) then
		profile.Data["Big-Cards"] -= math.ceil(Items[cardName].Price) or 1
		profile.Data.Cards[cardName] = (profile.Data.Cards[cardName] or 0) + 1
		profile:Save()
		profile:Reconcile()
		local result = "success"
		Packet.buyCard.sendTo({ result }, player)
		print("Card purchased successfully.")
	else
		Packet.sendNotification.sendTo({ "Error", "Not enough Big-Cards." }, player)
		warn("Not enough Big Cards for player: " .. player.Name)
	end
end

local function streamArea(player: Player, area: Vector3)
	if not player then
		return
	end
	task.spawn(function()
		player:RequestStreamAroundAsync(area)
	end)
end

local function payCards(amount: number, playerName: string)
	local player: Player? = Players:FindFirstChild(playerName)
	if not player then
		warn("player not found: " .. playerName)
		return
	end
	local profile = profiles[player]
	if not profile then
		Packet.sendNotification.sendTo({
			"Error",
			"Profile not found for player: " .. player.Name,
		}, player)
		warn("Profile not found for player: " .. player.Name)
		return
	end
	print("got req. from client to pay big cards!")
	local bigCards = math.ceil(profile.Data["Big-Cards"] + (amount or 0))
	profile.Data["Big-Cards"] = bigCards
	print("added big cards for " .. player.DisplayName .. " and an amount of " .. tostring(amount))
	print(player.DisplayName .. " now has " .. tostring(profile.Data["Big-Cards"]) .. " Big Cards!")
	local resourceEventParams = {
		flowType = GameAnalytics.EGAResourceFlowType.Source,
		currency = "BigCards",
		amount = amount,
		itemType = "Gameplay",
		itemId = "Big-Cards",
	}
	GameAnalytics:addResourceEvent(player.UserId, resourceEventParams)
	profile:Save()
	profile:Reconcile()
end

local function sellCards(player: Player, cardName: string)
	local profile = profiles[player]
	if not profile then
		Packet.sendNotification.sendTo({
			"Error",
			"Profile not found for player: " .. player.Name,
		}, player)
		warn("Profile not found for player: " .. player.Name)
		return
	end

	print("Attempting to sell card: " .. cardName)

	-- validate card exists
	if not Items[cardName] then
		Packet.sendNotification.sendTo({
			"Error",
			"Invalid card type.",
		}, player)
		warn("Invalid card to sell: ", cardName)
		return
	end
	if not profile.Data.Cards[cardName] or profile.Data.Cards[cardName] <= 0 then
		Packet.sendNotification.sendTo({
			"Error",
			"You don't have any " .. cardName .. " cards to sell.",
		}, player)
		return
	end

	-- calculate sell price (usually half of buy price)
	local sellPrice = Items[cardName].Price // 2

	-- update profile
	profile.Data["Big-Cards"] += sellPrice
	profile.Data.Cards[cardName] -= 1

	print(player.DisplayName .. " sold " .. cardName .. " for " .. tostring(sellPrice) .. " Big Cards")
	print(player.DisplayName .. " now has " .. tostring(profile.Data["Big-Cards"]) .. " Big Cards!")

	local resourceEventParams = {
		flowType = GameAnalytics.EGAResourceFlowType.Sink,
		currency = "BigCards",
		amount = sellPrice,
		itemType = "Gameplay",
		itemId = cardName .. "_Sell",
	}
	GameAnalytics:addResourceEvent(player.UserId, resourceEventParams)

	-- Save changes
	profile:Save()
	profile:Reconcile()
end

local function getProfile(player: Player)
	local profile = profiles[player]
	assert(profile or profiles[player], "Profile does not exist!")
	return {
		Data = profile.Data,
		Key = profile.Key,
		LastSaved = profile.LastSavedData,
	}
end

local function handleSprint(player: Player, v: number, b: boolean)
	local character = characterUtility.get(player)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid

	if b == true then
		-- sprint
		if humanoid then
			humanoid.WalkSpeed = v
		end
	else
		if humanoid then
			humanoid.WalkSpeed = 14 or v
		end
	end
end

-- Set the callback; this can only be done once by one server-side script
MarketplaceService.ProcessReceipt = processReceipt

-- Register Events
-- ("NewMatch")
-- ("PayCards")
-- ("FastTravel")
-- ("SetCameraHost")
-- ("GetPlayerInfo")
-- ("SetCameraView")
-- ("SetPlayerExperience")
-- ("LevelUp")
-- ("SetPlayerExperience")
--
--("FastTravel", FastTravel)
--("PayCards", payCards)
--("GetPlayerInfo", getPlayerInfo)
--("SetPlayerExperience", setPlayerExperience)
--("GetStats", getStats)

Packet.streamArea.listen(function(area, player: Player)
	streamArea(player, area[1])
end)
Packet.createMatch.listen(function(_, player: Player)
	enterMatch(player)
end)
Packet.buyCard.listen(function(cardName, player: Player)
	purchaseCard(player, cardName[1])
end)
Packet.payBigCards.listen(function(data)
	payCards(data[1], data[2])
end)
Packet.sprintRemote.listen(function(data: { boolean | buffer }, player: Player)
	handleSprint(player, data[1], data[2])
end)
Packet.cancelMatch.listen(function(_: nil?, player: Player)
	cancelMatch(player)
end)
Packet.sellCard.listen(function(data: { Instance | string }, player: Player)
	local cardName = data[2]
	sellCards(player, cardName)
end)

local getProfileRF = remoteEvents:FindFirstChild("GetProfile") :: RemoteFunction
getProfileRF.OnServerInvoke = getProfile

-- TODO) add player saving options

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

local serverEndTime = os.clock()
local serverTime = math.round((serverEndTime - serverStartTime) * 10000) / 10000
print("The server completed execution with a time of: " .. tostring(serverTime))
