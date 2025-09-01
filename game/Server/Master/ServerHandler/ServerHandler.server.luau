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
local ParryHandler = require(ReplicatedStorage.Combat.framework.features.parry)
local ProfileStore = require(ReplicatedStorage.Packages.profilestore)
local batch = require(ReplicatedStorage.Utility.batch)
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local dictionary = require(ReplicatedStorage.Utility.dictionary)
local lucide = require(ReplicatedStorage.Packages.lucide)
local observer = require(ReplicatedStorage.Utility.observer)
local orion = require(ReplicatedStorage.Combat.orion)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local productMarshaller = require(ReplicatedStorage.Products.productMarshaller)
local profileMarshaller = require(ReplicatedStorage.Datastore.profileMarshaller)
local profilestore = require(ReplicatedStorage.Packages.profilestore)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local promise = require(ReplicatedStorage.Packages.promise)
local safeteleport = require(ReplicatedStorage.Modules.safeteleport)
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

local playerStore = ProfileStore.New("player-related", profilestructure)

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
productMarshaller.product_callbacks[1904591683] = function(receipt: any | string?, player: Player)
	local profile = profiles[player]
	if not profile then
		print("Profile not found for player: " .. player.Name)
		return false -- indicate a failed purchase
	end
	local Card_int = profile.Data.Prisms :: number
	if Card_int and player then
		Card_int += 50
		local resourceEventParams = {
			flowType = GameAnalytics.EGAResourceFlowType.Source,
			currency = "Prisms",
			amount = 50,
			itemType = "IAP", -- In-App Purchase
		}
		print(receipt)
		GameAnalytics:addResourceEvent(player.UserId, resourceEventParams)
	end
	return true -- indicate a successful purchase
end

