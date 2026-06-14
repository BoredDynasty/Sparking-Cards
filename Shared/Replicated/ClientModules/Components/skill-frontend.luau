--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packet = require(ReplicatedStorage.Packet)
local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local audio = require(ReplicatedStorage.Modules.audio)
local displayorder = require(ReplicatedStorage.ClientModules.Interface.displayorder)
local fetchProfile = require(ReplicatedStorage.ClientModules.Utilities.fetchProfile)
local shadow = require(ReplicatedStorage.ClientModules.Interface.shadow)
local skill_chart = require(ReplicatedStorage.Structures["skill-chart"])
local text_counter = require(ReplicatedStorage.ClientModules.markdown["text-counter"])
local tooltip = require(ReplicatedStorage.ClientModules.Components.tooltip)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)
local wiggle = require(ReplicatedStorage.ClientModules.Interface.wiggle)

local module = {}

local player = Players.LocalPlayer
local templates = ReplicatedStorage.Interfaces
local player_gui = player.PlayerGui
local skill_gui = player_gui.SkillTree
local skill_canvas = skill_gui.CanvasGroup
local skill_frame = skill_canvas.Frame

shadow(skill_frame)

local holder = skill_frame.Holder
local spendings = skill_frame.Spendings

local catagory_pool = PoolerPlus:CreatePool("SkillCatagoryPool", function()
	return templates.SkillCatagory:Clone()
end)

local connection_pool = PoolerPlus:CreatePool("ConnectionPool", function()
	return templates.SkillConnectionVisual:Clone()
end)

local button_pool = PoolerPlus:CreatePool("SkillInfoPool", function()
	return templates.SkillLevelInfo:Clone()
end)

catagory_pool:Preload(30)
connection_pool:Preload(50)
button_pool:Preload(100)

local spinning_gradients = {} :: { UIGradient }

local technique_order = {} :: { string }
local skill_categories = {} :: { [string]: { [number]: any } }

for _, skill in ipairs(skill_chart) do
	local key = string.lower(skill.technique)
	local category = skill_categories[key]

	if not category then
		category = {}
		skill_categories[key] = category
		table.insert(technique_order, skill.technique)
	end

	table.insert(category, skill)
end

for _, category in pairs(skill_categories) do
	table.sort(category, function(left, right)
		return (left.upgrade_number or 0) < (right.upgrade_number or 0)
	end)
end

RunService.Heartbeat:Connect(function(delta)
	if not displayorder:GetState(skill_canvas) then
		return
	end

	if next(spinning_gradients) == nil then
		return
	end

	for _, gradient in ipairs(spinning_gradients) do
		gradient.Rotation += 30 * delta
	end
end)

local function getProfileData()
	return fetchProfile()
end

local function buildSkillSet(profile: typemarshaller.Profile?)
	local unlocked = {} :: { [string]: boolean }

	if not profile or not profile.Data then
		return unlocked
	end

	for _, skill_name in ipairs(profile.Data.skills or {}) do
		unlocked[string.lower(skill_name)] = true
	end

	return unlocked
end

local function getTechniquesUnlocked(technique: string, profile: typemarshaller.Profile?)
	if not profile or not profile.Data then
		return 0
	end

	local total = 0
	for _, skill_name in ipairs(profile.Data.skills or {}) do
		if string.lower(skill_name) == string.lower(technique) then
			total += 1
		end
	end

	local total_upgrades = #skill_categories[string.lower(technique)]
	if total > total_upgrades then
		warn("the player has unlocked more skills than allowed: ", total, ">", total_upgrades)
	end

	return total
end

local function getHighestUnlockedSkillName(technique: string, unlocked_set: { [string]: boolean })
	local category = skill_categories[string.lower(technique)]
	if not category then
		return nil
	end

	local highest_name: string?
	for _, skill in ipairs(category) do
		if unlocked_set[string.lower(skill.name)] then
			highest_name = skill.name
		end
	end

	return highest_name
end

local function makeButtonText(skill: any)
	local multiplier = skill.multiplier or 1.05
	local formatted_multiplier = math.floor((multiplier - 1) * 100)

	return string.format(
		"<font size='16'>%s</font>\n<font transparency='0.5'>Lv. %s · +%s%%</font>",
		skill.name,
		skill.upgrade_number,
		tostring(formatted_multiplier)
	)
end

local TextService = game:GetService("TextService")

local typewriter = require(ReplicatedStorage.ClientModules.markdown.typewriter)

local function clearActiveVisuals()
	table.clear(spinning_gradients)
end

function module:DisplaySpendings()
	local label = spendings.Amount
	label.Text = "..."

	local profile = getProfileData()
	local affinity = tonumber(profile and profile.Data.affinity)

	if affinity then
		local counter = text_counter.new(label, affinity, 3)
		counter:Start(counter)
	else
		label.Text = "?"
	end

	wiggle(spendings.SpendingsIcon)
end

