--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local Items = require(ReplicatedStorage.Market.Items)
local Packet = require(ReplicatedStorage.Packet)
local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local audio = require(ReplicatedStorage.Modules.audio)
local confetti = require(StarterPlayer.StarterPlayerScripts.Interface.confetti)
local fade = require(StarterPlayer.StarterPlayerScripts.Interface.fade)
local fetchProfile = require(StarterPlayer.StarterPlayerScripts.Utilities.fetchProfile)
local future = require(ReplicatedStorage.Packages.future)
local hint = require(StarterPlayer.StarterPlayerScripts.Components.hint)
local hydration = require(ReplicatedStorage.Utility.hydration)
local lucide = require(ReplicatedStorage.Packages.lucide)
local observer = require(ReplicatedStorage.Utility.observer)
local pop = require(StarterPlayer.StarterPlayerScripts.Interface.pop)
local prism_awarder = require(StarterPlayer.StarterPlayerScripts.Gameplay["prism-awarder"])
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local ripple = require(StarterPlayer.StarterPlayerScripts.Interface.ripple)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local tab = require(StarterPlayer.StarterPlayerScripts.Components.tab)
local text_counter = require(ReplicatedStorage.ClientModules.markdown["text-counter"])
local tooltip = require(StarterPlayer.StarterPlayerScripts.Components.tooltip)

-- market.luau

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local templates = ReplicatedStorage.Interfaces

local shopGui = playerGui.Shop
local shopCanvas = shopGui.CanvasGroup
local shopFrame = shopCanvas.Frame

local itemHolder = shopFrame.Holder
local shopFolder = templates.Shop
local spendings = shopFrame.Spendings

local money_label = spendings.Amount

local template = shopFolder.ItemTemplate

local limit = ratelimit(3, 0.5)
local alter_quantity_limit = ratelimit(5, 0.5)
local bookmark_limit = ratelimit(1, 1)

local module = {}

shadow(template)

local tabs = tab.new(shopFrame.Tabs.TabHolder)

local profile = fetchProfile()

local events = ReplicatedStorage.Events

local pool = PoolerPlus:CreatePool("MarketPool", function()
	return template:Clone()
end)

pool:AdaptivePreload()

function module:Unload()
	local active = pool:GetActiveObjects()
	for i, frame in ipairs(active) do
		frame:Destroy()
	end
end

function module:DisplaySpendings()
	money_label.Text = "..."

	profile = fetchProfile()

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

local ignore_tab_switch = false

function module:InitializeTabs()
	tabs:AddTab("Shop")
	tabs:AddTab("Inventory")

	tabs:SelectTab("Shop")

	tabs.Changed:Connect(function(name)
		if name == "Shop" then
			self:LoadItems()
		elseif name == "Inventory" then
			self:LoadInventory()
		end
	end)
end

