--!nonstrict

--# selene: allow(incorrect_standard_library_use)

-- Client.client.luau

print(script.Name)

-- // Services -- //

local MarketPlaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

-- // Requires -- //

local CardAwarder = require(script.Parent.Parent:WaitForChild("Gameplay"):WaitForChild("CardAwarder"))()
local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))
local Hint = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("hint"))
local ItemTags = require(ReplicatedStorage.Market.ItemTags)
local Items = require(ReplicatedStorage.Market.Items)
local Movement = require(script.Parent.Parent.Movement.Movement)
local OnIdle = require(script.Parent.Parent:WaitForChild("Gameplay"):WaitForChild("OnIdle"))
local OverShoulder = require(StarterPlayer.StarterPlayerScripts.Modules.OverShoulder)
local Packet = require(ReplicatedStorage.Packet)
local SignalPlus = require(ReplicatedStorage.Utility.SignalPlus)
local TextPlus = require(ReplicatedStorage.Utility.TextPlus)
local TweenPlus = require(ReplicatedStorage.Utility.TweenPlus)
local audio = require(ReplicatedStorage.Modules.audio).new()
local characterUtility = require(ReplicatedStorage.Utility.characterMarshaller)
local dialog = require(script.Parent.Parent.Components.dialog)
local gamecamera = require(script.Parent.Parent.Modules.gamecamera)
local keybindlink = require(ReplicatedStorage.ClientModules.keybindlink)
local limits = require(script.Parent.Parent.Utilities.limits)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local pop = require(script.Parent.Parent.Interface.pop)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local retryer = require(ReplicatedStorage.Utility.retryer)
local yoink = require(script.Parent.Parent.Utilities.yoink)
local orion = require(ReplicatedStorage.Combat.orion) -- Orion Combat Framework
local CardLibrary = require(ReplicatedStorage.Combat.CardLibrary) -- Corrected Path
local Maid = require(ReplicatedStorage.Utility.Maid)

print("Client Requirements")

-- // Variables -- //
local clientMaid = Maid.new()

local player = playerMarshaller.get()
local profile: typeof(profilestructure) = yoink:grab("profile_data")
local character = characterUtility.get(player)
local _rootPart = character.HumanoidRootPart
local _assets = ReplicatedStorage:WaitForChild("Assets") :: Folder
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents") :: Folder

---------------------------------- Client --------------------------------

local interfaceStartTime = os.clock()

local PlayerGui = player.PlayerGui
local templates = ReplicatedStorage:WaitForChild("Interfaces") :: Folder

audio:write_miscellaneous(audio, {
	["click"] = 90092163763441,
	["hover"] = 119879668444252,
	["leave"] = 85897203168160,
	["success"] = 76288726968959,
})

print("client starting")

