--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local connection_render = require(ReplicatedStorage.ClientModules.layouts["connection-render"])
local force_directed_layout = require(ReplicatedStorage.ClientModules.layouts["force-directed-layout"])
local hydration = require(ReplicatedStorage.Utility.hydration)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local skill_tree = require(ReplicatedStorage.Combat.framework["skill-tree"])
local transition = require(StarterPlayer.StarterPlayerScripts.Interface.transition)

-- skill-tree-renderer.luau
-- exempt from displayorder.luau

local module = {}

local player = playerMarshaller.get()
local player_gui = player.PlayerGui

local skill_gui = player_gui:FindFirstChild("SkillTree") :: ScreenGui
local skill_canvas_group = skill_gui:FindFirstChild("CanvasGroup") :: CanvasGroup
local skill_canvas = skill_canvas_group:FindFirstChild("TreeCanvas") :: Frame

local state = observer.new(false)

type node_frame = Frame & {
	Icon: ImageLabel,
	UICorner: UICorner,
}

local major_size_factor = 1.3
local minor_size_factor = 0.4

local function setNodeSizeFactor(node: node_frame, factor: number)
	local ui_scale = node:FindFirstChildOfClass("UIScale")
	if ui_scale then
		local tween = TweenPlus(ui_scale, {
			Scale = factor,
		}, {
			Time = 0.5,
			EasingDirection = "Out",
			EasingStyle = "Back",
		})

		tween:Start()
	else
		ui_scale = Instance.new("UIScale")
		hydration(ui_scale) {
			Name = "Node_scale",
			Scale = 1,
			Parent = node,
		}

		local tween = TweenPlus(ui_scale, {
			Scale = factor,
		}, {
			Time = 0.5,
			EasingDirection = "Out",
			EasingStyle = "Back",
		})

		tween:Start()
	end
end

local function createNode(skill: skill_tree.skill, ancestor: Instance?): node_frame
	local Instances = {
		Frame = Instance.new("Frame"),
		UICorner = Instance.new("UICorner"),
		ImageLabel = Instance.new("ImageLabel"),
		UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint"),
	}

	Instances.Frame.Name = skill.name
	Instances.Frame.AnchorPoint = Vector2.one / 2
	Instances.Frame.Size = if skill.type == "major"
		then setNodeSizeFactor(Instances.Frame, major_size_factor)
		else setNodeSizeFactor(Instances.Frame, minor_size_factor)

	Instances.Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Instances.Frame.Position = UDim2.fromScale(0.5, 0.5)
	Instances.Frame.BorderSizePixel = 0
	Instances.Frame.BackgroundColor3 = if skill.type == "major"
		then Color3.fromRGB(114, 53, 35)
		else Color3.fromHex("#5d4037")
	Instances.Frame.Parent = ancestor or ReplicatedStorage

	Instances.UICorner.Name = "UICorner"
	Instances.UICorner.CornerRadius = UDim.new(1, 0)
	Instances.UICorner.Parent = Instances.Frame

	Instances.ImageLabel.Name = "Icon"
	Instances.ImageLabel.Size = UDim2.new(0, 50, 0, 50)
	Instances.ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Instances.ImageLabel.BackgroundTransparency = 1
	Instances.ImageLabel.Position = UDim2.new(0.25, 0, 0.25, 0)
	Instances.ImageLabel.BorderSizePixel = 0
	Instances.ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Instances.ImageLabel.ImageColor3 = Color3.fromRGB(255, 219, 209)
	Instances.ImageLabel.Parent = Instances.Frame

	if typeof(skill.icon) == "Content" then
		Instances.ImageLabel.ImageContent = skill.icon
	else
		Instances.ImageLabel.Image = skill.icon
	end

	Instances.UIAspectRatioConstraint.Name = "UIAspectRatioConstraint"
	Instances.UIAspectRatioConstraint.Parent = Instances.ImageLabel

	Instances.Frame:SetAttribute("Node", true)

	return Instances.Frame :: any
end

function module:Open()
	if state:Get() then
		print("already open skill-tree")

		return
	end

	state:Set(true)

	task.spawn(transition.Circle, transition, {
		duration = 5,
	})

	hydration(skill_canvas) {
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromHex("#1a110f"), -- m3 surface
	}

	local texture = skill_canvas:FindFirstChild("Texture") :: ImageLabel
	if texture then
		texture.Visible = true
	else
		print("no texture?")
	end

	-- create the nodes
	-- create the edges
	-- convert nodes to an array
	local nodes = {}
	local nodes_array = {}
	local edges = {}
	for i, skill in ipairs(skill_tree) do
		local node = createNode(skill, skill_canvas)

		nodes[skill.name] = node

		for j, dependency in ipairs(skill.requirements) do
			if not dependency then
				print("no dependency")

				return
			end
			table.insert(edges, { source = nodes[skill.name], target = nodes[dependency] })
		end

		for j, v in pairs(nodes :: { [string]: Frame & { any } }) do
			table.insert(nodes_array, v)
		end
	end

	-- position the nodes using the force-directed layout
	force_directed_layout({
		nodes = nodes_array,
		edges = edges,
		canvas = skill_canvas,
	})

	-- render the connections
	for _, edge in ipairs(edges :: { { source: GuiObject, target: GuiObject } }) do
		connection_render(skill_canvas, edge.source, edge.target, function()
			local line = Instance.new("Frame")
			hydration(line) {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 0,
				Name = `{edge.source:GetFullName()}_{edge.target:GetFullName()}`,
			}

			return line
		end)
	end
end

function module:Close()
	if state:Get() == false then
		print("already closed")

		return
	end

	task.spawn(transition.Circle, transition, {
		duration = 5,
	})

	-- remove all nodes from the frame

	hydration(skill_canvas) {
		BackgroundTransparency = 1,
	}

	for _, child in ipairs(skill_canvas:GetChildren()) do
		if child:GetAttribute("Node") then
			child:Destroy()
		end
	end

	state:Set(false)
end
