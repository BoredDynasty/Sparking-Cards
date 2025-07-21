--!nonstrict

--# selene: allow(incorrect_standard_library_use)

-- Client.client.luau

print(script.Name)

-- // Services -- //
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

-- // Requires -- //

local CardAwarder = require(script.Parent.Parent:WaitForChild("Gameplay"):WaitForChild("CardAwarder"))()
local CardLibrary = require(ReplicatedStorage.Combat.CardLibrary) -- Corrected Path
local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))
local Hint = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("hint"))
local ItemTags = require(ReplicatedStorage.Market.ItemTags)
local Items = require(ReplicatedStorage.Market.Items)
local Maid = require(ReplicatedStorage.Utility.Maid)
local Movement = require(script.Parent.Parent.Movement.Movement)
local OnIdle = require(script.Parent.Parent:WaitForChild("Gameplay"):WaitForChild("OnIdle"))
-- local OverShoulder = require(script.Parent.Parent.Modules.OverShoulder)
local Packet = require(ReplicatedStorage.Packet)
local SignalPlus = require(ReplicatedStorage.Utility.SignalPlus)
local TextPlus = require(ReplicatedStorage.Utility.TextPlus)
local TweenPlus = require(ReplicatedStorage.Utility.TweenPlus)
local audio = require(ReplicatedStorage.Modules.audio)
local characterIteration = require(ReplicatedStorage.ClientModules.characterIteration)
local characterUtility = require(ReplicatedStorage.Utility.characterMarshaller)
local dialog = require(script.Parent.Parent.Components.dialog)
local dictionary = require(ReplicatedStorage.Utility.dictionary)
local displayorder = require(script.Parent.Parent.Interface.displayorder)
local gamecamera = require(script.Parent.Parent.Modules.gamecamera)
local hud = require(script.Parent.Parent.Components.hud)
local input = require(ReplicatedStorage.Packages.input)
local keybindlink = require(ReplicatedStorage.ClientModules.keybindlink)
local limits = require(script.Parent.Parent.Utilities.limits)
local lucide = require(ReplicatedStorage.Packages.lucide)
local orion = require(ReplicatedStorage.Combat.orion) -- Orion Combat Framework
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local pop = require(script.Parent.Parent.Interface.pop)
local profileMarshaller = require(ReplicatedStorage.Datastore.profileMarshaller)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local retryer = require(ReplicatedStorage.Utility.retryer)
local shadow = require(script.Parent.Parent.Interface.shadow)
local sway = require(script.Parent.Parent.Interface.sway)
-- local ripple = require(StarterPlayer.StarterPlayerScripts.Interface.ripple)
local yoink = require(ReplicatedStorage.Utility.yoink)
local keyboard = input.Keyboard.new()
local mouse = input.Mouse.new()

print("Client Requirements")

-- // Variables -- //

local player = playerMarshaller.get()
local profile: typeof(profilestructure) = profileMarshaller.client[player]
local character = characterUtility.get(player)
local _rootPart = character.HumanoidRootPart
local _assets = ReplicatedStorage:WaitForChild("Assets") :: Folder
local remoteEvents = ReplicatedStorage.Events

---------------------------------- Client --------------------------------

local interfaceStartTime = os.clock()

local PlayerGui = player.PlayerGui
local templates = ReplicatedStorage:WaitForChild("Interfaces", 5) :: Folder

Cmdr:SetActivationKeys({ Enum.KeyCode.Equals })
Cmdr:SetActivationUnlocksMouse(true)

audio:writeSFX({
	["click"] = 90092163763441,
	["hover"] = 119879668444252,
	["leave"] = 85897203168160,
	["success"] = 76288726968959,
})

print("client starting")