local function initializeMarket()
	local shopGui = PlayerGui:WaitForChild("Shop") :: ScreenGui
	local shopOpenFrame = shopGui:WaitForChild("Open") :: TextButton -- Floating Action Button
	local shopOpenButton = shopOpenFrame:WaitForChild("HitBox") :: TextButton
	local shopCanvas = shopGui:WaitForChild("CanvasGroup") :: CanvasGroup
	local shopFrame = shopCanvas:WaitForChild("Frame") :: Frame

	local shopNavigation = shopFrame:WaitForChild("Navigation") :: Frame
	local itemHolder = shopFrame:WaitForChild("Holder") :: Frame
	local shopFolder = templates:FindFirstChild("Shop") :: Folder

	local function unloadShop()
		for _, item in itemHolder:GetChildren() do
			if item and item:IsA("Frame") then
				item:Destroy()
				task.wait()
			end
		end
		return #(itemHolder:GetChildren()) * task.wait()
	end

	local function populateShop(t: {}?)
		local newRelease = shopFrame:FindFirstChild("NewRelease") :: TextLabel
		unloadShop()
		t = t or Items
		for _, item in pairs(t) do
			-- print("got item: " .. item.Name)
			local itemTemplate = shopFolder:FindFirstChild("ItemTemplate") :: Frame & {
				Title: Frame,
				Price: Frame,
				Buy: TextButton & {
					TextHolder: Frame,
				},
				Test: TextButton,
				Tags: Frame,
			}
			itemTemplate = itemTemplate:Clone()
			itemTemplate:SetAttribute("name", item.Name)
			itemTemplate.Parent = itemHolder

			local title = itemTemplate.Title
			local price = itemTemplate.Price

			local purchaseButton = itemTemplate.Buy
			local experimentButton = itemTemplate.Test

			TextPlus.Create(title, item.Name, {
				Font = Font.new(
					"rbxasset://fonts/families/Montserrat.json", -- Family.
					Enum.FontWeight.SemiBold, -- Weight.
					Enum.FontStyle.Normal -- Style.
				),
				Size = 16,
				Color = Color3.fromHex("#ffffff"),
				XAlignment = "Left",
				YAlignment = "Center",
				Dynamic = true,
			})
			TextPlus.Create(price, "$" .. tostring(item.Price), {
				Font = Font.new(
					"rbxasset://fonts/families/Montserrat.json", -- Family.
					Enum.FontWeight.Regular, -- Weight.
					Enum.FontStyle.Normal -- Style.
				),
				Size = 12.5,
				Color = Color3.fromHex("#39302e"),
				XAlignment = "Left",
				YAlignment = "Center",
				Dynamic = true,
			})

			itemTemplate.Visible = true
			if item.ExperimentsEnabled == true then
				experimentButton.Visible = true
				experimentButton.MouseButton1Click:Connect(function()
					print("Testing card: " .. item.Name)
				end)
			else
				experimentButton.Visible = false
			end

			if item.Tags then
				itemTemplate.Tags.Visible = true
				for _, tagName in pairs(item.Tags) do
					if ItemTags[tagName] then
						local tag = ItemTags[tagName]

						local image = Instance.new("ImageLabel")
						local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")

						--Properties:

						image.Parent = itemTemplate.Tags
						image.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						image.BackgroundTransparency = 1.000
						image.BorderColor3 = Color3.fromRGB(0, 0, 0)
						image.BorderSizePixel = 0
						image.Size = UDim2.new(0, 20, 0, 20)
						image.Visible = false
						image.Image = tag.Identification
						--[[
						local thread = task.spawn(Hint, tag.Description, itemTemplate.Tags)
						itemTemplate.Destroying:Once(function()
							-- cleaner
							task.cancel(thread)
						end)
						--]]
						UIAspectRatioConstraint.Parent = image
					end
				end
			end
			local purchaseDebounce = false -- exception too
			purchaseButton.MouseEnter:Connect(function()
				audio:read_miscellaneous(audio, "hover")
			end)
			purchaseButton.MouseLeave:Connect(function()
				audio:read_miscellaneous(audio, "leave")
			end)
			purchaseButton.MouseButton1Click:Connect(function()
				if purchaseDebounce == true then
					return
				end
				print("Purchasing card: " .. item.Name)
				Packet.buyCard.send({
					item.Name,
				})
				pop(purchaseButton)
				purchaseDebounce = true
				limits.debounce(purchaseDebounce)
			end)
			task.wait()
		end
	end
	local function populateOwnedFolder()
		local unloaded = unloadShop()
		task.wait(unloaded)
		profile = yoink:grab("profile_data")
		assert(profile, "Profile does not exist on the client!")
		for itemName: string, i in pairs(profile.Data.Cards) do
			-- print("got item: " .. itemName)
			local itemTemplate = shopFolder:FindFirstChild("ItemTemplate") :: Frame & {
				Title: Frame,
				Price: Frame,
				Buy: TextButton & {
					TextHolder: Frame,
				},
				Test: TextButton,
				Tags: Frame,
			}
			itemTemplate = itemTemplate:Clone()
			itemTemplate.Parent = itemHolder

			local title = itemTemplate.Title
			local quantity = itemTemplate.Price

			local sellButton = itemTemplate.Buy -- lol
			local experimentButton = itemTemplate.Test

			title = TextPlus.Create(title, itemName, {
				Font = Font.new(
					"rbxasset://fonts/families/Montserrat.json", -- Family.
					Enum.FontWeight.SemiBold, -- Weight.
					Enum.FontStyle.Normal -- Style.
				),
				Size = 20,
				Color = Color3.fromHex("#ffffff"),
				XAlignment = "Left",
				YAlignment = "Center",
				Dynamic = true,
			})
			--title.Text = itemName
			TextPlus.Create(quantity, "( <b>" .. tostring(i) .. "</b> )", {
				Font = Font.new(
					"rbxasset://fonts/families/Montserrat.json", -- Family.
					Enum.FontWeight.Regular, -- Weight.
					Enum.FontStyle.Normal -- Style.
				),
				Size = 12.5,
				Color = Color3.fromHex("#39302e"),
				XAlignment = "Left",
				YAlignment = "Center",
				Dynamic = true,
			})
			itemTemplate.Visible = true

			experimentButton.Visible = false
			sellButton.Visible = true
			sellButton.Text = "Sell"
			sellButton.MouseButton1Click:Connect(function()
				local dialog_title = "Slow down there!"
				local description = [[
				Are you sure you want to sell this Card? 
				]] .. itemName
				-- local folder_minus_icon = "rbxassetid://10723386127"
				local result = dialog(dialog_title, description)
				result:Once(function(a0: boolean)
					if a0 == true then
						Packet.sellCard.send({ player, itemName })
					else
						return
					end
				end)
			end)
			task.wait()
		end
	end
