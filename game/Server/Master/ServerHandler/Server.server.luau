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
local matchmaker = require(ReplicatedStorage.Modules.matchmaker)
local messagepack = require(ReplicatedStorage.Modules.Serialization.messagepack)
local observer = require(ReplicatedStorage.Utility.observer)
local orion = require(ReplicatedStorage.Combat.orion)
local party = require(ReplicatedStorage.Modules.party)
local productMarshaller = require(ReplicatedStorage.Products.productMarshaller)
local profilestore = require(ReplicatedStorage.Packages.profilestore)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local promise = require(ReplicatedStorage.Packages.promise)
local random = require(ReplicatedStorage.Utility.random)
local retryer = require(ReplicatedStorage.Utility.retryer)
local safeteleport = require(ReplicatedStorage.Modules.safeteleport)
local skill_tree = require(ReplicatedStorage.Combat.framework["skill-tree"])
local spr = require(ReplicatedStorage.Modules.spr)
local star = require(ReplicatedStorage.Environment.star)
local starsStructure = require(ReplicatedStorage.Structures.starsStructure)
local tablekit = require(ReplicatedStorage.Packages.tablekit)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)
local windshake = require(ReplicatedStorage.Packages.windshake)

local assets = ReplicatedStorage.Assets

local Events = ReplicatedStorage:WaitForChild("Events")
local MatchmakingRemotes = Events:WaitForChild("Matchmaking")
local PartyRemotes = Events:WaitForChild("Party")

-- ensure QueueUpdated RemoteEvent exists so matchmaker can broadcast safely
if not MatchmakingRemotes:FindFirstChild("QueueUpdated") then
	local ev = Instance.new("RemoteEvent")
	ev.Name = "QueueUpdated"
	ev.Parent = MatchmakingRemotes
end

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
			profile.Data.name = player.Name

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
		--print("no profile found to perform action.")
		return 0
	end

	return profile.prisms
end

local function AddPrisms(player: Player, amount: number)
	local profile = FetchProfileData(player)
	if not profile then
		--print("no profile found to perform action.")
		return
	end

	profile.prisms += amount
end

local function DeductPrisms(player: Player, amount: number)
	local profile = FetchProfileData(player)
	if not profile then
		--print("no profile found to perform action.")
		return
	end

	profile.prisms -= amount
end

local function AddCards(player: Player, name: string, amount: number)
	local profile = FetchProfileData(player)
	if not profile then
		--print("no profile found to perform action.")
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
		--print("no profile found to perform action.")
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
		--print("no profile found to perform action.")
		return
	end

	future.Try(table.insert, profile.quests, quest)
end

print("GameAnalytics is enabled.")

local gameAnalyticsConfig = {
	enableInfoLog = false,
	enableVerboseLog = false,
	availableResourceCurrencies = { "Prisms" },
	build = "0.3.0",
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

Cmdr:RegisterDefaultCommands()
Cmdr:RegisterCommandsIn(ReplicatedStorage.Commands)
Cmdr:RegisterHooksIn(ReplicatedStorage.Hooks)

-- selene:allow(mixed_table)
GameAnalytics:initialize(gameAnalyticsConfig)
GameAnalytics:configureAvailableResourceItemTypes(resourceItemTypes)
-- GameAnalytics:initServer(gameAnalyticsConfig.gameKey, gameAnalyticsConfig.secretKey)

-- TODO) add the products

local ServerAsset = assets.Server:Clone()
ServerAsset.Parent = game.Workspace

local function enterMatch(player: Player)
	--print("player entered match")

	if not player then
		return { success = false, message = "Invalid player" }
	end

	-- Determine if player is part of a party
	local pty = party:GetPartyForPlayer(player.UserId)

	if pty then
		-- only leader can start matchmaking for a party
		if pty.leader_id ~= player.UserId then
			local msg = "Only the party leader can start matchmaking."

			Packet.SendNotification.sendTo({ message = msg }, player)

			return { success = false, message = msg }
		end

		-- TODO: Implement or use the correct party method to set searching state
		-- done!
		matchmaker:JoinQueueForParty(pty)

		Packet.SendNotification.sendTo({ message = "Party joined matchmaking queue", duration = 5 }, player)
		return { success = true, message = "Party queued" }
	else
		-- solo player
		local ok = matchmaker:JoinQueueForPlayer(player)

		if ok then
			Packet.SendNotification.sendTo({ message = "Joined matchmaking queue", duration = 5 }, player)

			return { success = true, message = "Player queued" }
		else
			return { success = false, message = "Failed to join matchmaking queue." }
		end
	end
