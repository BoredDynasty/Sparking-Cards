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

local snackbar_gui = playerGui.Snackbar

local module = {}
module.__index = module

local disallowed_whitespace = { "\n", "\r", "\t", "\v", "\f" }

-- Stack manager to track and position hints
local snackbar_stack = {
	hints = {} :: { Hint },
}

local pool = PoolerPlus:CreatePool("HintPool", function()
	local templates = ReplicatedStorage.Interfaces

	return templates.Snackbar:Clone()
end)

type Hint = setmetatable<{
	hint: typeof(pool:Get()),
	Clicked: SignalPlus.Signal<>,
	CanClick: observer.Observer<boolean>,
	action_info: {
		name: string?,
		fn: () -> (),
	}?,
	expiry: number,
	dismissable: boolean,
	swipe_detector: swipe.SwipeDetector,
}, typeof(module.new())>

local function update_stack_positions()
	local base_y = -85
	local spacing = 45

	for i, hint_obj in ipairs(snackbar_stack.hints) do
		local target_y = base_y - (i - 1) * spacing
		spr.target(hint_obj.hint, 0.9, 0.9, {
			Position = UDim2.new(0.5, 0, 1, target_y),
		})
	end
end

local function register_hint(hint_obj: Hint)
	table.insert(snackbar_stack.hints, hint_obj)
	update_stack_positions()
end

local function unregister_hint(hint_obj: Hint)
	local i = table.find(snackbar_stack.hints, hint_obj)

	if i then
		table.remove(snackbar_stack.hints, i)
		update_stack_positions()
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
	-- is also chainable

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
	self.swipe_detector = swipe.new(self.hint)

	self.CanClick:Watch(function(new)
		future.Try(function()
			self.hint.Interactable = new
		end)
	end)

	self.hint.Activated:Connect(function()
		future.Try(function()
			self.Clicked:Fire()

			pop(self.hint, 1 / 8)
		end)
	end)

	future.Try(function()
		self:Render()
	end)

	self.swipe_detector.OnSwipe:Connect(function(direction, delta)
		future.Try(function()
			spr.target(self.hint, 0.5, 0.9, {
				Position = UDim2.fromOffset(delta.X, delta.Y),
			})
			if direction == "up" then
				if self.dismissable then
					self:Destroy()
				end
			else
				update_stack_positions()
			end
		end)
	end)

	self.Clicked:Connect(function()
		future.Try(function()
			self.hint.Parent = snackbar_gui

			spr.target(self.hint, 1, 0.9, {
				BackgroundTransparency = 1,
				TextTransparency = 1,
			})
			spr.completed(self.hint, function()
				self:Destroy()
			end)
		end)
	end)

	task.delay(self.expiry, function()
		future.Try(function()
			self.hint.Parent = snackbar_gui -- i wont explain

			spr.target(self.hint, 1, 0.9, {
				BackgroundTransparency = 1,
				TextTransparency = 1,
			})
			spr.completed(self.hint, function()
				self:Destroy()
			end)
		end)
	end)

	return self
end

function module.SetText(self: Hint, text: string, translate_text: boolean?)
	text = text or ""
	translate_text = translate_text or true

	for key, value in ipairs(disallowed_whitespace) do
		if string.find(text, value) then
			warn("whitespaces are not supported: ", disallowed_whitespace[key])
		end
	end

	future.Try(function()
		self.hint.Text = text
	end)

	return self
end

function module.SetExpiry(self: Hint, expiry: number)
	future.Try(function()
		self.expiry = expiry
	end)

	return self
end

function module.SetCanClick(self: Hint, enabled: boolean)
	-- note: dont put this into one line :sob:

	future.Try(function()
		self.CanClick:Set(enabled)
	end)

	return self
end

function module.Destroy(self: Hint)
	spr.stop(self.hint)

	self.CanClick:Destroy()
	self.Clicked:Destroy()
	self.hint:Destroy()

	unregister_hint(self)

	table.clear(self)
	setmetatable(self, nil)
end

function module.Render(self: Hint)
	-- auto-renders

	self.hint.Parent = snackbar_gui.CanvasGroup

	register_hint(self)

	spr.target(self.hint, 1, 1.5, {
		TextTransparency = 0,
	})
end

return module
