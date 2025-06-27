--!strict

local KeybindLink = {}

KeybindLink.__index = KeybindLink

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UserInputService = game:GetService("UserInputService")

local inputMapping = require(ReplicatedStorage.Modules.inputMapping)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

local player = playerMarshaller.get()

function KeybindLink.new(
	actionText: string,
	keyCode: Enum.KeyCode,
	gamepadKeyCode: Enum.KeyCode,
	layoutOrder: number
)
	local self = {}

	local Gui = player.PlayerGui:WaitForChild("KeybindVisualizer") :: ScreenGui
	local Template = Gui:FindFirstChild("Template") :: any

	if inputMapping.getInputType() ~= "Keyboard" then
		Gui.Enabled = false
	end

	self.KeybindInstance = Template:Clone() :: typeof(Template)
	self.KeybindInstance.Name = tostring(keyCode) .. "_Visualiser"
	self.KeybindInstance.Parent = Template.Parent
	self.KeybindInstance.Visible = true
	self.KeybindInstance.ActionFrame.ActionText.Text = actionText
	self.KeybindInstance.LayoutOrder = layoutOrder or 0
	local icon = self.KeybindInstance.InputFrame.Frame.ButtonTextImage
	local buttonText = self.KeybindInstance.InputFrame.Frame.ButtonText
	local buttonImage = self.KeybindInstance.InputFrame.Frame.ButtonImage
	if UserInputService.GamepadEnabled then
		if inputMapping.btn_images[gamepadKeyCode] then
			icon.Image = inputMapping.btn_images[gamepadKeyCode]

			-- Hide ButtonText and ButtonImage, show ButtonTextImage
			buttonText.Visible = false
			buttonImage.Visible = false
			icon.Visible = true
		end
	else
		-- Show ButtonImage
		buttonImage.Visible = true

		local buttonTextString = UserInputService:GetStringForKeyCode(keyCode)

		local buttonTextImage = inputMapping.btn_images[keyCode]
		if buttonTextImage == nil then
			buttonTextImage = inputMapping.mapping[buttonTextString]
		end

		if buttonTextImage == nil then
			local keyCodeMappedText = inputMapping.mapping[keyCode]
			if keyCodeMappedText then
				buttonTextString = keyCodeMappedText
			end
		end

		if buttonTextImage then
			icon.Image = buttonTextImage

			--  Hide ButtonText, show ButtonTextImage
			buttonText.Visible = false
			icon.Visible = true
		elseif buttonTextString ~= nil and buttonTextString ~= "" then
			if string.len(buttonTextString) > 2 then
				buttonText.TextSize = math.round(buttonText.TextSize * 6 / 7)
			end
			buttonText.Text = buttonTextString

			-- Hide ButtonTextImage, show ButtonText
			icon.Visible = false
			buttonText.Visible = true
		end
	end
	return setmetatable(self, KeybindLink)
end

function KeybindLink:Down()
	self.KeybindInstance.ActionFrame.BackgroundColor3 = Color3.fromRGB(237, 237, 237)
	self.KeybindInstance.ActionFrame.ActionText.TextColor3 = Color3.fromRGB(0, 0, 0)
	return self
end

function KeybindLink:Up()
	self.KeybindInstance.ActionFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	self.KeybindInstance.ActionFrame.ActionText.TextColor3 = Color3.fromRGB(255, 255, 255)
	return self
end

function KeybindLink:Show()
	self.KeybindInstance.Visible = true
	return self
end

function KeybindLink:Hide()
	self.KeybindInstance.Visible = false
	return self
end

function KeybindLink:Destroy()
	self.KeybindInstance:Destroy()
end

return KeybindLink
