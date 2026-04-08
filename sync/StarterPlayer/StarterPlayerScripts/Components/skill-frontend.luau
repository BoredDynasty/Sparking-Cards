--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local Packet = require(ReplicatedStorage.Packet)
local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local audio = require(ReplicatedStorage.Modules.audio)
local fetchProfile = require(StarterPlayer.StarterPlayerScripts.Utilities.fetchProfile)
local future = require(ReplicatedStorage.Packages.future)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local skill_chart = require(ReplicatedStorage.Structures["skill-chart"])
local tablekit = require(ReplicatedStorage.Packages.tablekit)
local text_counter = require(ReplicatedStorage.ClientModules.markdown["text-counter"])
local tooltip = require(StarterPlayer.StarterPlayerScripts.Components.tooltip)
local wiggle = require(StarterPlayer.StarterPlayerScripts.Interface.wiggle)

-- skill-frontend.luau

local module = {}

local player = Players.LocalPlayer
local profile = fetchProfile()

local Events = ReplicatedStorage.Events

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

RunService.Heartbeat:Connect(function(delta)
	if next(spinning_gradients) == nil then
		return
	end

	for i, gradient in ipairs(spinning_gradients) do
		gradient.Rotation += 30 * delta
	end
end)

local function getTotalUpgrades(technique: string)
	local total = 0

	for i, skill in ipairs(skill_chart) do
		if string.lower(skill.technique) == string.lower(technique) then
			total += 1
		end
	end

	if total == 0 then
		warn("its possible that '" .. technique .. "' is not a valid technique.")
	end

	return total
end

local function getTechniquesUnlocked(technique: string)
	profile = fetchProfile()

	if not profile then
		print("no player data to get techniques unlocked.")

		return 1
	end

	-- basically,
	-- we allow for multiple skill names of the same name
	-- inside the skill table.
	-- let's use that to our advantage:

	local total = 0

	for i, skill_name in ipairs(profile.Data.skills) do
		if string.lower(skill_name) == string.lower(technique) then
			total += 1
		end
	end

	-- run a check
	local total_upgrades = getTotalUpgrades(technique)
	if total > total_upgrades then
		-- what happened??
		warn("the player has unlocked more skills than allowed: ", total .. " > " .. total_upgrades)
	end

	return total
end

function module:DisplaySpendings()
	local label = spendings.Amount

	label.Text = "..."

	profile = fetchProfile()

	local affinity = tonumber(profile and profile.Data.affinity)

	if affinity then
		task.spawn(function()
			local counter = text_counter.new(label, affinity, 3)

			counter:Start(counter)
		end)
	else
		label.Text = "?"
	end

	wiggle(spendings.SpendingsIcon)
end

