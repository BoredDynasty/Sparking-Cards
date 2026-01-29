--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local Items = require(ReplicatedStorage.Market.Items)
local Packet = require(ReplicatedStorage.Packet)
local confetti = require(StarterPlayer.StarterPlayerScripts.Interface.confetti)
local hint = require(StarterPlayer.StarterPlayerScripts.Components.hint)
local pop = require(StarterPlayer.StarterPlayerScripts.Interface.pop)
local prism_awarder = require(StarterPlayer.StarterPlayerScripts.Gameplay["prism-awarder"])
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local safeteleport = require(ReplicatedStorage.Modules.safeteleport)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local text_counter = require(ReplicatedStorage.ClientModules.markdown["text-counter"])
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)
local wiggle = require(StarterPlayer.StarterPlayerScripts.Interface.wiggle)

-- market.luau

local player = Players.LocalPlayer
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

local template = shopFolder.ItemTemplate

local limit = ratelimit(1, 0.5)

local market = {}

local function createTemplate()
	return template:Clone()
end

function market:Unload()
	for _, item in ipairs(itemHolder:GetChildren()) do
		if item and item:IsA("Frame") then
			task.spawn(function()
				item:Destroy()

				if limit.count_map[item] then
					limit.count_map[item] = nil
				end
			end)
		end
	end
end

function market:DisplaySpendings(profile: typemarshaller.Profile)
	local prisms = tonumber(profile and profile.Data.prisms)

	if prisms then
		task.spawn(function()
			local counter = text_counter.new(money_label, prisms, 3)
			counter:Start(counter)
		end)
	else
		money_label.Text = "?"
	end
end

function market:LoadItems(items: Items.dataType?)
	market:Unload()

	items = items or Items

	-- hint.new():SetText("Loading Shop Items..."):SetCanClick(false)

	for i, item in pairs(items) do
		local template = createTemplate(itemHolder)
		template.Parent = itemHolder
		template:SetAttribute("name_", item.Name)

		task.spawn(shadow, template)

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
			end)
		else
			experimentButton.Visible = false
		end

		print("setting up buttons")

		task.spawn(function()
			local icon = purchaseButton:FindFirstChildOfClass("ImageLabel")
			if icon then
				icon.ImageContent = Content.fromAssetId(10734924532)

				wiggle(icon)
			end
		end)

		purchaseButton.MouseEnter:Connect(function()
			--audio:SFX("hover")
		end)
		purchaseButton.MouseLeave:Connect(function()
			--audio:SFX("leave")
		end)
		purchaseButton.MouseButton1Click:Connect(function()
			if not limit(template) then
				print("cooldown")

				return
			end

			print("Purchasing card: " .. item.Name)

			Packet.BuyCard.send({ card_name = item.Name })

			pop(purchaseButton)

			--audio:SFX("success")
		end)
	end

	print("done")
end

function market:LoadInventory(profile: typemarshaller.Profile)
	market:Unload()

	if not profile then
		print("no profile to load inventory")

		return
	end

	local items = profile.Data.cards

	for i, item in pairs(items :: { [string]: number }) do
		local template = createTemplate()
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

		task.spawn(function()
			local icon = sell_btn:FindFirstChildOfClass("ImageLabel")
			if icon then
				icon.ImageContent = Content.fromAssetId(10734896206)
			end
		end)

		sell_btn.MouseButton1Click:Connect(function()
			if not limit(template) then
				print("sell cooldown")

				return
			end

			Packet.SellCard.send({ card_name = i })
			--notify.success("Sold Card", `Successfully sold card`, 5, "success")

			local value = Items[i].Price or 1
			local floor = math.floor(value / 10)

			prism_awarder.award(floor, true)
		end)
	end
end

return market
