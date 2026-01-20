--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local Items = require(ReplicatedStorage.Market.Items)
local Packet = require(ReplicatedStorage.Packet)
local TextPlus = require(ReplicatedStorage.Utility.TextPlus)
local audio = require(ReplicatedStorage.Modules.audio)
local confetti = require(StarterPlayer.StarterPlayerScripts.Interface.confetti)
local markdown = require(ReplicatedStorage.ClientModules.markdown)
local number_abbreviation = require(ReplicatedStorage.Modules.Serialization["number-abbreviation"])
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local pop = require(StarterPlayer.StarterPlayerScripts.Interface.pop)
local prism_awarder = require(StarterPlayer.StarterPlayerScripts.Gameplay["prism-awarder"])
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local ripple = require(StarterPlayer.StarterPlayerScripts.Interface.ripple)
local safeteleport = require(ReplicatedStorage.Modules.safeteleport)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)
local wiggle = require(StarterPlayer.StarterPlayerScripts.Interface.wiggle)

-- market.luau

export type template = Frame & {
	Title: TextLabel,
	Buy: TextButton,
	Test: TextButton,
}

local player = playerMarshaller.get()
local playerGui = player.PlayerGui

local templates = ReplicatedStorage.Interfaces

local shopGui = playerGui.Shop
local shopCanvas = shopGui.CanvasGroup
local shopFrame = shopCanvas.Frame

local shopNavigation = shopFrame.Navigation
local itemHolder = shopFrame.Holder
local shopFolder = templates.Shop
local spendings = shopFrame.Spendings

local money_label = spendings.Amount

local market = {
	template = shopFolder.ItemTemplate :: template,
	limit = ratelimit(1, 0.5),
}