end

local function cancelMatch(player: Player)
	--print("cancel match")

	if not player then
		return { success = false, message = "Invalid player" }
	end

	local pty = party:GetPartyForPlayer(player.UserId)

	if pty then
		if pty.leader_id ~= player.UserId then
			local msg = "Only the party leader can cancel matchmaking for the party."

			Packet.SendNotification.sendTo({ message = msg }, player)

			return { success = false, message = msg }
		end

		-- TODO: Implement or use the correct party method to stop searching state
		matchmaker:LeaveQueueForParty(pty)

		Packet.SendNotification.sendTo({ message = "Party left matchmaking queue", duration = 5 }, player)

		return { success = true, message = "Party left queue" }
	else
		local ok = matchmaker:LeaveQueueForPlayer(player)

		if ok then
			Packet.SendNotification.sendTo({ message = "Left matchmaking queue", duration = 5 }, player)

			return { success = true, message = "Player left queue" }
		else
			return { success = false, message = "Failed to leave player queue." }
		end
	end
end

local function onPlayerAdded(player: Player)
	GameAnalytics:PlayerJoined(player)
	future.new(GameAnalytics.PlayerJoined, GameAnalytics, player)

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
	local profile = loadProfile(player)

	if profile then
		orion.new(player, profile)
	end
end

-- just in case the players have joined the server before the script loaded
for i, player in ipairs(Players:GetPlayers()) do
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
		warn("couldn't save in time for " .. player.Name)
	end

	task.defer(player.Destroy, player)
end

local function purchaseCard(player: Player, card_name: string)
	-- TODO)  attempt to index nil with 'Price'

	if not card_name then
		warn("no card name provided to buy: ", card_name)

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

	-- get the Item in the registered Items module
	local i = nil
	for j, item in ipairs(Items) do
		if item.Name == card_name then
			i = j
		end
	end

	if not i then
		warn("couldnt index Items table for [card_name]: ", card_name)

		return
	end

	local price = Items[i].Price

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
		warn("no card name provided to sell: ", card_name)

		return
	end

	local profile = FetchProfileData(player)

	if not profile then
		return
	end

	local ok, card = future
		.Try(function()
			return profile.cards[card_name] :: number
		end)
		:Unwrap()

	if not ok or card <= 0 then
		-- you ain't got nun to sell boi.

		warn("No cards to sell for player: " .. player.Name)
		return
	end

	-- get the Item in the registered Items module
	local i = nil
	for j, item in ipairs(Items) do
		if item.Name == card_name then
			i = j
		end
	end

	if not i then
		warn("couldnt index Items table for [card_name]: ", card_name)

		return
	end

	-- calculate sell price (usually half of buy price)
	local sellPrice = math.floor(Items[i].Price * 0.5)

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
		--warn("failed to index table for profile.", player)

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

local function startLightingCycle()
	-- how long, in minutes, a day ingame lasts
	local day_length = 24

	local cycle_time = day_length * 60
	local minutes_in_a_day = 24 * 60

	local start_time = tick() - (Lighting:GetMinutesAfterMidnight() / minutes_in_a_day) * cycle_time
	local end_time = start_time + cycle_time

	local time_ratio = minutes_in_a_day / cycle_time

	if day_length <= 0 then
		day_length = 1
	end

	RunService.Heartbeat:Connect(function()
		local current_time = tick()

		if current_time > end_time then
			start_time = end_time
			end_time = start_time + cycle_time
		end

		Lighting:SetMinutesAfterMidnight((current_time - start_time) * time_ratio)
	end)
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

