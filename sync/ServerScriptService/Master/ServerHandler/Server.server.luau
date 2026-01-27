--!strict

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
local Fireworks = require(ReplicatedStorage.Modules.Fireworks)
local GameAnalytics = require(ReplicatedStorage.Packages["gameanalytics-sdk"])
local Items = require(ReplicatedStorage.Market.Items)
local Packet = require(ReplicatedStorage.Packet)
local ProfileStore = require(ReplicatedStorage.Packages.profilestore)
local batch = require(ReplicatedStorage.Utility.batch)
local bufferencoder = require(ReplicatedStorage.Packages.bufferencoder)
local future = require(ReplicatedStorage.Packages.future)
local lucide = require(ReplicatedStorage.Packages.lucide)
local messagepack = require(ReplicatedStorage.Modules.Serialization.messagepack)
local observer = require(ReplicatedStorage.Utility.observer)
local orion = require(ReplicatedStorage.Combat.orion)
local party = require(ReplicatedStorage.Modules.party)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local productMarshaller = require(ReplicatedStorage.Products.productMarshaller)
local profilestore = require(ReplicatedStorage.Packages.profilestore)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local promise = require(ReplicatedStorage.Packages.promise)
local random = require(ReplicatedStorage.Utility.random)
local retryer = require(ReplicatedStorage.Utility.retryer)
local safeteleport = require(ReplicatedStorage.Modules.safeteleport)
local spr = require(ReplicatedStorage.Modules.spr)
local star = require(ReplicatedStorage.Environment.star)
local starsStructure = require(ReplicatedStorage.Structures.starsStructure)
local tablekit = require(ReplicatedStorage.Packages.tablekit)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)
local windshake = require(ReplicatedStorage.Packages.windshake)

local assets = ReplicatedStorage.Assets

local profiles = {}
local profile_key = "playerdata"
local player_related = profilestore.New(profile_key, profilestructure)

-- change this if i want data to save in studio
if RunService:IsStudio() then
	player_related = player_related.Mock
end

local function loadProfile(player: Player)
	local profile = retryer.infdelay(1, function(...)
		return player_related:StartSessionAsync(`player_{player.UserId}`, {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})
	end)

	if profile then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		profile.OnSessionEnd:Connect(function()
			profiles[player] = nil
			player:Kick("Session Locked, rejoin")
		end)

		print("Created profile")
		if player:FindFirstAncestorOfClass("Players") then
			profiles[player] = profile
			profile.Data.last_login = DateTime.now().UnixTimestampMillis
			profile:Reconcile()
			profile:Save()

			print("Created, reconciled and saved profile!")
		else
			profile:EndSession()
			warn("Data not loaded for " .. player.DisplayName .. ", session ended.")
		end
	elseif not profile then
		player:Kick("The Roblox Servers are on fire, try rejoining.")
	end

	return profile
end

local function FetchProfileData(player: Player): typemarshaller.ProfileData?
	local profile = profiles[player] :: typemarshaller.Profile?
	if not profile and profile == nil then
		Packet.SendNotification.sendTo({
			message = "Couldn't get data",
		}, player)

		local list = tablekit.Values(profiles :: any)

		warn("Couldn't fetch profile from table: ", table.unpack(list))

		return nil
	end

	return profile.Data
end

local function SaveProfileData(player: Player)
	local profile = profiles[player] -- we need the full table
	if not profile then
		warn("Cannot save profile; couldn't find one.")
	end

	profile:Reconcile()
	profile:Save()
end

local function GetPrisms(player: Player)
	local profile = FetchProfileData(player)
	if not profile then
		print("no profile found to perform action.")
		return 0
	end

	return profile.prisms
end

local function AddPrisms(player: Player, amount: number)
	local profile = FetchProfileData(player)
	if not profile then
		print("no profile found to perform action.")
		return
	end

	profile.prisms += amount
end

local function DeductPrisms(player: Player, amount: number)
	local profile = FetchProfileData(player)
	if not profile then
		print("no profile found to perform action.")
		return
	end

	profile.prisms -= amount
end

local function AddCards(player: Player, name: string, amount: number)
	local profile = FetchProfileData(player)
	if not profile then
		print("no profile found to perform action.")
		return
	end

	future.Try(function(...)
		if profile.cards[name] then
			profile.cards[name] += amount
		else
			profile.cards[name] = amount
		end
	end)
end

local function DeductCards(player: Player, name: string, amount: number)
	local profile = FetchProfileData(player)
	if not profile then
		print("no profile found to perform action.")
		return
	end

	future.Try(function(...)
		if profile.cards[name] then
			profile.cards[name] -= math.clamp(amount, 0, profile.cards[name])
		end
	end)
end

local function InsertQuestData(player: Player, quest: typemarshaller.Quest)
	local profile = FetchProfileData(player)
	if not profile then
		print("no profile found to perform action.")
		return
	end

	future.Try(table.insert, profile.quests, quest)
