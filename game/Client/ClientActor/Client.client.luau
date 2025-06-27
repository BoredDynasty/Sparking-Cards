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

print("Client Requirements")

-- // Variables -- //

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
local support = keybindlink.new("Support", Enum.KeyCode.R, Enum.KeyCode.ButtonA, 4):Show()

print("controls")

local interfaceEndTime = os.clock()
local totalExecutionTime = math.round((interfaceEndTime - interfaceStartTime) * 10000) / 10000
-- This results in four decimal places.

print("UI has finished with an execution time of: ", totalExecutionTime)

local defaultFootstep = _rootPart:FindFirstChild("Running")
if defaultFootstep then
	defaultFootstep:Destroy()
end

OnIdle()
