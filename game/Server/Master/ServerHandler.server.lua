--!nonstrict

-- Master.server.lua

print(string.format(`Server ID [ {game.JobId} ] \nVER. {game.PlaceVersion}`, "%q"))

local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LogService = game:GetService("LogService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local SafeTeleporter = require(ReplicatedStorage.Modules.SafeTeleporter)
local MatchHandler = require(ReplicatedStorage.Modules.MatchHandler)
local GameAnalytics = require(ReplicatedStorage.Modules.GameAnalytics)
local ProfileStore = require(ServerStorage.Modules.ProfileStore)

local FastTravelRE: RemoteEvent = ReplicatedStorage.RemoteEvents.FastTravel
local EnterMatchRE: RemoteEvent = ReplicatedStorage.RemoteEvents.EnterMatch
local DialogRE: RemoteEvent = ReplicatedStorage.RemoteEvents.NewDialogue
local SendAnalytic: RemoteEvent = ReplicatedStorage.RemoteEvents.SendAnalytic
local GetCards: RemoteFunction = ReplicatedStorage.RemoteEvents.GetCards
local SetHeadCFrame: UnreliableRemoteEvent = ReplicatedStorage.RemoteEvents.SetHeadCFrame
local GiveCardsRE = ReplicatedStorage.RemoteEvents.GiveCards
local GetLastLoginRE = ReplicatedStorage.RemoteEvents.GetLastLogin

local productFunctions = {}

print("Economic Analytics are enabled.")
print("Custom Analytics are enabled.")
print("Developer Notes gets updated every 24h.")

local gameAnalyticsConfig = {
	gameKey = "4e689e435634bbfe9892f625af5c51bf",
	secretKey = "1a5289ebbc7daa44accc4d5deb256833263c512a",
}

GameAnalytics:initServer(gameAnalyticsConfig.gameKey, gameAnalyticsConfig.secretKey)
GameAnalytics:initialize({
	useCustomUserId = true,
	automaticSendBusinessEvents = true,
	enableInfoLog = true,
	enableVerboseLog = true,
})

local function automaticDialog(player: Player, dialog: string)
	DialogRE:FireClient(player, dialog)
end

-- This product Id gives the player more cards (cards as in money)
productFunctions[1904591683] = function(receipt: any | string?, player: Player)
	local leaderstats = player:FindFirstChild("leaderstats") :: Folder
	local Cards: IntValue = leaderstats:FindFirstChild("Cards")
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

productFunctions[1906572512] = function(receipt, player)
	print(`Donated Successfully: {player.Name}.`)
	GameAnalytics:setCustomDimension01(player.UserId, tostring(receipt))
	task.delay(2.5, function()
		GameAnalytics:setCustomDimension01(player.UserId, "")
		print("Reset Dimension: 01")
		-- Reset the Dimension01
	end)
	return true
end

LogService.MessageOut:Connect(function(message, messageType)
	if messageType == Enum.MessageType.MessageError or messageType == Enum.MessageType.MessageWarning then
		GameAnalytics:addErrorEvent({
			message = message,
			severity = GameAnalytics.EGAErrorSeverity.Error,
		})
	end
end)

local ServerAsset = ReplicatedStorage.Assets.Server:Clone()
ServerAsset.Parent = game.Workspace

local function processReceipt(receiptInfo)
	local userId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId

	local player = Players:GetPlayerByUserId(userId)
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

local function FastTravel(place: number, players: { Player }, options)
	return SafeTeleporter(place, players, options)
end

local function enterMatch(player: Player)
	MatchHandler.AddPlayerToQueue(player)
end

local function chatted(player, message)
	if string.find(message, "@match") or string.find(message, "@ready") then
		enterMatch(player)
		automaticDialog(player, "There's no turning back!")
	end
end

local profiles = {}

local function onPlayerAdded(player: Player)
	-- Migrate to ProfileStore
	ProfileStore.GetProfileStore("PlayerRelated", {
		-- Template
		["Cards"] = 0,
		["Level"] = "Bronze I",
		["Experience"] = 0,
		["LastLogin"] = os.time(),
		-- Other
		options = {
			clockTime = 12,
		},
		combatBindings = {
			attack = Enum.KeyCode.MouseLeftButton, -- melee
			special_One = Enum.KeyCode.E, -- primary
			special_Two = Enum.KeyCode.Q, -- ultimate
			special_Three = Enum.KeyCode.R, -- any
		},
	})
	local profile = ProfileStore:LoadProfileAsync(`player-{player.UserId}`)

	if profile ~= nil then
		profile:AddUserId(player.UserId) -- GDPR compliance
		profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)
		profile:ListenToRelease(function()
			profiles[player] = nil
			player:Kick() -- The profile could've been loaded on another Roblox server
		end)
		if player:IsDescendantOf(Players) then
			profiles[player] = profile
		else
			profile:Release() -- Player left before the profile loaded
		end
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Parent = player
	leaderstats.Name = "leaderstats"
	--
	local Cards = Instance.new("IntValue")
	Cards.Name = "Cards"
	Cards.Parent = leaderstats
	Cards.Value = 0
	--
	local Rank = Instance.new("StringValue")
	Rank.Name = "Rank"
	Rank.Parent = leaderstats
	Rank.Value = ""

	local EXP = Instance.new("IntValue")
	EXP.Name = "ExperiencePoints"
	EXP.Parent = leaderstats
	EXP.Value = 0

	GameAnalytics:PlayerJoined(player)
	player.Chatted:Connect(function(message)
		chatted(player, message)
	end)
