--!strict

-- Shop.luau

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local ItemTags = require(ReplicatedStorage.Market.ItemTags)
local Items = require(ReplicatedStorage.Market.Items)
local Packet = require(ReplicatedStorage.Packet)
local TextPlus = require(ReplicatedStorage.Utility.TextPlus)
local audio = require(ReplicatedStorage.Modules.audio).new()
local dialog = require(script.Parent.dialog)
local gamecamera = require(StarterPlayer.StarterPlayerScripts.Modules.gamecamera)
local limits = require(StarterPlayer.StarterPlayerScripts.Utilities.limits)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local trove = require(ReplicatedStorage.Utility.trove).new()
local yoink = require(StarterPlayer.StarterPlayerScripts.Utilities.yoink)

local player = Players.LocalPlayer
local PlayerGui = player.PlayerGui
local profile = yoink:grab("profile_data") :: typeof(profilestructure)

local templates = ReplicatedStorage:WaitForChild("Interfaces") :: Folder

local shopGui = PlayerGui:WaitForChild("Shop") :: ScreenGui
local shopOpenFrame = shopGui:WaitForChild("Open") :: TextButton -- Floating Action Button
local shopOpenButton = shopOpenFrame:WaitForChild("HitBox") :: TextButton
local shopCanvas = shopGui:WaitForChild("CanvasGroup") :: CanvasGroup
local shopFrame = shopCanvas:WaitForChild("Frame") :: Frame

local shopNavigation = shopFrame:WaitForChild("Navigation") :: Frame
local itemHolder = shopFrame:WaitForChild("Holder") :: Frame

local shopRail: { [string]: GuiButton } = {}

audio:write_miscellaneous(audio, {
	["click"] = 90092163763441,
	["hover"] = 119879668444252,
	["leave"] = 85897203168160,
	["success"] = 76288726968959,
})

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
	local shopFolder = templates:FindFirstChild("Shop") :: Folder
	local newRelease = shopFrame:FindFirstChild("NewRelease") :: TextLabel
	unloadShop()
	t = t or Items
	for _, item in pairs(t) do
		-- print("got item: " .. item.Name)
		local itemTemplate = shopFolder:FindFirstChild("ItemTemplate") :: Frame & {
			Title: Frame,
			Price: TextLabel,
			Buy: TextButton,
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

		title = TextPlus.Create(title, item.Name, {
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
		price.Text = "$" .. tostring(item.Price)
		itemTemplate.Visible = true
		if item.ExperimentsEnabled == true then
			experimentButton.Visible = true
			experimentButton.MouseButton1Click:Connect(function()
				Pop(experimentButton)
				print("Testing card: " .. item.Name)
			end)
		else
			experimentButton.Visible = false
		end

		itemTemplate.Tags.Visible = true
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
			---Pop(purchaseButton)
			purchaseDebounce = true
			limits.debounce(purchaseDebounce)
		end)
		task.wait()
	end

	local itemMenu = shopNavigation:FindFirstChild("New") :: TextButton
	if string.find(newRelease.Text, "0", 1) then
		itemMenu.Transparency = 1
		newRelease.Visible = false
	else
		itemMenu.Transparency = 0
		newRelease.Visible = true
	end
end

local function populateOwnedFolder()
	local shopFolder = templates:FindFirstChild("Shop") :: Folder
	local unloaded = unloadShop()
	task.wait(unloaded)
	profile = yoink:grab("profile_data")
	assert(profile, "Profile does not exist on the client!")
	for itemName: string, i in pairs(profile.Data.Cards) do
		-- print("got item: " .. itemName)
		local itemTemplate = shopFolder:FindFirstChild("ItemTemplate") :: Frame
		itemTemplate = itemTemplate:Clone()
		itemTemplate.Parent = itemHolder

		local title = itemTemplate:FindFirstChild("Title") :: TextLabel
		local quantity = itemTemplate:FindFirstChild("Price") :: TextLabel

		local sellButton = itemTemplate:FindFirstChild("Buy") :: TextButton -- lol
		local experimentButton = itemTemplate:FindFirstChild("Test") :: TextButton

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
		quantity.Text = "( <b>" .. tostring(i) .. "</b> )"
		itemTemplate.Visible = true
		quantity.RichText = true

		experimentButton.Visible = false
		sellButton.Visible = true
		sellButton.Text = "Sell"
		sellButton.MouseButton1Click:Connect(function()
			local dialog_title = "Slow down there!"
			local description = [[
			Are you sure you want to sell this Card? 
			]] .. itemName
			local folder_minus_icon = "rbxassetid://10723386127"
			local result = dialog(dialog_title, description, folder_minus_icon)
			if result and result == true then
				print("selling card: " .. itemName)
				Packet.sellCard.send({ player, itemName })
			end
		end)
		task.wait()
	end
end

Packet.buyCard.listen(function(data: { string })
	local condition = "success"
	--print("got condition: ", data[1], " for buying Cards. (server > client)")
	if data[1] == condition then
		local allotedColors = 10
		local colors = Saturation.generateRandomColors(allotedColors)
		local folder = Instance.new("Folder")
		folder.Name = "ConfettiFolder"
		folder.Parent = shopFrame
		audio:read_miscellaneous(audio, "success")
		Confetti(colors, folder)
	end
end)

local dropshadow_folder: Folder? = nil

shopOpenButton.MouseButton1Click:Connect(function()
	--if checkDebounce(shopOpenButton) then
	--return
	--end
	print("open shop")
	if shopCanvas.Visible == false then
		DisplayOrder:changeVisibility(true, shopCanvas)
		gamecamera:changeFOV(60)
		audio:read_miscellaneous(audio, "click")
		DisplayOrder:setDisplayOrder("shop")
		populateShop()
		Pop(shopOpenButton)
		Pop(shopFrame)
		dropshadow_folder = shadow(shopFrame, Color3.new(), 0, 14)
		trove:Add(dropshadow_folder)
	elseif shopCanvas.Visible == true then
		DisplayOrder:changeVisibility(false, shopCanvas)
		audio:read_miscellaneous(audio, "leave")
		gamecamera:changeFOV(70)
		unloadShop()
		Pop(shopOpenButton)
		Pop(shopFrame)
		trove:Clean()
	end
end)
shopOpenButton.MouseEnter:Connect(function()
	audio:read_miscellaneous(audio, "hover")
	Hint("Buy Items in the Market", shopOpenButton)
end)
shopOpenButton.MouseLeave:Connect(function()
	audio:read_miscellaneous(audio, "leave")
end)

for _, item: GuiObject in shopNavigation:GetChildren() do
	if item:IsA("GuiButton") then
		shopRail[item.Name] = item
	end
end

shopRail.New.MouseButton1Click:Connect(function()
	if not limits.debounce_limit("shop_rail_btn_new") then
		return
	end
	populateShop()
end)
shopRail.Modifiers.MouseButton1Click:Connect(function()
	if not limits.debounce_limit("shop_rail_btn_modifiers") then
		return
	end
	populateOwnedFolder()
end)

local _shopNavigation = Rail.new(shopNavigation)
_shopNavigation:_initialize(_shopNavigation)

return {
	audio,
}