local function initializeMarket()
	print("init marker")
	local shopGui = PlayerGui:WaitForChild("Shop") :: ScreenGui
	local shopCanvas = shopGui:WaitForChild("CanvasGroup") :: CanvasGroup
	local shopFrame = shopCanvas:WaitForChild("Frame") :: Frame

	displayorder.compiled["shop"] = shopCanvas

	local shopNavigation = shopFrame:WaitForChild("Navigation") :: Frame
	local itemHolder = shopFrame:WaitForChild("Holder") :: Frame
	local shopFolder = templates:FindFirstChild("Shop") :: Folder
	local spendings = shopFrame:FindFirstChild("Spendings") :: Frame

	print("got market gui")

	local function unloadShop()
		for _, item in itemHolder:GetChildren() do
			if item and item:IsA("Frame") then
				item:Destroy()
				task.wait()
			end
		end
		return #(itemHolder:GetChildren()) * task.wait()
	end

	local function displaySpendings()
		local moneyFrame = spendings:FindFirstChild("Money") :: Frame
		profile = yoink.client:grab("profile_data") :: typeof(profilestructure)
		print("got profile for displaying spendings!!!!11!")
		local big_cards = tostring(profile.Data["Big-Cards"])
		TextPlus.Create(moneyFrame, big_cards, {
			Font = Font.new(
				"rbxasset://fonts/families/Montserrat.json", -- Family.
				Enum.FontWeight.SemiBold, -- Weight.
				Enum.FontStyle.Normal -- Style.
			),
			Size = 16,
			Color = Color3.fromHex("#ffffff"),
			XAlignment = "Left",
			YAlignment = "Center",
			LineSorting = true,
			WordSorting = true,
			Dynamic = true,
		})
	end
	coroutine.wrap(displaySpendings)
	Packet.profileChanged.listen(displaySpendings)
	coroutine.wrap(function()
		retryer.delay(10, math.huge, displaySpendings)
	end)
	shadow(shopFrame, Color3.new(), 0, 14)
	shadow(shopNavigation, Color3.new(), 0, 14)
	shadow(spendings, Color3.new(), 0, 14)

	local function populateShop(t: {}?)
		local newRelease = shopFrame:FindFirstChild("NewRelease") :: TextLabel
		unloadShop()
		t = Items
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

			shadow(itemTemplate, Color3.new(), 0, 14)

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
				LineSorting = true,
				WordSorting = true,
				Dynamic = true,
			})
			TextPlus.Create(price, "$" .. tostring(item.Price), {
				Font = Font.new(
					"rbxasset://fonts/families/Montserrat.json", -- Family.
					Enum.FontWeight.Regular, -- Weight.
					Enum.FontStyle.Normal -- Style.
				),
				Size = 12.5,
				Color = Color3.fromHex("#f5f5f5"),
				XAlignment = "Left",
				YAlignment = "Center",
				LineSorting = true,
				WordSorting = true,
				Dynamic = true,
			})

			coroutine.wrap(function()
				characterIteration:jump(title)
				characterIteration:jump(price)
			end)

			itemTemplate.Visible = true
			coroutine.wrap(function()
				if item.ExperimentsEnabled == true then
					experimentButton.Visible = true
					experimentButton:FindFirstChildOfClass("ImageLabel").Visible = true
					experimentButton.MouseButton1Click:Connect(function()
						print("Testing card: " .. item.Name)
					end)
				else
					experimentButton.Visible = false
				end
			end)

			itemTemplate.Tags.Visible = false
			coroutine.wrap(function()
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
			end)

			print("setting up buttons")
			local purchaseDebounce = false -- exception too
			TextPlus.Create(purchaseButton:FindFirstChild("TextHolder") :: Frame, "Purchase", {
				Font = Font.new(
					"rbxasset://fonts/families/Montserrat.json", -- Family.
					Enum.FontWeight.Bold, -- Weight.
					Enum.FontStyle.Normal -- Style.
				),
				Size = 12.5,
				Color = Color3.fromHex("#f5f5f5"),
				XAlignment = "Left",
				YAlignment = "Center",
				LineSorting = true,
				WordSorting = true,
				Dynamic = true,
			})
			purchaseButton.MouseEnter:Connect(function()
				audio:SFX("hover")
			end)
			purchaseButton.MouseLeave:Connect(function()
				audio:SFX("leave")
			end)
			purchaseButton.MouseButton1Click:Connect(function()
				if purchaseDebounce == true then
					return
				end
				print("Purchasing card: " .. item.Name)
				Packet.BuyCard.send({ cardName = item.Name })
				--ripple(Color3.new())
				pop(purchaseButton)
				audio:SFX("success")
				purchaseDebounce = true
				limits.debounce(purchaseDebounce)
			end)
			print("done")
			--task.wait()
		end
	end
	local function populateInventory()
		local unloaded = unloadShop()
		task.wait(unloaded)
		profile = yoink.client:grab("profile_data")
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

			TextPlus.Create(title, itemName, {
				Font = Font.new(
					"rbxasset://fonts/families/Montserrat.json", -- Family.
					Enum.FontWeight.SemiBold, -- Weight.
					Enum.FontStyle.Normal -- Style.
				),
				Size = 20,
				Color = Color3.fromHex("#ffffff"),
				XAlignment = "Left",
				YAlignment = "Center",
				LineSorting = true,
				WordSorting = true,
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
				LineSorting = true,
				WordSorting = true,
				Dynamic = true,
			})

			characterIteration:jump(title)
			characterIteration:jump(quantity)

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
						Packet.SellCard.send({ cardName = itemName, playerInstance = player })
					else
						return
					end
				end)
			end)
			task.wait()
		end
	end
	local debounce = false
	local function callback()
		if debounce then
			return
		end
		limits.debounce(debounce)
		displayorder:changeVisibility(not shopCanvas.Visible, shopCanvas)
		if shopCanvas.Visible then
			populateShop()
			sway:on(shopCanvas)
		else
			sway:off(shopCanvas)
		end
	end
	hud:create("Market", callback, lucide.GetAsset("shopping-cart"))
	hud:render()