function module:LoadCatagories()
	local last_scroll_position = holder.CanvasPosition
	module:Unload()

	local profile = getProfileData()
	local unlocked_set = buildSkillSet(profile)

	for _, technique in ipairs(technique_order) do
		local category = skill_categories[string.lower(technique)]
		if not category or #category == 0 then
			continue
		end

		local category_frame = catagory_pool:Get()
		local title = category_frame.TextLabel
		local total_upgrades = #category
		local techniques_unlocked = getTechniquesUnlocked(technique, profile)
		local highest_name = getHighestUnlockedSkillName(technique, unlocked_set) or "No upgrade unlocked"

		local title_text = string.format(
			"%s<br/><font size='14'><font transparency='0.5'>%d / %d Upgrades · %s</font></font>",
			technique,
			techniques_unlocked,
			total_upgrades,
			highest_name
		)

		title.Text = ""
		task.spawn(function()
			typewriter.play(title, title_text, { cps = 45 })
		end)

		local frame = category_frame.Frame
		for index, skill in ipairs(category) do
			local button = button_pool:Get()
			shadow(button)

			button.Text = makeButtonText(skill)

			-- Automatically scale the button width/height based on the skill name length.
			-- Measure the visible name (first line) using TextService and adapt size.
			local name_font = button.Font -- adjust if template uses a different font
			local name_size_px =
				TextService:GetTextSize(skill.name or "", 16, name_font, Vector2.new(2000, 2000))
			local padding_x = 40 -- left/right padding
			local padding_y = 18 -- top/bottom padding
			local line_count_estimate = 2 -- name + subline
			local width_px = math.clamp(math.ceil(name_size_px.X + padding_x), 140, 520)
			local height_px = math.clamp(math.ceil(name_size_px.Y * line_count_estimate + padding_y), 44, 120)

			-- Apply absolute pixel sizing to the button
			button.Size = UDim2.new(0, width_px, 0, height_px)

			-- If the template includes a UIAspectRatioConstraint, update it to match new size
			local aspect = button:FindFirstChildOfClass("UIAspectRatioConstraint")
			if aspect then
				aspect.AspectRatio = width_px / math.max(1, height_px)
			end

			-- Scale the outline frame with the button and adjust its aspect ratio too
			local outline = button:FindFirstChild("Outline")
			if outline then
				outline.Size = UDim2.new(1, 0, 1, 0)

				button.UIPadding:Destroy() -- remove padding to let outline fit exactly
				button.AutomaticSize = Enum.AutomaticSize.None -- disable automatic sizing to use our pixel dimensions

				local outline_aspect = outline:FindFirstChildOfClass("UIAspectRatioConstraint")
				if outline_aspect then
					outline_aspect.AspectRatio = width_px / math.max(1, height_px)
				end
			end

			button.Name = string.format("%02d", skill.upgrade_number)

			local is_owned = unlocked_set[string.lower(skill.name)]
			local is_available = skill.upgrade_number == techniques_unlocked + 1 and not is_owned

			local ui_stroke = button.Outline.UIStroke
			local gradient = ui_stroke.UIGradient
			local visible = is_owned or is_available
			ui_stroke.Enabled = visible
			gradient.Enabled = visible

			if visible then
				table.insert(spinning_gradients, gradient)
				gradient.Destroying:Connect(function()
					table.remove(spinning_gradients, table.find(spinning_gradients, gradient))
				end)
			end

			button.Interactable = is_owned or is_available

			button.Activated:Connect(function()
				button.Interactable = false
				if is_available then
					Packet.BuySkill.send({ skill_name = skill.name })
					task.delay(0.5, function()
						module:LoadCatagories()
						module:DisplaySpendings()
					end)
					audio:PlaySFX("click")
				else
					audio:PlaySFX("cancel")
				end
			end)

			button.MouseButton2Click:Connect(function()
				button.Interactable = false
				if is_owned then
					Packet.SellSkill.send({ skill_name = skill.name })
					task.delay(0.5, function()
						module:LoadCatagories()
						module:DisplaySpendings()
					end)
					audio:PlaySFX("click")
				else
					audio:PlaySFX("cancel")
				end
			end)

			tooltip.new(button, skill.description or "No description")

			button.MouseEnter:Connect(function()
				audio:PlaySFX("hover")
			end)

			button.MouseLeave:Connect(function()
				audio:PlaySFX("leave")
			end)

			button.TouchSwipe:Connect(function(direction, _)
				if direction == Enum.SwipeDirection.Down and is_owned then
					Packet.SellSkill.send({ skill_name = skill.name })
					task.delay(0.5, function()
						module:LoadCatagories()
						module:DisplaySpendings()
					end)
				end
			end)

			button.Parent = frame

			if index < total_upgrades then
				local connection_visual = connection_pool:Get()
				connection_visual.Name = string.format("%02d.5", skill.upgrade_number)
				connection_visual.Visible = true
				connection_visual.Parent = frame
			end
		end

		category_frame.Parent = holder
	end

	task.defer(function()
		local layout = holder.UIListLayout
		local padding = layout.Padding.Offset
		local total_height = padding
		for _, category in ipairs(holder:GetChildren()) do
			if category:IsA("Frame") then
				total_height += category.AbsoluteSize.Y + padding
			end
		end
		holder.CanvasSize = UDim2.new(0, 0, 0, total_height)
	end)

	holder.CanvasPosition = last_scroll_position
end

function module:Unload()
	clearActiveVisuals()

	for _, object in ipairs(catagory_pool:GetActiveObjects()) do
		object:Destroy()
	end

	for _, object in ipairs(connection_pool:GetActiveObjects()) do
		object:Destroy()
	end

	for _, object in ipairs(button_pool:GetActiveObjects()) do
		object:Destroy()
	end

	holder.CanvasSize = UDim2.new(0, 0, 0, 0)
end

return module
