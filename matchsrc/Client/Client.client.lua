--!nonstrict

-- Client.client.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- // Variables -- //

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local character = player.Character or player.CharacterAdded:Wait()

local ReplicateRE = ReplicatedStorage.RemoteEvents.ReplicateCutscene
local Camera = game.Workspace.CurrentCamera

local defaultCFrame = Camera.CFrame

---------------------------------- Cutscenes --------------------------------

local replicateConnection = nil
local connection
replicateConnection = ReplicateRE.OnClientEvent:Connect(function(cutsceneFolder: Folder)
	if not connection then
		connection = RunService.RenderStepped:Connect(function(delta)
			local frames = (delta * 60)
			local steppedFrames: CFrameValue | IntValue =
				cutsceneFolder:FindFirstChild(tostring(math.ceil(frames))) :: any
			character.Humanoid.AutoRotate = false
			Camera.CameraType = Enum.CameraType.Scriptable
			if steppedFrames then
				Camera.CFrame = character.HumanoidRootPart.CFrame * steppedFrames.Value
			else
				connection:Disconnect()
				character.Humanoid.AutoRotate = true
				Camera.CameraType = Enum.CameraType.Custom
				Camera.CFrame = defaultCFrame
			end
		end)
	end
end)

-- Sway

local function lerp(a, b, t)
	return a + (b - a) * t
end

local RenderPriority = Enum.RenderPriority.Camera.Value + 1
RunService:BindToRenderStep("Camera-Sway", RenderPriority + 1, function(delta)
	local mouseDelta = UserInputService:GetMouseDelta()
	local sway = 0
	sway = lerp(sway, math.clamp(mouseDelta.X, -5, 5), (5 * delta))
	-- print("swaying")
	if not replicateConnection then
		Camera.CFrame = Camera.CFrame * CFrame.Angles(0, 0, math.rad(sway))
	end
end)

-- Head Bobbing

local function bobble(humanoid: Humanoid)
	if humanoid.MoveDirection.Magnitude > 0 then
		local time = tick()
		local x = math.cos(time * 5) * 0.25
		local y = math.abs(math.sin(time * 5)) * 0.25
		local offset = Vector3.new(x, y, 0)
		humanoid.CameraOffset = humanoid.CameraOffset:Lerp(offset, 0.25)
		-- print("bobbling")
	else
		humanoid.CameraOffset = humanoid.CameraOffset * 0.25
	end
end

task.spawn(function()
	RunService.PreRender:Connect(function()
		if character then
			local humanoid = character:WaitForChild("Humanoid")
			if humanoid then
				bobble(humanoid)
			end
		end
	end)
end)

-- Tilt

local function getRollAngle(humanoid)
	return defaultCFrame.RightVector:Dot(humanoid.MoveDirection)
end

local function roll(humanoid)
	local rollAngle = getRollAngle(humanoid)
	local rotate = CFrame.new():Lerp(CFrame.Angles(0, 0, math.rad(rollAngle)), 0.075)
	Camera.CFrame = Camera.CFrame * rotate
end

task.spawn(function()
	RunService:BindToRenderStep("Tilt", RenderPriority, function()
		-- print("tilting")
		if character then
			local humanoid = character:WaitForChild("Humanoid")
			if humanoid then
				roll(humanoid)
			end
		end
	end)
end)

print("Camera has finished executing.")

---------------------------------- Cards --------------------------------

local cardChoices = {
	Fire = Enum.KeyCode.One,
	Frost = Enum.KeyCode.Two,
}

local function getChoice(input, gameProcessed)
	local result = nil
	if gameProcessed then
		return
	end
	for choice, keyCode in pairs(cardChoices) do
		if input.KeyCode == keyCode then
			print(`{player.DisplayName} chose: {choice}`)
			result = choice
		end
	end
	return result
end

local function onInputBegan(input, gameProcessed)
	local choice = getChoice(input, gameProcessed)
	if choice then
		print("Player chose: ", choice)
		-- Send choice to server
		local sendCardChoice: RemoteEvent = ReplicatedStorage.RemoteEvents.SendCardChoice
		sendCardChoice:FireServer(choice)
	end
end

UserInputService.InputBegan:Connect(onInputBegan)

---------------------------------- Combat --------------------------------

-- Function to rotate the character based on mouse position
local function updateCharacterFacing(humanoidRootPart: BasePart)
	local mousePosition = mouse.Hit.Position -- Get the mouse's world position
	local characterPosition = humanoidRootPart.Position

	-- Calculate the direction the character should face (Y-axis ignored)
	local direction = (Vector3.new(mousePosition.X, characterPosition.Y, mousePosition.Z) - characterPosition).unit
	print(`Got direction: {direction}`)
	-- Set the character's CFrame to face that direction
	humanoidRootPart.CFrame = CFrame.lookAt(characterPosition, characterPosition + direction)
	print("Set RootPart.CFrame: ", humanoidRootPart.CFrame)