local function createTemplate(ancestor: Instance?): template
	local Instances = {
		ItemTemplate = Instance.new("Frame"),
		UICorner = Instance.new("UICorner"),
		UIStroke = Instance.new("UIStroke"),
		Buy = Instance.new("TextButton"),
		UICorner_2 = Instance.new("UICorner"),
		ImageLabel = Instance.new("ImageLabel"),
		AspectRatio = Instance.new("UIAspectRatioConstraint"),
		AspectRatio_2 = Instance.new("UIAspectRatioConstraint"),
		Test = Instance.new("TextButton"),
		UICorner_3 = Instance.new("UICorner"),
		ImageLabel_2 = Instance.new("ImageLabel"),
		AspectRatio_3 = Instance.new("UIAspectRatioConstraint"),
		AspectRatio_4 = Instance.new("UIAspectRatioConstraint"),
		Image_3 = Instance.new("ImageLabel"),
		AspectRatio_5 = Instance.new("UIAspectRatioConstraint"),
		Title = Instance.new("TextLabel"),
		AspectRatio_6 = Instance.new("UIAspectRatioConstraint"),
		AspectRatio_7 = Instance.new("UIAspectRatioConstraint"),
	}

	Instances.ItemTemplate.Name = "ItemTemplate"
	Instances.ItemTemplate.AnchorPoint = Vector2.new(0.5, 0.5)
	Instances.ItemTemplate.Size = UDim2.new(0.41, 0, 0.29, 0)
	Instances.ItemTemplate.BorderColor3 = Color3.new(0, 0, 0)
	Instances.ItemTemplate.Position = UDim2.new(0.21, 0, 0.14, 0)
	Instances.ItemTemplate.BorderSizePixel = 0
	Instances.ItemTemplate.BackgroundColor3 = Color3.new(0.1, 0.07, 0.06)

	Instances.UICorner.Name = "UICorner"
	Instances.UICorner.CornerRadius = UDim.new(0.14, 0)
	Instances.UICorner.Parent = Instances.ItemTemplate

	Instances.UIStroke.Name = "UIStroke"
	Instances.UIStroke.Color = Color3.new(0.52, 0.45, 0.43)
	Instances.UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Instances.UIStroke.Transparency = 0.8
	Instances.UIStroke.Parent = Instances.ItemTemplate

	Instances.Buy.Name = "Buy"
	Instances.Buy.AnchorPoint = Vector2.new(0.5, 0.5)
	Instances.Buy.Size = UDim2.new(0.2, 0, 0.3, 0)
	Instances.Buy.BorderColor3 = Color3.new(0, 0, 0)
	Instances.Buy.Position = UDim2.new(0.88, 0, 0.78, 0)
	Instances.Buy.BorderSizePixel = 0
	Instances.Buy.BackgroundColor3 = Color3.new(0.91, 0.74, 0.7)
	Instances.Buy.FontFace =
		Font.new("rbxassetid://11702779517", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	Instances.Buy.TextColor3 = Color3.new(1, 0.86, 0.82)
	Instances.Buy.Text = ""
	Instances.Buy.TextWrapped = true
	Instances.Buy.Parent = Instances.ItemTemplate

	Instances.UICorner_2.Name = "UICorner"
	Instances.UICorner_2.CornerRadius = UDim.new(1, 0)
	Instances.UICorner_2.Parent = Instances.Buy

	Instances.ImageLabel.Name = "ImageLabel"
	Instances.ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	Instances.ImageLabel.Size = UDim2.new(0.33, 0, 0.59, 0)
	Instances.ImageLabel.BorderColor3 = Color3.new(0, 0, 0)
	Instances.ImageLabel.BackgroundTransparency = 1
	Instances.ImageLabel.Position = UDim2.new(0.49, 0, 0.53, 0)
	Instances.ImageLabel.BorderSizePixel = 0
	Instances.ImageLabel.BackgroundColor3 = Color3.new(1, 1, 1)
	Instances.ImageLabel.ImageColor3 = Color3.new(0.27, 0.16, 0.13)
	Instances.ImageLabel.Image = "rbxassetid://10734896206"
	Instances.ImageLabel.Parent = Instances.Buy

	Instances.AspectRatio.Name = "AspectRatio"
	Instances.AspectRatio.Parent = Instances.ImageLabel

	Instances.AspectRatio_2.Name = "AspectRatio"
	Instances.AspectRatio_2.AspectRatio = 1.79
	Instances.AspectRatio_2.Parent = Instances.Buy

	Instances.Test.Name = "Test"
	Instances.Test.AnchorPoint = Vector2.new(0.5, 0.5)
	Instances.Test.ZIndex = 3
	Instances.Test.Size = UDim2.new(0.11, 0, 0.3, 0)
	Instances.Test.BorderColor3 = Color3.new(0, 0, 0)
	Instances.Test.BackgroundTransparency = 1
	Instances.Test.Position = UDim2.new(0.69, 0, 0.78, 0)
	Instances.Test.BorderSizePixel = 0
	Instances.Test.BackgroundColor3 = Color3.new(0.27, 0.16, 0.13)
	Instances.Test.FontFace =
		Font.new("rbxassetid://11702779517", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	Instances.Test.TextColor3 = Color3.new(1, 1, 1)
	Instances.Test.Text = ""
	Instances.Test.Parent = Instances.ItemTemplate

	Instances.UICorner_3.Name = "UICorner"
	Instances.UICorner_3.CornerRadius = UDim.new(1, 0)
	Instances.UICorner_3.Parent = Instances.Test

	Instances.ImageLabel_2.Name = "ImageLabel"
	Instances.ImageLabel_2.AnchorPoint = Vector2.new(0.5, 0.5)
	Instances.ImageLabel_2.Size = UDim2.new(0.5, 0, 0.5, 0)
	Instances.ImageLabel_2.BorderColor3 = Color3.new(0, 0, 0)
	Instances.ImageLabel_2.BackgroundTransparency = 1
	Instances.ImageLabel_2.Position = UDim2.new(0.5, 0, 0.5, 0)
	Instances.ImageLabel_2.BorderSizePixel = 0
	Instances.ImageLabel_2.BackgroundColor3 = Color3.new(0.45, 0.21, 0.14)
	Instances.ImageLabel_2.ImageColor3 = Color3.new(1, 0.86, 0.82)
	Instances.ImageLabel_2.Image = "rbxassetid://10734883986"
	Instances.ImageLabel_2.Parent = Instances.Test

	Instances.AspectRatio_3.Name = "AspectRatio"
	Instances.AspectRatio_3.AspectRatio = 0.98
	Instances.AspectRatio_3.Parent = Instances.ImageLabel_2

	Instances.AspectRatio_4.Name = "AspectRatio"
	Instances.AspectRatio_4.AspectRatio = 0.98
	Instances.AspectRatio_4.Parent = Instances.Test

	Instances.Image_3.Name = "Image"
	Instances.Image_3.AnchorPoint = Vector2.new(0.5, 0.5)
	Instances.Image_3.Size = UDim2.new(0.25, 0, 0.69, 0)
	Instances.Image_3.BorderColor3 = Color3.new(0, 0, 0)
	Instances.Image_3.BackgroundTransparency = 1
	Instances.Image_3.Position = UDim2.new(0.21, 0, 0.5, 0)
	Instances.Image_3.BorderSizePixel = 0
	Instances.Image_3.BackgroundColor3 = Color3.new(1, 1, 1)
	Instances.Image_3.Image = "rbxassetid://86354301652315"
	Instances.Image_3.Parent = Instances.ItemTemplate

	Instances.AspectRatio_5.Name = "AspectRatio"
	Instances.AspectRatio_5.AspectRatio = 0.99
	Instances.AspectRatio_5.Parent = Instances.Image_3

	Instances.Title.Name = "Title"
	Instances.Title.AnchorPoint = Vector2.new(0.5, 0.5)
	Instances.Title.Size = UDim2.new(0.6, 0, 0.23, 0)
	Instances.Title.BorderColor3 = Color3.new(0, 0, 0)
	Instances.Title.BackgroundTransparency = 1
	Instances.Title.Position = UDim2.new(0.68, 0, 0.26, 0)
	Instances.Title.BorderSizePixel = 0
	Instances.Title.BackgroundColor3 = Color3.new(1, 1, 1)
	Instances.Title.FontFace =
		Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	Instances.Title.RichText = true
	Instances.Title.TextColor3 = Color3.new(0.95, 0.87, 0.85)
	Instances.Title.Text = 'Item<br/><font weight="Regular"><font transparency="0.5">$20</font></font>'
	Instances.Title.TextXAlignment = Enum.TextXAlignment.Left
	Instances.Title.Parent = Instances.ItemTemplate

	Instances.AspectRatio_6.Name = "AspectRatio"
	Instances.AspectRatio_6.AspectRatio = 7.1
	Instances.AspectRatio_6.Parent = Instances.Title

	Instances.AspectRatio_7.Name = "AspectRatio"
	Instances.AspectRatio_7.AspectRatio = 2.75
	Instances.AspectRatio_7.Parent = Instances.ItemTemplate

	Instances.ItemTemplate = ancestor or ReplicatedStorage

	return Instances.ItemTemplate :: any
end

function market:Unload()
	for _, item in ipairs(itemHolder:GetChildren()) do
		if item and item:IsA("Frame") then
			item:Destroy()

			if market.limit.count_map[item] then
				market.limit.count_map[item] = nil
			end

			RunService.Heartbeat:Wait()
		end
	end
end

function market:DisplaySpendings(profile: typemarshaller.Profile)
	local prisms = tonumber(profile and profile.Data.prisms)

	if prisms then
		local counter = markdown.text_counter.new({
			to = tonumber(profile and profile.Data.prisms) or 0,
			from = 0,
			direction = "up",
			delay = 0,
			duration = 2,
			label = money_label,
			separator = " ",
		})
		counter:Start()

		counter.completed:Wait()

		task.defer(counter.Destroy, counter)
	else
		money_label.Text = "?"
	end
end

function market:LoadItems(items: Items.dataType?)
	market:Unload()

	items = items or Items

	for i, item in pairs(items) do
		local template = createTemplate(itemHolder)
		template:SetAttribute("name_", item.Name)

		shadow(template)

		local title = template.Title

		local purchaseButton = template.Buy
		local experimentButton = template.Test

		title.Text = item.Name
			.. [[<br/>
			<font weight="Regular">
			<font transparency="0.5">]]
			.. item.Price
			.. [[</font></font>]]

		template.Visible = true
		purchaseButton.AutoButtonColor = false

		if item.ExperimentsEnabled then
			experimentButton.Visible = true

			experimentButton.MouseButton1Click:Connect(function()
				print("Testing card: " .. item.Name)
				-- ts dont work yet lmao
				-- but lets add a function
				if not player then
					return
				end

				local placeId = 90845913624517 -- Match

				safeteleport(placeId, player, {
					reserve_server = true,
					data = {
						identification1 = player.UserId,
						testing_card = {
							item,
						},
					},
				})
			end)
		else
			experimentButton.Visible = false
		end

		print("setting up buttons")

		local icon = purchaseButton:FindFirstChildOfClass("ImageLabel")
		if icon then
			icon.ImageContent = Content.fromAssetId(10734924532)
			wiggle(icon)
		end

		purchaseButton.MouseEnter:Connect(function()
			--audio:SFX("hover")
		end)
		purchaseButton.MouseLeave:Connect(function()
			--audio:SFX("leave")
		end)
		purchaseButton.MouseButton1Click:Connect(function()
			if not market.limit(template) then
				print("cooldown")

				return
			end

			print("Purchasing card: " .. item.Name)

			Packet.BuyCard.send({ cardName = item.Name })

			pop(purchaseButton)

			--audio:SFX("success")

			confetti({
				Color3.fromRGB(255, 0, 255),
				Color3.fromRGB(0, 255, 255),
				Color3.fromRGB(255, 255, 0),
				Color3.fromRGB(255, 0, 0),
				Color3.fromRGB(0, 255, 0),
				Color3.fromRGB(0, 0, 255),
			}, shopCanvas, true)
		end)
	end

	print("done")
end

function market:LoadInventory(profile: typemarshaller.Profile)
	market:unload()

	if not profile then
		print("no profile to load inventory")
		return
	end

	local items = profile.Data.cards

	for i, item in pairs(items :: { [string]: number }) do
		local template = market.template:Clone()
		template:SetAttribute("name: ", i)
		template.Parent = itemHolder

		shadow(template)

		local title = template.Title

		local sell_btn = template.Buy
		local experimentButton = template.Test

		title.Text = i
			.. [[<br/>
			<font weight="Regular">
			<font transparency="0.5">]]
			.. item
			.. [[</font></font>]]

		template.Visible = true
		experimentButton.Visible = false

		print("setting up buttons")

		local icon = sell_btn:FindFirstChildOfClass("ImageLabel")
		if icon then
			icon.ImageContent = Content.fromAssetId(10734896206)
		end

		template:SetAttribute("Tooltip", "Careful to accidentally sell your Card!")

		sell_btn.MouseButton1Click:Connect(function()
			if not market.limit(template) then
				print("sell cooldown")

				return
			end

			Packet.SellCard.send({ cardName = i, playerInstance = player })
			--notify.success("Sold Card", `Successfully sold card`, 5, "success")

			local value = Items[i].Price or 1
			local floor = math.floor(value / 10)

			prism_awarder.award(floor, true)
		end)

		ripple:Watch(sell_btn)
	end
end

return market