end

print("client almost done")

local movementSingleton = Movement.new()
movementSingleton:sprint(movementSingleton)
movementSingleton:jump(movementSingleton)
movementSingleton:slide(movementSingleton)
print("client movement")
gamecamera:bobble()
gamecamera:sway()
gamecamera:trail()
print("game camera")
-- control

local mouse_one = keybindlink.new("M1", Enum.KeyCode.MouseLeftButton, Enum.KeyCode.ButtonB, 1):Show()
local skill = keybindlink.new("Primary", Enum.KeyCode.E, Enum.KeyCode.ButtonX, 2):Show()
local ultimate = keybindlink.new("Ultimate", Enum.KeyCode.Q, Enum.KeyCode.ButtonY, 3):Show()
local support = keybindlink.new("Support", Enum.KeyCode.R, Enum.KeyCode.ButtonA, 4):Show() -- Support/Auxiliary ability

print("controls")

-- Initialize Orion Combat Framework on Client
orion.InitClient()

-- Helper function to get the Orion attack name for a given action and card
local function getOrionAttackName(actionType: string): string?
	if not profile or not profile.EquippedCard then
		warn("Client: No profile or equipped card found.")
		return nil
	end
	local equippedCardName = profile.EquippedCard -- This should be the key like "FrostGauntlet" or "FireSword"
	local cardInfo = CardLibrary[equippedCardName]

	if not cardInfo or not cardInfo.Moveset then
		warn("Client: Card info or moveset not found in CardLibrary for equipped card:", equippedCardName)
		return nil
	end

	local attackName: string?

	if actionType == "M1" then
		attackName = cardInfo.Moveset.M1
	elseif actionType == "Primary" then -- Corresponds to 'E' key, mapped to Skill
		attackName = cardInfo.Moveset.Skill
	elseif actionType == "Ultimate" then -- Corresponds to 'Q' key
		attackName = cardInfo.Moveset.Ultimate
	elseif actionType == "Support" then -- Corresponds to 'R' key
		attackName = cardInfo.Moveset.Support
	else
		warn("Client: Unknown actionType provided to getOrionAttackName:", actionType)
		return nil
	end

	if attackName and orion.RegisteredAttacks[attackName] then
		return attackName
	elseif attackName then
		-- This warning means the CardLibrary specifies an attack name, but it hasn't been registered in Orion yet.
		-- This is expected if the attack module for it hasn't been created or loaded.
		warn("Client: Attack '", attackName, "' for card '", equippedCardName, "' (action: ", actionType, ") is defined in CardLibrary but not registered in Orion.")
		return nil
	else
		warn("Client: No attackName defined in CardLibrary for card '", equippedCardName, "' action '", actionType, "'.")
		return nil
	end
end

-- Variables for M1 Combo Tracking
local clientPlayerComboData = {} -- [playerId] = { currentAttackName = "attackName", count = 1, lastAttackTime = tick() }
local COMBO_WINDOW_DURATION = 0.8 -- Max time between M1 presses to continue a combo (adjust as needed)