end

local function getAnimations(folder: Folder)
	local animationTable = {}
	for _, animation: Animation in pairs(folder:GetChildren() :: any) do
		if animation:IsA("Animation") then
			table.insert(animationTable, animation)
		end
	end
end

local function playNextAnimation(folder: { Animation }, i: number)
	local result = false
	if i == 0 then
		print(`Couldn't find next anims: {folder}, {i}`)
		result = false
	end
	i += 1 -- Increment
	if i >= #folder then
		print("Getting animation(s): ", folder, i)
	end
	-- Play the current animation
	local selectedAnimation = folder[i]
	selectedAnimation:Play()
	return result
end

local function onTarget(humanoidRootPart: BasePart)
	local WeaponClass = require(ReplicatedStorage.Classes.WeaponClass)
	local range =
		tonumber(humanoidRootPart.ExtentsCFrame * CFrame.new(3, humanoidRootPart.ExtentsCFrame.YVector.Y, 3))
	if range then
		print("Got range: ", range)
		local otherPlayer = WeaponClass:Raycast(range)
		if otherPlayer and player then
			print("otherPlayer: ", otherPlayer)
			local DamageIndict = require(ReplicatedStorage.Classes.WeaponClass.DamageIndict)
			DamageIndict(otherPlayer, 15, true)
		end
	end
end

---------------------------------- UI --------------------------------

print(script.Name)
local TweenService = game:GetService("TweenService")
local MarketPlaceService = game:GetService("MarketplaceService")

-- // Requires

local UIEffect = require(ReplicatedStorage.Packages.UIEffect)

-- // Variables

local Humanoid = character:WaitForChild("Humanoid")
local TInfo = TweenInfo.new(0.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut)

-- // Everything else

-- Main Menu
local MainMenu = player.PlayerGui.MainHud
local MainMenuFrame = MainMenu.CanvasGroup.Frame
MainMenu.CanvasGroup.Visible = true
MainMenu.CanvasGroup.GroupTransparency = 0
MainMenuFrame.Visible = true
repeat
	task.wait()
	Camera.CameraType = Enum.CameraType.Scriptable
until Camera.CameraType == Enum.CameraType.Scriptable

---1604.172, 267.097, 6215.333, 24.286, 65.438, 0
Camera.CFrame = CFrame.new(-1604.172, 267.097, 6215.333) -- The roads

MainMenuFrame.PlayButton.MouseButton1Click:Once(function()
	Camera.CameraType = Enum.CameraType.Custom
	TweenService:Create(MainMenu.CanvasGroup, TInfo, { GroupTransparency = 1 }):Play()
end)

-- PlayerHud
local PlayerHud = player.PlayerGui.PlayerHud
local playerProfileImage =
	Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)

local DialogRemote = ReplicatedStorage.RemoteEvents.NewDialogue

UserInputService.WindowFocusReleased:Connect(function()
	UIEffect.changeColor("Red", PlayerHud.Player.Design.Radial)
	--UIEffect:Zoom(true)
	--UIEffect:BlurEffect(true)
	PlayerHud.Player.PlayerImage.Image = playerProfileImage
	PlayerHud.Player.TextLabel.Text = player.DisplayName
end)

UserInputService.WindowFocused:Connect(function()
	UIEffect.changeColor("Green", PlayerHud.Player.Design.Radial)
	--UIEffect:Zoom(false)
	--UIEffect:BlurEffect(false)
	PlayerHud.Player.PlayerImage.Image = playerProfileImage
	PlayerHud.Player.TextLabel.Text = player.DisplayName
end)

local function newDialog(dialog)
	UIEffect.TypewriterEffect(dialog, PlayerHud.Player.TextLabel)
	UIEffect.changeColor("Blue", PlayerHud.Player.Design.Radial)
	print(`New Dialog for {player.DisplayName}: {dialog}`)
	task.wait(10)
	UIEffect.changeColor("Green", PlayerHud.Player.Design.Radial)
end

DialogRemote.OnClientEvent:Connect(newDialog)

print(`UI is executing.`)

-- Gamepasses

local BuyCards = player.PlayerGui.DynamicUI.BuyCards

local function promptPurchase(ID)
	MarketPlaceService:PromptProductPurchase(player, ID)
end

BuyCards.Frame.Buy.MouseButton1Down:Connect(function()
	promptPurchase(1904591683) -- Buying Cards
end)

-- Emotes

local EmoteGui = player.PlayerGui.EmoteGUI

local playingAnimation = nil

