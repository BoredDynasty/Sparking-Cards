--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local Items = require(ReplicatedStorage.Market.Items)
local Packet = require(ReplicatedStorage.Packet)
local TextPlus = require(ReplicatedStorage.Utility.TextPlus)
local audio = require(ReplicatedStorage.Modules.audio)
local characterIteration = require(ReplicatedStorage.ClientModules.characterIteration)
local confetti = require(StarterPlayer.StarterPlayerScripts.Interface.confetti)
local notify = require(script.Parent.notify)
local number_abbreviation = require(ReplicatedStorage.Modules.Serialization["number-abbreviation"])
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local pop = require(StarterPlayer.StarterPlayerScripts.Interface.pop)
local prism_awarder = require(StarterPlayer.StarterPlayerScripts.Gameplay["prism-awarder"])
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local promise = require(ReplicatedStorage.Packages.promise)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local ripple = require(StarterPlayer.StarterPlayerScripts.Interface.ripple)
local safeteleport = require(ReplicatedStorage.Modules.safeteleport)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local tooltip = require(script.Parent.tooltip)

-- market.luau

export type template = Frame & {
	Title: Frame,
	Price: Frame,
	Buy: TextButton & {
		TextHolder: Frame,
	},
	Test: TextButton,
	Tags: Frame,
}

local player = playerMarshaller.get()
local playerGui = player.PlayerGui

local templates = ReplicatedStorage:FindFirstChild("Interfaces") :: Folder

local shopGui = playerGui:WaitForChild("Shop") :: ScreenGui
local shopCanvas = shopGui:WaitForChild("CanvasGroup") :: CanvasGroup
local shopFrame = shopCanvas:WaitForChild("Frame") :: Frame

local shopNavigation = shopFrame:WaitForChild("Navigation") :: Frame
local itemHolder = shopFrame:WaitForChild("Holder") :: Frame
local shopFolder = templates:FindFirstChild("Shop") :: Folder
local spendings = shopFrame:FindFirstChild("Spendings") :: Frame

local market = {
	template = shopFolder:FindFirstChild("ItemTemplate") :: template,
	limit = ratelimit(1, 0.5),
}

function market:unload()
	for _, item in itemHolder:GetChildren() do
		if item and item:IsA("Frame") then
			item:Destroy()

			if market.limit.count_map[item] then
				market.limit.count_map[item] = nil
			end

			RunService.Heartbeat:Wait()
		end
	end

	return #(itemHolder:GetChildren()) * RunService.Heartbeat:Wait()
end

function market:display_spendings(profile: {
	Data: profilestructure.profile,
})
	local moneyFrame = spendings:FindFirstChild("Money") :: Frame

	promise.new(function()
		local text = ""

		if profile then
			text = number_abbreviation:Format(profile.Data.Prisms, "space")
		else
			text = "0"
		end

		TextPlus.Create(moneyFrame, text, {
			Font = Font.new(
				"rbxasset://fonts/families/Montserrat.json", -- Family.
				Enum.FontWeight.SemiBold, -- Weight.
				Enum.FontStyle.Normal -- Style.
			),
			Size = 16,
			Color = Color3.fromHex("#ffdbd1"),
			XAlignment = "Left",
			YAlignment = "Center",
			LineSorting = true,
			WordSorting = true,
			Dynamic = true,
		})
	end)
end

