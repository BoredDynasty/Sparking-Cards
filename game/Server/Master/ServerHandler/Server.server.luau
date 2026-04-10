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
local ServerStorage = game:GetService("ServerStorage")

local Cmdr = require(ReplicatedStorage.Packages:WaitForChild("cmdr"))
local Cryo = require(ReplicatedStorage.Combat.framework.attacks.Cryo)
local Fireworks = require(ReplicatedStorage.Modules.Fireworks)
local GameAnalytics = require(ReplicatedStorage.Packages["gameanalytics-sdk"])
local Items = require(ReplicatedStorage.Market.Items)
local Packet = require(ReplicatedStorage.Packet)
local ProfileStore = require(ReplicatedStorage.Packages.profilestore)
local Pyro = require(ReplicatedStorage.Combat.framework.attacks.Pyro)
local audio = require(ReplicatedStorage.Modules.audio)
local batch = require(ReplicatedStorage.Utility.batch)
local beam = require(ReplicatedStorage.Combat.framework.gameplay.beam)
local bufferencoder = require(ReplicatedStorage.Packages.bufferencoder)
local combo = require(ReplicatedStorage.Combat.framework.utils.combo)
local future = require(ReplicatedStorage.Packages.future)
local grip = require(ReplicatedStorage.Combat.framework.utils.grip)
local ground_crack = require(ReplicatedStorage.Combat.framework.effects["ground-crack"])
local log_analytics = require(ReplicatedStorage.Utility["log-analytics"])
local lucide = require(ReplicatedStorage.Packages.lucide)
local matchmaker = require(ReplicatedStorage.Modules.matchmaker)
local messagepack = require(ReplicatedStorage.Modules.Serialization.messagepack)
local observer = require(ReplicatedStorage.Utility.observer)
local pages = require(ReplicatedStorage.Utility.pages)
local party = require(ReplicatedStorage.Modules.party)
local product_manager = require(ServerStorage.modules.Products["product-manager"])
local profilestore = require(ReplicatedStorage.Packages.profilestore)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local quest = require(ServerStorage.modules.quest)
local random = require(ReplicatedStorage.Utility.random)
local retryer = require(ReplicatedStorage.Utility.retryer)
local safeteleport = require(ReplicatedStorage.Modules.safeteleport)
local settings_schema = require(ReplicatedStorage.Structures["settings-schema"])
local skill_chart = require(ReplicatedStorage.Structures["skill-chart"])
local spr = require(ReplicatedStorage.Modules.spr)
local sword = require(ReplicatedStorage.Combat["combat-styles"].sword)
local tablekit = require(ReplicatedStorage.Packages.tablekit)
local train = require(ServerStorage.modules.train)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

local assets = ReplicatedStorage.Assets

local Events = ReplicatedStorage:WaitForChild("Events")
local MatchmakingRemotes = Events:WaitForChild("Matchmaking")
local PartyRemotes = Events:WaitForChild("Party")

type PlayerData = {
	player: Player,
	damage_multiplier: number,
	style: typemarshaller.StyleModule,
	card_name: string,
}

local combat_data = {} :: { PlayerData }

