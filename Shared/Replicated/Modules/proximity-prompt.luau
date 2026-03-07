--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local Trove = require(ReplicatedStorage.Packages.trove)

-- proximity-prompt.luau

local module = {}

export type ProximityPrompt = setmetatable<{
	keybind: Enum.KeyCode,
	adornee: Instance?,
	interaction_name: string,
	action: string,
	hold_duration: number,
	max_distance: number,
	fn: (() -> ())?,

	Holding: any,
	Triggered: any,

	SetAdornee: (self: ProximityPrompt, adornee: Instance) -> (),
	SetKeybind: (self: ProximityPrompt, keycode: Enum.KeyCode) -> (),
	SetName: (self: ProximityPrompt, str: string) -> (),
	SetAction: (self: ProximityPrompt, str: string, fn: (() -> ())?) -> (),
	SetHoldDuration: (self: ProximityPrompt, duration: number) -> (),
	SetMaxDistance: (self: ProximityPrompt, distance: number) -> (),
	Show: (self: ProximityPrompt) -> (),
	Hide: (self: ProximityPrompt) -> (),
	Destroy: (self: ProximityPrompt) -> (),
}, typeof(module)>

local pool = PoolerPlus:CreatePool("ProxyPool", function()
	return ReplicatedStorage.Interfaces.ProxyPrompt
end)
pool:AdaptivePreload()

function module.new(): ProximityPrompt
	return setmetatable({
		keybind = Enum.KeyCode.E,
		adornee = nil,
		interaction_name = "",
		action = "",
		hold_duration = 3,
		max_distance = 20, -- in studs
		fn = nil,

		Holding = SignalPlus(),
		Triggered = SignalPlus(),

		-- Internal state
		_prompt = nil,
		_trove = Trove.new(),
		_in_range = false,
		_is_showing = false,
		_is_holding = false,
		_hold_time = 0,
		_player = Players.LocalPlayer,
	}, module) :: ProximityPrompt
end

function module.SetAdornee(self: ProximityPrompt, adornee: Instance)
	self.adornee = adornee
	if self._prompt then
		self._prompt.Adornee = adornee
	end
end

function module.SetKeybind(self: ProximityPrompt, keycode: Enum.KeyCode)
	self.keybind = keycode
	if self._prompt and self._is_showing then
		self:_UpdatePromptUI()
	end
end

function module.SetName(self: ProximityPrompt, str: string)
	self.interaction_name = str
	if self._prompt and self._is_showing then
		self:_UpdatePromptUI()
	end
end

function module.SetAction(self: ProximityPrompt, str: string, fn: (() -> ())?)
	self.action = str
	self.fn = fn
	if self._prompt and self._is_showing then
		self:_UpdatePromptUI()
	end
end

function module.SetHoldDuration(self: ProximityPrompt, duration: number)
	self.hold_duration = duration
end

function module.SetMaxDistance(self: ProximityPrompt, distance: number)
	self.max_distance = distance
end

function module.Show(self: ProximityPrompt)
	if self._is_showing or not self.adornee then
		return
	end

	self._is_showing = true
	self._prompt = pool:Get()
	self._prompt.Adornee = self.adornee

	self:_UpdatePromptUI()
	self:_SetupInputHandling()
	self:_SetupProximityDetection()
end

function module.Hide(self: ProximityPrompt)
	if not self._is_showing then
		return
	end

	self._is_showing = false
	self._is_holding = false
	self._hold_time = 0

	if self._prompt then
		pool:Return(self._prompt)
		self._prompt = nil
	end

	-- Clean up input and proximity connections
	self._trove:Clean()
end

function module.Destroy(self: ProximityPrompt)
	self:Hide()
	self.Holding:Destroy()
	self.Triggered:Destroy()
	self._trove:Destroy()
end

function module._UpdatePromptUI(self: ProximityPrompt)
	if not self._prompt then
		return
	end

	local button = self._prompt:FindFirstChildOfClass("TextButton")
	if not button then
		return
	end

	local str = "%s<br/><font transparency='0.4'><font size='14'>%s to interact</font></font>"
	local formatted = string.format(str, self.interaction_name, self.keybind.Name)

	button.Text = formatted
	button.Details.Text = formatted

	button.Key.Text = self.keybind.Name
end

function module._SetupInputHandling(self: ProximityPrompt)
	if not self._prompt then
		return
	end

	-- Handle keybind input
	local input_connection = self._trove:Add(
		UserInputService.InputBegan:Connect(function(input: InputObject, game_processed: boolean)
			if game_processed or not self._is_showing or not self._in_range then
				return
			end

			if input.KeyCode == self.keybind then
				self._is_holding = true
				self._hold_time = 0
			end
		end)
	)

	-- Handle release
	local release_connection = self._trove:Add(
		UserInputService.InputEnded:Connect(function(input: InputObject, game_processed: boolean)
			if input.KeyCode == self.keybind then
				self._is_holding = false
				self._hold_time = 0
			end
		end)
	)

	-- Handle hold tracking
	local hold_connection = self._trove:Add(RunService.Heartbeat:Connect(function(delta: number)
		if not self._is_holding or not self._is_showing then
			return
		end

		self._hold_time += delta

		self.Holding:Fire(self._hold_time, self.hold_duration)

		if self._hold_time >= self.hold_duration then
			self._is_holding = false
			self._hold_time = 0

			self.Triggered:Fire()

			if self.fn then
				self.fn()
			end
		end
	end))
end

function module._SetupProximityDetection(self: ProximityPrompt)
	local character = self._player.Character
	if not character then
		return
	end

	local humanoid_root_part = character:FindFirstChild("HumanoidRootPart")
	if not humanoid_root_part then
		return
	end

	-- Proximity detection loop
	local proximity_connection = self._trove:Add(RunService.Heartbeat:Connect(function()
		if not self._is_showing or not self.adornee or not character.Parent then
			self:Hide()

			return
		end

		local adornee_position = Vector3.new()

		if self.adornee:IsA("BasePart") then
			adornee_position = (self.adornee :: BasePart).Position
		elseif self.adornee:IsA("Model") then
			local model_primary_part = (self.adornee :: Model).PrimaryPart

			adornee_position = model_primary_part.Position
		end

		if not adornee_position then
			return
		end

		local distance = (humanoid_root_part.Position - adornee_position).Magnitude

		local was_in_range = self._in_range

		self._in_range = distance <= self.max_distance

		-- Handle range changes
		if self._in_range and not was_in_range then
			self:_UpdatePromptUI()
		elseif not self._in_range and was_in_range then
			self._is_holding = false
			self._hold_time = 0
		end
	end))
end

return module