-- Skill purchases
Packet.BuySkill.listen(function(data, player: Player)
	local skill_name = data.skill_name
	local profile = FetchProfileData(player)
	if not profile then
		Packet.SendNotification.sendTo({ message = "Profile not found" }, player)
		return
	end

	local skill_info
	for _, s in ipairs(skill_tree) do
		if s.name == skill_name then
			skill_info = s
			break
		end
	end

	if not skill_info then
		Packet.SendNotification.sendTo({ message = "Skill not found" }, player)
		return
	end

	profile.skills = profile.skills or {}
	if profile.skills[skill_name] then
		Packet.SendNotification.sendTo({ message = "Skill already unlocked" }, player)
		return
	end

	-- requirements
	for _, req in ipairs(skill_info.requirements or {}) do
		if not profile.skills[req] then
			Packet.SendNotification.sendTo({ message = "Requirements not met" }, player)
			return
		end
	end

	if profile.affinity < skill_info.cost then
		Packet.SendNotification.sendTo({ message = "Not enough Affinity" }, player)
		return
	end

	profile.affinity -= skill_info.cost
	profile.skills[skill_name] = true

	SaveProfileData(player)

	Packet.SkillPurchased.sendTo({ skill_name = skill_name, remaining_affinity = profile.affinity }, player)
	Packet.SendNotification.sendTo({ message = "Skill unlocked: " .. skill_name }, player)
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

-- Matchmaking remotes
MatchmakingRemotes.JoinQueue.OnServerInvoke = function(player: Player, data: {}?)
	-- data can contain details in the future
	local result = enterMatch(player)
	-- normalize return
	return result or { success = true }
end

MatchmakingRemotes.LeaveQueue.OnServerInvoke = function(player: Player, data: {}?)
	local result = cancelMatch(player)

	return result or { success = true }
end

MatchmakingRemotes.RequestQueueInfo.OnServerInvoke = function(player: Player)
	return matchmaker:GetQueueInfo()
end

MatchmakingRemotes.GetMyQueueStatus.OnServerInvoke = function(player: Player)
	local info = matchmaker:GetQueueInfo()

	for _, p in ipairs(info.players) do
		if p.userId == player.UserId then
			return { queued = true, kind = "player" }
		end
	end

	for _, pr in ipairs(info.parties) do
		if pr.leader == player.UserId then
			return { queued = true, kind = "party", party_id = pr.party_id }
		end
	end

	return { queued = false }
end
Packet.SellCard.listen(function(data, player: Player)
	local card_name = data.card_name

	sellCards(player, card_name)
end)
Packet.SetNetworkOwner.listen(function(data: { object: Instance, player: Instance? })
	setNetworkOwner(data.player, data.object)
end)
PartyRemotes.Create.OnServerInvoke = function(player: Player, settings: { [string]: any }?)
	local pty = party.new(player.UserId)

	if pty and settings then
		local new_settings = {}

		new_settings.mode = settings.mode or pty.settings.mode
		new_settings.modifiers = settings.modifiers or pty.settings.modifiers
		new_settings.allow_spectators = if settings.allow_spectators ~= nil
			then settings.allow_spectators
			else pty.settings.allow_spectators
		new_settings.friends_only = if settings.friends_only ~= nil
			then settings.friends_only
			else pty.settings.friends_only

		pty:SetSettings(new_settings)
	end

	Packet.SendNotification.sendTo({ message = "Party created." }, player)
	return { success = true, party_id = pty and pty.party_id or nil }
end
PartyRemotes.Delete.OnServerInvoke = function(player: Player, data: { party_id: string })
	local party_obj = party:GetPartyById(data and data.party_id or "")

	if party_obj then
		for i, member_id in ipairs(party_obj.members) do
			if member_id == player.UserId then
				if party_obj.leader_id == player.UserId then
					party:RemovePartyById(party_obj.party_id)
					-- we added this function because `party_obj:Destroy()` throws an error

					Packet.SendNotification.sendTo({ message = "Party disbanded." }, player)

					return true
				end
				break
			end
		end
	end

	return false
end
PartyRemotes.Join.OnServerInvoke = function(player: Player, data: { party_id: string })
	local party_obj = party:GetPartyById(data and data.party_id or "")

	if party_obj then
		local success = party_obj:AddMember(player.UserId)

		if success then
			Packet.SendNotification.sendTo({ message = "Joined party successfully!" }, player)
		else
			Packet.SendNotification.sendTo({ message = "Failed to join party." }, player)
		end

		return success
	end

	return false
end
PartyRemotes.Leave.OnServerInvoke = function(player: Player, data: { party_id: string })
	local party_obj = party:GetPartyById(data and data.party_id or "")

	if party_obj then
		for i, member_id in ipairs(party_obj.members) do
			if member_id == player.UserId then
				party_obj:RemoveMember(player.UserId)

				return true
			end
		end
	end

	return false
end
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
	--print("is ok: ", ok, result)

	--print(`Player {player.Name} blew {data.amount} fireworks at position {tostring(data.position)}`)
end)

ReplicatedStorage.Events.GetProfile.OnServerInvoke = getProfile

startLightingCycle()

-- TODO) add player saving options
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
windshake:Init({
	MatchWorkspaceWind = true,
})

print("The server completed execution.")