local gameAnalyticsConfig = {
	enableInfoLog = false,
	enableVerboseLog = false,
	availableResourceCurrencies = { "Affinity", "Prisms" },
	build = "0.4.0",
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
GameAnalytics:initialize(gameAnalyticsConfig :: any)
GameAnalytics:configureAvailableResourceItemTypes(resourceItemTypes)

-- change this if i want data to save in studio
--[[
if RunService:IsStudio() then
	player_related = player_related.Mock
end
--]]
local profiles = {}
local profile_key = "playerdata"
local player_related = profilestore.New(profile_key, profilestructure)
local pending_setting_saves = {} :: { [Player]: thread }

local function loadProfile(player: Player)
	local profile = player_related:StartSessionAsync(`player_{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	print("profile active: ", profile:IsActive())

	if profile then
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		profile.OnSessionEnd:Connect(function()
			profiles[player] = nil

			print(
				`Profile session has ended ({profile.Key}) - Profile.Data will no longer be saved to the DataStore`
			)
			print("Session Locked for: ", player.Name)
			player:Kick("Session Locked, rejoin")
		end)

		print("Created profile")

		if player:FindFirstAncestorOfClass("Players") then
			profiles[player] = profile

			profile.Data.last_login = DateTime.now().UnixTimestampMillis
			profile.Data.name = player.Name -- just for me to see with my datastore editor.

			profile:Reconcile()
			profile:Save()

			print("Created, reconciled and saved profile!")
		else
			profile:EndSession()

			warn("Data not loaded for " .. player.DisplayName .. ", session ended.")
		end
	else
		print("The Roblox Servers are on fire.")
	end

	return profile
end

local function FetchProfileData(player: Player): typemarshaller.ProfileData?
	local profile = profiles[player] :: typemarshaller.Profile?

	if not profile then
		if not RunService:IsStudio() then
			-- i really need a break from seeing ts.

			Packet.SendNotification.sendTo({
				message = "Couldn't get data",
				duration = 1.5,
			}, player)

			local list = tablekit.ToString(profiles :: any)

			warn("Couldn't fetch profile from table: ", list)
		end

		return nil
	end

	return profile.Data
end

local function SaveProfileData(player: Player)
	local profile = profiles[player] -- we need the full table
	if not profile then
		warn("Cannot save profile; couldn't find one.")

		return
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

local function AddPrisms(
	player: Player,
	amount: number,
	transaction_type: Enum.AnalyticsEconomyTransactionType,
	item_name: string?
)
	local profile = FetchProfileData(player)
	if not profile then
		--print("no profile found to perform action.")
		return
	end

	local ending_balance = math.clamp(profile.prisms + amount, 0, math.huge)

	log_analytics.economy(player, {
		amount = amount,
		flow_type = Enum.AnalyticsEconomyFlowType.Source,
		currency_type = "Prisms",
		ending_balance = ending_balance,
		transaction_type = transaction_type,
		item_sku = item_name,
	})

	profile.prisms += amount
end

local function DeductPrisms(
	player: Player,
	amount: number,
	transaction_type: Enum.AnalyticsEconomyTransactionType,
	item_name: string?
)
	local profile = FetchProfileData(player)
	if not profile then
		--print("no profile found to perform action.")
		return
	end

	local ending_balance = math.clamp(profile.prisms - amount, 0, math.huge)

	log_analytics.economy(player, {
		amount = amount,
		flow_type = Enum.AnalyticsEconomyFlowType.Sink,
		currency_type = "Prisms",
		ending_balance = ending_balance,
		transaction_type = transaction_type,
		item_sku = item_name,
	})

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

local function AddExperience(player: Player, amount: number, reason: string?)
	local profile = FetchProfileData(player)
	if not profile then
		--print("no profile found to perform action.")
		return
	end

	Packet.SendNotification.sendTo({
		message = `Gained {amount} EXP ` .. (reason and ` ({reason})` or ""),
		duration = 2,
	}, player)

	Events.SendExpRewardClient:InvokeClient(player, amount) -- the client might wanna do a cool effect yknow

	local formatted_reason = ""
	-- e.g "Quest Completed" to "Quest_Completed" for better analytics formatting
	if reason then
		formatted_reason = string.gsub(reason, "%s+", "_")
	else
		formatted_reason = "Unknown"
	end

	-- do some analytics
	log_analytics.economy(player, {
		transaction_type = Enum.AnalyticsEconomyTransactionType.Gameplay,
		amount = amount,
		ending_balance = profile.experience + amount,
		currency_type = "Experience",
		item_sku = formatted_reason,
	})

	-- add it all up
	profile.experience += amount
end

local function InsertQuestData(player: Player, quest: typemarshaller.Quest)
	local profile = FetchProfileData(player)
	if not profile then
		--print("no profile found to perform action.")
		return
	end

	-- this is really just an array push but whatever.
	-- if there is a copy of the quest in the profile already, update it instead of inserting a new one.
	local updated = false

	for i, q in ipairs(profile.quests) do
		if q.name == quest.name then
			profile.quests[i] = quest
			updated = true
			break
		end
	end

	if not updated then
		table.insert(profile.quests, quest)
	end
end

local function registerCombatPlayer(player: Player)
	local style = sword.new(player, "Katana") -- change this later
	local combo_info = combo.new(3)

	style:Equip()
	style:CreateTrail()

	print("grip data: ", style:GetGripData())

	local data = {
		player = player,
		damage_multiplier = 1.00,
		style = style,
		combo_info = combo_info,
		card_name = "Pyro",
	} :: PlayerData

	table.insert(combat_data, data)

	print("registered combat player")
end

local function indexCombatPlayer(player: Player): PlayerData?
	for i, data in ipairs(combat_data) do
		if (player.UserId == data.player.UserId) or player.Name == data.player.Name then
			return data
		end
	end

	return nil
end

local function indexCombatModule(name: string): typemarshaller.AttackModule
	local modules = {
		pyro = Pyro,
		cryo = Cryo,
	}

	return modules[string.lower(name)] -- non-case-sensitive
end

local function executeAttack(player: Player, attack_type: typemarshaller.AttackType)
	local data = indexCombatPlayer(player)
	if not data then
		warn("no combat data")

		return
	end

	local profile = FetchProfileData(player)
	if not profile then
		warn("couldnt fetch profile for attack execution")
		return
	end

	local equipped_card = profile.equipped_card

	local module = indexCombatModule(equipped_card)
	if not module then
		warn("couldnt index module: ", module, equipped_card)
		return
	end

	local attack_func = module.moveset[attack_type]
	if attack_func then
		print("executing attack")
		return attack_func(player)
	else
		warn(`Attack function for type '{attack_type}' not found in module '{equipped_card}'`)
		return
	end
end

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

local function cancelMatch(player: Player, suppress_notification: boolean?)
	--print("cancel match")

	if not player then
		return { success = false, message = "Invalid player" }
	end

	local pty = party:GetPartyForPlayer(player.UserId)

	if pty then
		if pty.leader_id ~= player.UserId then
			local msg = "Only the party leader can cancel matchmaking for the party."

			if not suppress_notification then
				Packet.SendNotification.sendTo({ message = msg }, player)
			end

			return { success = false, message = msg }
		end

		-- TODO: Implement or use the correct party method to stop searching state
		matchmaker:LeaveQueueForParty(pty)

		if not suppress_notification then
			Packet.SendNotification.sendTo({ message = "Party left matchmaking queue", duration = 5 }, player)
		end

		return { success = true, message = "Party left queue" }
	else
		local ok = matchmaker:LeaveQueueForPlayer(player)

		if ok then
			if not suppress_notification then
				Packet.SendNotification.sendTo({ message = "Left matchmaking queue", duration = 5 }, player)
			end

			return { success = true, message = "Player left queue" }
		else
			return { success = true, message = "Player not in queue" }
		end
	end
end

local function onPlayerAdded(player: Player)
	loadProfile(player)
	GameAnalytics:PlayerJoined(player)

	log_analytics.onboarding_funnel_step(player, {
		step_name = "Joined",
		step = 1,
	})

	registerCombatPlayer(player)
end

local function onPlayerRemoving(player: Player)
	GameAnalytics:PlayerRemoved(player)

	local pending_setting_save = pending_setting_saves[player]
	if pending_setting_save then
		task.cancel(pending_setting_save)
		pending_setting_saves[player] = nil
	end

	local profile = profiles[player]

	if profile then
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

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerRemoving(player)
	end
end)

local function purchaseCard(player: Player, card_name: string)
	-- TODO)  attempt to index nil with 'Price'

	if not card_name then
		warn("no card name provided to buy: ", card_name)

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

	local price = Items[i].Price

	local prisms = GetPrisms(player)

	if prisms >= price then
		AddCards(player, card_name, 1)

		local deduct_amount = math.ceil(price) or 1

		DeductPrisms(player, deduct_amount, Enum.AnalyticsEconomyTransactionType.Shop, card_name)

		local event_parameters = {
			flowType = GameAnalytics.EGAResourceFlowType.Sink,
			currency = "Prisms",
			amount = 1,
			itemType = "Weapons",
			itemId = card_name .. " Card",
		}

		GameAnalytics:addResourceEvent(player.UserId, event_parameters)

		SaveProfileData(player)

		Packet.SendNotification.sendTo({
			message = `You purchased a {card_name} Card.`,
		}, player)

		log_analytics.onboarding_funnel_step(player, {
			step_name = "First Purchase",
			step = 2,
		})
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

	local character = player.Character
	if character and not area then
		local primary_part = character.PrimaryPart
		if primary_part then
			area = primary_part.Position
		end
	elseif not character and not area then
		area = Vector3.one
	end

	task.spawn(function()
		player:RequestStreamAroundAsync(area)
	end)
end

local function payPrisms(amount: number, username: string)
	local player = Players:FindFirstChild(username) :: Player
	assert(player, "Couldn't fetch player by name: " .. username)

	AddPrisms(player, amount, Enum.AnalyticsEconomyTransactionType.Gameplay)

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
	AddPrisms(player, sellPrice, Enum.AnalyticsEconomyTransactionType.Shop, card_name)
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

local overideClocktime = false

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
		if overideClocktime then
			start_time = tick() - (Lighting:GetMinutesAfterMidnight() / minutes_in_a_day) * cycle_time

			return
		end

		local current_time = tick()

		if current_time > end_time then
			start_time = end_time
			end_time = start_time + cycle_time
		end

		Lighting:SetMinutesAfterMidnight((current_time - start_time) * time_ratio)
	end)
end

local function insertShopBookmark(player: Player, card_name: string)
	if not card_name then
		warn("no card to bookmark")

		return
	end

	local profile = FetchProfileData(player)
	if not profile then
		return
	end

	local i = table.find(profile.bookmarked_shop_items, card_name)
	if i then
		table.remove(profile.bookmarked_shop_items, i)
	else
		table.insert(profile.bookmarked_shop_items, card_name)
	end

	log_analytics.onboarding_funnel_step(player, {
		step_name = "Wishlist",
		step = 3,
	})
end

local function sanitizeSettingValue(
	definition: typemarshaller.SettingDefinition,
	value: typemarshaller.SettingValue
): typemarshaller.SettingValue?
	local choices = definition.choices

	local function value_in_choices(candidate: typemarshaller.SettingValue): boolean
		if choices == nil then
			return true
		end

		for _, choice in ipairs(choices) do
			if choice.value == candidate then
				return true
			end
		end

		return false
	end

	if definition.value_type == "boolean" then
		if type(value) ~= "boolean" then
			return nil
		end

		if not value_in_choices(value) then
			return nil
		end

		return value
	end

	if definition.value_type == "string" then
		if type(value) ~= "string" then
			return nil
		end

		if not value_in_choices(value) then
			return nil
		end

		return value
	end

	if type(value) ~= "number" then
		return nil
	end

	if value ~= value then
		return nil
	end

	local min_value = definition.min
	local max_value = definition.max

	if min_value ~= nil and max_value ~= nil and max_value < min_value then
		min_value, max_value = max_value, min_value
	end

	if min_value ~= nil then
		value = math.max(value, min_value)
	end

	if max_value ~= nil then
		value = math.min(value, max_value)
	end

	local step = definition.step
	if step ~= nil and step > 0 then
		value = math.round(value / step) * step
	end

	if min_value ~= nil then
		value = math.max(value, min_value)
	end

	if max_value ~= nil then
		value = math.min(value, max_value)
	end

	if not value_in_choices(value) then
		return nil
	end

	return value
end

local function scheduleSettingSave(player: Player)
	local existing = pending_setting_saves[player]
	if existing then
		task.cancel(existing)
	end

	pending_setting_saves[player] = task.delay(2, function()
		pending_setting_saves[player] = nil
		SaveProfileData(player)
	end)
end

local function saveSetting(player: Player, identifier: string, value: typemarshaller.SettingValue): boolean
	if type(identifier) ~= "string" or identifier == "" then
		return false
	end

	local profile = FetchProfileData(player)
	if not profile then
		return false
	end

	local definition = settings_schema.map[identifier] :: typemarshaller.SettingDefinition?
	if definition == nil then
		return false
	end

	local sanitized = sanitizeSettingValue(definition, value)
	if sanitized == nil then
		return false
	end

	profile.options[identifier] = sanitized
	scheduleSettingSave(player)

	log_analytics.onboarding_funnel_step(player, {
		step_name = "Personalization",
		step = 4,
	})

	return true
end

local function saveQuest(player: Player, bfr: buffer)
	local quest = bufferencoder.read(bfr) :: typemarshaller.Quest
	if not quest then
		return false
	end

	local profile = FetchProfileData(player)
	if not profile then
		return false
	end

	InsertQuestData(player, quest)
	SaveProfileData(player)

	--print("saved quest data for player: ", player.Name, " quest: ", quest.name)

	return true
end

local function initializeAudio()
	--print("init audio")

	task.spawn(function()
		audio:AddSFX("wood-block-1", 9120917813)
		audio:AddSFX("wood-block-2", 9120917604)
		audio:AddSFX("wood-block-3", 9120917605)
		audio:AddSFX("wood-block-4", 9120917794)
		audio:AddSFX("wood-block-5", 9120917978)

		audio:AddSFX("continue", 92647604633081)

		audio:AddSFX("click", 90092163763441)
		audio:AddSFX("hover", 119879668444252)
		audio:AddSFX("leave", 85897203168160)
		audio:AddSFX("success", 76288726968959)

		audio:AddSFX("ground-crack", 139091089156450)

		audio:AddSFX("ice-blast", 77805087245612)

		audio:AddMusic("train_brakes", 185857550)
		audio:AddMusic("train_clattering", 113519632244308, {
			looped = true,
		})
		audio:AddSFX("train_ambient", 133261320841417, {
			looped = true,
		})
		audio:AddSFX("train_starting", 107540416784700)
		audio:AddSFX("train_door_open", 98411275767590)
	end)
end

local match_waiting_time = {}
local player_match_waiting_time = {}

local function logMatchWaitingTime(player: Player, seconds: number)
	local max_indexes = 100
	if #match_waiting_time > max_indexes then
		table.remove(match_waiting_time, 1)
	end

	table.insert(match_waiting_time, seconds)

	local mean = 0

	-- find the mean
	local sum = 0
	for j, t in ipairs(match_waiting_time) do
		sum += t
	end

	mean = sum / #match_waiting_time

	--print(`Server mean matchmaking waiting time: {mean} seconds ({#match_waiting_time} samples)`)

	player_match_waiting_time[player] = mean

	-- log to analytics
	log_analytics.custom(player, {
		name = "Match Waiting Time",
		value = mean,
		custom_fields = {
			sample_size = tostring(#match_waiting_time),
			server_mean_waiting_time = tostring(mean),
		},
		-- no item_sku or transaction type since this isn't an economy event
	})
end

local function getGamepasses(player: Player)
	local gamepasses = product_manager:FetchAllFromModule()

	if gamepasses then
		local owned = {}

		for i, gamepass in ipairs(gamepasses) do
			local player_owns = MarketplaceService:PlayerOwnsAssetAsync(player, gamepass.Id)
			if player_owns then
				table.insert(owned, gamepass)
			end
		end

		return owned
	else
		warn("Failed to get gamepasses for player: " .. player.Name)
		return {}
	end
end

local function getAllGamepasses()
	return product_manager:FetchAll()
end

Packet.SetTime.listen(function(data, player: Player?)
	overideClocktime = true

	setClock(data.clock_time)

	task.delay(1, function()
		overideClocktime = false
	end)
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

	local skill_info: typemarshaller.Skill
	for _, s in ipairs(skill_chart) do
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
	if table.find(profile.skills, skill_name) then
		Packet.SendNotification.sendTo({ message = "Skill already unlocked" }, player)
		return
	end

	-- requirements
	for _, req in ipairs(skill_info.requirements or {}) do
		if not table.find(profile.skills, req) then
			Packet.SendNotification.sendTo({ message = "Requirements not met" }, player)
			return
		end
	end

	if profile.affinity < skill_info.cost then
		Packet.SendNotification.sendTo({ message = "Not enough Affinity" }, player)
		return
	end

	profile.affinity -= skill_info.cost
	table.insert(profile.skills, skill_name)

	SaveProfileData(player)

	Packet.SendNotification.sendTo({ message = "Skill unlocked: " .. skill_name }, player)

	log_analytics.onboarding_funnel_step(player, {
		step_name = "First Skill",
		step = 5,
	})
end)

Packet.SellSkill.listen(function(data, player: Player)
	local skill_name = data.skill_name
	local profile = FetchProfileData(player)
	if not profile then
		Packet.SendNotification.sendTo({ message = "Profile not found" }, player)
		return
	end

	local skill_info
	for _, s in ipairs(skill_chart) do
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
	local index = table.find(profile.skills, skill_name)
	if not index then
		Packet.SendNotification.sendTo({ message = "Skill not unlocked" }, player)
		return
	end

	-- Refund half the cost
	local refund = math.floor(skill_info.cost / 2)
	profile.affinity += refund
	table.remove(profile.skills, index)

	SaveProfileData(player)

	Packet.SendNotification.sendTo(
		{ message = "Skill sold: " .. skill_name .. " (Refunded " .. refund .. " Affinity)" },
		player
	)
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
	cancelMatch(player, true)

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

		party:SetSettingsById(pty.party_id, new_settings)
		--[[
		-- deprecated, use the above function instead
		pty:SetSettings(new_settings)
		--]]
	end

	Packet.SendNotification.sendTo({ message = "Party created." }, player)

	log_analytics.onboarding_funnel_step(player, {
		step_name = "Create a Party",
		step = 6,
	})

	return { success = true, party_id = pty and pty.party_id or nil }
end
PartyRemotes.Delete.OnServerInvoke = function(player: Player, data: { party_id: string })
	local party_obj = party:GetPartyById(data and data.party_id or "")

	if party_obj then
		for i, member_id in ipairs(party_obj.members) do
			if member_id == player.UserId then
				if party_obj.leader_id == player.UserId then
					cancelMatch(player, true)

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
		print("got party obj")

		cancelMatch(player, true)

		local ok = party:AddPlayerToPartyById(data.party_id, player.UserId)

		if ok then
			Packet.SendNotification.sendTo({ message = "Joined party successfully!" }, player)
		else
			Packet.SendNotification.sendTo({ message = "Failed to join party." }, player)
		end

		return ok
	end

	return false
end
PartyRemotes.Leave.OnServerInvoke = function(player: Player, data: { party_id: string })
	local party_obj = party:GetPartyById(data and data.party_id or "")

	if party_obj then
		for i, member_id in ipairs(party_obj.members) do
			if member_id == player.UserId then
				cancelMatch(player, true)

				party:RemovePlayerFromPartyById(data.party_id, player.UserId)

				return true
			end
		end
	end

	return false
end

ReplicatedStorage.Events.GetProfile.OnServerInvoke = getProfile
ReplicatedStorage.Events.GetProfileServer.OnInvoke = FetchProfileData

MarketplaceService.ProcessReceipt = function(receipt)
	product_manager:ProcessReceipt(receipt)
end

Events.GetGamepasses.OnServerInvoke = getGamepasses
Events.FetchAllProducts.OnServerInvoke = getAllGamepasses
Events.ReportQuestProgressServer.OnInvoke = saveQuest
Events.SendExpRewardServer.OnInvoke = AddExperience
Events.BookmarkShopCard.OnServerInvoke = insertShopBookmark
local save_setting_remote = Events:FindFirstChild("SaveSetting")
if save_setting_remote and save_setting_remote:IsA("RemoteFunction") then
	save_setting_remote.OnServerInvoke = saveSetting
else
	warn("Events.SaveSetting remote is missing or invalid; settings will not persist.")
end
Events.ExecuteAttack.OnServerInvoke = function(player: Player, ...)
	return executeAttack(player, ...)
end
Events.GetPlayerCombatData.OnInvoke = indexCombatPlayer
Events.SendMatchmakingTime.OnServerEvent:Connect(function(player: Player, seconds: number)
	logMatchWaitingTime(player, seconds)
end)
Events.FireBeam.OnServerEvent:Connect(function(player, params)
	print("firing beam")
	beam.fire(params)
	print("beam fired!")
end)
Events.FireGroundCrack.OnServerEvent:Connect(function(player, type: keyof<typeof(ground_crack)>, ...)
	print("firing ground crack")
	ground_crack[type](...)
	print("ground crack fired!")
end)
Events.SetMusicVolume.OnServerEvent:Connect(function(player, volume)
	-- send it right back!
	Events.SetMusicVolume:FireClient(player, volume)
end)
Events.ToggleGUISound.OnServerEvent:Connect(function(player, volume)
	Events.ToggleGUISound:FireClient(player, volume)
end)
Events.ToggleMusic.OnServerEvent:Connect(function(player, is_on)
	Events.ToggleMusic:FireClient(player, is_on)
end)
initializeAudio()
startLightingCycle()
grip.auto_update()
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

print("The server completed execution.")
