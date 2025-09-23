--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TextPlus = require(ReplicatedStorage.Utility.TextPlus)
local characterIteration = require(script.Parent.characterIteration)
local input = require(ReplicatedStorage.Packages.input)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local promise = require(ReplicatedStorage.Packages.promise)
local spr = require(ReplicatedStorage.Modules.spr)
local trove = require(ReplicatedStorage.Packages.trove)

-- keybindlink.luau

local keybind_link = {}
keybind_link.__index = keybind_link

local player = playerMarshaller.get()
local player_gui = player.PlayerGui

local keybind_gui = player_gui:WaitForChild("Keybind") :: LayerCollector

type self = {
	_key: Enum.KeyCode,
	_interface: Frame,
	_button_state: observer.Observer<boolean>,
	_keyboard_object: typeof(input.Keyboard.new()),
	_trove: typeof(trove.new()),
}

export type metatable = setmetatable<self, typeof(keybind_link)>

function keybind_link:_createTemplate(ancestor: Instance?)
	-- Instances:

	local Template = Instance.new("Frame")
	local Button = Instance.new("TextButton")
	local AspectRatio = Instance.new("UIAspectRatioConstraint")
	local ButtonImage = Instance.new("ImageLabel")
	local AspectRatio_2 = Instance.new("UIAspectRatioConstraint")
	local UICorner = Instance.new("UICorner")
	local div = Instance.new("Frame")
	local AspectRatio_3 = Instance.new("UIAspectRatioConstraint")
	local Arrow = Instance.new("ImageLabel")
	local AspectRatio_4 = Instance.new("UIAspectRatioConstraint")
	local AspectRatio_5 = Instance.new("UIAspectRatioConstraint")

	--Properties:

	Template.Name = "Template"
	Template.Parent = ancestor or workspace
	Template.AnchorPoint = Vector2.new(0.5, 0.5)
	Template.BackgroundColor3 = Color3.fromRGB(26, 17, 15)
	Template.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Template.BorderSizePixel = 0
	Template.Position = UDim2.new(0.498087943, 0, 0.931967199, 0)
	Template.Size = UDim2.new(0.90152961, 0, 0.0760320723, 0)

	Button.Name = "Button"
	Button.Parent = Template
	Button.AnchorPoint = Vector2.new(0.5, 0.5)
	Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Button.BackgroundTransparency = 1.000
	Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Button.BorderSizePixel = 0
	Button.Position = UDim2.new(0.841463387, 0, 0.5, 0)
	Button.Size = UDim2.new(0.309119821, 0, 1, 0)
	Button.Modal = true
	Button.Font = Enum.Font.Gotham
	Button.Text = "M1"
	Button.TextColor3 = Color3.fromRGB(255, 255, 255)
	Button.TextSize = 14.000

	AspectRatio.Name = "AspectRatio"
	AspectRatio.Parent = Button
	AspectRatio.AspectRatio = 1.610

	ButtonImage.Name = "ButtonImage"
	ButtonImage.Parent = Template
	ButtonImage.AnchorPoint = Vector2.new(0.5, 0.5)
	ButtonImage.BackgroundTransparency = 1.000
	ButtonImage.Position = UDim2.new(0.114528105, 0, 0.521192491, 0)
	ButtonImage.Size = UDim2.new(0.101802759, 0, 0.530069292, 0)
	ButtonImage.Image = "rbxassetid://6764432293"
	ButtonImage.ImageRectOffset = Vector2.new(100, 700)
	ButtonImage.ImageRectSize = Vector2.new(100, 100)

	AspectRatio_2.Name = "AspectRatio"
	AspectRatio_2.Parent = ButtonImage
	AspectRatio_2.DominantAxis = Enum.DominantAxis.Height

	UICorner.CornerRadius = UDim.new(1, 0)
	UICorner.Parent = Template

	div.Name = "div"
	div.Parent = Template
	div.AnchorPoint = Vector2.new(0.5, 0.5)
	div.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	div.BackgroundTransparency = 0.600
	div.BorderColor3 = Color3.fromRGB(0, 0, 0)
	div.BorderSizePixel = 0
	div.Position = UDim2.new(0.468451768, 0, 0.480295748, 0)
	div.Size = UDim2.new(0.436903566, 0, 0.0220862199, 0)
	div.Visible = false

	AspectRatio_3.Name = "AspectRatio"
	AspectRatio_3.Parent = div
	AspectRatio_3.AspectRatio = 103.000

	Arrow.Name = "Arrow"
	Arrow.Parent = Template
	Arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	Arrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Arrow.BackgroundTransparency = 1.000
	Arrow.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Arrow.BorderSizePixel = 0
	Arrow.Position = UDim2.new(0.496288449, 0, 0.51642853, 0)
	Arrow.Size = UDim2.new(0.0848356336, 0, 0.44172442, 0)
	Arrow.Image = "rbxassetid://10709768114"
	Arrow.ImageTransparency = 0.600

	AspectRatio_4.Name = "AspectRatio"
	AspectRatio_4.Parent = Arrow

	AspectRatio_5.Name = "AspectRatio"
	AspectRatio_5.Parent = Template
	AspectRatio_5.AspectRatio = 5.207

	return Template
