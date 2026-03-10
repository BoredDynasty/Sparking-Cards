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
local hint = require(StarterPlayer.StarterPlayerScripts.Components.hint)
local pop = require(StarterPlayer.StarterPlayerScripts.Interface.pop)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local tablekit = require(ReplicatedStorage.Packages.tablekit)
local text_counter = require(ReplicatedStorage.ClientModules.markdown["text-counter"])
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

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

function module:DisplayTotalAchievements()
	-- we want to achieve a sort of "vertical carousel" typa effect.
	-- it looks like a typewriter effect, but cooler.
	-- i dont know what its called

	profile = fetchProfile()

	if not profile then
		return
	end

	pop(total.ImageLabel)

	local total_achievements = #profile.Data.achievements

	-- we will use a scrolling frame!
	local scrolling_frame = total.Frame

	amount_pool:ReturnAll()

	for i = 1, 50 do
		local template = amount_pool:Get()

		-- gradually change the text to the total amount of achievements
		local current_amount = math.floor((i / 50) * total_achievements)
		template.Text = current_amount

		template.Parent = scrolling_frame

		RunService.Heartbeat:Wait()
	end

	-- automagically scroll the frame to the bottom as we add items
	scrolling_frame.CanvasPosition = Vector2.new(0, 0)

	local goal = scrolling_frame.CanvasPosition + Vector2.new(0, 100000)
	local tween = TweenService:Create(
		scrolling_frame,
		TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CanvasPosition = goal }
	)
	tween:Play()
end

function module:DisplayTotalPoints()
	profile = fetchProfile()

	if not profile then
		return
	end

	pop(total.ImageLabel)

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
		template.Text = current_points

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

function module:LoadItems()
	profile = fetchProfile()

	if not profile then
		--print("no profile to load badges")

		return
	end

	module:Unload()

	local items = profile.Data.achievements

	for i, item in ipairs(items) do
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
end

-- TODO: implement a searchbar for searching badges by name or description. this will be a bit tricky, but it should be doable.
local function initializeSearchbar()
	-- we will implement this later, for now its just a placeholder.
end

return module