function market:load_items(items: Items.dataType?)
	local unload_time = market:unload()

	task.wait(unload_time)

	items = items or Items

	for i, item in pairs(items) do
		local template = market.template:Clone()
		template:SetAttribute("name_", item.Name)
		template.Parent = itemHolder

		shadow(template)

		local title = template.Title
		local price = template.Price

		local purchaseButton = template.Buy
		local experimentButton = template.Test

		TextPlus.Create(title, item.Name, {
			Font = Font.new(
				"rbxasset://fonts/families/Montserrat.json", -- Family.
				Enum.FontWeight.SemiBold, -- Weight.
				Enum.FontStyle.Normal -- Style.
			),
			Size = 16,
			Color = Color3.fromHex("#ffdbd1"),
			XAlignment = "Left",
			YAlignment = "Center",
			LineSorting = true,
			WordSorting = true,
			Dynamic = true,
		})
		TextPlus.Create(price, "$" .. number_abbreviation:Format(item.Price, "space"), {
			Font = Font.new(
				"rbxasset://fonts/families/Montserrat.json", -- Family.
				Enum.FontWeight.Regular, -- Weight.
				Enum.FontStyle.Normal -- Style.
			),
			Size = 12.5,
			Color = Color3.fromHex("#ffdbd1"),
			XAlignment = "Left",
			YAlignment = "Center",
			LineSorting = true,
			WordSorting = true,
			Dynamic = true,
		})

		task.spawn(function()
			characterIteration:jump(title)
			characterIteration:jump(price)
		end)

		template.Visible = true

		if item.ExperimentsEnabled ~= false then
			experimentButton.Visible = true

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

		template.Tags.Visible = false

		print("setting up buttons")

		TextPlus.Create(purchaseButton:FindFirstChild("TextHolder") :: Frame, "Purchase", {
			Font = Font.new(
				"rbxasset://fonts/families/Montserrat.json", -- Family.
				Enum.FontWeight.Bold, -- Weight.
				Enum.FontStyle.Normal -- Style.
			),
			Size = 12.5,
			Color = Color3.fromHex("#ffdbd1"),
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
			if not market.limit(template) then
				print("cooldown")

				return
			end

			print("Purchasing card: " .. item.Name)

			Packet.BuyCard.send({ cardName = item.Name })

			pop(purchaseButton)

			audio:SFX("success")

			confetti({
				Color3.fromRGB(255, 0, 255),
				Color3.fromRGB(0, 255, 255),
				Color3.fromRGB(255, 255, 0),
				Color3.fromRGB(255, 0, 0),
				Color3.fromRGB(0, 255, 0),
				Color3.fromRGB(0, 0, 255),
			}, shopCanvas, true)
		end)

		ripple:Watch(purchaseButton)
		if item.ExperimentsEnabled then
			ripple:Watch(experimentButton)
		end
	end

	print("done")
end

function market:load_inventory(profile: {
	Data: profilestructure.profile,
})
	local unload_time = market:unload()

	task.wait(unload_time)

	if not profile then
		return
	end

	local items = profile.Data.Cards

	for i, item in pairs(items :: { [string]: number }) do
		local template = market.template:Clone()
		template:SetAttribute("name: ", i)
		template.Parent = itemHolder

		shadow(template)

		local title = template.Title
		local quantity = template.Price

		local sell_btn = template.Buy
		local experimentButton = template.Test

		TextPlus.Create(title, item.Name, {
			Font = Font.new(
				"rbxasset://fonts/families/Montserrat.json", -- Family.
				Enum.FontWeight.SemiBold, -- Weight.
				Enum.FontStyle.Normal -- Style.
			),
			Size = 16,
			Color = Color3.fromHex("#ffdbd1"),
			XAlignment = "Left",
			YAlignment = "Center",
			LineSorting = true,
			WordSorting = true,
			Dynamic = true,
		})
		TextPlus.Create(quantity, number_abbreviation:Format(item, "space") .. `{i} cards.`, {
			Font = Font.new(
				"rbxasset://fonts/families/Montserrat.json", -- Family.
				Enum.FontWeight.Regular, -- Weight.
				Enum.FontStyle.Normal -- Style.
			),
			Size = 12.5,
			Color = Color3.fromHex("#ffdbd1"),
			XAlignment = "Left",
			YAlignment = "Center",
			LineSorting = true,
			WordSorting = true,
			Dynamic = true,
		})

		task.spawn(function()
			characterIteration:jump(title)
			characterIteration:jump(quantity)
		end)

		template.Visible = true
		experimentButton.Visible = false

		print("setting up buttons")

		TextPlus.Create(sell_btn.TextHolder, "Sell", {
			Font = Font.new(
				"rbxasset://fonts/families/Montserrat.json", -- Family.
				Enum.FontWeight.Bold, -- Weight.
				Enum.FontStyle.Normal -- Style.
			),
			Size = 12.5,
			Color = Color3.fromHex("#ffdbd1"),
			XAlignment = "Left",
			YAlignment = "Center",
			LineSorting = true,
			WordSorting = true,
			Dynamic = true,
		})

		template:SetAttribute("Tooltip", "Careful to accidentally sell your Card!")
		tooltip:Add(sell_btn)

		sell_btn.MouseButton1Click:Connect(function()
			if not market.limit(template) then
				print("sell cooldown")

				return
			end

			Packet.SellCard.send({ cardName = i, playerInstance = player })
			notify.success("Sold Card", `Successfully sold card`, 5, "success")

			local value = Items[i].Price or 1
			local floor = math.floor(value / 10)

			prism_awarder.award(floor, true)
		end)

		ripple:Watch(sell_btn)
	end
end

return market