end

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

Cmdr.Registry:RegisterDefaultCommands()
Cmdr.Registry:RegisterCommandsIn(ReplicatedStorage.Commands)
Cmdr.Registry:RegisterHooksIn(ReplicatedStorage.Hooks)

-- selene:allow(mixed_table)
GameAnalytics:initialize(gameAnalyticsConfig)
GameAnalytics:configureAvailableResourceItemTypes(resourceItemTypes)
-- GameAnalytics:initServer(gameAnalyticsConfig.gameKey, gameAnalyticsConfig.secretKey)

-- TODO) add the products

local ServerAsset = assets.Server:Clone()
ServerAsset.Parent = game.Workspace

local function enterMatch(player: Player)
	print("player entered match")

	if not player then
		return
	end

	Packet.SendNotification.sendTo({ message = "Joined matchmaking queue", duration = 5 }, player)
end

local function cancelMatch(player: Player)
	print("cancel match")

	if not player then
		return
	end

	Packet.SendNotification.sendTo({ message = "Left matchmaking queue", duration = 5 }, player)
end

local function onPlayerAdded(player: Player)
	GameAnalytics:PlayerJoined(player)
	future.new(GameAnalytics.PlayerJoined, GameAnalytics, player)
	--orion.registerPlayer(player)

	local function addHighlight(character: Model)
		return future.new(function()
			if character:FindFirstChildOfClass("Highlight") then
				return "already has highlight"
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

			return "new highlight"
		end)
	end

	player.CharacterAdded:Connect(function(character)
		character:SetAttribute("Stamina", 100)
		character:SetAttribute("MaxStamina", 100)

		addHighlight(character):Expect("couldn't make highlight for some reason")
	end)

	addHighlight(player.Character or player.CharacterAdded:Wait() :: any)
	batch(player:GetDescendants())
	loadProfile(player)
end

-- just in case the players have joined the server before the script loaded
for i, player in ipairs(playerMarshaller.all()) do
	if player.Parent == Players then
		task.spawn(onPlayerAdded, player)
	end
end

local function onPlayerRemoving(player: Player)
	GameAnalytics:PlayerRemoved(player)
	local profile = profiles[player]

	if profile ~= nil then
		SaveProfileData(player)

		print("saved data for " .. player.Name)

		profile:EndSession()

		profiles[player] = nil

		print("ended session for " .. player.Name)
	else
		print("couldn't save in time for " .. player.Name)
	end

	task.defer(player.Destroy, player)
end

local function purchaseCard(player: Player, card_name: string)
	if not card_name then
		print("no card name provided to buy: ", card_name)
		return
	end

	local event_parameters = {
		flowType = GameAnalytics.EGAResourceFlowType.Sink,
		currency = "Prisms",
		amount = 1,
		itemType = "Weapons",
		itemId = card_name .. " Card",
	}

	GameAnalytics:addResourceEvent(player.UserId, event_parameters)

	local price = Items[card_name].Price

	local prisms = GetPrisms(player)

	if prisms >= price then
		AddCards(player, card_name, 1)

		local deduct_amount = math.ceil(price) or 1

		DeductPrisms(player, deduct_amount)

		SaveProfileData(player)

		Packet.SendNotification.sendTo({
			message = `You purchased a {card_name} Card.`,
		}, player)
	else
		Packet.SendNotification.sendTo({
			message = `Could not buy {card_name}`,
		}, player)
	end
end

local function streamArea(player: Player, area: Vector3)
	if not player then
		return
	end

	area = area or Vector3.one

	task.spawn(function()
		player:RequestStreamAroundAsync(area)
	end)
end

local function payPrisms(amount: number, username: string)
	local player = Players:FindFirstChild(username) :: Player
	assert(player, "Couldn't fetch player by name: " .. username)

	AddPrisms(player, amount)

	local event_parameters = {
		flowType = GameAnalytics.EGAResourceFlowType.Source,
		currency = "Prisms",
		amount = amount,
		itemType = "Gameplay",
		itemId = "Prisms",
	}

	GameAnalytics:addResourceEvent(player.UserId, event_parameters)

	SaveProfileData(player)
end

local function sellCards(player: Player, card_name: string)
	if not card_name then
		print("no card name provided to sell: ", card_name)
		return
	end

	local profile = FetchProfileData(player)

	if not profile.cards[card_name] or profile.cards[card_name] <= 0 then
		-- you ain't got nun to sell boi.

		warn("No cards to sell for player: " .. player.Name)
		return
	end

	-- calculate sell price (usually half of buy price)
	local sellPrice = math.floor(Items[card_name].Price * 0.5)

	-- update profile
	AddPrisms(player, sellPrice)
	DeductCards(player, card_name, 1)

	local event_parameters = {
		flowType = GameAnalytics.EGAResourceFlowType.Sink,
		currency = "Prisms",
		amount = sellPrice,
		itemType = "Gameplay",
		itemId = card_name .. "_Sell",
	}

	GameAnalytics:addResourceEvent(player.UserId, event_parameters)
	-- Save changes
	SaveProfileData(player)
