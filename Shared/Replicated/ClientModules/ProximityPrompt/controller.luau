--!native
--!optimize 2
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local ClientModules = ReplicatedStorage.Shared.ClientModules
local Modules = ReplicatedStorage.Shared.Modules
local Packages = ReplicatedStorage.Packages

local ProximityPromptUI = require(ClientModules.ProximityPrompt.ProximityPromptUI)
local ProximityPrompt = require(ClientModules.ProximityPrompt)
local Trove = require(Packages.trove)
local TweenPlus = require(Modules.TweenPlus)
local spr = require(Modules.spr)

--[[
	@class ProximityPromptController
	@description A singleton that manages all ProximityPrompt instances.
]]
local ProximityPromptController = {}
ProximityPromptController.__index = ProximityPromptController

local _singleton
local _prompts = {}
local _trove = Trove.new()
local _ui: ProximityPromptUI = nil
local _currentPrompt: ProximityPrompt = nil
local _isHolding = false
local _holdBeganTimestamp = 0
local _lastPosition = Vector3.new()

local function _createUI()
	_ui = Instance.new("ScreenGui")
	_ui.Name = "ProximityPromptUI"
	_ui.ResetOnSpawn = false
	_ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local canvasGroup = Instance.new("CanvasGroup")
	canvasGroup.Name = "CanvasGroup"
	canvasGroup.Size = UDim2.new(0, 200, 0, 80)
	canvasGroup.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	canvasGroup.BackgroundTransparency = 0.2
	canvasGroup.GroupTransparency = 1
	canvasGroup.Parent = _ui

	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingTop = UDim.new(0, 10)
	uiPadding.PaddingBottom = UDim.new(0, 10)
	uiPadding.PaddingLeft = UDim.new(0, 10)
	uiPadding.PaddingRight = UDim.new(0, 10)
	uiPadding.Parent = canvasGroup

    local uiListLayout = Instance.new("UIListLayout")
    uiListLayout.FillDirection = Enum.FillDirection.Vertical
    uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    uiListLayout.Padding = UDim.new(0, 5)
    uiListLayout.Parent = canvasGroup

	local primary = Instance.new("Frame")
	primary.Name = "Primary"
	primary.Size = UDim2.new(1, 0, 0, 30)
	primary.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    primary.BackgroundTransparency = 0.5
	primary.LayoutOrder = 1
	primary.Parent = canvasGroup

	local primaryCorner = Instance.new("UICorner")
	primaryCorner.CornerRadius = UDim.new(0, 8)
	primaryCorner.Parent = primary

	local primaryPadding = Instance.new("UIPadding")
	primaryPadding.PaddingLeft = UDim.new(0, 10)
	primaryPadding.PaddingRight = UDim.new(0, 10)
	primaryPadding.Parent = primary

    local keybind = Instance.new("TextLabel")
	keybind.Name = "Keybind"
	keybind.Size = UDim2.new(1, 0, 1, 0)
	keybind.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	keybind.BackgroundTransparency = 1
	keybind.TextColor3 = Color3.fromRGB(255, 255, 255)
	keybind.TextScaled = true
	keybind.Font = Enum.Font.SourceSansBold
	keybind.Text = "E"
	keybind.Parent = primary

    local keybindSize = Instance.new("UITextSizeConstraint")
    keybindSize.MaxTextSize = 24
    keybindSize.Parent = keybind

	local secondary = Instance.new("Frame")
	secondary.Name = "Secondary"
	secondary.Size = UDim2.new(1, 0, 0, 20)
	secondary.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    secondary.BackgroundTransparency = 1
	secondary.LayoutOrder = 2
	secondary.Parent = canvasGroup

	local objectText = Instance.new("TextLabel")
	objectText.Name = "Object"
	objectText.Size = UDim2.new(1, 0, 1, 0)
	objectText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	objectText.BackgroundTransparency = 1
	objectText.TextColor3 = Color3.fromRGB(255, 255, 255)
	objectText.TextScaled = true
	objectText.Font = Enum.Font.SourceSans
	objectText.Text = "Object"
	objectText.Parent = secondary

    local objectTextSize = Instance.new("UITextSizeConstraint")
    objectTextSize.MaxTextSize = 16
    objectTextSize.Parent = objectText

	local tertiary = Instance.new("Frame")
	tertiary.Name = "Tertiary"
	tertiary.Size = UDim2.new(1, 0, 0, 15)
	tertiary.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    tertiary.BackgroundTransparency = 1
	tertiary.LayoutOrder = 3
	tertiary.Parent = canvasGroup

	local actionText = Instance.new("TextLabel")
	actionText.Name = "Action"
	actionText.Size = UDim2.new(1, 0, 1, 0)
	actionText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	actionText.BackgroundTransparency = 1
	actionText.TextColor3 = Color3.fromRGB(200, 200, 200)
	actionText.TextScaled = true
	actionText.Font = Enum.Font.SourceSansLight
	actionText.Text = "Action"
	actionText.Parent = tertiary

    local actionTextSize = Instance.new("UITextSizeConstraint")
    actionTextSize.MaxTextSize = 12
    actionTextSize.Parent = actionText

	local progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(1, 0, 0, 5)
	progressBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	progressBar.BackgroundTransparency = 0.5
	progressBar.LayoutOrder = 4
	progressBar.Parent = canvasGroup

	local progressBarCorner = Instance.new("UICorner")
	progressBarCorner.CornerRadius = UDim.new(0, 8)
	progressBarCorner.Parent = progressBar

	local progress = Instance.new("Frame")
	progress.Name = "Progress"
	progress.Size = UDim2.new(0, 0, 1, 0)
	progress.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	progress.Parent = progressBar

    local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 8)
	progressCorner.Parent = progress

	_ui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	_trove:Add(_ui)
