--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local gradients = require(ReplicatedStorage.ClientModules.markdown.gradients)
const typewriter = require(ReplicatedStorage.ClientModules.markdown.typewriter)
const SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
const spr = require(ReplicatedStorage.Modules.spr)

-- killfeed.luau

-- a killfeed inspired by this twitter post
-- https://x.com/KenamiRBX/status/2061578219111755998

local module = {}
module.EntryCreated = SignalPlus()

export type SpecialElimination = {
	{
		name: string, -- what was so *extraordinary* about this elimination? e.g. "Headshot", "Backstab", "Pyro Reaction"
		experience: number, -- the number of experience points awarded for this elimination
	}
}

local player = Players.LocalPlayer
local player_gui = player:WaitForChild("PlayerGui")
local killfeed_gui = player_gui:WaitForChild("Killfeed")::any

local entry_pool = PoolerPlus:CreatePool("KillfeedEntries", function()
	return ReplicatedStorage.Interfaces.KillfeedEntry:Clone()
end)

local total_entries = 0

function module.create_entry(target: string, total_exp: number, special_elimination: SpecialElimination?)
	-- this uses a buncha rich text
	-- (e.g) <font color="#ffe5cb">+130</font>   Eliminated Josh<br/>  <font size="22"><font color="#ffe5cb">+30</font>   Headshot</font>

	local entry_label = entry_pool:Get()

	total_entries += 1

	module.EntryCreated:Fire()

	entry_label.TextTransparency = 1
	entry_label.UIStroke.Transparency = 1

	-- concatenate the special elimination text if it exists
	local special_elimination_text = ""
	if special_elimination then
		for _, elimination in ipairs(special_elimination) do
			special_elimination_text ..= string.format(
				'<font size="22"><font color="#ffe5cb">+%d</font>   %s</font><br/>',
				elimination.experience,
				elimination.name
			)
		end
	end

	local entry_text = string.format(
		'<font color="#ffe5cb">+%d</font>   Eliminated %s<br/>%s',
		total_exp,
		target,
		special_elimination_text
	)

	entry_label.Parent = killfeed_gui.CanvasGroup.Frame

	typewriter.play(entry_label, entry_text, {cps = 40})

	-- now we use some fun text effects!
	-- gradients.FireOutline(entry_label, 0, 1, true)

	-- wrap the outline effect in a RunService event.
	local connection
	connection = RunService.RenderStepped:Connect(function(delta_time)
		-- we can use the delta_time to animate the outline effect over time.
		-- for example, we can make the outline pulse in and out.
		local time = tick()
		local pulse = (math.sin(time * 5) + 1) / 2 -- oscillates between 0 and 1

		gradients.FireOutline(entry_label, pulse, #entry_text, true)
	end)

	task.wait(5)

	-- fade away after a few seconds
	spr.target(entry_label, 0.8, 5, {
		TextTransparency = 1
	})
	spr.target(entry_label.UIStroke, 0.8, 5, {
		Transparency = 1
	})

	spr.completed(entry_label, function()
		if connection then
			connection:Disconnect()
			connection = nil
		end

		entry_pool:Return(entry_label)
	end)
end

module.EntryCreated:Connect(function()
	if total_entries > 5 then
		killfeed_gui.CanvasGroup.Type.Visible = true 
		killfeed_gui.CanvasGroup.Type.Text = "KILLSTREAK"
	else
		killfeed_gui.CanvasGroup.Type.Visible = false
	end
end)

return module