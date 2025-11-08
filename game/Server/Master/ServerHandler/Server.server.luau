--!nonstrict

-- Server.server.luau

print(script.Name)

local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local LogService = game:GetService("LogService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cmdr = require(ReplicatedStorage.Packages:WaitForChild("cmdr"))
local GameAnalytics = require(ReplicatedStorage.Packages["gameanalytics-sdk"])
local Items = require(ReplicatedStorage.Market.Items)
local MatchMaker = require(ReplicatedStorage.Modules.MatchMaker)
local Packet = require(ReplicatedStorage.Packet)
local ParryHandler = require(ReplicatedStorage.Combat.framework.features.parry)
local ProfileStore = require(ReplicatedStorage.Packages.profilestore)
local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local aurora = require(ReplicatedStorage.Environment.aurora)
local batch = require(ReplicatedStorage.Utility.batch)
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local lucide = require(ReplicatedStorage.Packages.lucide)
local messagepack = require(ReplicatedStorage.Modules.Serialization.messagepack)
local observer = require(ReplicatedStorage.Utility.observer)
local orion = require(ReplicatedStorage.Combat.orion)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local productMarshaller = require(ReplicatedStorage.Products.productMarshaller)
local profilestore = require(ReplicatedStorage.Packages.profilestore)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local promise = require(ReplicatedStorage.Packages.promise)
local safeteleport = require(ReplicatedStorage.Modules.safeteleport)
local spr = require(ReplicatedStorage.Modules.spr)
local star = require(ReplicatedStorage.Environment.star)
local starsStructure = require(ReplicatedStorage.Structures.starsStructure)
local stores = require(ReplicatedStorage.Datastore.stores)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)
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

Cmdr.Registry:RegisterDefaultCommands()
Cmdr.Registry:RegisterCommandsIn(ReplicatedStorage.Commands)
Cmdr.Registry:RegisterHooksIn(ReplicatedStorage.Hooks)

-- selene:allow(mixed_table)
GameAnalytics:initialize(gameAnalyticsConfig)
GameAnalytics:configureAvailableResourceItemTypes(resourceItemTypes)
-- GameAnalytics:initServer(gameAnalyticsConfig.gameKey, gameAnalyticsConfig.secretKey)

local matchSettings = MatchMaker:NewOptions()
matchSettings.MatchPlaceId = 13609839542
matchSettings.NumberOfTeams = 2
matchSettings.MaxPlayersPerTeam = 1
matchSettings.MatchExpirationTime = 600

local queue = MatchMaker:GetQueue("global", matchSettings)

--[[
	This is only for if I want to write
	data to the profiles while testing.
]]
--[[
if RunService:IsStudio() then
	playerStore = playerStore.Mock
end
--]]

-- TODO) add the products

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

	print(queue)

	queue:QueuePlayers({ player })

	Packet.SendNotification.sendTo(
		{ message = "Joined matchmaking queue", title = "Matchmaking", type = "info", duration = 5 },
		player
	)
end

local function cancelMatch(player: playerMarshaller.player)
	print("cancel match")

	if not player then
		return
	end

	Packet.SendNotification.sendTo(
		{ message = "Left matchmaking queue", title = "Matchmaking", type = "info", duration = 5 },
		player
	)
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
		return promise
			.new(function(resolve: (string, Highlight?) -> ...unknown)
				if character:FindFirstChildOfClass("Highlight") then
					resolve("already has highlight", nil)

					return
				end
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
			.new(function(resolve: (string) -> ...unknown, reject: (string, unknown) -> ...unknown)
				local success, err = pcall(character.Destroy, character)

				if success then
					resolve("Optimized Character Cleanup.")
				elseif not success and err then
					reject("Couldn't optimize character cleanup: ", err)
				end
			end)
			:andThen(print)
			:catch(warn)
	end)

	addHighlight(player.Character or player.CharacterAdded:Wait())
	batch(player:GetDescendants())
	stores.load(player)

	Packet.SendNotification.sendTo({ message = "Player fully loaded", title = "Server" }, player)
end

-- just in case the players have joined the server before the script loaded
for i, player in ipairs(playerMarshaller.all()) do
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
	if not profile then
		Packet.SendNotification.sendTo({
			message = "Couldn't get data",
			title = "Your data did not load.",
			type = "error",
		}, player)
		return
	end

	if not profile.Data.Cards[cardName] or profile.Data.Cards[cardName] <= 0 then
		Packet.SendNotification.sendTo({
			message = "Couldn't get data",
			title = "You don't have any " .. cardName .. " Cards to sell.",
			type = "warning",
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

local function getProfile(player: playerMarshaller.player): { Data: profilestructure.profile? }
	local profile = stores.get(player)

	print("getting profile: server")

	if not profile then
		Packet.SendNotification.sendTo({
			message = "Couldn't get data",
			title = "Your data did not load.",
			type = "error",
			duration = 5,
		}, player)

		return nil
	end

	return {
		Data = profile.Data,
	}
end

local function setClock(number: number)
	spr.stop(Lighting, "ClockTime")
	spr.target(Lighting, 1, 1, {
		ClockTime = number,
	})
end

local function addQuest(player: playerMarshaller.player, quest_data: string)
	-- deserialize
	quest_data = messagepack.decode(quest_data) :: {
		name: string,
		description: string,
		inquirer_img: number | Instance, -- img id or a model
		progress: number,
		date_acquired: number, -- unix timestamp millis
		date_completed: number?,
		completed: boolean?,
		module: ModuleScript?,
	}

	stores:addQuest(player, quest_data)

	print("server: added quest")
end

local function addProducts()
	-- TODO) add the product thingies
end

-- Set the callback; this can only be done once by one server-side script
MarketplaceService.ProcessReceipt = function(receiptInfo: typemarshaller.ReceiptInfo)
	productMarshaller._call(receiptInfo)
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

Packet.AddQuest.listen(function(data: { player: Instance, questData: string }, player: Player?)
	addQuest(data.player, data.questData)
end)
Packet.SetTime.listen(function(data: { clock_time: number }, player: Player?)
	setClock(data.clock_time)
end)
Packet.StreamArea.listen(function(data: { areaCenter: Vector3 }, player: playerMarshaller.player)
	streamArea(player, data.areaCenter)
end)
Packet.CreateMatch.listen(function(_, player: playerMarshaller.player)
	enterMatch(player)
end)
Packet.BuyCard.listen(function(data: { cardName: string }, player: playerMarshaller.player)
	purchaseCard(player, data.cardName)
end)
Packet.PayPrisms.listen(function(data: { amount: number, recipientUsername: string })
	payPrisms(data.amount, data.recipientUsername)
end)
Packet.CancelMatch.listen(function(_, player: playerMarshaller.player)
	cancelMatch(player)
end)
Packet.SellCard.listen(
	function(data: { cardName: string, playerInstance: Instance }, player: playerMarshaller.player)
		local cardName = data.cardName
		sellCards(player, cardName)
	end
)
Packet.SetNetworkOwner.listen(function(data: { object: Instance, player: Instance? })
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