end

local function setNetworkOwner(player: Player?, object: BasePart)
	if not object then
		print("no object provided to set network owner to: ", object)
		return
	end

	future.new(object.SetNetworkOwner, object, player or nil)
end

local function getProfile(player: Player): typemarshaller.Profile?
	local ok, profile = retryer.delay(1, 10, function()
		return profiles[player]
	end)

	if not ok or not profile then
		warn("failed to index table for profile.", player)

		return nil
	end

	return {
		Data = profile.Data,
	}
end

local function setClock(number: number)
	spr.stop(Lighting, "ClockTime")

	number = math.clamp(number, 0, 24) or 12

	spr.target(Lighting, 1, 4, {
		ClockTime = number,
	})
end

local function addQuest(player: Player, quest_data: string)
	-- deserialize
	local deserialized_data = messagepack.decode(quest_data) :: {
		name: string,
		description: string,
		inquirer_img: number | Instance, -- img id or a model
		progress: number,
		date_acquired: number, -- unix timestamp millis
		date_completed: number?,
		completed: boolean?,
		module: ModuleScript?,
	}

	InsertQuestData(player, deserialized_data)

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

Packet.AddQuest.listen(function(data, player: Player?)
	addQuest(data.player, data.quest_data)
end)
Packet.SetTime.listen(function(data, player: Player?)
	setClock(data.clock_time)
end)
Packet.StreamArea.listen(function(data, player: Player)
	streamArea(player, data.area_center)
end)
Packet.CreateMatch.listen(function(_, player: Player)
	enterMatch(player)
end)
Packet.BuyCard.listen(function(data, player: Player)
	purchaseCard(player, data.card_name)
end)
Packet.PayPrisms.listen(function(data)
	payPrisms(data.amount, data.recipient_username)
end)
Packet.CancelMatch.listen(function(_, player: Player)
	cancelMatch(player)
end)
Packet.SellCard.listen(function(data, player: Player)
	local card_name = data.card_name
	sellCards(player, card_name)
end)
Packet.SetNetworkOwner.listen(function(data: { object: Instance, player: Instance? })
	setNetworkOwner(data.player, data.object)
end)
Packet.CreateParty.listen(function(data: { settings: { [string]: any } }, player: Player)
	-- TODO) create party
	party.new(player.UserId)
end)
Packet.DeleteParty.listen(function(data: { party_id: string }, player: Player)
	-- TODO) delete party
	local party_obj = party:GetPartyById(data.party_id)
	if party_obj then
		for i, member_id in ipairs(party_obj.members) do
			if member_id == player.UserId then
				-- only the leader can delete the party
				if party_obj.leader_id == player.UserId then
					party_obj:Destroy()
				end
				break
			end
		end
	end
end)
Packet.JoinParty.listen(function(data: { party_id: string }, player: Player)
	-- TODO) join party
	local party_obj = party:GetPartyById(data.party_id)
	if party_obj then
		local success = party_obj:AddMember(player.UserId)
		if success then
			-- joined party successfully
			Packet.SendNotification.sendTo({
				message = "Joined party successfully!",
			}, player)
		else
			-- failed to join Party
			Packet.SendNotification.sendTo({
				message = "Failed to join party.",
			}, player)
		end
	end
end)
Packet.LeaveParty.listen(function(data: { party_id: string }, player: Player)
	-- TODO) leave party
	local party_obj = party:GetPartyById(data.party_id)
	if party_obj then
		for i, member_id in ipairs(party_obj.members) do
			if member_id == player.UserId then
				party_obj:RemoveMember(player.UserId)
				break
			end
		end
	end
end)
Packet.BlowFirework.listen(function(data: { amount: number, position: Vector3 }, player: Player)
	local WhenToStop = 0

	local fut = future.Try(function()
		while WhenToStop < data.amount do
			Fireworks.create(
				data.position + Vector3.new(random.float(-4, 4), -2, random.float(-4, 4)),
				data.amount
			)

			WhenToStop += 1
		end
	end)

	local ok, result = fut:Await()
	print("is ok: ", ok, result)

	print(`Player {player.Name} blew {data.amount} fireworks at position {tostring(data.position)}`)
end)

ReplicatedStorage.Events.GetProfile.OnServerInvoke = getProfile

-- TODO) add player saving options
playerMarshaller.added(onPlayerAdded)
playerMarshaller.removing(onPlayerRemoving)

windshake:Init({
	MatchWorkspaceWind = true,
})

print("The server completed execution.")
