--!nocheck

-- Master.server.lua

print(string.format(`Server ID [ {game.JobId} ] \nVER. {game.PlaceVersion}`, "%q"))

local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService = game:GetService("AnalyticsService")

local SafeTeleporter = require(ReplicatedStorage.Modules.SafeTeleporter)
local MatchHandler = require(ReplicatedStorage.Modules.MatchHandler)
local DataStoreClass = require(ReplicatedStorage.Classes.DataStore)

local FastTravelRE: RemoteEvent = ReplicatedStorage.RemoteEvents.FastTravel
local EnterMatchRE: RemoteEvent = ReplicatedStorage.RemoteEvents.EnterMatch
local DialogRE: RemoteEvent = ReplicatedStorage.RemoteEvents.NewDialogue
local SendAnalytic: RemoteEvent = ReplicatedStorage.RemoteEvents.SendAnalytic
local GetCards: RemoteFunction = ReplicatedStorage.RemoteEvents.GetCards

local productFunctions = {}

print("Economic Analytics are enabled.")
print("Custom Analytics are enabled.")
print("Developer Notes gets updated every 24h.")

local function touchDialog(otherPart: BasePart, player: Player)
	if not player then
		player = Players:GetPlayerFromCharacter(otherPart.Parent)
	end
	local message = otherPart:GetAttribute("TouchDialog")
		or otherPart:GetAttribute("DialogText")
		or otherPart:GetAttribute("Dialog")
	if message then
		DialogRE:FireClient(player, message)
		print(`Sending Dialog to {player.DisplayName}: {message}`)
	end
end

local function automaticDialog(player: Player, dialog: string)
	DialogRE:FireClient(player, dialog)
end

-- This product Id gives the player more cards (cards as in money)
productFunctions[1904591683] = function(receipt, player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local Cards: IntValue = leaderstats:FindFirstChild("Cards")
	if Cards then
		Cards.Value += 50
		AnalyticsService:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Source,
			"Cards",
			50,
			DataStoreClass:getPlayerStats().Value,
			Enum.AnalyticsEconomyTransactionType.IAP.Name,
			"Extra Cards"
		)
		local customFields = {
			[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = tostring(receipt),
			[Enum.AnalyticsCustomFieldKeys.CustomField03.Name] = player.Name,
			[Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = player.UserId,
		}
		AnalyticsService:LogCustomEvent(player, "Receipts", 1, customFields)
	end
	return true -- indicate a successful purchase
end

productFunctions[1906572512] = function(receipt, player)
	print(`Donated Successfully: {player.Name}.`)
	local customFields = {
		[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = tostring(receipt),
		[Enum.AnalyticsCustomFieldKeys.CustomField03.Name] = player.Name,
		[Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = player.UserId,
	}
	AnalyticsService:LogCustomEvent(player, "Receipts", 1, customFields)
	return true
end

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
	AnalyticsService:LogOnboardingFunnelStepEvent(player, 1, "Player Joined")
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
	AnalyticsService:LogOnboardingFunnelStepEvent(player, 1, "Player Leaving")
	pcall(function()
		player:Destroy() -- performance reasons
	end)
end

local function isPlayerNearPart(player: Player, part: BasePart, maxDistance: number)
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local playerPosition = character.HumanoidRootPart.Position
		local partPosition = part.Position
		local distance = (playerPosition - partPosition).Magnitude
		return distance <= maxDistance
	end
end

local function setCameraView(player, view)
	local setCameraHost = ReplicatedStorage.RemoteEvents.SetCameraHost
	setCameraHost:FireClient(player, view)
end

local function panCameraAtObject(player: Player, otherPart: BasePart, value)
	-- // we want to grab the players attention to the object
	local setCameraHost = ReplicatedStorage.RemoteEvents.SetCameraHost
	if value == true then
		setCameraHost:FireClient(player, otherPart)
	elseif value == false then
		setCameraView(player, "Default")
	end
end

local function getClickDetector(otherPart: BasePart, cooldown: { Player })
	if otherPart:FindFirstChildOfClass("ClickDetector") then
		local clickDetect = otherPart:FindFirstChildOfClass("ClickDetector")
		clickDetect.MouseClick:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not table.find(cooldown, player) then
				table.insert(cooldown, player)
				touchDialog(otherPart, player)
				task.delay(10, table.remove, cooldown, 1)
			end
		end)
	end
end

local function otherPartTouched(otherPart: BasePart, cooldown: { Player })
	otherPart.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not table.find(cooldown, player) then
			task.spawn(function()
				table.insert(cooldown, player)
				touchDialog(otherPart, player)
				task.wait(10)
				table.remove(cooldown, 1)
			end)
		end
	end)
end

local function teleportPartClicked(otherPart: BasePart, destination: Vector3)
	local player = Players:GetPlayerFromCharacter(otherPart.Parent)
	if player then -- // check if we have the player
		otherPart.ClickDetector.MouseClick:Connect(function()
			player.Character.HumanoidRootPart:PivotTo(destination)
		end)
	end
end

local function addDestinations()
	local cooldown = {}
	return task.spawn(function()
		for _, tag in pairs(CollectionService:GetTagged("TeleportPart")) do
			local Teleport: BasePart = tag
			local destination = Teleport:GetAttribute("Destination")
			teleportPartClicked(Teleport, destination)
			for _, player: Player in pairs(Players:GetPlayers()) do
				if isPlayerNearPart(player, Teleport, 10) then
					panCameraAtObject(player, Teleport, true)
					print("Player is near the part: ", player, Teleport)
				else
					panCameraAtObject(player, Teleport, false)
					-- print("Player is not near the part: ", player)
				end
			end
		end
		for _, tag in CollectionService:GetTagged("DialogTrigger") do
			local otherPart: BasePart = tag
			-- // Call functions
			getClickDetector(otherPart, cooldown)
			otherPartTouched(otherPart, cooldown)
		end
	end)
end

local function add_NPC_Interactions()
	return task.spawn(function()
		for _, tag in CollectionService:GetTagged("NPC") do
			local otherPart: BasePart = tag:FindFirstChild("HumanoidRootPart")
			-- we have to make sure that the player is near the NPC
			for _, player in pairs(Players:GetPlayers()) do
				if isPlayerNearPart(player, otherPart, 10) then
					panCameraAtObject(otherPart, true)
					print("Player is near the NPC: ", player, otherPart.Name)
					print("Sending new Dialog")
					automaticDialog(
						player,
						`{otherPart.Parent.Name}: {otherPart.Parent:GetAttribute("Dialog")}`
					)
				else
					panCameraAtObject(otherPart, false)
					print("Player is not near the NPC: ", player)
				end
			end
		end
	end)
end

local function catchAnalytic(player, topic, param1, customFields)
	AnalyticsService:LogCustomEvent(player, topic, param1, customFields)
	print(`New Analytic: `, topic, param1, customFields)
end

local function returnCards(player): number?
	local value = player.leaderstats.Cards.Value
	print(`{player.DisplayName} has: {value}`)
	return value
end

-- Set the callback; this can only be done once by one server-side script
MarketplaceService.ProcessReceipt = processReceipt
DataStoreClass:StartBindToClose()
--
addDestinations()
add_NPC_Interactions()
--
FastTravelRE.OnServerEvent:Connect(FastTravel)
EnterMatchRE.OnServerEvent:Connect(enterMatch)
SendAnalytic.OnServerEvent:Connect(catchAnalytic)
GetCards.OnServerInvoke = returnCards
--
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
