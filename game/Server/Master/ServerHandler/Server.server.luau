--!nonstrict

-- Server.server.luau

print(script.Name)

local LogService = game:GetService("LogService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StopWatchReporter = game:GetService("StopWatchReporter")

local Cmdr = require(ReplicatedStorage.Packages:WaitForChild("cmdr"))
local GameAnalytics = require(ReplicatedStorage.Packages["gameanalytics-sdk"])
local Items = require(ReplicatedStorage.Market.Items)
local MatchHandler = require(ReplicatedStorage.Modules.MatchHandler)
local Packet = require(ReplicatedStorage.Packet)
local ParryHandler = require(ReplicatedStorage.Combat.framework.features.parry)
local ProfileStore = require(ReplicatedStorage.Packages.profilestore)
local aurora = require(ReplicatedStorage.Environment.aurora)
local batch = require(ReplicatedStorage.Utility.batch)
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local dictionary = require(ReplicatedStorage.Utility.dictionary)
local lucide = require(ReplicatedStorage.Packages.lucide)
local observer = require(ReplicatedStorage.Utility.observer)
local orion = require(ReplicatedStorage.Combat.orion)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local productMarshaller = require(ReplicatedStorage.Products.productMarshaller)
local profilestore = require(ReplicatedStorage.Packages.profilestore)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local promise = require(ReplicatedStorage.Packages.promise)
local safeteleport = require(ReplicatedStorage.Modules.safeteleport)
local stores = require(ReplicatedStorage.Datastore.stores)
local windshake = require(ReplicatedStorage.Packages.windshake)

local remoteEvents = ReplicatedStorage.Events
local assets = ReplicatedStorage:FindFirstChild("Assets") :: Folder

print("GameAnalytics is enabled.")

local gameAnalyticsConfig = {
	enableInfoLog = false,
	enableVerboseLog = false,
	availableResourceCurrencies = { "Prisms" },
	build = "0.2.0",
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
Cmdr:RegisterCommandsIn(ReplicatedStorage.Commands)

-- selene:allow(mixed_table)
GameAnalytics:initialize(gameAnalyticsConfig)
GameAnalytics:configureAvailableResourceItemTypes(resourceItemTypes)
-- GameAnalytics:initServer(gameAnalyticsConfig.gameKey, gameAnalyticsConfig.secretKey)

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
productMarshaller.product_callbacks[1904591683] = function(
	receipt: any | string?,
	player: playerMarshaller.player
)
	local profile = stores.get(player)
	if not profile then
		return false -- indicate a failed purchase
	end

	if player and stores.getPrisms(player) then
		stores:addPrisms(player, 50)

		local resourceEventParams = {
			flowType = GameAnalytics.EGAResourceFlowType.Source,
			currency = "Prisms",
			amount = 50,
			itemType = "IAP", -- In-App Purchase
		}

		GameAnalytics:addResourceEvent(player.UserId, resourceEventParams)
	end
	return true -- indicate a successful purchase
end

productMarshaller.product_callbacks[1906572512] = function(
	receipt: any | string?,
	player: playerMarshaller.player
)
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

local function enterMatch(player: playerMarshaller.player)
	print("player entered match")

	if not player then
		return
	end

	MatchHandler.AddPlayerToQueue(player)

	Packet.SendNotification.sendTo({ message = "Joined matchmaking queue", title = "Matchmaking" }, player)
end

local function cancelMatch(player: playerMarshaller.player)
	print("cancel match")

	if not player then
		return
	end

	MatchHandler.RemovePlayerFromQueue(player)

	Packet.SendNotification.sendTo({ message = "Left matchmaking queue", title = "Matchmaking" }, player)
end

local function onPlayerAdded(player: playerMarshaller.player)
	-- for the client to mess around with
	local editConfig = Instance.new("BindableEvent")
	editConfig.Parent = player
	editConfig.Name = "EditConfig"

	local toggleShiftLock = Instance.new("BindableEvent")
	toggleShiftLock.Parent = player
	toggleShiftLock.Name = "ToggleShiftLock"

	GameAnalytics:PlayerJoined(player)
	--orion.registerPlayer(player)

	local function addHighlight(character: characterMarshaller.Character)
		promise
			.new(function(resolve)
				local highlight = Instance.new("Highlight")
				highlight.Adornee = character
				highlight.Parent = character
				highlight.DepthMode = Enum.HighlightDepthMode.Occluded
				highlight.FillColor = Color3.fromRGB(255, 255, 255)
				highlight.FillTransparency = 0.95
				highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
				highlight.OutlineTransparency = 0.7
				highlight.Enabled = true

				resolve("new highlight: ", highlight)
			end)
			:andThen(print)
			:catch(warn)
	end

	characterMarshaller.added(player, function(character: characterMarshaller.Character)
		character:SetAttribute("Stamina", 100)
		character:SetAttribute("MaxStamina", 100)

		addHighlight(character)
	end)

	-- Optimize character cleanup
	characterMarshaller.removing(player, function(character)
		promise
			.new(function(resolve, reject)
				local success, err = pcall(character.Destroy, character)

				if success then
					resolve("Optimized Character Cleanup.")
				elseif not success and err then
					reject("Couldn't optimize character cleanup")
				end
			end)
			:andThen(print)
			:catch(warn)
	end)

	addHighlight(player.Character or player.CharacterAdded:Wait())
	batch(player:GetDescendants())
	task.delay(1, stores.load, player)

	Packet.SendNotification.sendTo({ message = "Player fully loaded", title = "Server" }, player)
end

-- just in case the players have joined the server before the script loaded
for _, player in ipairs(playerMarshaller.all()) do
	if player.Parent == Players then
		task.spawn(onPlayerAdded, player)
	end
end

local function onPlayerRemoving(player: playerMarshaller.player)
	GameAnalytics:PlayerRemoved(player)
	local profile = stores.get(player)

	if profile ~= nil then
		stores:wrapSave(player)

		print("saved data for " .. player.DisplayName)

		profile:EndSession()

		stores.server[player] = nil

		print("ended session for " .. player.DisplayName)
	else
		print("couldn't save in time for " .. player.DisplayName)
	end

	task.defer(player.Destroy, player)
end

local function purchaseCard(player: playerMarshaller.player, cardName: string)
	local resourceEventParams = {
		flowType = GameAnalytics.EGAResourceFlowType.Sink,
		currency = "Prisms",
		amount = 1,
		itemType = "Weapons",
		itemId = cardName .. " Card",
	}

	GameAnalytics:addResourceEvent(player.UserId, resourceEventParams)

	local price = Items[cardName].Price

	local prisms = stores.getPrisms(player)

	if prisms >= price then
		stores:addCard(player, cardName, 1)

		local deductAmount = math.ceil(price) or 1

		stores:deductPrims(player, deductAmount)

		stores:wrapSave(player)

		Packet.SendNotification.sendTo({
			message = `You purchased a {cardName} Card.`,
			title = `Card purchased`,
			type = "success",
		}, player)
	else
		Packet.SendNotification.sendTo({
			message = `Could not buy {cardName}`,
			title = "Not enough Prisms.",
			type = "error",
		}, player)
	end
end

local function streamArea(player: playerMarshaller.player, area: Vector3)
	if not player then
		return
	end

	task.spawn(function()
		player:RequestStreamAroundAsync(area)
	end)
end

local function payPrisms(amount: number, playerName: string)
	local player = playerMarshaller.getByName(playerName)

	stores:addPrisms(player, amount)

	local resourceEventParams = {
		flowType = GameAnalytics.EGAResourceFlowType.Source,
		currency = "Prisms",
		amount = amount,
		itemType = "Gameplay",
		itemId = "Prisms",
	}

	GameAnalytics:addResourceEvent(player.UserId, resourceEventParams)

	stores:wrapSave(player)
end

local function sellCards(player: Player, cardName: string)
	local profile = stores.get(player)

	if not profile.Data.Cards[cardName] or profile.Data.Cards[cardName] <= 0 then
		Packet.SendNotification.sendTo({
			message = "Couldn't get data",
			title = "You don't have any " .. cardName .. " Cards to sell.",
			type = "error",
		}, player)

		warn("No cards to sell for player: " .. player.Name)
		return
	end

	-- calculate sell price (usually half of buy price)
	local sellPrice = math.floor(Items[cardName].Price * 0.5)

	-- update profile
	stores:addPrisms(player, sellPrice)
	stores:deductCards(player, cardName, 1)

	local resourceEventParams = {
		flowType = GameAnalytics.EGAResourceFlowType.Sink,
		currency = "Prisms",
		amount = sellPrice,
		itemType = "Gameplay",
		itemId = cardName .. "_Sell",
	}

	GameAnalytics:addResourceEvent(player.UserId, resourceEventParams)
	-- Save changes
	stores:wrapSave(player)
end

local function setNetworkOwner(player: playerMarshaller.player?, object: BasePart)
	if not object then
		return
	end

	promise.new(function()
		object:SetNetworkOwner(player or nil)
	end)
end

local function getProfile(player: playerMarshaller.player)
	local profile = stores.get(player)

	print("getting profile: server")

	return {
		Data = profile.Data,
	}
end

-- Set the callback; this can only be done once by one server-side script
MarketplaceService.ProcessReceipt = function(receiptInfo)
	return productMarshaller.processReceipt(receiptInfo, productMarshaller.product_callbacks)
end

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

Packet.StreamArea.listen(function(data, player: playerMarshaller.player)
	streamArea(player, data.areaCenter)
end)
Packet.CreateMatch.listen(function(_, player: playerMarshaller.player)
	enterMatch(player)
end)
Packet.BuyCard.listen(function(data, player: playerMarshaller.player)
	purchaseCard(player, data.cardName)
end)
Packet.PayPrisms.listen(function(data)
	payPrisms(data.amount, data.recipientUsername)
end)
Packet.CancelMatch.listen(function(_, player: playerMarshaller.player)
	cancelMatch(player)
end)
Packet.SellCard.listen(function(data, player: playerMarshaller.player)
	local cardName = data.cardName
	sellCards(player, cardName)
end)
Packet.SetNetworkOwner.listen(function(data)
	setNetworkOwner(data.player, data.object)
end);

(remoteEvents.GetProfile :: RemoteFunction).OnServerInvoke = getProfile

local borealis = aurora.new():setPosition(Vector3.new(0, 50, 0)):adjust(1.1, 1.1)

-- TODO) add player saving options

playerMarshaller.added(function(player: playerMarshaller.player)
	onPlayerAdded(player)
end)
playerMarshaller.removing(function(player: playerMarshaller.player)
	onPlayerRemoving(player)
end)

windshake:Init({
	MatchWorkspaceWind = true,
})

local serverEndTime = os.clock()
local serverTime = math.round((serverEndTime - serverStartTime) * 10000) / 10000
print("The server completed execution with a time of: " .. tostring(serverTime))
