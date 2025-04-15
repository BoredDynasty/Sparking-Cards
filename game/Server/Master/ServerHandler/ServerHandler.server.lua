--!nonstrict

-- ServerHandler.server.lua

print(script.Name)

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LogService = game:GetService("LogService")
local RunService = game:GetService("RunService")

local ProfileStore = require(ReplicatedStorage.Packages.profilestore)
local SafeTeleporter = require(ReplicatedStorage.Modules.SafeTeleporter)
local MatchHandler = require(ReplicatedStorage.Modules.MatchHandler)
local Red = require(ReplicatedStorage.Packages.Red)
local GameAnalytics = require(ReplicatedStorage.Packages["gameanalytics-sdk"])
-- local ActorGroup = require(ReplicatedStorage.Utility.ActorGroup)

local assets = ReplicatedStorage:FindFirstChild("Assets") :: Folder

local productFunctions = {} :: { (receipt: (any | string)?, player: Player) -> boolean }

print("Economic Analytics are enabled.")
print("Custom Analytics are enabled.")
print("Developer Notes gets updated every 24h.")

local gameAnalyticsConfig = {
	enableInfoLog = false,
	enableVerboseLog = false,
	availableResourceCurrencies = { "Cards" },
	build = "0.1.0",
	availableGamepasses = { "Extra Cards" },
	automaticSendBusinessEvents = true,
	reportErrors = true,
	useCustomId = true, -- Corrected key name
	gameKey = "4e689e435634bbfe9892f625af5c51bf",
	secretKey = "1a5289ebbc7daa44accc4d5deb256833263c512a",
}

local serverStartTime = os.clock()

-- selene:allow(mixed_table)
GameAnalytics:initialize(gameAnalyticsConfig)
GameAnalytics:initServer(gameAnalyticsConfig.gameKey, gameAnalyticsConfig.secretKey)

-- This product Id gives the player more cards (cards as in money)
productFunctions[1904591683] = function(receipt: any | string?, player: Player)
	local leaderstats = player:FindFirstChild("leaderstats") :: Folder
	local Cards: IntValue = leaderstats:FindFirstChild("Cards") :: IntValue
	if Cards and player then
		Cards.Value += 50
		local resourceEventParams = {
			flowType = GameAnalytics.EGAResourceFlowType.Source,
			currency = "Cards",
			amount = 50,
			itemType = "Extra Cards",
		}
		print(receipt)
		GameAnalytics:addResourceEvent(player.UserId, resourceEventParams)
		-- Log the purchase in the custom analytics
	end
	return true -- indicate a successful purchase
end

productFunctions[1906572512] = function(receipt: any | string?, player: Player)
	print(`Donated Successfully: {player.Name}.`)

	print(receipt) -- debug
	return true
end

