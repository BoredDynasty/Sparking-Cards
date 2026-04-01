--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local input = require(ReplicatedStorage.Packages.input)
local observer = require(ReplicatedStorage.Utility.observer)
local spr = require(ReplicatedStorage.Modules.spr)

-- crosshair-service.luau

local crosshair_module = {}
crosshair_module.__index = crosshair_module

export type crosshair_interface<T> = ScreenGui & {
	Crosshair: Frame & {
		Top: Frame,
		Bottom: Frame,
		Left: Frame,
		Right: Frame,
		Hitmarker: ImageLabel,
	},
}

type crosshair_lines = "Bottom" | "Center" | "Left" | "Right" | "Top"

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local DEFAULT_RADIUS = 50
local DEFAULT_LINE_MARGIN = 7
local DEFAULT_LINE_LENGTH = 10
local DEFAULT_THICKNESS = 2
local HITMARKER_SIZE = 24

local function create_crosshair_interface(): crosshair_interface<crosshair_lines>
	local screen_gui = Instance.new("ScreenGui")
	screen_gui.Name = "Crosshair"
	screen_gui.ResetOnSpawn = false
	screen_gui.IgnoreGuiInset = true
	screen_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen_gui.Parent = playerGui
	screen_gui.DisplayOrder = math.huge

	local crosshair_frame = Instance.new("Frame")
	crosshair_frame.Name = "Crosshair"
	crosshair_frame.AnchorPoint = Vector2.new(0.5, 0.5)
	crosshair_frame.Position = UDim2.fromScale(0.5, 0.5)
	crosshair_frame.Size = UDim2.fromOffset(0, 0)
	crosshair_frame.BackgroundTransparency = 1
	crosshair_frame.Parent = screen_gui

	local function make_line(name: string, size: UDim2, anchor: Vector2, position: UDim2): Frame
		local line = Instance.new("Frame")
		line.Name = name
		line.Size = size
		line.AnchorPoint = anchor
		line.Position = position
		line.BackgroundColor3 = Color3.new(1, 1, 1)
		line.BackgroundTransparency = 0.6
		line.BorderSizePixel = 0
		line.Parent = crosshair_frame
		return line
	end

	local line_size_v = UDim2.new(0, DEFAULT_THICKNESS, 0, DEFAULT_LINE_LENGTH)
	local line_size_h = UDim2.new(0, DEFAULT_LINE_LENGTH, 0, DEFAULT_THICKNESS)

	make_line(
		"Top",
		line_size_v,
		Vector2.new(0.5, 1),
		UDim2.fromOffset(0, -DEFAULT_RADIUS - DEFAULT_LINE_MARGIN)
	)
	make_line(
		"Bottom",
		line_size_v,
		Vector2.new(0.5, 0),
		UDim2.fromOffset(0, DEFAULT_RADIUS + DEFAULT_LINE_MARGIN)
	)
	make_line(
		"Left",
		line_size_h,
		Vector2.new(1, 0.5),
		UDim2.fromOffset(-DEFAULT_RADIUS - DEFAULT_LINE_MARGIN, 0)
	)
	make_line(
		"Right",
		line_size_h,
		Vector2.new(0, 0.5),
		UDim2.fromOffset(DEFAULT_RADIUS + DEFAULT_LINE_MARGIN, 0)
	)

	local hitmarker = Instance.new("ImageLabel")
	hitmarker.Name = "Hitmarker"
	hitmarker.Size = UDim2.fromOffset(HITMARKER_SIZE, HITMARKER_SIZE)
	hitmarker.AnchorPoint = Vector2.new(0.5, 0.5)
	hitmarker.Position = UDim2.fromOffset(0, 0)
	hitmarker.BackgroundTransparency = 1
	hitmarker.Image = ""
	hitmarker.Visible = false
	hitmarker.Parent = crosshair_frame

	return screen_gui :: any
end

function crosshair_module.new(radius: number?)
	local self = setmetatable({
		interface = nil :: crosshair_interface<crosshair_lines>?,
		enabled = observer.new(false),
		radius = observer.new(radius or DEFAULT_RADIUS),
		frozen = observer.new(false),
		can_animate = observer.new(true),
		render_priority = Enum.RenderPriority.Camera.Value,
		mouse = input.Mouse.new(),
		render_tag = "crosshair-update",
	}, crosshair_module)

	self.interface = create_crosshair_interface()

	self.line_positions = {
		Top = UDim2.fromOffset(0, -self.radius:Get() - DEFAULT_LINE_MARGIN),
		Left = UDim2.fromOffset(-self.radius:Get() - DEFAULT_LINE_MARGIN, 0),
		Right = UDim2.fromOffset(self.radius:Get() + DEFAULT_LINE_MARGIN, 0),
		Bottom = UDim2.fromOffset(0, self.radius:Get() + DEFAULT_LINE_MARGIN),
	} :: { [crosshair_lines]: UDim2 }

	self:SetRadius(self.radius:Get())

	return self
