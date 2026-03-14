--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local bounds = require(StarterPlayer.StarterPlayerScripts.Utilities.bounds)
local expressive_shapes = require(StarterPlayer.StarterPlayerScripts.Interface["expressive-shapes"])

local future = require(ReplicatedStorage.Packages.future)
local spr = require(ReplicatedStorage.Modules.spr)
local trove = require(ReplicatedStorage.Packages.trove)

-- dialogue.luau
-- allows for creating dialogue tables
-- and then executing them.
-- very similar to the hint.luau module, but with more features and more complexity.

local module = {}
module.__index = module

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:FindFirstChild("Humanoid") :: Humanoid

local dialogue_gui = playerGui:WaitForChild("Dialogue")

type DialogEntry = {
	Character: string,
	Text: string,
}

export type Dialogue = {
	Characters: { [string]: any },
	-- going in a linear order, the dialogs will be executed in order
	Dialogs: { [number]: DialogEntry },
	-- functions for the buttons, also executed in order, but only after the dialogue is done
	Actions: { [number]: () -> () },
	StopSignal: SignalPlus.Signal<>,
}

local dialogue_queue = {
	active = nil :: DialogueController?,
	incoming = {} :: { DialogueController },
}

local debounce_locked = false

local pool = PoolerPlus:CreatePool("DialoguePool", function()
	local templates = ReplicatedStorage.Interfaces

	return templates.DialogBar:Clone()
end)

local text_str = "%s<br/><font transparency='0.4'>%s</font>"

type DialogueController = setmetatable<{
	dialogue: Dialogue,
	instance: typeof(pool:Get()),
	current_index: number,
	playing: boolean,
	Dismissed: SignalPlus.Signal<>,
	_trove: typeof(trove.new()),
}, typeof(module)>

local function show_dialogue(controller: DialogueController)
	local scale = controller.instance:FindFirstChild("ui_scale", true) :: UIScale

	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "ui_scale"
		scale.Scale = 1
		scale.Parent = controller.instance
	end

	-- pop effect: start bigger
	scale.Scale = 1.25

	-- start below screen
	controller.instance.Position = UDim2.fromScale(0.5, 1.2)
	controller.instance.Visible = true

	spr.stop(scale)
	spr.stop(controller.instance, "Position")

	-- scale back to 1
	spr.target(scale, 0.5, 1.5, {
		Scale = 1,
	})

	-- animate up to center-bottom
	spr.target(controller.instance, 0.8, 3.5, {
		Position = UDim2.new(0.5, 0, 1, -85),
	})
end

local function hide_dialogue(controller: DialogueController, on_complete: () -> ())
	local scale = controller.instance:FindFirstChild("ui_scale", true) :: UIScale?

	if not scale then
		on_complete()
		return
	end

	spr.stop(scale)
	spr.stop(controller.instance, "Position")

	-- pop effect: scale up
	spr.target(scale, 0.4, 1.5, {
		Scale = 1.25,
	})

	-- animate down below screen
	spr.target(controller.instance, 0.5, 0.8, {
		Position = UDim2.fromScale(0.5, 1.5),
	})

	spr.completed(controller.instance, function()
		if controller.instance then
			controller.instance.Visible = false
		end
		on_complete()

		expressive_shapes.unregister(controller.instance.ImageLabel :: ImageLabel)
	end)
end

local function show_current_dialog(controller: DialogueController)
	local current_entry = controller.dialogue.Dialogs[controller.current_index]

	if not current_entry then
		return
	end

	future.Try(function()
		local text_label = controller.instance.TextLabel

		text_label.Text = string.format(text_str, current_entry.Character, current_entry.Text)
	end)

	expressive_shapes.register(controller.instance.ImageLabel, controller.instance.ImageLabel.ImageLabel)
end

local function process_queue()
	if debounce_locked then
		return
	end

	if dialogue_queue.active then
		return
	end

	if #dialogue_queue.incoming == 0 then
		return
	end

	local next_controller = table.remove(dialogue_queue.incoming, 1)
	dialogue_queue.active = next_controller

	debounce_locked = true

	show_dialogue(next_controller)

	next_controller.playing = true
	next_controller.current_index = 1

	show_current_dialog(next_controller)
end

local function enqueue_dialogue(controller: DialogueController)
	table.insert(dialogue_queue.incoming, controller)
	process_queue()
end

local function advance_dialogue(controller: DialogueController)
	controller.current_index += 1

	if controller.current_index > #controller.dialogue.Dialogs then
		-- All dialogs shown, execute actions
		controller.playing = false

		for _, action in ipairs(controller.dialogue.Actions) do
			task.spawn(action)
		end

		-- Dismiss after actions
		task.delay(0.5, function()
			if controller.instance then
				hide_dialogue(controller, function()
					debounce_locked = false
					dialogue_queue.active = nil

					controller.Dismissed:Fire()
					process_queue()
				end)
			end
		end)
	else
		show_current_dialog(controller)
	end
end

--[[
	```luau

	-- usage

	local module = require(path.to.dialogue)

	local dialogue = module.new()
	dialogue.Dialogs = {
		{ Character = "npc_name", Text = "Hello traveler!" },
		{ Character = "npc_name", Text = "Welcome to our world." },
	}
	dialogue.Actions = {
		function() print("Dialogue finished!") end,
	}

	module.start(dialogue)

	```
]]
function module.new()
	return {
		Characters = {} :: { [string]: any },
		Dialogs = {} :: { [number]: DialogEntry },
		Actions = {} :: { [number]: () -> () },
		StopSignal = SignalPlus(),
	}
end

function module.start(dialogue: Dialogue)
	local self = setmetatable({}, module)

	self.dialogue = dialogue
	self.instance = pool:Get()
	self.current_index = 0
	self.playing = false
	self.Dismissed = SignalPlus()
	self._trove = trove.new()

	self._trove:Add(self.Dismissed)

	local default_jump_power = humanoid.JumpPower
	local default_jump_height = humanoid.JumpHeight

	self._trove:Connect(UserInputService.JumpRequest, function()
		-- no.
		if not humanoid then
			return
		end

		local state = humanoid:GetState()
		if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then
			humanoid.JumpPower = 0
			humanoid.JumpHeight = 0
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

			return
		else
			humanoid.JumpPower = default_jump_power
			humanoid.JumpHeight = default_jump_height
		end
	end)

	-- Connect to next dialog on spacebar
	self._trove:Connect(UserInputService.InputBegan, function(key: InputObject, processed)
		if processed then
			return
		end
		if not self.playing then
			return
		end

		if key.KeyCode == Enum.KeyCode.Space then
			advance_dialogue(self)
		end
		if key.KeyCode == Enum.KeyCode.MouseLeftButton then
			local position = self.instance.AbsolutePosition
			local size = self.instance.AbsoluteSize
			if bounds.inner(position, size, UserInputService:GetMouseLocation()) then
				advance_dialogue(self)
			end
		end
	end)

	self._trove:Add(dialogue.StopSignal)

	-- Connect to stop signal
	dialogue.StopSignal:Connect(function()
		if self.instance then
			self:Destroy()
		end
	end)

	self.instance.Parent = dialogue_gui

	enqueue_dialogue(self)

	return self
end

function module.Destroy(self: DialogueController)
	spr.stop(self.instance)

	pool:Return(self.instance)

	if dialogue_queue.active == self then
		dialogue_queue.active = nil
	else
		local i = table.find(dialogue_queue.incoming, self)
		if i then
			table.remove(dialogue_queue.incoming, i)
		end
	end

	self._trove:Destroy()

	table.clear(self)
	setmetatable(self, nil)
end

return module