end

local function onPlayerRemoving(player: Player)
	--
	GameAnalytics:PlayerRemoved(player)
	pcall(function()
		task.defer(player:Destroy())
	end)
end

local function teleportPartClicked(player: Player, otherPart: BasePart, destination: Vector3)
	if player then -- // check if we have the player
		player:RequestStreamAroundAsync(destination)
		otherPart:FindFirstChildOfClass("ClickDetector").MouseClick:Connect(function()
			local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
			humanoidRootPart:PivotTo(destination)
		end)
	end
end

local function setupNonPlayableCharacters()
	local npcs = CollectionService:GetTagged("NPC")
	local registeredNPCs = {
		"Claire",
		"Obsidian",
	}
	for _, npc in pairs(npcs) do
		if table.find(registeredNPCs, npc.Name) then
			local humanoid = npc:FindFirstChildOfClass("Humanoid") :: Humanoid
			local configurationFolder = npc:FindFirstChild("NPC_Config") :: Folder
			if configurationFolder then
				local animationsConfiguration =
					configurationFolder:FindFirstChild("Animations") :: Configuration
				local idleAnimationID = animationsConfiguration:GetAttribute("Idle") :: number
				local animator = humanoid:FindFirstChildOfClass("Animator") :: Animator

				-- New animation instance
				local animation = Instance.new("Animation")
				animation.AnimationId = "rbxassetid://" .. idleAnimationID
				local animationTrack = animator:LoadAnimation(animation) :: AnimationTrack
				animationTrack.Looped = true
				animationTrack:Play()
			end
		end
	end
end

local function catchAnalytic(player, topic, param1, customFields)
	AnalyticsService:LogCustomEvent(player, topic, param1, customFields)
	print(`New Analytic: `, topic, param1, customFields)
end

local function setHeadDirection(player: Player, neckCFrame)
	for _, otherPlayer: Player in pairs(Players:GetPlayers()) do
		local otherCharacter = otherPlayer.Character or otherPlayer.CharacterAdded:Wait()
		if otherCharacter.Humanoid.Health > 0 and otherCharacter then
			if
				otherPlayer ~= player
				and (otherCharacter.Head.Position - player.Character.Head.Position).Magnitude < 10
			then
				ReplicatedStorage.RemoteEvents.SetHeadCFrame:FireClient(otherPlayer, player, neckCFrame)
			end
		end
	end
end

local function returnCards(player: Player): number
	local value = player.leaderstats.Cards.Value :: number
	print(`{player.DisplayName} has: {value}`)
	return value
end

local function payCards(player, reason: string)
	player.leaderstats.Cards.Value += 50
	if reason then
		print(reason)
	end
end

local function getLastLogin(player: Player): {}?
	local lastLogin = DataStore.GetStore("Player-Related")
	local lastLoginData = lastLogin:GetAsync(`player:{player.UserId}`)
	return lastLoginData
end

local lastTime = tick()
local fps = 0
local frameTimes = {}

local function calculateFPS(): number
	RunService.Heartbeat:Wait()
	local currentTime = tick()
	local deltaTime = currentTime - lastTime
	lastTime = currentTime

	if deltaTime > 0 then
		fps = 1 / deltaTime
	end

	-- Smoothing FPS calculation
	table.insert(frameTimes, fps)
	if #frameTimes > 30 then -- Keep last 30 frames for average
		table.remove(frameTimes, 1)
	end

	-- Calculate average FPS
	local total = 0
	for _, f in ipairs(frameTimes) do
		total = total + f
	end

	local averageFPS = total / #frameTimes
	return math.floor(averageFPS)
end

local function updateServerInfo()
	task.spawn(function()
		while true do
			task.wait(5)
			local server = ReplicatedStorage.Assets.Server :: Model
			local billboard = server.Top:FindFirstChildOfClass("BillBoardGui") :: BillBoardGui
			local details = billboard.ServerDetails :: TextLabel
			-- Get server frames
			local frames = calculateFPS()
			details.Text = `{frames}<br />—<br />360`
		end
	end)
end

-- Set the callback; this can only be done once by one server-side script
MarketplaceService.ProcessReceipt = processReceipt
updateServerInfo()
--
FastTravelRE.OnServerEvent:Connect(FastTravel)
EnterMatchRE.OnServerEvent:Connect(enterMatch)
SendAnalytic.OnServerEvent:Connect(catchAnalytic)
SetHeadCFrame.OnServerEvent:Connect(setHeadDirection)
GiveCardsRE.OnServerEvent:Connect(payCards)
GetCards.OnServerInvoke = returnCards
GetLastLoginRE.OnServerInvoke = getLastLogin
--
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