local function playanim(AnimationID)
	if character ~= nil and Humanoid ~= nil then
		local anim = "rbxassetid://" .. tostring(AnimationID)
		local oldnim = character:FindFirstChild("LocalAnimation")
		Humanoid.WalkSpeed = 0

		if playingAnimation ~= nil then
			playingAnimation:Stop()
		end

		if oldnim ~= nil then
			if oldnim.AnimationId == anim then
				oldnim:Destroy()
				Humanoid.WalkSpeed = 14

				return
			end
			oldnim:Destroy()
		end

		local animation = Instance.new("Animation")
		animation.Parent = character
		animation.Name = "LocalAnimation"
		animation.AnimationId = anim
		playingAnimation = Humanoid:LoadAnimation(animation)
		playingAnimation:Play()
		Humanoid.WalkSpeed = 0
	end
end

local HolderFrame = EmoteGui.HolderFrame

for _, emoteButtons in HolderFrame.Circle:GetDescendants() do
	if emoteButtons:IsA("GuiButton") then
		emoteButtons.MouseButton1Down:Connect(function()
			playanim(emoteButtons:FindFirstChildOfClass("IntValue").Value)
		end)
	end
end

EmoteGui.HolderFrame.Visible = false

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if input == Enum.KeyCode.Tab and not gameProcessedEvent then
		EmoteGui.HolderFrame.Visible = not EmoteGui.HolderFrame.Visible
	end
end)
print(`UI is halfway executing.`)

-- Main Menu
local function mainHud()
	local MainHudGui = player.PlayerGui.MainHud
	local Canvas = MainHudGui.CanvasGroup
	local Frame = Canvas:FindFirstChild("Frame")

	Canvas.GroupTransparency = 0

	local function continueGameplay()
		UIEffect:changeVisibility(Canvas, false)
	end
	Frame.PlayButton.MouseButton1Down:Once(continueGameplay)
end

mainHud()

-- Tooltip
local tooltipFrame = player.PlayerGui.ToolTip.CanvasGroup.Frame

local function showTooltip(text, more)
	tooltipFrame.Details.Text = text -- Update the tooltip text
	tooltipFrame.Visible = true
	if more then
		if type(more) == "string" then
			tooltipFrame.Accept.Text = more
		else
			tooltipFrame.Accept.MouseButton1Click:Once(more)
		end
	end
end

local function hideTooltip()
	tooltipFrame.Visible = false
end

mouse.Move:Connect(function()
	if tooltipFrame.Visible then
		local xOffset, yOffset = 10, 10 -- Add some padding
		tooltipFrame.Position = UDim2.new(0, mouse.X + xOffset, 0, mouse.Y + yOffset)
	end
end)

print(`UI is almost done executing.`)

-- MatchHud
local MatchHud = player.PlayerGui.MatchHud
local MatchData = MatchHud.CanvasGroup.Frame.Data
local MatchStatus = MatchHud.CanvasGroup.Frame.Status

local elapsed = ""

local function getTime(remote: UnreliableRemoteEvent)
	elapsed = "00:00:00"
	remote.OnClientEvent:Connect(function(int: number?)
		elapsed = int
	end)
	return elapsed
end

local matchID: string = game:GetAttribute("matchID")

repeat
	task.wait(0.5)
	-- return function()
	elapsed = getTime(ReplicatedStorage.RemoteEvents.UpdateTime)
	task.wait(1)
	MatchData.Text = `{elapsed} | ID: {matchID}`
-- end
until string.find(elapsed, "30:00:00")

for i, a: Player in Players:GetPlayers() do
	if i ~= 2 then
		MatchStatus.Text = "Not Enough Players"
		warn(`Not enough players {i}, {a}`)
	end
end

-- Chance
local ChanceUI = player.PlayerGui.Chance

player:SetAttribute("Chance", "%0")
local baseHealth = 400

Humanoid.HealthChanged:Connect(function(health)
	print(`{player.DisplayName} health has changed to: {health}`)
	baseHealth = baseHealth / health
	local chance = baseHealth
	local red = 255
	red = red / 20.4 * (chance / 2)
	if red > 255 then
		red = 255
	end
	local font_color = tostring(Color3.fromRGB(red, 255, 255))
	for _, textLabel: TextLabel in ChanceUI.CanvasGroup:GetDescendants() do
		textLabel.Text = `<font color="{font_color}">%{player:GetAttribute("Chance") :: string}</font>`
		UIEffect:CustomAnimation("Click", textLabel) -- To get larger
		UIEffect:CustomAnimation("Shake", textLabel) -- To rotate
	end
end)

-- Other
-- Tooltip Triggers
PlayerHud.Player.MouseEnter:Connect(function()
	showTooltip("That's you!", player.DisplayName)
end)

PlayerHud.Player.MouseLeave:Connect(function()
	hideTooltip()
end)

print(`UI has finished executing.`)

-- [TODO)