function module:LoadItems<K, V>(items)
	module:Unload()

	items = items or Items

	profile = fetchProfile()

	for i, item in pairs(items) do
		local template = pool:Get()
		template.Visible = true
		template:SetAttribute("name_", item.Name)

		-- variables
		-- TODO) figure out an effective way to get rid of these observers so no memory leak
		local quantity = observer.new(1) :: observer.Observer<number>
		local is_bookmarked = observer.new(false) :: observer.Observer<boolean>

		-- find the item in player bookmarks

		future.Try(function()
			if profile then
				local j = table.find(profile.Data.bookmarked_shop_items, item.Name)
				if j then
					is_bookmarked:Set(true)
				end
			end
		end)

		local title = template.Title
		local description = template.Description

		local purchaseButton = template.Buy
		local experimentButton = template.Test

		local title_str = [[
			%s<br/><font weight="Regular"><font transparency="0.5">$%s</font></font>
		]]

		title.Text = string.format(title_str :: any, item.Name, item.Price)

		quantity.Changed:Connect(function()
			local new_quantity = quantity:Get()

			local price = math.floor(item.Price * new_quantity) + 0.99

			task.spawn(function()
				profile = fetchProfile()
				if not profile then
					return
				end

				local prisms = profile.Data.prisms

				local remaining_balance = prisms - price
				if remaining_balance <= 0 then
					-- let the player know they're too BROKE to afford this card.

					local snackbar = hint.new()
					snackbar:SetText("You're too broke to afford this.")
					snackbar:SetExpiry(1)
					audio:PlayVariation("cancel", 1)
				end
			end)

			if price == item.Price then
				title.Text = string.format(title_str :: any, item.Name, price)
			else
				title.Text = string.format(title_str :: any, item.Name, item.Price .. " > " .. price)
			end
		end)

		template.Visible = true

		-- format the description

		description.Text = `"{item.Details.MovesetName}"`
		description.TextColor3 = item.Details.TextColor

		purchaseButton.AutoButtonColor = false

		if item.ExperimentsEnabled then
			experimentButton.Visible = true

			experimentButton.Activated:Connect(function()
				--print("Testing card: " .. item.Name)
				-- ts dont work yet lmao
				-- but lets add a function
				if not player then
					return
				end
			end)
		else
			experimentButton.Visible = false
		end

		-- bookmark system

		local bookmark_button = template.Bookmark

		bookmark_button.MouseEnter:Connect(function()
			task.spawn(function()
				if not is_bookmarked:Get() then
					local content = Content.fromAssetId(10709782154)

					bookmark_button.ImageLabel.ImageContent = content
				else
					local content = Content.fromAssetId(10709781919)

					bookmark_button.ImageLabel.ImageContent = content
				end
			end)
		end)

		bookmark_button.MouseLeave:Connect(function()
			task.spawn(function()
				if not is_bookmarked:Get() then
					local content = Content.fromAssetId(10709782154)

					bookmark_button.ImageLabel.ImageContent = content
				else
					local content = Content.fromAssetId(10709782044)

					bookmark_button.ImageLabel.ImageContent = content
				end
			end)
		end)

		bookmark_button.Activated:Connect(function()
			if not bookmark_limit(bookmark_button) then
				return
			end

			is_bookmarked:Map(function(current)
				return not current
			end)

			-- toggle bookmark on the server

			events.BookmarkShopCard:InvokeServer(item.Name)
		end)

		-- quantity system

		local quantity_frame = template.Quantity

		-- automagically updates text!
		hydration(quantity_frame.TextLabel) {
			Text = quantity,
		}

		local quantity_add = quantity_frame:WaitForChild("Add")
		local quantity_remove = quantity_frame:WaitForChild("Remove")

		--tooltip.register(quantity_add, "Increase quantity")
		--tooltip.register(quantity_remove, "Decrease quantity")

		quantity_add.Activated:Connect(function()
			future.Try(function()
				if not alter_quantity_limit(quantity_frame.Add) then
					return
				end

				quantity:Map(function(current)
					return math.clamp(current + 1, 1, 1000)
				end)

				pop(quantity_add)

				audio:PlaySFX("continue")
			end)
		end)

		quantity_remove.Activated:Connect(function()
			future.Try(function()
				if not alter_quantity_limit(quantity_frame.Add) then
					return
				end

				if quantity:Get() == 1 then
					audio:PlayVariation("wood-block", 3)

					print("attempted setting quantity below 1")
				end

				quantity:Map(function(current)
					return math.clamp(current - 1, 1, 1000)
				end)

				pop(quantity_remove)

				audio:PlaySFX("continue")
			end)
		end)

		quantity_remove.MouseEnter:Connect(function()
			audio:PlaySFX("hover")
		end)

		quantity_remove.MouseLeave:Connect(function()
			audio:PlaySFX("leave")
		end)

		quantity_add.MouseEnter:Connect(function()
			audio:PlaySFX("hover")
		end)

		quantity_add.MouseLeave:Connect(function()
			audio:PlaySFX("leave")
		end)

		purchaseButton.MouseEnter:Connect(function()
			audio:PlaySFX("hover")
		end)

		purchaseButton.MouseLeave:Connect(function()
			audio:PlaySFX("leave")
		end)

		purchaseButton.Activated:Connect(function()
			if not limit(template) then
				--print("cooldown")

				return
			end

			--print("Purchasing card: " .. item.Name)

			for k = 1, quantity:Get() do
				Packet.BuyCard.send({ card_name = item.Name })
			end

			confetti(nil, shopCanvas)

			pop(purchaseButton)

			ripple(purchaseButton)

			audio:PlaySFX("click")

			module:DisplaySpendings()
		end)

		template.AncestryChanged:Connect(function(k, new)
			if new ~= itemHolder then
				-- cleanup the observers

				future.Try(function()
					quantity:Destroy()
					is_bookmarked:Destroy()
				end)
			end
		end)

		template.Parent = itemHolder
	end

	--print("done")
end

