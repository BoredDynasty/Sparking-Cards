--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local connection_render = require(ReplicatedStorage.ClientModules.layouts["connection-render"])
local hydration = require(ReplicatedStorage.Utility.hydration)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local force_directed_layout = require(ReplicatedStorage.ClientModules.layouts["force-directed-layout"])
local skills = require(ReplicatedStorage["skill-data"])
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

local function createNode(skill: {any}, ancestor: Instance?): node_frame
	local Instances = {
		Frame = Instance.new("Frame"),
		UICorner = Instance.new("UICorner"),
		ImageLabel = Instance.new("ImageLabel"),
		UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint"),
	}

	Instances.Frame.Name = skill.name
	Instances.Frame.AnchorPoint = Vector2.one / 2
	Instances.Frame.Size = if skill.type == "major" then UDim2.new(0.12, 0, 0.16, 0) else UDim2.new(0.08, 0, 0.11, 0)
	Instances.Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Instances.Frame.Position = UDim2.fromScale(0.5, 0.5)
	Instances.Frame.BorderSizePixel = 0
	Instances.Frame.BackgroundColor3 = if skill.type == "major" then Color3.fromRGB(114, 53, 35) else Color3.fromRGB(70, 70, 70)
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
	Instances.ImageLabel.Image = skill.icon
	Instances.ImageLabel.Parent = Instances.Frame

	Instances.UIAspectRatioConstraint.Name = "UIAspectRatioConstraint"
	Instances.UIAspectRatioConstraint.Parent = Instances.ImageLabel

	Instances.Frame:SetAttribute("Node", true)

	return Instances.Frame :: any
end

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

function module:Open()
	if state:Get() then
		print("already open skill-tree")

		return
	end

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
	local nodes = {}
	for _, skill in pairs(skills) do
		local node = createNode(skill, skill_canvas)
		nodes[skill.name] = node
	end

	-- create the edges
	local edges = {}
	for _, skill in pairs(skills) do
		for _, dependency in ipairs(skill.dependencies) do
			table.insert(edges, { source = nodes[skill.name], target = nodes[dependency] })
		end
	end

	-- convert nodes to an array
	local nodes_array = {}
	for _, node in pairs(nodes) do
		table.insert(nodes_array, node)
	end

	-- position the nodes using the force-directed layout
	force_directed_layout({
		nodes = nodes_array,
		edges = edges,
		canvas = skill_canvas,
	})

	-- render the connections
	for _, edge in ipairs(edges) do
		connection_render(skill_canvas, edge.source, edge.target, function()
			local line = Instance.new("Frame")
			line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			line.BorderSizePixel = 0
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
end