end

--[[
	@constructor ProximityPromptController.new()
	@return ProximityPromptController
]]
function ProximityPromptController.new()
	if _singleton then
		return _singleton
	end

	local self = setmetatable({}, ProximityPromptController)

	_singleton = self
	return self
end

--[[
	@method AddPrompt
	@param prompt ProximityPrompt - The prompt to add.
	@description Adds a prompt to the controller.
]]
function ProximityPromptController:AddPrompt(prompt: ProximityPrompt)
	table.insert(_prompts, prompt)
end

--[[
	@method RemovePrompt
	@param prompt ProximityPrompt - The prompt to remove.
	@description Removes a prompt from the controller.
]]
function ProximityPromptController:RemovePrompt(prompt: ProximityPrompt)
	local index = table.find(_prompts, prompt)
	if index then
		table.remove(_prompts, index)
	end
end


local function _isPromptInLineOfSight(prompt: ProximityPrompt, player: Player): boolean
	local character = player.Character
	if not character then return false end

	local head = character:FindFirstChild("Head")
	if not head then return false end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {character, prompt.__instance}

	local origin = head.Position
	local direction = (prompt.__instance.WorldPosition - origin)
	local result = workspace:Raycast(origin, direction, raycastParams)

	return not result
end

local function _updateUIPosition(prompt: ProximityPrompt, dt: number)
	local camera = workspace.CurrentCamera
	if not camera then return end

	local worldPosition = prompt.__instance.WorldPosition
	local vector, onScreen = camera:WorldToScreenPoint(worldPosition)

	if onScreen then
		local position = UDim2.fromPixels(vector.X, vector.Y)
		local lastPosition = UDim2.fromPixels(_lastPosition.X, _lastPosition.Y)
		local newPosition = lastPosition:Lerp(position, dt * 10)
		_ui.CanvasGroup.Position = newPosition
		_lastPosition = Vector3.new(newPosition.X.Offset, newPosition.Y.Offset, 0)
	else
		_ui.CanvasGroup.Visible = false
	end
end

local function _updateUIContent(prompt: ProximityPrompt)
	_ui.CanvasGroup.Primary.Keybind.Text = UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)
	_ui.CanvasGroup.Secondary.Object.Text = prompt.ObjectText
	_ui.CanvasGroup.Tertiary.Action.Text = prompt.ActionText
end

local function _animateIn()
	if not _ui then return end

	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)
	local goal = { GroupTransparency = 0 }

	local tween = TweenPlus.new(_ui.CanvasGroup, tweenInfo, goal, spr.spring)
	tween:Play()