end

local function get_raw_icon_data()
	-- x and y are for the ImageRectOffset
	return {
		[Enum.KeyCode.MouseLeftButton] = {
			x = 100,
			y = 700,
		},
		[Enum.KeyCode.MouseRightButton] = {
			x = 100,
			y = 500,
		},
		[Enum.KeyCode.MouseMiddleButton] = {
			x = 100,
			y = 600,
		},
	}
end

function keybind_link.new(key: Enum.KeyCode, keyboardObject: typeof(input.Keyboard.new())): metatable
	local canvas = keybind_gui:WaitForChild("CanvasGroup") :: CanvasGroup
	local holder = canvas:WaitForChild("Holder") :: Frame

	local self = setmetatable({
		_key = key,
	}, keybind_link)

	self._interface = self._createTemplate(holder)
	self._button_state = observer.new(false)
	self._keyboard_object = keyboardObject
	self._trove = trove.new()

	self:_connectHandlers(self)

	return self
end

function keybind_link:_connectHandlers(self: metatable)
	local key_image = self._interface:WaitForChild("ButtonImage") :: ImageLabel

	local key_down_conn = (self._keyboard_object.KeyDown :: RBXScriptSignal<Enum.KeyCode>):Connect(
		function(key)
			self._button_state:Set(true)

			promise
				.new(function()
					-- create new scale
					local scale = self._trove:Construct(Instance, "UIScale", key_image) :: UIScale

					spr.target(scale, 0.8, 2, {
						Scale = 1.2,
					})
				end)
				:catch(warn)
		end
	)
	local key_up_conn = (self._keyboard_object.KeyUp :: RBXScriptSignal<Enum.KeyCode>):Connect(function(key)
		if key == self._key then
			promise
				.new(function()
					local scale = key_image:FindFirstChildOfClass("UIScale")

					if scale then
						spr.target(scale, 0.8, 2, {
							Scale = 1,
						})
						spr.completed(scale, function()
							self._trove:Remove(scale)
						end)
					end
				end)
				:catch(warn)

			self._button_state:Set(false)
		end
	end)

	local conn = self._button_state:Watch(function(newValue: boolean, oldValue: boolean)
		print("keybind: " .. self._key.Name .. " state is now: " .. tostring(newValue))
	end)

	promise
		.new(function()
			self._trove:Add(conn)
			self._trove:Add(key_up_conn)
			self._trove:Add(key_down_conn)
		end)
		:catch(warn)
end

function keybind_link:setText(self: metatable, text: string)
	local label = self._interface:WaitForChild("Button") :: Frame

	TextPlus.Create(label, text, {
		Font = Font.new(
			"rbxasset://fonts/families/Montserrat.json", -- Family.
			Enum.FontWeight.Regular, -- Weight.
			Enum.FontStyle.Normal -- Style.
		),
		Size = 14,
		Color = Color3.fromHex("#ffffff"),
		XAlignment = "Left",
		YAlignment = "Center",
		LineSorting = true,
		WordSorting = true,
		Dynamic = true,
	})
	characterIteration:jump(label)
end

function keybind_link:autoSetImage(self: metatable)
	local key_down_conn = (self._keyboard_object.KeyDown :: RBXScriptSignal<Enum.KeyCode>):Connect(
		function(key)
			local key_image = self._interface:WaitForChild("ButtonImage") :: ImageLabel
			local key_label = self._interface:WaitForChild("ButtonName") :: TextLabel

			local icon_data = get_raw_icon_data()

			promise
				.new(function()
					local icon = if icon_data[key] then icon_data[key] else key.Name
					-- if the icon data key exists, use it else use the key name.

					if type(icon) == "string" then
						key_label.Text = icon

						key_label.Visible = true
						key_image.Visible = false
					else
						key_label.Visible = false
						key_image.Visible = true

						key_image.ImageRectOffset = Vector2.new(icon.x, icon.y)
						key_image.ImageRectSize = Vector2.one * 100
					end
				end)
				:catch(warn)
		end
	)

	promise
		.new(function()
			self._trove:Add(key_down_conn)
		end)
		:catch(warn)
end

function keybind_link:Destroy(self: metatable)
	promise
		.new(function()
			self._interface:Destroy()
			self._trove:Destroy()
			self._button_state:Destroy()
		end)
		:catch(warn)

	setmetatable(self, nil)
end

return keybind_link