function module:LoadCatagories()
	module:Unload()

	local visited_techniques = {}

	for i, skill_data in ipairs(skill_chart) do
		local technique = skill_data.technique

		if table.find(visited_techniques, technique) then
			continue
		end

		table.insert(visited_techniques, technique)

		local catagory = catagory_pool:Get()

		local total_upgrades = getTotalUpgrades(technique)

		local title = catagory.TextLabel

		local title_str = "%s<br/><font size='14'><font transparency='0.5'>%s Upgrades - %s</font></font>"
		--print(title_str)

		local techniques_unlocked = getTechniquesUnlocked(technique)
		local techniques_unlocked_str = tostring(techniques_unlocked)

		-- get the name of the number of techniques unlocked.
		-- e.g "Better Investment Oppertunity" instead of just "2"
		for j, skill in ipairs(skill_chart) do
			if
				string.lower(skill.technique) == string.lower(technique)
				and skill.upgrade_number == techniques_unlocked
			then
				techniques_unlocked_str = skill.name
				--print(techniques_unlocked_str)
				break
			end
		end

		task.spawn(function()
			title.Text = string.format(title_str :: any, technique, total_upgrades, techniques_unlocked_str)
		end)
		--print(title.Text)

		for j, skill in ipairs(skill_chart) do
			if j > getTotalUpgrades(skill.technique) then
				-- we're somehow going overboard.
				-- continue?
				continue
			end

			local button = button_pool:Get()

			shadow(button)

			local info_str = "<font transparency='.5'>Lv. %s</font> > + %s"
			--print("info str: ", info_str)

			local upgrade_number = skill.upgrade_number
			--print("upgrade #: ", upgrade_number)

			-- the multiplier is like "1.05" or "1.2"
			-- we want it like "5%" or "20%"
			task.spawn(function()
				local multiplier = skill.multiplier or 1.05

				local formatted_multiplier = math.floor((multiplier - 1) * 100)
				--print(tablekit.ToString(skill :: any), formatted_multiplier)

				button.Text = string.format(
					info_str :: any,
					upgrade_number,
					formatted_multiplier,
					tostring(upgrade_number) .. "%"
				)
			end)
			--print(button.Text)

			task.spawn(function()
				if upgrade_number > techniques_unlocked then
					-- this skill is locked
					--print("locked: ", skill.name)

					-- if we find the gradient spinning, we will stop it and hide the ui stroke.
					local ui_stroke = button.Outline.UIStroke
					ui_stroke.Enabled = false
					local gradient = ui_stroke.UIGradient
					gradient.Enabled = false

					local index = table.find(spinning_gradients, gradient)
					if index then
						table.remove(spinning_gradients, index)
					end
				else
					-- we will do a cool gradient spinning effect on the UIStroke.
					local ui_stroke = button.Outline.UIStroke
					ui_stroke.Enabled = true
					local gradient = ui_stroke.UIGradient
					gradient.Enabled = true

					table.insert(spinning_gradients, gradient)
					gradient.Destroying:Connect(function()
						table.remove(spinning_gradients, table.find(spinning_gradients, gradient))
					end)
				end
			end)

			-- since the UIListLayout is sorted by Name, we will use numbers to sort the buttons in the right order.
			-- (including the connection visuals)
			-- the connection visual should be in between the buttons, so we will use decimal numbers for them.

			task.spawn(function()
				button.Name = string.format("%02d", upgrade_number)
			end)

			-- connection visuals

			task.spawn(function()
				future.Try(function()
					if j < total_upgrades then
						local connection_visual = connection_pool:Get()

						connection_visual.Name = string.format("%02d.5", upgrade_number)
						connection_visual.Visible = true
						connection_visual.Parent = catagory.Frame
					end
				end)
			end)

			-- Add clicking functionality
			button.Activated:Connect(function()
				button.Interactable = false -- hey pal, we dont want any errors.

				if upgrade_number > techniques_unlocked then
					-- Buy the skill
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
				button.Interactable = false -- same here

				if upgrade_number <= techniques_unlocked then
					-- Sell the skill
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

			tooltip.new(button, "RMB or swipe down to sell.")

			button.MouseEnter:Connect(function()
				audio:PlaySFX("hover")
			end)

			button.MouseLeave:Connect(function()
				audio:PlaySFX("leave")
			end)

			-- for mobile (and maybe PC)
			button.TouchSwipe:Connect(function(direction, delta)
				if direction == Enum.SwipeDirection.Down then
					if upgrade_number <= techniques_unlocked then
						-- Sell the skill
						Packet.SellSkill.send({ skill_name = skill.name })
						task.delay(0.5, function()
							module:LoadCatagories()
							module:DisplaySpendings()
						end)
					end
				end
			end)

			button.Parent = catagory.Frame
		end

		catagory.Parent = holder
	end

	-- expand the Holder CanvasSize to fit the catagories
	-- note: the holder is a ScrollingFrame
	task.spawn(function()
		local layout = holder.UIListLayout
		local padding = layout.Padding.Offset
		local total_height = padding
		for i, catagory in ipairs(holder:GetChildren()) do
			if catagory:IsA("Frame") then
				total_height += catagory.AbsoluteSize.Y + padding
			end
		end

		holder.CanvasSize = UDim2.new(0, 0, 0, total_height)
	end)

	--print(tablekit.ToString(visited_techniques :: any))
end

function module:Unload()
	table.clear(spinning_gradients)

	for i, object in ipairs(catagory_pool:GetActiveObjects()) do
		object:Destroy()
	end
	for i, object in ipairs(connection_pool:GetActiveObjects()) do
		object:Destroy()
	end
	for i, object in ipairs(button_pool:GetActiveObjects()) do
		object:Destroy()
	end
end

return module
