--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _StarterPlayer = game:GetService("StarterPlayer")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local _observer = require(ReplicatedStorage.Utility.observer)
local input = require(ReplicatedStorage.Packages.input)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- tooltip.luau
-- supports both gui and 3D objects

local tooltip = {}
tooltip.tracked = {} :: { Instance }
tooltip.mouse = input.Mouse.new()

local player = playerMarshaller.get()
local playerGui = player.PlayerGui

local moved = tooltip.mouse.Moved :: SignalPlus.Signal<Vector2>

local tooltipGui = playerGui:WaitForChild("Tooltip") :: any
local canvasGroup = tooltipGui:WaitForChild("CanvasGroup") :: any
local frame = canvasGroup:WaitForChild("Frame") :: Frame
local details = frame:FindFirstChild("Details") :: TextLabel?

function tooltip:Add(inst: Instance)
	table.insert(tooltip.tracked, inst)
end

function tooltip:Remove(inst: Instance)
	for i, v in ipairs(tooltip.tracked) do
		local maybeInst = v :: Instance
		if maybeInst == inst then
			table.remove(tooltip.tracked, i)
			return true
		end
	end
	return false
end

function tooltip:Clear()
	table.clear(tooltip.tracked)
end

local function getTooltipTextForInstance(inst: Instance?): string?
	if not inst then
		return nil
	end

	-- Prefer attribute first
	local ok, attr = pcall(function()
		return inst:GetAttribute("Tooltip")
	end)
	if ok and type(attr) == "string" and attr ~= "" then
		return attr
	end

	-- Then look for a StringValue child named Tooltip
	local sv = inst:FindFirstChild("Tooltip")
	if sv and sv:IsA("StringValue") and sv.Value ~= "" then
		return sv.Value :: string
	end

	return nil
end

local function showText(text: string?)
	if not text or text == "" then
		frame.Visible = false
		return
	end

	if details then
		details.Text = text :: string
	else
		-- find first TextLabel descendant and set its text
		local anyLabel = frame:FindFirstChildOfClass("TextLabel")
		if anyLabel then
			anyLabel.Text = text :: string
		end
	end
	frame.Visible = true
end

local function isTrackedAncestor(inst: Instance?): Instance?
	if not inst then
		return nil
	end

	for _, t in ipairs(tooltip.tracked) do
		local trackedInst = t :: Instance
		if trackedInst then
			if
				inst == trackedInst
				or inst:IsDescendantOf(trackedInst)
				or trackedInst:IsDescendantOf(inst)
			then
				return trackedInst
			end
		end
	end

	return nil
end

local function onMoved(position: Vector2)
	-- update position
	local offset = Vector2.one * 16
	local pos = position + offset

	-- clamp to viewport
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
		or Vector2.new(1280, 720)
	local frameSize = Vector2.new(frame.AbsoluteSize.X, frame.AbsoluteSize.Y)
	pos = Vector2.new(
		math.clamp(pos.X, 0, viewport.X - frameSize.X),
		math.clamp(pos.Y, 0, viewport.Y - frameSize.Y)
	)

	-- Convert to UDim2 for ScreenGui
	frame.Position = UDim2.fromOffset(math.floor(pos.X), math.floor(pos.Y))

	-- determine hovered instance: prefer Mouse.Target (3D) then GUI element under mouse
	local hovered3D = ((tooltip.mouse :: any).Target) :: Instance?
	local trackedInst = nil

	if hovered3D then
		trackedInst = isTrackedAncestor(hovered3D)
	end

	-- If no 3D tracked, check GUI under mouse
	if not trackedInst then
		local guiObjects = playerGui:GetGuiObjectsAtPosition(position.X, position.Y)
		for _, obj in ipairs(guiObjects) do
			trackedInst = isTrackedAncestor(obj)
			if trackedInst then
				break
			end
		end
	end

	if trackedInst then
		local text = getTooltipTextForInstance(trackedInst)
		showText(text)
	else
		showText(nil)
	end
end

moved:Connect(onMoved)

-- Hide tooltip initially
frame.Visible = false

return tooltip
