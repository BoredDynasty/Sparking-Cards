--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)

local future = require(ReplicatedStorage.Packages.future)

local observer = require(ReplicatedStorage.Utility.observer)

local pop = require(StarterPlayer.StarterPlayerScripts.Interface.pop)

local spr = require(ReplicatedStorage.Modules.spr)

local swipe = require(StarterPlayer.StarterPlayerScripts.Interface.swipe)

-- hint.luau

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local snackbar_gui = playerGui:WaitForChild("Snackbar")

local module = {}
module.__index = module

local disallowed_whitespace = { "\n", "\r", "\t", "\v", "\f" }

-- Queue manager for hints - only one active at a time
local snackbar_queue = {
	active = nil :: Hint?,
	incoming = {} :: { Hint },
}

local pool = PoolerPlus:CreatePool("HintPool", function()
	local templates = ReplicatedStorage.Interfaces

	return templates.Snackbar:Clone()
end)

type Snackbar = setmetatable<
	{
		hint: typeof(pool:Get()),
		Clicked: SignalPlus.Signal<>,
		CanClick: observer.Observer<boolean>,
		action_info: {
			name: string?,
			fn: () -> (),
		}?,
		expiry: number,
		dismissable: boolean,
		--swipe_detector: swipe.SwipeDetector,
	},
	typeof(module.new())
>

local function show_hint(snackbar_obj: Snackbar)
	-- animate in with pop effect
	local scale = snackbar_obj.hint:FindFirstChild("ui_scale", true) :: UIScale?

	if not scale then
		-- create scale if it doesn't exist
		scale = Instance.new("UIScale")
		scale.Name = "ui_scale"
		scale.Scale = 1
		scale.Parent = snackbar_obj.hint
	end

	-- pop effect: start bigger
	scale.Scale = 1.25

	-- start below screen
	snackbar_obj.hint.Position = UDim2.fromScale(0.5, 1.2)
	snackbar_obj.hint.Visible = true

	spr.stop(scale)
	spr.stop(snackbar_obj.hint, "Position")

	-- scale back to 1
	spr.target(scale, 0.5, 1.5, {
		Scale = 1,
	})

	-- animate up to center-bottom
	spr.target(snackbar_obj.hint, 0.8, 3.5, {
		Position = UDim2.new(0.5, 0, 1, -85),
	})
end

local function hide_snackbar(snackbar_obj: Snackbar, on_complete: () -> ())
	-- animate out with pop effect
	local scale = snackbar_obj.hint:FindFirstChild("ui_scale", true) :: UIScale?

	if not scale then
		on_complete()
		return
	end

	spr.stop(scale)
	spr.stop(snackbar_obj.hint, "Position")

	-- pop effect: scale up
	spr.target(scale, 0.4, 1.5, {
		Scale = 1.25,
	})

	-- animate down below screen
	spr.target(snackbar_obj.hint, 0.5, 0.8, {
		Position = UDim2.fromScale(0.5, 1.5),
	})

	spr.completed(snackbar_obj.hint, function()
		if snackbar_obj.hint then
			snackbar_obj.hint.Visible = false
		end
		on_complete()
	end)
end

local function process_queue()
	-- sort the table from how much text there is, longest to shortest
	table.sort(snackbar_queue.incoming, function(a: Snackbar, b: Snackbar)
		return string.len(a.hint.TextLabel.Text) > string.len(b.hint.TextLabel.Text)
	end)

	-- if active hint exists, don't process
	if snackbar_queue.active then
		return
	end

	-- if no incoming hints, stop
	if #snackbar_queue.incoming == 0 then
		return
	end

	-- move first incoming to active
	local next_hint = table.remove(snackbar_queue.incoming, 1)
	snackbar_queue.active = next_hint

	show_hint(next_hint)
end

local function enqueue_hint(snackbar_obj: Snackbar)
	table.insert(snackbar_queue.incoming, snackbar_obj)

	process_queue()
end

local function dequeue_hint(snackbar_obj: Snackbar)
	if snackbar_queue.active == snackbar_obj then
		snackbar_queue.active = nil

		process_queue()
	else
		local i = table.find(snackbar_queue.incoming, snackbar_obj)
		if i then
			table.remove(snackbar_queue.incoming, i)
		end
	end
end

--[[
	```luau

	-- usage

	local module = require(path.to.hint)

	local hint = module.new()
	hint:SetText("english or spanish?")
	hint:SetExpiry(5)
	hint:SetCanClick(false)

	-- it auto renders and cleans up by itself.
	-- pretty neat, huh?

	print("new hint!")

	```
]]
function module.new()
	local self = setmetatable({}, module)

	self.hint = pool:Get()
	self.Clicked = SignalPlus()
	self.CanClick = observer.new(false)
	self.expiry = 4
	self.dismissable = true
	--self.swipe_detector = swipe.new(self.hint)
	self.action_info = nil

	local action_button = self.hint.ActionHolder.ActionButton
	local exit_button = self.hint.ActionHolder.Exit

	self.CanClick:Watch(function(new)
		future.Try(function()
			self.hint.Interactable = new
			action_button.Interactable = new

			action_button.Visible = new
		end)
	end)

	future.Try(function()
		self:Render()
	end)

	action_button.Visible = self.CanClick:Get()

	action_button.Activated:Connect(function()
		future.Try(function()
			if not self.action_info then
				return
			end

			task.spawn(self.action_info.fn)
		end)
	end)

	exit_button.Activated:Connect(function()
		if not self.dismissable then
			return
		end

		self:Dismiss()
	end)

	self.Clicked:Connect(function()
		self:Dismiss()
	end)

	task.delay(self.expiry, function()
		self:Dismiss()
	end)

	return self
end

function module.SetText(self: Snackbar, text: string, translate_text: boolean?)
	text = text or ""
	translate_text = translate_text or true

	for key, value in ipairs(disallowed_whitespace) do
		if string.find(text, value) then
			warn("whitespaces are not supported: ", disallowed_whitespace[key])
		end
	end

	future.Try(function()
		self.hint.TextLabel.Text = text
	end)

	return self
end

function module.SetAction(self: Snackbar, fn: () -> (), name: string?)
	local action_button = self.hint.ActionHolder.ActionButton

	action_button.Text = name or "Action"

	future.Try(function()
		self.action_info = {
			name = name,
			fn = fn,
		}
	end)
end

function module.SetExpiry(self: Snackbar, expiry: number)
	future.Try(function()
		self.expiry = expiry
	end)

	return self
end

function module.SetCanClick(self: Snackbar, enabled: boolean)
	-- note: dont put this into one line :sob:

	future.Try(function()
		self.CanClick:Set(enabled)
	end)

	return self
end

function module.SetCanDismiss(self: Snackbar, enabled: boolean)
	future.Try(function()
		self.dismissable = enabled

		self.hint.ActionHolder.Exit.Visible = enabled
	end)
end

function module.Dismiss(self: Snackbar)
	future.Try(function()
		self.hint.Parent = snackbar_gui

		hide_snackbar(self, function()
			if self and self.Destroy then
				self:Destroy()
			end
		end)
	end)
end

function module.Destroy(self: Snackbar)
	spr.stop(self.hint)

	self.CanClick:Destroy()
	self.Clicked:Destroy()

	pool:Return(self.hint)

	dequeue_hint(self)

	table.clear(self)
	setmetatable(self, nil)
end

function module.Render(self: Snackbar)
	-- queue the hint for rendering

	self.hint.Position = UDim2.fromScale(0.5, 1.2) -- below the visible screen
	self.hint.Parent = snackbar_gui

	enqueue_hint(self)
end

return module