end

function crosshair_module:_UpdateLinePositions()
	self.line_positions = {
		Top = UDim2.fromOffset(0, -self.radius:Get() - DEFAULT_LINE_MARGIN),
		Left = UDim2.fromOffset(-self.radius:Get() - DEFAULT_LINE_MARGIN, 0),
		Right = UDim2.fromOffset(self.radius:Get() + DEFAULT_LINE_MARGIN, 0),
		Bottom = UDim2.fromOffset(0, self.radius:Get() + DEFAULT_LINE_MARGIN),
	} :: { [crosshair_lines]: UDim2 }
end

function crosshair_module:SetRadius(radii: number)
	if typeof(radii) ~= "number" then
		warn("radii is not a number")
		return
	end

	self.radius:Set(radii)
	self:_UpdateLinePositions()

	for lineName, position in pairs(self.line_positions) do
		local line = self.interface.Crosshair:FindFirstChild(lineName)
		if line then
			if self.can_animate:Get() then
				spr.target(line, 0.7, 8, {
					Position = position,
				})
			else
				(line :: Frame).Position = position
			end
		end
	end
end

function crosshair_module:Shove(radii: number)
	if typeof(radii) ~= "number" then
		warn("radii is not a number")
		return
	end

	self.radius:Set(radii)
	self:_UpdateLinePositions()

	for lineName, position in pairs(self.line_positions) do
		local line = self.interface.Crosshair:FindFirstChild(lineName)
		if line then
			if self.can_animate:Get() then
				spr.target(line, 0.7, 8, {
					Position = position,
				})
			else
				(line :: Frame).Position = position
			end
		end
	end
end

function crosshair_module:Update()
	if self.frozen:Get() then
		return
	end

	local mouse_position = self.mouse:GetPosition()
	if not mouse_position then
		return
	end

	self.interface.Crosshair.Position = UDim2.fromOffset(mouse_position.X, mouse_position.Y)
end

function crosshair_module:ShowHitmarker(duration: number?)
	local hitmarker = self.interface.Crosshair:FindFirstChild("Hitmarker")
	if not hitmarker then
		return
	end

	hitmarker.Visible = true
	hitmarker.ImageTransparency = 1

	spr.target(hitmarker, 0.1, 6, {
		ImageTransparency = 0,
		Size = UDim2.fromOffset(HITMARKER_SIZE * 1.25, HITMARKER_SIZE * 1.25),
	})

	local duration = duration or 0.18
	task.delay(duration, function()
		if not hitmarker.Parent then
			return
		end
		spr.target(hitmarker, 0.2, 6, {
			ImageTransparency = 1,
			Size = UDim2.fromOffset(HITMARKER_SIZE, HITMARKER_SIZE),
		})
		task.delay(0.2, function()
			if hitmarker.Parent then
				hitmarker.Visible = false
			end
		end)
	end)
end

function crosshair_module:Freeze()
	self.frozen:Set(true)
end

function crosshair_module:Thaw()
	self.frozen:Set(false)
end

function crosshair_module:Enable()
	if not self.interface then
		return
	end

	self.enabled:Set(true)
	UserInputService.MouseIconEnabled = false
	self.interface.Enabled = true

	if not self.interface.Parent then
		self.interface.Parent = playerGui
	end

	RunService:BindToRenderStep(self.render_tag, self.render_priority, function()
		self:Update()
	end)
end

function crosshair_module:Disable()
	self.enabled:Set(false)
	UserInputService.MouseIconEnabled = true
	if self.interface then
		self.interface.Enabled = false
	end
	RunService:UnbindFromRenderStep(self.render_tag)
end

function crosshair_module:Destroy()
	self:Disable()

	if self.interface then
		self.interface:Destroy()
		self.interface = nil
	end

	self.enabled:Destroy()
	self.can_animate:Destroy()
	self.radius:Destroy()
	self.frozen:Destroy()
	self.mouse:Destroy()

	table.clear(self)
	setmetatable(self, nil)
end

return crosshair_module