function module:LoadInventory()
	module:Unload()

	profile = fetchProfile()

	if not profile then
		local snackbar = hint.new()
		future.Try(function()
			snackbar:SetText("Couldn't fetch inventory.")
			snackbar:SetCanClick(true)
			snackbar:SetAction(function()
				module:LoadInventory()
			end, "Retry")
		end)

		return
	end

	local items = profile.Data.cards :: { [string]: number }

	for i, item in pairs(items) do
		if item <= 0 then
			continue
		end

		local quantity = observer.new(1) :: observer.Observer<number>

		local template = pool:Get()
		template:SetAttribute("name_", i)
		template.Visible = true

		local bookmark_button = template.Bookmark

		bookmark_button.Visible = false

		local title = template.Title
		template.Description.Visible = false

		local sell_btn = template.Buy
		local experimentButton = template.Test

		local item_data = Items[item]
		if not item_data then
			warn("Couldn't find item data for " .. i)
			item_data = {
				Name = i,
				Price = 0,
				Details = {
					TextColor = Color3.new(1, 1, 1),
				},
			}
		end
		local title_color = item_data.Details.TextColor

		local str =
			'<font color="%s">%s</font><br/><font weight="Regular"><font transparency="0.5">%s</font></font>'

		title.Text = string.format(str :: any, "#" .. title_color:ToHex(), i, item)

		template.Visible = true
		experimentButton.Visible = false

		--print("setting up buttons")

		task.spawn(function()
			local icon = sell_btn:FindFirstChildOfClass("ImageLabel")
			if icon then
				icon.ImageContent = Content.fromAssetId(10734908626)
			end
		end)

		local quantity_frame = template.Quantity

		hydration(quantity_frame.TextLabel) {
			Text = quantity,
		}

		local quantity_add = quantity_frame:WaitForChild("Add")
		local quantity_remove = quantity_frame:WaitForChild("Remove")

		quantity_add.Activated:Connect(function()
			if not alter_quantity_limit(quantity_frame.Add) then
				return
			end

			local max = 1000
			max = profile.Data.cards[i]

			if quantity:Get() == max then
				audio:PlayVariation("cancel", 1)

				print("attempted setting quantity over max")

				fade.fade(
					quantity_frame.Remove.ImageLabel,
					{ duration = 0.5, transparency = { start = 0.5, target = 1 } }
				)
			end

			quantity:Map(function(current)
				return math.clamp(current + 1, 1, max)
			end)

			audio:PlaySFX("hover")

			pop(quantity_frame.Add)
		end)

		quantity_remove.Activated:Connect(function()
			if not alter_quantity_limit(quantity_frame.Remove) then
				return
			end

			if quantity:Get() == 1 then
				audio:PlayVariation("cancel", 1)

				print("attempted setting quantity below 1")

				fade.fade(quantity_frame.Remove.ImageLabel, {
					duration = 0.5,
					transparency = { start = quantity_frame.Remove.ImageLabel.Transparency, target = 0.5 },
				})
			end

			quantity:Map(function(current)
				return math.clamp(current - 1, 1, 1000)
			end)

			audio:PlaySFX("hover")

			pop(quantity_frame.Remove)
		end)

		local remove_btn = quantity_frame:FindFirstChild("Remove")
		-- we gotta do this because `Instance.Remove` == function

		remove_btn.MouseEnter:Connect(function()
			audio:PlaySFX("hover")
		end)

		remove_btn.MouseLeave:Connect(function()
			audio:PlaySFX("leave")
		end)

		quantity_frame.Add.MouseEnter:Connect(function()
			audio:PlaySFX("hover")
		end)

		quantity_frame.Add.MouseLeave:Connect(function()
			audio:PlaySFX("leave")
		end)

		sell_btn.MouseEnter:Connect(function()
			audio:PlaySFX("hover")
		end)

		sell_btn.MouseLeave:Connect(function()
			audio:PlaySFX("leave")
		end)

		sell_btn.Activated:Connect(function()
			if not limit(template) then
				--print("sell cooldown")

				return
			end

			for j = 1, quantity:Get() do
				Packet.SellCard.send({ card_name = i })
			end
			--notify.success("Sold Card", `Successfully sold card`, 5, "success")

			local value = Items[item].Price
			local floor = math.floor(value / 10)

			prism_awarder.award(floor, true)

			module:DisplaySpendings()
		end)

		template.AncestryChanged:Connect(function(k, new)
			if new ~= itemHolder then
				-- cleanup the observer

				future.Try(quantity.Destroy, quantity)
			end
		end)
		template.Parent = itemHolder
	end
end

print(events.GetGamepasses:InvokeServer())

return module
