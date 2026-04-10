--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local audio = require(ReplicatedStorage.Modules.audio)
local badges = require(ReplicatedStorage.Structures.badges)
local fetchProfile = require(StarterPlayer.StarterPlayerScripts.Utilities.fetchProfile)
local future = require(ReplicatedStorage.Packages.future)
local hint = require(StarterPlayer.StarterPlayerScripts.Components.hint)
local leventine = require(ReplicatedStorage.Utility.leventine)
local pop = require(StarterPlayer.StarterPlayerScripts.Interface.pop)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local ripple = require(StarterPlayer.StarterPlayerScripts.Interface.ripple)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local spr = require(ReplicatedStorage.Modules.spr)
local tablekit = require(ReplicatedStorage.Packages.tablekit)
local text_counter = require(ReplicatedStorage.ClientModules.markdown["text-counter"])
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)
local wiggle = require(StarterPlayer.StarterPlayerScripts.Interface.wiggle)

-- badge-frontend.luau

local module = {}
module.limit = ratelimit(1, 0.5)

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local profile = fetchProfile()

local badgesGui = playerGui:WaitForChild("Badges")
local badgesCanvas = badgesGui.CanvasGroup
local shopFrame = badgesCanvas.Frame

local itemHolder = shopFrame.Holder
local total = shopFrame.Total

local pool = PoolerPlus:CreatePool("BadgePool", function()
	return ReplicatedStorage.Interfaces.BadgeTemplate:Clone()
end)

local amount_pool = PoolerPlus:CreatePool("AmountPool", function()
	local Instances = {
		Amount = Instance.new("TextLabel"),
	}

	Instances.Amount.AnchorPoint = Vector2.new(0.5, 0.5)
	Instances.Amount.Size = UDim2.new(1, 0, 1, 0)
	Instances.Amount.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Instances.Amount.BorderSizePixel = 0
	Instances.Amount.BackgroundTransparency = 1
	Instances.Amount.Position = UDim2.new(0.5, 0, 0.5, 0)
	Instances.Amount.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Instances.Amount.FontFace =
		Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	Instances.Amount.TextColor3 = Color3.fromRGB(255, 219, 209)
	Instances.Amount.Text = "0"

	return Instances.Amount
end)

pool:AdaptivePreload()

local function isRegisteredBadge(badge: typemarshaller.Badge)
	local tbl = {
		name = badge.name,
		description = badge.description,
		points = badge.points,
	}

	for i, badge_data in ipairs(badges) do
		if tbl == badge_data or tbl.name == badge_data.name then
			return true
		end
	end

	return false
end

local function getBadgeDataFromName(name: string): typemarsh
	for i, badge_data in ipairs(badges) do
		if badge_data.name == name then
			return badge_data
		end
	end

	return nil
end

function module:Unload()
	for _, item in ipairs(itemHolder:GetChildren()) do
		if item and item:IsA("Frame") then
			item:Destroy()

			if module.limit.count_map[item] then
				module.limit.count_map[item] = nil
			end

			RunService.Heartbeat:Wait()
		end
	end
end

local function doRocketAnimation()
	local image_label = total.ImageLabel -- a rocket icon
	-- so lets make a quick rocket effect

	spr.stop(image_label)
	wiggle(image_label)
	spr.target(image_label, 0.8, 4, {
		Position = image_label.Position + UDim2.fromOffset(5, -5),
	})
	spr.completed(image_label, function()
		spr.target(image_label, 1, 5, {
			Position = image_label.Position + UDim2.fromOffset(-5, 5),
		})
	end)
end

function module:DisplayTotalAchievements()
	-- we want to achieve a sort of "vertical carousel" typa effect.
	-- it looks like a typewriter effect, but cooler.
	-- i dont know what its called

	profile = fetchProfile()

	if not profile then
		return
	end

	doRocketAnimation()

	local total_achievements = #profile.Data.achievements

	-- we will use a scrolling frame!
	local scrolling_frame = total.Frame

	amount_pool:ReturnAll()

	for i = 1, 50 do
		local template = amount_pool:Get()

		-- gradually change the text to the total amount of achievements
		local current_amount = math.floor((i / 50) * total_achievements)
		template.Text = tostring(current_amount)

		template.Parent = scrolling_frame

		RunService.Heartbeat:Wait()
	end

	-- automagically scroll the frame to the bottom as we add items
	scrolling_frame.CanvasPosition = Vector2.new(0, 0)

	local goal = scrolling_frame.CanvasPosition + Vector2.new(0, 100000)
	local tween = TweenService:Create(
		scrolling_frame,
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CanvasPosition = goal }
	)
	tween:Play()
end

