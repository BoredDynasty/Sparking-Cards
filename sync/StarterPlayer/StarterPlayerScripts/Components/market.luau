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
local fetchProfile = require(StarterPlayer.StarterPlayerScripts.Utilities.fetchProfile)
local future = require(ReplicatedStorage.Packages.future)
local hint = require(StarterPlayer.StarterPlayerScripts.Components.hint)
local hydration = require(ReplicatedStorage.Utility.hydration)
local lucide = require(ReplicatedStorage.Packages.lucide)
local navigation_rail = require(StarterPlayer.StarterPlayerScripts.Components["navigation-rail"])
local observer = require(ReplicatedStorage.Utility.observer)
local pop = require(StarterPlayer.StarterPlayerScripts.Interface.pop)
local prism_awarder = require(StarterPlayer.StarterPlayerScripts.Gameplay["prism-awarder"])
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local ripple = require(StarterPlayer.StarterPlayerScripts.Interface.ripple)
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

local navigation = navigation_rail.new()

local profile = fetchProfile()

local events = ReplicatedStorage.Events

local pool = PoolerPlus:CreatePool("MarketPool", function()
	return template:Clone()
end, function(object: Frame)
	object.Visible = false

	if limit.count_map[object] then
		limit.count_map[object] = nil
	end
end, function(object: Frame)
	future.Try(object.Destroy, object)
end)

pool:AdaptivePreload()

function module:Unload()
	pool:ReturnAll()
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

function module:StartNavigation()
	navigation:Button("Home", lucide.GetAsset("home"), function()
		-- this is already running along the main thread
		market:LoadItems()
	end)
	navigation:Button("Inventory", lucide.GetAsset("backpack"), function()
		market:LoadInventory()
	end)

	navigation:SetAdornee(shopGui)
	navigation:SetActionIcon(lucide.GetAsset("ticket"))
	navigation:Render()
end

function module:GetNavigation()
	return navigation
end

function module:LoadItems<K, V>(items)
	pool:ReturnAll()

	items = items or Items

	print("shop")

	profile = fetchProfile()

	for i, item in pairs(items) do
		local template = pool:Get()
		template.Visible = true
		template:SetAttribute("name_", item.Name)

		-- variables
		local quantity = observer.new(1) :: observer.Observer<number>
		local is_bookmarked = observer.new(false) :: observer.Observer<boolean>
		print("shop")

		-- find the item in player bookmarks

		future.Try(function()
			if profile then
				local j = table.find(profile.Data.bookmarked_shop_items, item.Name)
				if j then
					is_bookmarked:Set(true)
				end
			end
		end)
		print("shop")

		local title = template.Title
		local description = template.Description

		local purchaseButton = template.Buy
		local experimentButton = template.Test

		title.Text = item.Name
			.. [[<br/>
			<font weight="Regular">
			<font transparency="0.5">]]
			.. item.Price
			.. [[</font></font>]]

		quantity.Changed:Connect(function()
			local new_quantity = quantity:Get()

			title.Text = item.Name
				.. [[<br/>
			<font weight="Regular">
			<font transparency="0.5">$]]
				.. item.Price
				.. [[ > $]]
				.. item.Price * new_quantity
				.. [[</font></font>]]
		end)
		print("shop")

		template.Visible = true

		-- format the description

		description.Text = `"{item.Details.MovesetName}"`
		description.TextColor3 = item.Details.TextColor

		purchaseButton.AutoButtonColor = false
		print("shop")

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
					local content = Content.fromAssetId(10709782044)

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
					local content = Content.fromAssetId(10709782044)

					bookmark_button.ImageLabel.ImageContent = content
				else
					local content = Content.fromAssetId(10709781919)

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
		print("shop")

		-- quantity system

		local quantity_frame = template.Quantity

		-- automagically updates text!
		hydration(quantity_frame.TextLabel) {
			Text = quantity,
		}
		print("shop")

		local quantity_add = quantity_frame:WaitForChild("Add")
		local quantity_remove = quantity_frame:WaitForChild("Remove")

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
		print("shop")

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

			pop(purchaseButton)

			ripple(purchaseButton)

			audio:PlaySFX("click")

			module:DisplaySpendings()
		end)

		template.AncestryChanged:Connect(function(k, new)
			if new ~= itemHolder then
				-- cleanup the observers

				quantity:Destroy()
				is_bookmarked:Destroy()
			end
		end)
		print("shop")

		template.Parent = itemHolder
	end

	--print("done")
end

function module:LoadInventory()
	pool:ReturnAll()

	profile = fetchProfile()

	if not profile then
		local snackbar = hint.new()
		snackbar:SetText("Couldn't fetch inventory.")
		snackbar:SetCanClick(true)
		snackbar:SetAction(function()
			module:LoadInventory()
		end, "Retry")

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

		local str = [[
			%s
			<br/>
			<font weight="Regular">
			<font transparency="0.5"
			%s
			</font></font>
		]]

		title.Text = string.format(str :: any, i, item)

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

		quantity_frame.Add.Activated:Connect(function()
			if not alter_quantity_limit(quantity_frame.Add) then
				return
			end

			audio:PlaySFX("hover")
		end)

		quantity_frame.Remove.Activated:Connect(function()
			if not alter_quantity_limit(quantity_frame.Remove) then
				return
			end

			audio:PlaySFX("hover")
		end)

		quantity_frame.Remove.MouseEnter:Connect(function()
			audio:PlaySFX("hover")
		end)

		quantity_frame.Remove.MouseLeave:Connect(function()
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
				Packet.BuyCard.send({ card_name = item.Name })
			end
			--notify.success("Sold Card", `Successfully sold card`, 5, "success")

			local value = Items[i].Price
			local floor = math.floor(value / 10)

			prism_awarder.award(floor, true)

			module:DisplaySpendings()
		end)

		template.AncestryChanged:Connect(function(k, new)
			if new ~= itemHolder then
				-- cleanup the observer

				quantity:Destroy()
			end
		end)
		template.Parent = itemHolder
	end
end

return module