end
initializeMarket()

print("client almost done")

local movementSingleton = Movement.new()

movementSingleton:dash(movementSingleton)
movementSingleton:sprint(movementSingleton)
movementSingleton:jump(movementSingleton)
movementSingleton:slide(movementSingleton)
movementSingleton:walk(movementSingleton)

print("client movement")
gamecamera:sway()
-- gamecamera:trail()
print("game camera")
-- control

local function getAttackTypeFromKey(key: Enum.KeyCode)
	-- profile = yoink.client:grab("profile_data")
	local attackTypes = {
		[Enum.KeyCode.MouseLeftButton] = "M1",
		[Enum.KeyCode.E] = "Skill",
		[Enum.KeyCode.Q] = "Ultimate",
		[Enum.KeyCode.R] = "Support",
	}
	local attackType = attackTypes[key]
	--assert(attackType, "Invalid key for attack type: " .. tostring(key))
	return attackType
end

keyboard.KeyDown:Connect(function(key: Enum.KeyCode)
	local attack_type = getAttackTypeFromKey(key)
	if attack_type then
		orion:execute(player, attack_type)
	end
end)

mouse.LeftDown:Connect(function()
	local attack_type = "M1"
	if attack_type then
		orion:execute(player, attack_type)
	end
end)

orion.registerPlayer(player)

-- Listen for profile changes to update equipped card if necessary
-- This assumes 'yoink' or the profile system has a way to notify changes.
-- If yoink:grab("profile_data") always returns the latest, this might not be strictly needed
-- unless CardLibrary itself changes dynamically.
-- For simplicity, we'll assume 'profile' variable is updated when it changes.
-- yoink.updated("profile_data", function(newProfile)
-- profile = newProfile
-- print("Client: Profile updated, current equipped card:", profile and profile.EquippedCard)
-- end)

local interfaceEndTime = os.clock()
local totalExecutionTime = math.round((interfaceEndTime - interfaceStartTime) * 10000) / 10000
-- This results in four decimal places.

print("UI has finished with an execution time of: ", totalExecutionTime)

local defaultFootstep = _rootPart:FindFirstChild("Running")
if defaultFootstep then
	defaultFootstep:Destroy()
end

OnIdle()