end

local function _animateOut()
	if not _ui then return end

	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)
	local goal = { GroupTransparency = 1 }

	local tween = TweenPlus.new(_ui.CanvasGroup, tweenInfo, goal, spr.spring)
	tween:Play()
end

local function _updateProgressBar(prompt: ProximityPrompt)
	if not _ui then return end

	local holdDuration = prompt.HoldDuration
	if holdDuration <= 0 then
		_ui.CanvasGroup.ProgressBar.Visible = false
		return
	end

	_ui.CanvasGroup.ProgressBar.Visible = true
	local elapsedTime = time() - _holdBeganTimestamp
	local progress = math.clamp(elapsedTime / holdDuration, 0, 1)

	local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
	local goal = { Size = UDim2.new(progress, 0, 1, .0) }
	local tween = TweenPlus.new(_ui.CanvasGroup.ProgressBar.Progress, tweenInfo, goal)
	tween:Play()

	if progress >= 1 then
		prompt.Triggered:Fire()
		_isHolding = false
	end
end

--[[
	@method Start
	@description Starts the controller.
]]
function ProximityPromptController:Start()
	_createUI()

	_trove:Connect(UserInputService.InputBegan, function(input, processed)
		if processed or not _currentPrompt then return end

		if input.KeyCode == _currentPrompt.KeyboardKeyCode or input.KeyCode == _currentPrompt.GamepadKeyCode then
			if _currentPrompt.HoldDuration > 0 then
				_isHolding = true
				_holdBeganTimestamp = time()
			end
			_currentPrompt.PromptInteractionHoldBegin:Fire()
		end
	end)

	_trove:Connect(UserInputService.InputEnded, function(input, processed)
		if processed or not _currentPrompt then return end

		if input.KeyCode == _currentPrompt.KeyboardKeyCode or input.KeyCode == _currentPrompt.GamepadKeyCode then
			if _isHolding then
				_isHolding = false
				_currentPrompt.PromptInteractionHoldEnd:Fire()
			else
				_currentPrompt.Triggered:Fire()
			end
		end
	end)

	_trove:Connect(RunService.Heartbeat, function(dt)
		local player = Players.LocalPlayer
		if not player or not player.Character then
			return
		end

		local playerPosition = player.Character:GetPivot().Position
		local closestPrompt: ProximityPrompt = nil
		local minDistance = math.huge

		for _, prompt in ipairs(_prompts) do
			if not prompt.Enabled then
				continue
			end

			local distance = (playerPosition - prompt.__instance.WorldPosition).Magnitude
			if distance <= prompt.MaxActivationDistance and distance < minDistance then
				if not prompt.RequiresLineOfSight or (prompt.RequiresLineOfSight and _isPromptInLineOfSight(prompt, player)) then
					closestPrompt = prompt
					minDistance = distance
				end
			end
		end

		if closestPrompt and closestPrompt ~= _currentPrompt then
			if _currentPrompt then
				_currentPrompt.PromptHidden:Fire()
				_animateOut()
			end
			_currentPrompt = closestPrompt
			_updateUIContent(_currentPrompt)
			_currentPrompt.PromptShown:Fire()
			_animateIn()
		elseif not closestPrompt and _currentPrompt then
			_currentPrompt.PromptHidden:Fire()
			_animateOut()
			_currentPrompt = nil
		end

		if _currentPrompt then
			_ui.CanvasGroup.Visible = true
			_updateUIPosition(_currentPrompt, dt)
			if _isHolding then
				_updateProgressBar(_currentPrompt)
			else
				local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Linear)
				local goal = { Size = UDim2.new(0, 0, 1, 0) }
				local tween = TweenPlus.new(_ui.CanvasGroup.ProgressBar.Progress, tweenInfo, goal)
				tween:Play()
			end
		else
			if _ui and _ui.CanvasGroup and _ui.CanvasGroup.GroupTransparency == 1 then
				_ui.CanvasGroup.Visible = false
			end
		end
	end)
end

--[[
	@method Destroy
	@description Destroys the controller.
]]
function ProximityPromptController:Destroy()
	_trove:Destroy()
	_singleton = nil
end

return ProximityPromptController.new()
