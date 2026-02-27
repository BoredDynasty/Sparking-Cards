--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenService = game:GetService("TweenService")

local number_abbreviation = require(ReplicatedStorage.Modules.Serialization["number-abbreviation"])

-- text-counter.luau

local module = {}
module.__index = module

type Counter = setmetatable<{
	label: TextLabel | TextButton,
	value: NumberValue,
	number: number,
	tween: Tween,
}, typeof(module)>

--[[
	```luau

	-- usage example
	local text_counter = require(path.to.text-counter)

	local counter = text_counter.new(someLabel, 1000, 2) -- count to 1000 in 2 seconds

	counter:Start()

	-- auto abbreviates after completion
	```
]]
function module.new(label: TextLabel | TextButton, number: number, time: number): Counter
	local self = setmetatable({}, module)

	local t_info = TweenInfo.new(time, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)

	self.label = label
	self.value = Instance.new("NumberValue")
	self.number = number
	self.tween = TweenService:Create(self.value, t_info, { Value = self.number })

	return self
end

function module.Start(self: Counter)
	if self.label:GetAttribute("is_text_counting") then
		repeat
			task.wait(1)
		until not self.label:GetAttribute("is_text_counting")
	end

	self.label:SetAttribute("is_text_counting", true)

	self.tween:Play()

	assert(self.label, "no label?")

	self.value.Changed:Connect(function()
		local number_value = math.round(self.value.Value * 1) / 1

		self.label.Text = tostring(number_value)
	end)

	task.spawn(function()
		self.tween.Completed:Wait()

		task.wait(1)

		self.label.Text = number_abbreviation:Format(self.number, "space")
		self.value:Destroy()

		self.label:SetAttribute("is_text_counting", false)

		setmetatable(self, nil)
	end)
end

function module.Destroy(self: Counter)
	self.tween:Cancel()

	self.label.Text = number_abbreviation:Format(self.number, "space")
	self.value:Destroy()

	self.label:SetAttribute("is_text_counting", false)

	setmetatable(self, nil)
end

return module
