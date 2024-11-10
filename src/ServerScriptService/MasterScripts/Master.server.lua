--!nocheck

print("Server ID [ " .. game.JobId .. " ]")

local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataStoreClass = require(ReplicatedStorage.Classes.DataStoreClass)
local AnalyticsClass = require(ReplicatedStorage.Classes.AnalyticsClass)
local SafeTeleporter = require(ReplicatedStorage.Modules.SafeTeleporter)
local UIEffectsClass = require(ReplicatedStorage.Classes.UIEffect)
local LoadingClass = require(ReplicatedStorage.Classes.LoadingClass)

local FastTravelRE = ReplicatedStorage.RemoteEvents.FastTravel
local DialogRE = ReplicatedStorage.RemoteEvents.NewDialogue

local productFunctions = {}

print("Economic Analytics are enabled.")
print("Custom Analytics are enabled.")

local function touchDialog(otherPart: BasePart, player)
	local message = otherPart:GetAttribute("TouchDialog")
	DialogRE:FireClient(player, message)
end

local function addDecorations(player: Player)
	player.CharacterAdded:Connect(function(character)
		local torso = character:FindFirstChild("Torso") :: BasePart
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

		local namePlate = ReplicatedStorage.Assets.NamePlate
		local newNamePlate: BillboardGui = namePlate:Clone()
		newNamePlate.Parent = character
		newNamePlate.Adornee = character
		newNamePlate.CanvasGroup.Frame:FindFirstChild("Name").Text = "@" .. player.DisplayName
		newNamePlate.CanvasGroup.Frame.Description.Text = player.leaderstats.Rank.Value

		local part = ReplicatedStorage.Assets:FindFirstChild("CardBackItem")

		local partClone = part:Clone()
		partClone.Anchored = false
		partClone.CanCollide = false

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = torso
		weld.Part1 = partClone
		weld.Parent = partClone

		local offset = CFrame.new(0, 0, 2)
		partClone.CFrame = torso.CFrame * offset
		partClone.CFrame = partClone.CFrame * CFrame.fromOrientation(-90, 0, 0)

		partClone.Parent = character
	end)
end

-- This product Id gives the player more cards (cards as in money)
productFunctions[1904591683] = function(receipt, player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	local leaderstats = player:FindFirstChild("leaderstats")
	local multiplier = leaderstats:FindFirstChild("MultiplierType")
	local Cards = leaderstats and leaderstats:FindFirstChild("Cards")
	if Cards then
		--local newMultiplier = math.ceil(50 * MultiplierNumber)
		--Cards.Value += newMultiplier
		Cards.Value += 50
		task.wait(1)
		AnalyticsClass:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Source,
			50,
			Enum.AnalyticsEconomyTransactionType.IAP.Name,
			"50_Cards"
		)
	end
	return true -- indicate a successful purchase
end

productFunctions[1906572512] = function(receipt, player)
	local alreadyDonated: {} = {} :: {} -- unessecary lmao
	if not table.find(alreadyDonated, player.Name) then
		table.insert(alreadyDonated, player.Name)
		print("Donated Successfully!")
		AnalyticsClass:LogOnboardingFunnelStepEvent(player, "Donation", 5)
		task.wait(10)
		table.clear(alreadyDonated)
	end
end

local Clone = ReplicatedStorage.Assets.Server:Clone()
Clone.Parent = workspace

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
			warn("Failed to process receipt:", receiptInfo, result)
		end
	end

	-- The user's benefits couldn't be awarded
	-- Return "NotProcessedYet" to try again next time the user joins
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

local function teleport(players: { Player }, place: number): any
	for i, player: Player in players do
		local matchUI = player.PlayerGui.DynamicUI.MatchMakingUI
		UIEffectsClass.Sound("Favorite")
		UIEffectsClass.changeVisibility(matchUI.CanvasGroup, true)
	end
	SafeTeleporter.Teleport(players, place)
	print("Teleporting to " .. place)

	return "Teleporting to " .. place
end

local function onPlayerAdded(player)
	local experience = DataStoreClass.PlayerAdded(player)
	AnalyticsClass.LogCustomEvent(player, "ExperiencePoints")
	addDecorations(player)
	player.Character.Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=14512867805"
	player.CharacterRemoving:Connect(function(character)
		task.defer(character.Destroy, character)
	end)
end

local function FastTravel(player, from: string, travelAreas: {}, FastTravelGui: ScreenGui?)
	return SafeTeleporter.Teleport({ player }, travelAreas[2])
end

local function onPlayerRemoving(player)
	DataStoreClass.PlayerRemoving(player)
	task.defer(player.Destroy, player)
end

task.spawn(function()
	for _, tag in pairs(CollectionService:GetTagged("TeleportPart")) do
		local Teleport = tag

		local destination = Teleport:GetAttribute("Destination")

		Teleport.ClickDetector.MouseClick:Connect(function(player)
			LoadingClass.New(1.2, player)
			task.wait(1)
			player.Character.HumanoidRootPart:PivotTo(destination)
		end)
	end
	for _, tag in CollectionService:GetTagged("TouchDialog") do
		local otherPart: BasePart? = tag
		local cooldown = {}
		otherPart.Touched:Connect(function(player)
			if not table.find(cooldown, otherPart) then
				table.insert(cooldown, otherPart)
				touchDialog(otherPart, player)
				task.wait(10)
				table.remove(cooldown, otherPart)
			end
		end)
	end
end)

-- Set the callback; this can only be done once by one server-side script
MarketplaceService.ProcessReceipt = processReceipt
DataStoreClass.StartBindToClose()
ReplicatedStorage.RemoteEvents.JoinQueueEvent.OnServerInvoke(teleport)
FastTravelRE.OnServerEvent:Connect(FastTravel)
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