-- Connect keybinds to Orion framework
mouse_one.activated:Connect(function()
	if not profile or not profile.EquippedCard then return end
	local equippedCardName = profile.EquippedCard
	local cardInfo = CardLibrary[equippedCardName]
	if not cardInfo then return end

	local targetInfo = { targetPosition = player:GetMouse().Hit.Position }
	local currentComboData = clientPlayerComboData[player.UserId]
	local attackNameToExecute: string?

	if currentComboData
		and (tick() - currentComboData.lastAttackTime < COMBO_WINDOW_DURATION)
		and currentComboData.count < (cardInfo.MaxCombo or 1)
	then
		-- Try to continue combo
		local lastAttackData = orion.RegisteredAttacks[currentComboData.currentAttackName]
		if lastAttackData and lastAttackData.NextComboAttack then
			attackNameToExecute = lastAttackData.NextComboAttack
			currentComboData.count += 1
			-- print("Client: Continuing combo to", attackNameToExecute, "Count:", currentComboData.count)
		else
			-- No next attack or last attack data missing, reset combo
			attackNameToExecute = getOrionAttackName("M1") -- Get base M1
			clientPlayerComboData[player.UserId] = { count = 1 }
			-- print("Client: Resetting combo (no next attack), starting with", attackNameToExecute)
		end
	else
		-- Start or restart combo
		attackNameToExecute = getOrionAttackName("M1") -- Get base M1
		clientPlayerComboData[player.UserId] = { count = 1 }
		-- print("Client: Starting new combo with", attackNameToExecute)
	end

	if attackNameToExecute then
		orion.RequestExecuteAttack(attackNameToExecute, equippedCardName, targetInfo)
		if clientPlayerComboData[player.UserId] then -- Ensure it was initialized
			clientPlayerComboData[player.UserId].currentAttackName = attackNameToExecute
			clientPlayerComboData[player.UserId].lastAttackTime = tick()
		end
	else
		warn("Client: No M1 attack found for", equippedCardName)
		clientPlayerComboData[player.UserId] = nil -- Clear combo data if no attack found
	end
end)

skill.activated:Connect(function()
	local attackName = getOrionAttackName("Primary")
	if attackName and profile and profile.EquippedCard then
		local targetInfo = { targetPosition = player:GetMouse().Hit.Position }
		orion.RequestExecuteAttack(attackName, profile.EquippedCard, targetInfo)
	end
end)

ultimate.activated:Connect(function()
	local attackName = getOrionAttackName("Ultimate")
	if attackName and profile and profile.EquippedCard then
		local targetInfo = { targetPosition = player:GetMouse().Hit.Position }
		orion.RequestExecuteAttack(attackName, profile.EquippedCard, targetInfo)
	end
end)

support.activated:Connect(function()
	local attackName = getOrionAttackName("Support")
	if attackName and profile and profile.EquippedCard then
		local targetInfo = { targetPosition = player:GetMouse().Hit.Position }
		orion.RequestExecuteAttack(attackName, profile.EquippedCard, targetInfo)
	end
end)

-- Listen for profile changes to update equipped card if necessary
-- This assumes 'yoink' or the profile system has a way to notify changes.
-- If yoink:grab("profile_data") always returns the latest, this might not be strictly needed
-- unless CardLibrary itself changes dynamically.
-- For simplicity, we'll assume 'profile' variable is updated when it changes.
-- yoink.updated("profile_data", function(newProfile)
-- profile = newProfile
-- print("Client: Profile updated, current equipped card:", profile and profile.EquippedCard)
-- end)

-- Add keybindlink connections to maid for cleanup
clientMaid:GiveTask(mouse_one)
clientMaid:GiveTask(skill)
clientMaid:GiveTask(ultimate)
clientMaid:GiveTask(support)

local interfaceEndTime = os.clock()
local totalExecutionTime = math.round((interfaceEndTime - interfaceStartTime) * 10000) / 10000
-- This results in four decimal places.

print("UI has finished with an execution time of: ", totalExecutionTime)

local defaultFootstep = _rootPart:FindFirstChild("Running")
if defaultFootstep then
	defaultFootstep:Destroy()
end

OnIdle()