productMarshaller.product_callbacks[1906572512] = function(receipt: any | string?, player: Player)
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
	-- Start profile session with timeout
	local profile = playerStore:StartSessionAsync(`player:{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	}):await()

	-- If player leaves during the async call, end the session and stop
	if not player:IsDescendantOf(Players) then
		if profile then
			profile:EndSession()
		end
		return
	end

	if profile then
		-- Set up profile
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		-- Handle session end
		profile.OnSessionEnd:Connect(function()
			profiles[player] = nil
			if player:IsDescendantOf(Players) then
				player:Kick("Session Locked, rejoin")
			end
		end)

		-- The player is in the game, so we can proceed
		profiles[player] = profile

		profile.Data.LastLogin = os.time()

		profile:Reconcile()
		profile:Save()
	else
		player:Kick("The Roblox Servers are on fire. Try rejoining.")
	end

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
		local highlight = Instance.new("Highlight")
		highlight.Adornee = character
		highlight.Parent = character
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.FillColor = Color3.fromRGB(255, 255, 255)
		highlight.FillTransparency = 0.95
		highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		highlight.OutlineTransparency = 0.7
		highlight.Enabled = true

		print("new highlight", highlight)
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

	Packet.SendNotification.sendTo({ message = "Player fully loaded", title = "Server" }, player)
end

-- just in case the players have joined the server before the script loaded
for _, player in ipairs(playerMarshaller.all()) do
	if player.Parent == Players then
		task.spawn(onPlayerAdded, player)
	end
end

ProfileStore.OnError:Connect(function(error_message, store_name, profile_key)
	print(`DataStore error (Store:{store_name};Key:{profile_key}): {error_message}`)
end)

local function onPlayerRemoving(player: playerMarshaller.player)
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
		Packet.SendNotification.sendTo({
			message = "Couldn't get data",
			title = "Profile not found",
			type = "error",
		}, player)

		warn("Profile not found for player: " .. player.Name)

		return
	end
	if not Items[cardName] then
		Packet.SendNotification.sendTo({
			message = "Couldn't get data",
			title = "Card does not exist",
			type = "error",
		}, player)

		warn("Card does not exist: " .. cardName)

		return
	end

	print("Purchasing card: " .. cardName .. " for player: " .. player.Name)

	local resourceEventParams = {
		flowType = GameAnalytics.EGAResourceFlowType.Sink,
		currency = "Prisms",
		amount = 1,
		itemType = "Weapons",
		itemId = cardName .. " Card",
	}

	GameAnalytics:addResourceEvent(player.UserId, resourceEventParams)

	local cards = profile.Data.Prisms

	if cards and cards >= math.ceil(Items[cardName].Price) then
		profile.Data.Prisms -= math.ceil(Items[cardName].Price) or 1
		profile.Data.Cards[cardName] = (profile.Data.Cards[cardName] or 0) + 1

		profile:Save()
		profile:Reconcile()

		--local result = "success"

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

		warn("Not enough Prisms for player: " .. player.Name)
	end

	Packet.profileChanged.sendTo({ nil }, player)
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
	local player = playerMarshaller.getByName(playerName)

	if not player then
		warn("player not found: " .. playerName)
		return
	end

	local profile = profiles[player]

	if not profile then
		Packet.SendNotification.sendTo({
			message = "Couldn't get data",
			title = "Profile not found",
			type = "error",
		}, player)

		warn("Profile not found for player: " .. player.Name)
		return
	end

	print("got req. from client to pay prisms!")

	local prisms = math.ceil(profile.Data.Prisms + (amount or 0))
	profile.Data.Prisms = prisms

	print("added prisms for " .. player.DisplayName .. " and an amount of " .. tostring(amount))
	print(player.DisplayName .. " now has " .. tostring(profile.Data.Prisms) .. " Prisms!")

	local resourceEventParams = {
		flowType = GameAnalytics.EGAResourceFlowType.Source,
		currency = "Prisms",
		amount = amount,
		itemType = "Gameplay",
		itemId = "Prisms",
	}

	GameAnalytics:addResourceEvent(player.UserId, resourceEventParams)

	Packet.profileChanged.sendTo({ nil }, player)

	profile:Save()
	profile:Reconcile()
end

local function sellCards(player: Player, cardName: string)
	local profile = profiles[player]

	if not profile then
		Packet.SendNotification.sendTo({
			message = "Couldn't get data",
			title = "Profile not found",
			type = "error",
		}, player)

		warn("Profile not found for player: " .. player.Name)

		return
	end

	print("Attempting to sell card: " .. cardName)

	-- validate card exists
	if not Items[cardName] then
		Packet.SendNotification.sendTo({
			message = "Couldn't get data",
			title = "Invalid Card",
			type = "error",
		}, player)

		warn("Invalid card to sell: ", cardName)

		return
	end

	if not profile.Data.Cards[cardName] or profile.Data.Cards[cardName] <= 0 then
		Packet.SendNotification.sendTo({
			message = "Couldn't get data",
			title = "You don't have any " .. cardName .. " Cards to sell.",
			type = "error",
		}, player)

		warn("Invalid card to sell: ", cardName)

		return
	end

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
	local sellPrice = Items[cardName].Price // 2

	-- update profile
	profile.Data.Prisms += sellPrice
	profile.Data.Cards[cardName] -= 1

	print(player.DisplayName .. " sold " .. cardName .. " for " .. tostring(sellPrice) .. " Prisms")
	print(player.DisplayName .. " now has " .. tostring(profile.Data.Prisms) .. " Prisms!")

	local resourceEventParams = {
		flowType = GameAnalytics.EGAResourceFlowType.Sink,
		currency = "Prisms",
		amount = sellPrice,
		itemType = "Gameplay",
		itemId = cardName .. "_Sell",
	}

	GameAnalytics:addResourceEvent(player.UserId, resourceEventParams)

	Packet.profileChanged.sendTo({ nil }, player)
	-- Save changes
	profile:Save()
	profile:Reconcile()
end

local function getProfile(player: Player)
	local value = nil

	promise
		.new(function(resolve, reject)
			local profile = profiles[player]

			if not profile then
				reject("Profile does not exist!")
			end

			value = {
				Data = profile.Data,
				Key = profile.Key,
				LastSaved = profile.LastSavedData,
			}

			resolve({
				Data = profile.Data,
				Key = profile.Key,
				LastSaved = profile.LastSavedData,
			})
		end)
		:andThen(print)
		:catch(warn)

	return value
end

local function setNetworkOwner(player: Player?, object: BasePart)
	if not object then
		return
	end
	object:SetNetworkOwner(player)
end

local function handleYoinkRequest(player: playerMarshaller.player, key: string)
	local value = nil
	if key == "profile_data" then
		value = getProfile(player)
	end
	return value
end

-- Set the callback; this can only be done once by one server-side script
MarketplaceService.ProcessReceipt = function(receiptInfo: {
	[any]: any,
})
	productMarshaller.processReceipt(receiptInfo, productMarshaller.product_callbacks)
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

Packet.StreamArea.listen(function(area, player: Player)
	streamArea(player, area)
end)
Packet.CreateMatch.listen(function(_, player: Player)
	enterMatch(player)
end)
Packet.BuyCard.listen(function(data, player: Player)
	purchaseCard(player, data.cardName)
end)
Packet.PayPrisms.listen(function(data)
	payCards(data.amount, data.recipientUsername)
end)
Packet.CancelMatch.listen(function(_, player: Player)
	cancelMatch(player)
end)
Packet.SellCard.listen(function(data, player: Player)
	local cardName = data.cardName
	sellCards(player, cardName)
end)
Packet.SetNetworkOwner.listen(function(data)
	setNetworkOwner(data.player, data.object)
end)

local yoinkWrapper = ReplicatedStorage:FindFirstChild("YoinkWrapper") :: RemoteFunction
yoinkWrapper.OnServerInvoke = handleYoinkRequest

-- TODO) add player saving options

playerMarshaller.added(function(player)
	onPlayerAdded(player)
end)
playerMarshaller.removing(function(player)
	onPlayerRemoving(player)
end)

windshake:Init({
	MatchWorkspaceWind = true,
})

local serverEndTime = os.clock()
local serverTime = math.round((serverEndTime - serverStartTime) * 10000) / 10000
print("The server completed execution with a time of: " .. tostring(serverTime))
