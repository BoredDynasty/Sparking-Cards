--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UserInputService = game:GetService("UserInputService")

local dictionary = require(ReplicatedStorage.Utility.dictionary)

local inputTypeString
-- If device has active keyboard and mouse, assume those inputs
if UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
	inputTypeString = "Keyboard/Mouse"
	-- Else if device has touch capability but no keyboard and mouse, assume touch input
elseif UserInputService.TouchEnabled then
	inputTypeString = "Touch"
	-- Else if device has an active gamepad, assume gamepad input
elseif UserInputService.GamepadEnabled then
	inputTypeString = "Gamepad"
end

local function getInputType()
	local lastInputEnum = UserInputService:GetLastInputType()

	if
		lastInputEnum == Enum.UserInputType.Keyboard
		or string.find(tostring(lastInputEnum.Name), "MouseButton")
		or lastInputEnum == Enum.UserInputType.MouseWheel
	then
		inputTypeString = "Keyboard/Mouse"
	elseif lastInputEnum == Enum.UserInputType.Touch then
		inputTypeString = "Touch"
	elseif string.find(tostring(lastInputEnum.Name), "Gamepad") then
		inputTypeString = "Gamepad"
	end
	return inputTypeString, lastInputEnum
end

local GamepadButtonImage = {
	[Enum.KeyCode.ButtonX] = "rbxasset://textures/ui/Controls/xboxX.png",
	[Enum.KeyCode.ButtonY] = "rbxasset://textures/ui/Controls/xboxY.png",
	[Enum.KeyCode.ButtonA] = "rbxasset://textures/ui/Controls/xboxA.png",
	[Enum.KeyCode.ButtonB] = "rbxasset://textures/ui/Controls/xboxB.png",
	[Enum.KeyCode.DPadLeft] = "rbxasset://textures/ui/Controls/dpadLeft.png",
	[Enum.KeyCode.DPadRight] = "rbxasset://textures/ui/Controls/dpadRight.png",
	[Enum.KeyCode.DPadUp] = "rbxasset://textures/ui/Controls/dpadUp.png",
	[Enum.KeyCode.DPadDown] = "rbxasset://textures/ui/Controls/dpadDown.png",
	[Enum.KeyCode.ButtonSelect] = "rbxasset://textures/ui/Controls/xboxmenu.png",
	[Enum.KeyCode.ButtonL1] = "rbxasset://textures/ui/Controls/xboxLS.png",
	[Enum.KeyCode.ButtonR1] = "rbxasset://textures/ui/Controls/xboxRS.png",
}

local KeyboardButtonImage = {
	[Enum.KeyCode.Backspace] = "rbxasset://textures/ui/Controls/backspace.png",
	[Enum.KeyCode.Return] = "rbxasset://textures/ui/Controls/return.png",
	[Enum.KeyCode.LeftShift] = "rbxasset://textures/ui/Controls/shift.png",
	[Enum.KeyCode.RightShift] = "rbxasset://textures/ui/Controls/shift.png",
	[Enum.KeyCode.Tab] = "rbxasset://textures/ui/Controls/tab.png",
}

local KeyboardButtonIconMapping = {
	["'"] = "rbxasset://textures/ui/Controls/apostrophe.png",
	[","] = "rbxasset://textures/ui/Controls/comma.png",
	["`"] = "rbxasset://textures/ui/Controls/graveaccent.png",
	["."] = "rbxasset://textures/ui/Controls/period.png",
	[" "] = "rbxasset://textures/ui/Controls/spacebar.png",
}

local KeyCodeToTextMapping = {
	[Enum.KeyCode.LeftControl] = "Ctrl",
	[Enum.KeyCode.RightControl] = "Ctrl",
	[Enum.KeyCode.LeftAlt] = "Alt",
	[Enum.KeyCode.RightAlt] = "Alt",
	[Enum.KeyCode.F1] = "F1",
	[Enum.KeyCode.F2] = "F2",
	[Enum.KeyCode.F3] = "F3",
	[Enum.KeyCode.F4] = "F4",
	[Enum.KeyCode.F5] = "F5",
	[Enum.KeyCode.F6] = "F6",
	[Enum.KeyCode.F7] = "F7",
	[Enum.KeyCode.F8] = "F8",
	[Enum.KeyCode.F9] = "F9",
	[Enum.KeyCode.F10] = "F10",
	[Enum.KeyCode.F11] = "F11",
	[Enum.KeyCode.F12] = "F12",
}

return {
	getInputType = getInputType,
	mapping = dictionary.merge(KeyCodeToTextMapping, KeyboardButtonIconMapping) :: typeof(KeyCodeToTextMapping) & typeof(KeyboardButtonIconMapping),
	btn_images = dictionary.merge(KeyboardButtonImage, GamepadButtonImage) :: typeof(GamepadButtonImage) & typeof(KeyboardButtonImage),
}
