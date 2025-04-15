--!strict

local UserInputService = game:GetService("UserInputService")

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

return getInputType
