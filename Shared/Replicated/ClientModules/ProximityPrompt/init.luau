--!native
--!optimize 2
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Dependencies = ReplicatedStorage.Shared.Dependencies

local Trove = require(Packages.trove)
local Signal = require(Dependencies.SignalPlus)

--[[
	@class ProximityPrompt
	@description A class that imitates Roblox's ProximityPrompt but with more features.
]]
local ProximityPrompt = {}
ProximityPrompt.__index = ProximityPrompt

export type self = {
	__className: string;
	__instance: BasePart;

	_trove: typeof(Trove.new());

	-- @property Enabled boolean - Whether the prompt is enabled.
	Enabled: boolean;
	-- @property MaxActivationDistance number - The maximum distance from the prompt that the player can activate it.
	MaxActivationDistance: number;
	-- @property ObjectText string - The text that appears above the action text.
	ObjectText: string;
	-- @property ActionText string - The text that appears below the object text.
	ActionText: string;
	-- @property HoldDuration number - The duration in seconds that the player must hold the key to trigger the prompt.
	HoldDuration: number;
	-- @property KeyboardKeyCode Enum.KeyCode - The key that the player must press to trigger the prompt.
	KeyboardKeyCode: Enum.KeyCode;
	-- @property GamepadKeyCode Enum.KeyCode - The gamepad button that the player must press to trigger the prompt.
	GamepadKeyCode: Enum.KeyCode;
	-- @property RequiresLineOfSight boolean - Whether the prompt requires a line of sight to be activated.
	RequiresLineOfSight: boolean;

	-- @signal Triggered - Fired when the prompt is triggered.
	Triggered: Signal.Signal;
	-- @signal PromptShown - Fired when the prompt is shown.
	PromptShown: Signal.Signal;
	-- @signal PromptHidden - Fired when the prompt is hidden.
	PromptHidden: Signal.Signal;
	-- @signal PromptInteractionHoldBegin - Fired when the player starts holding the key to trigger the prompt.
	PromptInteractionHoldBegin: Signal.Signal;
	-- @signal PromptInteractionHoldEnd - Fired when the player stops holding the key to trigger the prompt.
	PromptInteractionHoldEnd: Signal.Signal;
}

--[[
	@constructor ProximityPrompt.new(instance: BasePart)
	@param instance BasePart - The instance to attach the prompt to.
	@return self
]]
function ProximityPrompt.new(instance: BasePart): self
	local self = setmetatable({} :: self, ProximityPrompt)

	self.__className = "ProximityPrompt"
	self.__instance = instance
	self._trove = Trove.new()

	self.Enabled = true
	self.MaxActivationDistance = 10
	self.ObjectText = ""
	self.ActionText = ""
	self.HoldDuration = 0
	self.KeyboardKeyCode = Enum.KeyCode.E
	self.GamepadKeyCode = Enum.KeyCode.ButtonX
	self.RequiresLineOfSight = true

	self.Triggered = self._trove:Add(Signal.new())
	self.PromptShown = self._trove:Add(Signal.new())
	self.PromptHidden = self._trove:Add(Signal.new())
	self.PromptInteractionHoldBegin = self._trove:Add(Signal.new())
	self.PromptInteractionHoldEnd = self._trove:Add(Signal.new())

	return self
end

--[[
	@method Destroy
	@description Destroys the prompt and cleans up its connections.
]]
function ProximityPrompt:Destroy()
	self._trove:Destroy()
end

return ProximityPrompt