function module:DisplayTotalPoints()
	profile = fetchProfile()

	if not profile then
		return
	end

	doRocketAnimation()

	local total_points = 0

	for i, achievement in ipairs(profile.Data.achievements) do
		total_points += achievement.points
	end

	-- do the same thing with the points as we did with the total achievements.

	local scrolling_frame = total.Frame

	amount_pool:ReturnAll()

	for i = 1, 50 do
		local template = amount_pool:Get()

		local current_points = math.floor((i / 50) * total_points)
		template.Text = tostring(current_points)

		template.Parent = scrolling_frame

		RunService.Heartbeat:Wait()
	end

	scrolling_frame.CanvasPosition = Vector2.new(0, 0)

	local goal = scrolling_frame.CanvasPosition + Vector2.new(0, 100000)
	local tween = TweenService:Create(
		scrolling_frame,
		TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CanvasPosition = goal }
	)
	tween:Play()
end

function module:LoadItems<V>(sorted_table: { typemarshaller.Badge })
	profile = fetchProfile()

	module:Unload()

	local items = sorted_table or {}

	if not sorted_table or next(sorted_table) == nil then
		future.Try(function()
			items = profile.Data.achievements or {}
		end)
	end

	for i, item in ipairs(items) do
		if not item.name or not item.description or not item.points then
			if RunService:IsStudio() then
				warn("Invalid badge data: " .. tablekit.ToString(item :: any))
			else
				warn(tablekit.ToString(item :: any) .. " is missing required fields.")
				continue
			end
		end

		if not isRegisteredBadge(item) then
			warn(tablekit.ToString(item :: any) .. " is not a registered badge.")
		end
		local template = pool:Get()

		shadow(template)

		local details_btn = template.Details
		local share_btn = template.Share

		-- load title
		local title = template.Title

		local date_achieved = DateTime.fromUnixTimestampMillis(item.date_acquired)
		local universal_time = date_achieved:FormatUniversalTime("LL", "en-us")
		print("~" .. universal_time)

		local title_str = "%s<br/><font weight='Regular'><font transparency='0.5'>%s</font></font>"

		title.Text = string.format(title_str :: any, item.name, universal_time)

		-- TODO: finish the details and share implementations.
		details_btn.Activated:Connect(function()
			if not module.limit(details_btn) then
				return
			end

			audio:PlaySFX("click")

			pop(details_btn)
		end)

		share_btn.Activated:Connect(function()
			if not module.limit(share_btn) then
				return
			end

			audio:PlaySFX("click")

			pop(share_btn)
		end)

		template.Parent = itemHolder
	end

	-- also load the other badges the player hasnt achieved yet, but make them grayed out or smth.
	for i, badge_data in ipairs(badges) do
		local found = false
		for j, item in ipairs(items) do
			if item.name == badge_data.name then
				found = true
				break
			end
		end

		if not found then
			local template = pool:Get()

			shadow(template)

			local title = template.Title
			title.Text = badge_data.name

			local details_btn = template.Details
			local share_btn = template.Share
			share_btn.Visible = false
			details_btn.Activated:Connect(function()
				if not module.limit(details_btn) then
					return
				end

				audio:PlayVariation("cancel", 1)

				local snackbar = hint.new()
				snackbar:SetText("You have not unlocked this badge yet.")
				snackbar:SetCanDismiss(true)
				snackbar:SetExpiry(2)
				snackbar:SetCanClick(false)
			end)

			template.Parent = itemHolder
		end
	end
end

local function initializeSearchbar()
	-- use a levenshtien or smth

	local searchbar = shopFrame.Frame
	local text_box = searchbar.TextBox

	local last_text = ""
	local is_done_typing = true

	text_box.PlaceholderText = "Search " .. tostring(#badges) .. " Achievements..."

	text_box.Focused:Connect(function()
		ripple(text_box)
	end)

	text_box.Changed:Connect(function()
		if last_text == text_box.Text then
			return
		end

		is_done_typing = false

		-- get all badge names
		local badge_names = {}
		for i, badge in ipairs(badges) do
			table.insert(badge_names, badge.name)
		end

		local map = leventine.map(text_box.Text, { table.unpack(badge_names) })

		local conn = text_box.ReturnPressedFromOnScreenKeyboard:Connect(function()
			task.wait(0.5)
			is_done_typing = true
		end)

		task.delay(2, function()
			is_done_typing = true
		end)

		if is_done_typing then
			-- reconvert
			local sorted = {}

			for i, badge_name in ipairs(map) do
				local badge = getBadgeDataFromName(badge_name)

				if not badge then
					continue
				end

				table.insert(sorted, badge)
			end

			conn:Disconnect()

			module:LoadItems(sorted)
		end
	end)
end

initializeSearchbar()

return module
