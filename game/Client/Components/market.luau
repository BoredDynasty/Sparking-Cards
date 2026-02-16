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
local future = require(ReplicatedStorage.Packages.future)
local hint = require(StarterPlayer.StarterPlayerScripts.Components.hint)
local lucide = require(ReplicatedStorage.Packages.lucide)
local navigation_rail = require(StarterPlayer.StarterPlayerScripts.Components["navigation-rail"])
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

local itemHolder = shopFrame.Holder
local shopFolder = templates.Shop
local spendings = shopFrame.Spendings

local money_label = spendings.Amount

local template = shopFolder.ItemTemplate

local limit = ratelimit(1, 0.5)

local market = {}

shadow(template)

local function expectProfile(): typemarshaller.Profile
	local fut = future.new(function()
		return get_profile:InvokeServer() :: typemarshaller.Profile
	end)

	repeat
		task.wait(1)
	--print("pending profile fetch")
	until not fut:IsPending()

	local result = fut:Unwrap()

	--[[
	if not result and RunService:IsStudio() then
		result = { Data = profilestructure }
	end
	--]]

	return result
end

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

function market:Unload()
	pool:ReturnAll()
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

function market:StartNavigation()
	local navigation = navigation_rail.new()
	navigation:Button("Home", lucide.GetAsset("home"), function()
		-- this is already running along the main thread
		market:LoadItems()
	end)
	navigation:Button("Inventory", lucide.GetAsset("backpack"), function()
		market:LoadInventory(expectProfile())
	end)

	navigation:SetActionIcon(lucide.GetAsset("ticket"))
	navigation:Render()
end

function market:LoadItems<K, V>(items)
	pool:ReturnAll()

	items = items or Items

	for i, item in pairs(items) do
		local template = pool:Get()
		template.Visible = true
		template:SetAttribute("name_", item.Name)

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

		--print("setting up buttons")

		task.spawn(function()
			local icon = purchaseButton:FindFirstChildOfClass("ImageLabel")
			if icon then
				icon.ImageContent = Content.fromAssetId(10734924532)

				wiggle(icon)
			end
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

			Packet.BuyCard.send({ card_name = item.Name })

			pop(purchaseButton)

			audio:PlaySFX("click")
		end)

		template.Parent = itemHolder
	end

	--print("done")
end

function market:LoadInventory(profile: typemarshaller.Profile)
	pool:ReturnAll()

	if not profile then
		--print("no profile to load inventory")

		return
	end

	local items = profile.Data.cards

	for i, item in pairs(items) do
		if item <= 0 then
			continue
		end

		local template = pool:Get()
		template:SetAttribute("name_", i)
		template.Parent = itemHolder
		template.Visible = true

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

		--print("setting up buttons")

		task.spawn(function()
			local icon = sell_btn:FindFirstChildOfClass("ImageLabel")
			if icon then
				icon.ImageContent = Content.fromAssetId(10734896206)
			end
		end)

		sell_btn.Activated:Connect(function()
			if not limit(template) then
				--print("sell cooldown")

				return
			end

			Packet.SellCard.send({ card_name = i })
			--notify.success("Sold Card", `Successfully sold card`, 5, "success")

			local value = Items[i].Price
			local floor = math.floor(value / 10)

			prism_awarder.award(floor, true)
		end)
	end
end

return market
