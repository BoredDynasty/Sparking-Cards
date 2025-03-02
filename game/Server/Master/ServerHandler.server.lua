--!nocheck

-- Master.server.lua

print(string.format(`Server ID [ {game.JobId} ] \nVER. {game.PlaceVersion}`, "%q"))

local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService = game:GetService("AnalyticsService")
local LogService = game:GetService("LogService")

local SafeTeleporter = require(ReplicatedStorage.Modules.SafeTeleporter)
local MatchHandler = require(ReplicatedStorage.Modules.MatchHandler)
local DataStoreClass = require(ReplicatedStorage.Classes.DataStore)
local GameAnalytics = require(ReplicatedStorage.Packages.GameAnalytics.GameAnalytics)

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
	local leaderstats = player:FindFirstChild("leaderstats")
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

local function onPlayerAdded(player: Player)
	DataStoreClass.PlayerAdded(player)
	GameAnalytics:PlayerJoined(player)
	player.Chatted:Connect(function(message)
		chatted(player, message)
	end)
	-- // The actual stuff
	-- // Character
	player.CharacterAdded:Connect(function(character: Model)
		local cardBackItem: BasePart = ReplicatedStorage.Assets.CardBackItem:Clone()
		cardBackItem.Parent = character
		local HumanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		local weldConstraint = Instance.new("WeldConstraint")
		weldConstraint.Parent = cardBackItem
		weldConstraint.Part0 = cardBackItem
		weldConstraint.Part1 = character:FindFirstChild("Torso")
		cardBackItem.CFrame = HumanoidRootPart.CFrame * CFrame.new(0, 0, 1)
		--
		character.Animate.walk.WalkAnim.AnimationId = "rbxassetid://14512867805"
	end)
end

local function onPlayerRemoving(player: Player)
	DataStoreClass.PlayerRemoving(player)
	GameAnalytics:PlayerRemoved(player)
	pcall(function()
		task.defer(player:Destroy())
	end)
end

local function teleportPartClicked(player: Player, otherPart: BasePart, destination: Vector3)
	if player then -- // check if we have the player
		player:RequestStreamAroundAsync(destination)
		otherPart.ClickDetector.MouseClick:Connect(function()
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
			local humanoid = npc:FindFirstChildOfClass("Humanoid")
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

local function returnCards(player): number?
	local value = player.leaderstats.Cards.Value
	print(`{player.DisplayName} has: {value}`)
	return value
end

local function payCards(player, reason: string)
	player.Leaderstats.Cards.Value += 50
	if reason then
		--
		print(reason)
	end
end

local function getLastLogin(player: Player): {}?
	local lastLogin = DataStoreClass.GetStore("Player-Related")
	local lastLoginData = lastLogin:GetAsync(`player:{player.UserId}`)
	return lastLoginData
end

-- Set the callback; this can only be done once by one server-side script
MarketplaceService.ProcessReceipt = processReceipt
DataStoreClass:StartBindToClose()
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
