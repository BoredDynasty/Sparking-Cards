--!strict

--[=[
	UELog module
	An Unreal Engine inspired logger for client-side display.

	@class UELog
]=]

local default_font = Enum.Font.Roboto
local default_size = 17
local default_padding = 3
local default_width = 0.25
local default_displayorder = 127
local default_fadetime = 1
local default_show_time = true
local default_lifetime = 10
local default_position = UDim2.fromOffset(25, 25)
local default_colors = {
	[Enum.MessageType.MessageInfo] = Color3.fromRGB(255, 255, 255),
	[Enum.MessageType.MessageError] = Color3.fromRGB(203, 0, 0),
	[Enum.MessageType.MessageOutput] = Color3.fromRGB(255, 255, 255),
	[Enum.MessageType.MessageWarning] = Color3.fromRGB(255, 225, 58),
}

type local_time = {
	Hour: number,
	Minute: number,
	Second: number,
}

local LogService = game:GetService("LogService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player_marshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local spr = require(ReplicatedStorage.Modules.spr)

local player = player_marshaller.get()
local player_gui = player.PlayerGui

local function create_ui(): ScreenGui
	local new_screen = Instance.new("ScreenGui")
	new_screen.Name = "UELog"

	new_screen.DisplayOrder = default_displayorder
	new_screen.ResetOnSpawn = false

	local new_list = Instance.new("Frame", new_screen)
	new_list.Name = "List"

	new_list.BackgroundTransparency = 1

	new_list.Position = default_position
	new_list.Size = UDim2.fromScale(default_width, 0.0001)

	local new_template = Instance.new("TextLabel", new_screen)
	new_template.Name = "UELogTemplate"

	new_template.Visible = false

	new_template.AutomaticSize = Enum.AutomaticSize.Y
	new_template.BackgroundTransparency = 1

	new_template.Position = UDim2.fromScale(0, 0)
	new_template.Size = UDim2.fromScale(1, 0)

	new_template.Font = default_font
	new_template.TextSize = default_size
	new_template.TextXAlignment = Enum.TextXAlignment.Left

	new_template.TextScaled = false
	new_template.RichText = true
	new_template.TextWrapped = true

	local new_layout = Instance.new("UIListLayout", new_list)
	new_layout.Name = "Layout"

	new_layout.SortOrder = Enum.SortOrder.Name
	new_layout.Padding = UDim.new(0, default_padding)

	new_layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	new_layout.VerticalAlignment = Enum.VerticalAlignment.Top

	return new_screen
end

local UELog = {}
UELog.__index = UELog

--[=[
	Creates and returns a new UELog instance.

	@example
	local logger = UELog.new()
]=]
UELog.new = function()
	local self = setmetatable({}, UELog)

	-- Create UI and parent it to PlayerGui
	self.log = create_ui()
	self.log.Parent = player_gui

	-- Cache UI elements for quick access
	self.list = self.log:FindFirstChild("List")
	self.layout = self.list:FindFirstChild("Layout")
	self.template = self.log:FindFirstChild("UELogTemplate")

	-- Configuration
	self.colors = default_colors
	self.life_time = default_lifetime
	self.fade_time = default_fadetime
	self.show_time = default_show_time

	-- Connection for incoming LogService messages
	self.message_incoming_connection = LogService.MessageOut:Connect(function(...)
		self:create_message(...)
	end)

	return self
end

--[=[
	Displays a message in the log.

	@param msg string -- text to show
	@param message_type Enum.MessageType? -- optional message type to pick color
]=]
function UELog:create_message(msg: string, message_type: Enum.MessageType?)
	local new_message: TextLabel = self.template:Clone()
	new_message.Parent = self.list

	if not message_type then
		message_type = Enum.MessageType.MessageInfo
	end

	if self.show_time then
		local now = DateTime.now()

		local time_table = now:ToLocalTime() :: local_time

		local hours = time_table.Hour
		local minutes = time_table.Minute
		local seconds = time_table.Second
		local milliseconds = math.floor((now.UnixTimestampMillis % 1000))

		msg = string.format("%02d:%02d:%02d.%03d | %s", hours, minutes, seconds, milliseconds, tostring(msg))
	end

	new_message.Text = tostring(msg)
	new_message.TextColor3 = self.colors[message_type]

	new_message.Interactable = false
	new_message.Visible = true

	new_message.Name = "1"

	self:_update_layout()

	task.delay(self.life_time, function()
		if new_message then
			spr.target(new_message, 1, 2, {
				TextTransparency = 1,
			})

			task.wait(self.fade_time)

			if new_message then
				new_message:Destroy()
			end
		end
	end)
end

--[=[
	Clears all text entries from the log.
]=]
function UELog:clear()
	if self.list then
		for _, instance in ipairs(self.list:GetChildren() :: { Instance }) do
			if instance:IsA("TextLabel") then
				instance:Destroy()
			end
		end
	end
end

--[=[
	Disable the log UI (hide).
]=]
function UELog:disable()
	if self.log then
		self.log.Enabled = false
	end
end

--[=[
	Enable the log UI (show).
]=]
function UELog:enable()
	if self.log then
		self.log.Enabled = true
	end
end

--[[ Customization API ]]
--

--[=[
	Toggles display of timestamps.
]=]
function UELog:set_show_time(bool: boolean)
	self.show_time = bool
end

--[=[
	Sets padding between log messages. Expects UDim ONE.
]=]
function UELog:set_padding(new_padding: UDim)
	if self.layout then
		self.layout.Padding = new_padding
	end
end

--[=[
	Sets the width of the log. Expects UDim ONE.
]=]
function UELog:set_width(new_width: UDim)
	if self.list then
		self.list.Size = UDim2.new(new_width.Scale, new_width.Offset, 0.01, 0)
	end
end

--[=[
	Sets position of the log UI.
]=]
function UELog:set_position(new_position: UDim2)
	if self.list then
		self.list.Position = new_position
	end
end

--[=[
	Sets fade time for messages when their lifetime ends.
]=]
function UELog:set_fade_time(fadetime: number)
	self.fade_time = fadetime
end

--[=[
	Sets lifetime for messages in seconds.
]=]
function UELog:set_life_time(lifetime: number)
	self.life_time = lifetime
end

--[=[
	Sets font for the log template and existing entries.
	@param font Enum.Font
]=]
function UELog:set_font(font: Enum.Font)
	if self.template then
		-- Use Font property to set enum font on TextLabels
		self.template.Font = font

		for _, instance in ipairs(self.list:GetChildren() :: { Instance }) do
			if instance:IsA("TextLabel") then
				instance.Font = font
			end
		end
	end
end

--[=[
	Sets color for a specific message type.
]=]
function UELog:set_color(message_type: Enum.MessageType, color: Color3)
	self.colors[message_type] = color
end

--[=[
	Overwrite all colors. Table should include all relevant Enum.MessageType keys.
]=]
function UELog:set_colors(colors: { [Enum.MessageType]: Color3 })
	self.colors = colors
end

--[[ Internal helpers ]]
--

function UELog:_update_layout()
	if self.list then
		for _, instance in ipairs(self.list:GetChildren() :: { Instance }) do
			if instance:IsA("TextLabel") then
				local indx = tonumber(instance.Name)
				if not indx then
					continue
				end

				instance.Name = tostring(indx + 1)
			end
		end
	end
end

--[=[
	Destroy the logger and disconnect listeners.
]=]
function UELog:destroy()
	if self.log then
		self.log:Destroy()
	end

	if self.message_incoming_connection then
		self.message_incoming_connection:Disconnect()
	end
end

return UELog