LogService.MessageOut:Connect(function(message: string, messageType: Enum.MessageType)
	task.spawn(function()
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

local function _FastTravel(place: number, players: { Player }, options)
	return SafeTeleporter(place, players, options)
end

local function enterMatch(player: Player)
	MatchHandler.AddPlayerToQueue(player)
end

local function _teleportPartClicked(player: Player, otherPart: BasePart, destination: CFrame)
	if player then -- // check if we have the player
		local clickDetector = otherPart:FindFirstChild("ClickDetector") :: ClickDetector
		clickDetector.MouseClick:Connect(function()
			local character = player.Character :: Model
			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
			if humanoidRootPart then
				humanoidRootPart:PivotTo(destination)
			end
		end)
	end
end

local function _payCards(player: Player, reason: string?, amount: number)
	if not amount then
		amount = 50
	end
	if not reason then
		reason = "Unknown"
	end
	local leaderstats = player:FindFirstChild("leaderstats") :: Folder
	local cardsInteger = leaderstats:FindFirstChild("Cards") :: IntValue
	local resourceEventParams = {
		flowType = GameAnalytics.EGAResourceFlowType.Source,
		currency = "Cards",
		amount = amount,
		itemType = reason,
	}
	GameAnalytics:addResourceEvent(player.UserId, resourceEventParams)
	cardsInteger.Value += amount
	if reason then
		print(reason)
	end
end

local playerStore = ProfileStore.New("player-related", {
	-- Template
	["Cards"] = 0,
	["Level"] = "Bronze I",
	["Experience"] = 0,
	["LastLogin"] = os.time(),
	-- Other
	["options"] = {
		["clockTime"] = 12,
		["description"] = "Destined for awesomeness!",
		["profileBannerLink"] = "rbxassetid://95864343491678",
	},
	["combatBindings"] = {
		["attack"] = "LMB", -- melee
		["special_One"] = "E", -- primary
		["special_Two"] = "Q", -- ultimate
		["special_Three"] = "R", -- any
	},
})

type profileType = { [typeof(playerStore:StartSessionAsync())]: any }
local profiles: profileType = {}

if RunService:IsStudio() then
	playerStore = playerStore.Mock
end

--[[
local LEADERSTATS_TEMPLATE = {
	Cards = { className = "IntValue", default = 0 },
	Rank = { className = "StringValue", default = "Bronze I" },
	Experience = { className = "IntValue", default = 0 },
}
--]]
local function createLeaderstats(player: Player, data: { [string]: any })
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local Cards = Instance.new("IntValue")
	Cards.Name = "Cards"
	Cards.Parent = leaderstats
	Cards.Value = data.Cards

	local Rank = Instance.new("StringValue")
	Rank.Name = "Rank"
	Rank.Parent = leaderstats
	Rank.Value = data.Level

	local EXP = Instance.new("IntValue")
	EXP.Name = "ExperiencePoints"
	EXP.Parent = leaderstats
	EXP.Value = data.Experience

	return leaderstats
end

local function onPlayerAdded(player: Player)
	debug.profilebegin("player_added")

	-- Start profile session with timeout
	local profileSuccess, profile = pcall(function()
		return playerStore:StartSessionAsync(`player:{player.UserId}`, {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})
	end)

	if not profileSuccess or not profile then
		player:Kick("Profile load failed - Please rejoin")
		debug.profileend()
		return
	end
	-- Set up profile
	profile:AddUserId(player.UserId)
	profile:Reconcile()

	-- Handle session end
	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		if player.Parent == Players then
			player:Kick("Session Locked, rejoin")
		end
	end)

	-- Store profile if player still here

	task.spawn(function()
		local character = player.Character or player.CharacterAdded:Wait() :: Model
		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
		if character or rootPart then
			player:RequestStreamAroundAsync(rootPart.Position)
		end
	end)

	-- if player.Parent == Players then
	table.insert(profiles, 1, profile)

	-- Load leaderstats data in parallel
	task.spawn(function()
		local leaderStatInfo = playerStore:GetAsync(`player:{player.UserId}`)
		if leaderStatInfo and leaderStatInfo.Data then
			createLeaderstats(player, leaderStatInfo.Data)
		else
			player:Kick("Roblox Servers on fire. It's best to rejoin.")
		end
	end)

	GameAnalytics:PlayerJoined(player)

	player.Chatted:Connect(function(message: string)
		if message:match("@match") or message:match("@ready") then
			enterMatch(player)
		end
	end)

	-- Optimize character cleanup
	player.CharacterRemoving:Connect(function(char: Model)
		task.delay(1, function() -- Give time for any final processing
			if char and char.Parent then
				char:Destroy()
			end
		end)
	end)
	-- else
	-- profile:EndSession()
	-- end

	debug.profileend()
end

local function onPlayerRemoving(player: Player)
	GameAnalytics:PlayerRemoved(player)
	local profile = profiles[player]
	if profile ~= nil then
		profile:EndSession()
	end
	task.defer(player.Destroy, player)
end

local function _setPlayerExperience(player: Player, exp: number)
	local leaderstats = player:WaitForChild("leaderstats") :: Folder
	local expValue = leaderstats:FindFirstChild("Experience") :: IntValue
	expValue.Value = exp
end

local function _getPlayerInfo(player: Player): any
	local profile = profiles[player]
	local data = nil
	if profile then
		data = profile
	end
	return data
end

local function streamArea(player: Player, area: Vector3)
	task.spawn(function()
		player:RequestStreamAroundAsync(area)
	end)
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
--

local RequestStream = Red.Event(
	"RequestStream",
	(
			function(area: Vector3)
				if not area then
					return
				end
				area = area :: Vector3
				assert(typeof(area) == "Vector3", "The requested to stream area is not a Vector3.")
				return area
			end
		) :: (Vector3) -> any
)
RequestStream:Server():On(streamArea)

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

local serverEndTime = os.clock()
local serverTime = math.round((serverEndTime - serverStartTime) * 10000) / 10000
print("The server completed execution with a time of: " .. tostring(serverTime))
