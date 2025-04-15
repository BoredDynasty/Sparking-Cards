--!nonstrict

-- Client.client.lua

print(script.Name)

-- // Services -- //

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MarketPlaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

-- // Variables -- //

local player = Players.LocalPlayer :: Player
local character = player.Character or player.CharacterAdded:Wait() :: Model
local humanoid: Humanoid = character:FindFirstChild("Humanoid") :: Humanoid
local rootPart = humanoid.RootPart :: BasePart
local _assets = ReplicatedStorage:FindFirstChild("Assets") :: Folder
local TInfo = TweenInfo.new(0.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut)
local camera = game.Workspace.CurrentCamera
local mouse = player:GetMouse()

local function initCharacter()
	character = player.Character or player.CharacterAdded:Wait()
	if character then
		humanoid = character:WaitForChild("Humanoid") :: Humanoid
	else
		task.spawn(function()
			character = player.CharacterAdded:Wait()
			if character then
				humanoid = character:WaitForChild("Humanoid") :: Humanoid
			end
		end)
	end
end

initCharacter()

-- // Util

local TweenCache = {}

local function createAndPlayTween(instance: Instance, info: TweenInfo, goal: { [string]: any })
	-- Clean up existing tween
	if TweenCache[instance] then
		TweenCache[instance]:Cancel()
		TweenCache[instance]:Destroy()
		TweenCache[instance] = nil
	end

	local tween = TweenService:Create(instance, info, goal)
	TweenCache[instance] = tween

	tween.Completed:Once(function()
		TweenCache[instance] = nil
		tween:Destroy()
	end)

	tween:Play()
	return tween
end

local function throttle(callback: () -> ...any, interval: number): (...any) -> ()
	local lastExecution = 0
	return function(...)
		local now = tick()
		if now - lastExecution >= interval then
			lastExecution = now
			callback(...)
		end
	end
end

---------------------------------- Camera --------------------------------

--// Jump Bobbing

local camEdit = Instance.new("CFrameValue")
camEdit.Parent = character
camEdit.Value = CFrame.new() * CFrame.Angles(math.rad(-0.75), 0, 0)

humanoid.StateChanged:Connect(function(newState: Enum.HumanoidStateType)
	if newState == Enum.HumanoidStateType.Landed then
		local goal = { Value = CFrame.new() }
		local altTInfo = TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

		local landedRecoil = createAndPlayTween(camEdit, altTInfo, goal)

		landedRecoil.Completed:Connect(function()
			camEdit.Value = CFrame.new() * CFrame.Angles(math.rad(0.225), 0, 0)
			altTInfo = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			local landedRecovery = createAndPlayTween(camEdit, altTInfo, goal)
			task.spawn(function()
				landedRecovery.Completed:Wait()
				landedRecovery:Destroy()
			end)
		end)
		task.spawn(function()
			for _ = 1, 60 do
				camera.CFrame *= camEdit.Value
				RunService.Heartbeat:Wait()
			end
		end)
	end
end)

-- Tilt

-- Util
local rootJoint = rootPart:FindFirstChild("RootJoint") :: JointInstance
if not rootJoint then
	warn("couldnt find rootjoint")
end
local motor6D = rootJoint.C0

local momentumFactor = 0.0065
local minimumMomentum = 0
local maximumMomentum = math.huge -- hehe
local speed = 7.5

task.spawn(function()
	throttle(function()
		local deltaTime = RunService.Heartbeat:Wait()
		if humanoid.Health <= 1 then
			return
		end
		local direction = rootPart.CFrame:VectorToObjectSpace(humanoid.MoveDirection)
		local momentum = rootPart.CFrame:VectorToObjectSpace(rootPart.AssemblyLinearVelocity) * momentumFactor

		momentum = Vector3.new(
			math.clamp(math.abs(momentum.X), minimumMomentum, maximumMomentum),
			0,
			math.clamp(math.abs(momentum.Z), minimumMomentum, maximumMomentum)
		)

		local x = direction.X * momentum.X
		local z = direction.Z * momentum.Z

		local angles = { -z, -x, 0 } -- For R6
		local goal = motor6D * CFrame.Angles(unpack(angles))
		local alpha = deltaTime * speed

		motor6D:Lerp(goal, alpha)
	end, 1 / 60)
end)

print("The Camera on the client has finished.")

---------------------------------- UI --------------------------------

-- // Requires -- //

local _PlayerSettings = require(ReplicatedStorage.ClientModules.PlayerSettings)
local SoundManager = require(ReplicatedStorage.Modules.SoundManager)
local Red = require(ReplicatedStorage.Packages.Red)
local RankStructure = require(ReplicatedStorage.Structures.RankStructure)
-- selene: allow(incorrect_standard_library_use)
local Confetti = require("../Modules/Confetti")

local interfaceStartTime = os.clock()

local PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui
-- local assets = ReplicatedStorage:FindFirstChild("Assets") :: Folder

-- // Util -- //

local debounceDelay = 1

local audioTable: { [string]: number } = {
	["Click"] = 90092163763441,
	["Hover"] = 119879668444252,
	["Leave"] = 85897203168160,
	["Success"] = 76288726968959,
}
local canvasPositions = {
	[1] = UDim2.fromScale(0.5, 0.5),
	[2] = UDim2.fromScale(0.5, 0.7),
}

local function typewriterEffect(textLabel: TextLabel | TextButton, text: string, typingSpeed: number)
	local length = #text
	-- Use a coroutine for better performance
	coroutine.wrap(function()
		for i = 1, length do
			if not textLabel.Parent then
				return
			end -- Check if UI still exists
			textLabel.Text = string.sub(text, 1, i)

			-- Pool audio objects instead of creating new ones
			local audio = SoundManager:Play(audioTable.Click)
			if audio then
				audio.Volume = 0.4
				audio.PlaybackSpeed = 1.897
			end

			task.wait(typingSpeed)
		end
	end)()
end

local function changeFOV(change: number)
	-- Usually 60 or 70.
	createAndPlayTween(camera, TInfo, { FieldOfView = change })
end

local function changeVisibility(visibility: boolean, canvas: CanvasGroup)
	-- TODO) Add a way to implement the Easing module
	if visibility == true then
		canvas.Visible = true
		canvas.Position = canvasPositions[2]
		local altTInfo = TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local goal = { Position = canvasPositions[1] }
		createAndPlayTween(canvas, altTInfo, goal)
	elseif visibility == false then
		canvas.Position = canvasPositions[1]
		local altTInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local goal = { Position = canvasPositions[2] }
		local tween = createAndPlayTween(canvas, altTInfo, goal)
		tween.Completed:Once(function()
			canvas.Visible = false
		end)
	end
end

local hintGui = PlayerGui:WaitForChild("Hint") :: ScreenGui
local hintCanvas = hintGui:WaitForChild("CanvasGroup") :: CanvasGroup
local hintFrame = hintCanvas:WaitForChild("Frame") :: Frame

local hintDetailText = hintFrame:FindFirstChild("Details") :: TextLabel
local hintContext = hintFrame:FindFirstChild("Element") :: TextButton

local hintDelay = 0.5 -- seconds
local mouseOverPosition = nil

local function getMousePosition(): (number, number)
	local a0 = UserInputService:GetMouseLocation()
	return a0.X, a0.Y
end

local function isInDeadzone(element: GuiObject, x: number, y: number): boolean
	local result: boolean = false
	mouseOverPosition = { x = x, y = y } :: { [string]: number }
	task.delay(hintDelay, function()
		if mouseOverPosition then
			-- Check if the mouse is still within the deadzone
			local currentMouseX, currentMouseY = getMousePosition()
			local deadzoneRadiusX = element.AbsoluteSize.X
			local deadzoneRadiusY = element.AbsoluteSize.Y
			if
				math.abs(currentMouseX - mouseOverPosition.x) <= deadzoneRadiusX
				and math.abs(currentMouseY - mouseOverPosition.y) <= deadzoneRadiusY
			then
				-- We can show the tooltip
				result = true
			else
				-- Mouse moved too much, don't show
				result = false
			end
		end
	end)
	return result
end

local hintDebounce = false

local function showHint(details: string, context: string)
	if isInDeadzone(hintCanvas, mouse.X, mouse.Y) == false then
		print("deadzone")
		return
	end
	if hintDebounce == true then
		return
	end
	hintDebounce = true

	changeVisibility(true, hintCanvas)
	changeFOV(60)
	typewriterEffect(hintDetailText, details, 0.05)
	typewriterEffect(hintContext, context, 0.05)
end

local function hideHint()
	changeVisibility(false, hintCanvas)
	changeFOV(70)
	hintDetailText.Text = ""
	hintContext.Text = ""
end

print("UI is executing.")

-- // Everything else -- //

-- Main Menu
local MainMenu = PlayerGui:WaitForChild("MainMenu") :: ScreenGui
local mainMenuCanvas = MainMenu:WaitForChild("CanvasGroup") :: CanvasGroup
local MainMenuFrame = mainMenuCanvas:WaitForChild("Frame") :: Frame
local optionsFrame = mainMenuCanvas:WaitForChild("Options") :: Frame

mainMenuCanvas.Visible = true
mainMenuCanvas.GroupTransparency = 0
MainMenuFrame.Visible = true
task.spawn(function()
	repeat
		task.wait() --  We use spawn so we don't yield the cur. thread
		camera.CameraType = Enum.CameraType.Scriptable
	until camera.CameraType == Enum.CameraType.Scriptable
end)

--- 1604.172, 267.097, 6215.333, 24.286, 65.438, 0 -- the roads

local maxTilt = 8

local cameraPositions = {
	CFrame.new(-1721.989, 270.293, 182.625), -- Baseplate
} :: { CFrame }

local targettedArea =
	Vector3.new(cameraPositions[1].Position.X, cameraPositions[1].Position.Y, cameraPositions[1].Position.Z)

local RequestStream = Red.Event("RequestStream", function()
	assert(typeof(targettedArea) == "Vector3", "Area requested to be streamed is not a Vector3 somehow!")
	return targettedArea
end)
RequestStream:Client():Fire(targettedArea)

local randomCamPos = math.random(1, #cameraPositions)

local previousMousePosition = mouse.Hit
local cameraConnection = RunService.RenderStepped:Connect(function()
	-- very sigma effect chat
	local currentMousePosition = mouse.Hit

	if previousMousePosition ~= currentMousePosition then
		local newPosition = CFrame.Angles(
			math.rad(((mouse.Y - mouse.ViewSizeY / 2) / mouse.ViewSizeY) * -maxTilt),
			math.rad(((mouse.X - mouse.ViewSizeX / 2) / mouse.ViewSizeX) * -maxTilt),
			0
		)
		camera.CFrame = cameraPositions[randomCamPos] * newPosition
	end
end) :: RBXScriptConnection | nil

local mainMenuButtons = MainMenuFrame:FindFirstChild("Buttons") :: Frame

local playButton = mainMenuButtons:FindFirstChild("PlayButton") :: TextButton
local optionsButton = mainMenuButtons:FindFirstChild("Options") :: TextButton

playButton.MouseButton1Click:Once(function()
	camera.CameraType = Enum.CameraType.Custom
	SoundManager:Play(audioTable.Success)
	if cameraConnection then
		cameraConnection:Disconnect()
	end
	mainMenuCanvas.Position = canvasPositions[1]
	local altTInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local goal = { Position = canvasPositions[2] }
	local tween = createAndPlayTween(mainMenuCanvas, altTInfo, goal)
	tween.Completed:Once(function()
		mainMenuCanvas.Visible = false
	end)
	cameraConnection = nil
end)

optionsButton.MouseButton1Click:Connect(function()
	optionsFrame.Visible = true
	SoundManager:Play(audioTable.Click)
end)

-- Battle Gui

local BattleGui = PlayerGui:FindFirstChild("NewMatch") :: ScreenGui
local BattleCanvas = BattleGui:FindFirstChild("CanvasGroup") :: CanvasGroup
local BattleFrame = BattleCanvas:FindFirstChild("Status") :: Frame
local NewBattle = BattleFrame:FindFirstChild("HitBox") :: TextButton
local BattleDesign = BattleFrame:FindFirstChild("Design") :: Folder
local BattleDesignFrame = BattleDesign:FindFirstChild("Frame") :: Frame

local function newMatch()
	local newMatchEvent = Red.Event("NewMatch", function()
		assert(typeof(player) == "Player", "New Match arguement is somehow not a player.")
		return player
	end)
	newMatchEvent:Client():Fire(player)

	local goal: { [string]: number }
	local altTInfo: TweenInfo

	NewBattle.Text = "Finding Battle..."
	NewBattle.Interactable = false

	showHint("Sent match request to the server. Hang tight!", "Battle")

	SoundManager:Play(audioTable.Success)

	local patternVisual = BattleGui:FindFirstChild("Pattern") :: ImageLabel
	patternVisual.Visible = true
	task.wait()
	altTInfo = TweenInfo.new(1, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut, -1, true, 0.5)
	goal = { ImageTransparency = 0.00 }
	createAndPlayTween(NewBattle, altTInfo, goal)

	task.delay(5, hideHint)
	print(`New Match for: {player.DisplayName}`)
end

NewBattle.MouseButton1Click:Connect(newMatch)
NewBattle.MouseEnter:Connect(function()
	showHint("This probably doesn't work yet.", "Battle")
	SoundManager:Play(audioTable.Hover)
	task.wait()
	local altTInfo = TweenInfo.new(0.3)
	local goal = { BackgroundColor3 = Color3.fromHex("#141218") }
	createAndPlayTween(BattleDesignFrame, altTInfo, goal)
end)
NewBattle.MouseLeave:Connect(function()
	hideHint()
	SoundManager:Play(audioTable.Leave)
	task.wait()
	local altTInfo = TweenInfo.new(0.3)
	local goal = { BackgroundColor3 = Color3.new(0, 0, 0) }
	createAndPlayTween(BattleDesignFrame, altTInfo, goal)
end)

-- Gamepasses

local DynamicUI = PlayerGui:FindFirstChild("DynamicUI") :: Folder
local GamePasses = DynamicUI:FindFirstChild("GamePasses") :: ScreenGui
local GamePassesCanvas = GamePasses:FindFirstChild("CanvasGroup") :: CanvasGroup
local GamePassesFrame = GamePassesCanvas:FindFirstChild("Frame") :: Frame

local productIdentifications = {
	Extra_Cards = 1904591683,
	Donations = 1906572512,
}
local _passesIdentifications = {
	Double_Cards = 891181374,
}

local function promptPurchase(id: number)
	MarketPlaceService:PromptProductPurchase(player, id)
	task.wait()
	SoundManager:Play(audioTable.Success)
	print("Purchaseded product for player.")
end

local function _openGamepasses()
	-- We're gonna have a whole sequence for this.
	local getStartedSVG = GamePassesFrame:FindFirstChild("GetStarted") :: ImageLabel -- For engagement
	getStartedSVG.Rotation = 4
	local tipFrame = GamePassesFrame:FindFirstChild("Tip") :: Frame
	local tipText = tipFrame:FindFirstChild("Information") :: TextLabel

	local learnMoreText = [[
	Show that you care & donate a couple bucks to the developer! 
	In return, you recieve a most <i>wonderful</i> <b>50 Cards</b> prize!
	]]

	typewriterEffect(tipText, learnMoreText, 0.05)
	local goal = { Rotation = 0 }
	local altTInfo = TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	createAndPlayTween(getStartedSVG, altTInfo, goal)
end

local gamepassesTipFrame = GamePassesFrame:FindFirstChild("Tip") :: Frame
local gamepassesLearnMore = gamepassesTipFrame:FindFirstChild("More") :: TextButton
gamepassesLearnMore.MouseEnter:Connect(function()
	showHint(
		[[
		Game Products are a wonderful way to enhance your experience. 
		<i>We suggest you get one of our passes/products.
		]],
		"Gamepasses"
	)
	SoundManager:Play(audioTable.Hover)
end)
gamepassesLearnMore.MouseLeave:Connect(function()
	hideHint()
	SoundManager:Play(audioTable.Leave)
end)

-- TODO add support for more products & gamepasses

local purchaseProduct = GamePassesFrame:FindFirstChild("Purchase") :: TextButton
local closePassesFrame = GamePassesFrame:FindFirstChild("Close") :: TextButton
local gamePassDebounce = false
purchaseProduct.MouseButton1Click:Connect(function()
	if gamePassDebounce then
		return
	end
	promptPurchase(productIdentifications.Extra_Cards)
	SoundManager:Play(audioTable.Success)
	changeVisibility(false, GamePassesCanvas)

	print("Prompted product purchase for player.")
	gamePassDebounce = true
	task.delay(debounceDelay, function()
		gamePassDebounce = false
	end)
end)
local confettiDebounce = false
purchaseProduct.MouseEnter:Connect(function()
	showHint("Purchase a product", "Purchasable")
	if confettiDebounce then
		return
	end
	local confettiColors = {
		Color3.new(1.000000, 0.321569, 0.321569),
		Color3.new(1.000000, 0.921569, 0.486275),
		Color3.new(0.572549, 1.000000, 0.486275),
		Color3.new(0.207843, 0.392157, 1.000000),
		Color3.new(0.980392, 0.411765, 1.000000),
	}
	local confettiFolder = Instance.new("Folder")
	confettiFolder.Name = "ConfettiFolder"
	confettiFolder.Parent = GamePassesFrame
	Confetti(confettiColors, confettiFolder)
	task.wait()
	local possibleConfetti = confettiFolder:GetChildren()
	if not possibleConfetti then
		task.delay(10, confettiFolder.Destroy, confettiFolder)
		-- no memory leak ma'am.
	end
	confettiDebounce = true
	task.delay(debounceDelay, function()
		confettiDebounce = false
		confettiFolder:Destroy()
	end)
	SoundManager:Play(audioTable.Hover)
end)
purchaseProduct.MouseLeave:Connect(function()
	hideHint()
	SoundManager:Play(audioTable.Leave)
end)
closePassesFrame.MouseButton1Click:Connect(function()
	changeVisibility(false, GamePassesCanvas)
	SoundManager:Play(audioTable.Leave)
end)

-- Emotes

local EmoteGui = PlayerGui:FindFirstChild("EmoteGUI") :: ScreenGui
local EmoteCanvas = EmoteGui:FindFirstChild("CanvasGroup") :: CanvasGroup

local playingAnimation = nil :: AnimationTrack?

local function playAnim(AnimationID: number)
	if not (character and humanoid and humanoid.Health < 0.1) then
		return
	end

	-- Clean up previous animation
	if playingAnimation then
		playingAnimation:Stop()
		playingAnimation:Destroy()
		playingAnimation = nil
	end

	-- Clean up old animation instance
	local oldAnim = character:FindFirstChild("LocalAnimation") :: Animation?
	if oldAnim then
		oldAnim:Destroy()
		oldAnim = nil
	end

	-- Create new animation without yielding
	local animation = Instance.new("Animation")
	animation.Parent = character
	animation.Name = "LocalAnimation"
	animation.AnimationId = "rbxassetid://" .. tostring(AnimationID)

	local animator = humanoid:FindFirstChild("Animator") :: Animator
	if not animator then
		animation:Destroy()
		return
	end

	playingAnimation = animator:LoadAnimation(animation) :: AnimationTrack
	if playingAnimation then
		playingAnimation:Play()
	end
	humanoid.WalkSpeed = 0
end

local HolderFrame = EmoteCanvas:FindFirstChild("HolderFrame") :: Frame
local HolderCircle = HolderFrame:FindFirstChild("Circle") :: ImageLabel

task.spawn(function()
	local emoteDebounce = false
	for _, emoteButtons in HolderCircle:GetChildren() do
		if emoteButtons:IsA("TextButton") then
			local defaultTextSize = emoteButtons.TextSize :: number
			emoteButtons.MouseEnter:Connect(function()
				local goal = { TextSize = emoteButtons.TextSize + 2 }
				createAndPlayTween(emoteButtons, TInfo, goal)
				SoundManager:Play(audioTable.Hover)
			end)
			emoteButtons.MouseLeave:Connect(function()
				local goal = { TextSize = defaultTextSize }
				createAndPlayTween(emoteButtons, TInfo, goal)
				SoundManager:Play(audioTable.Leave)
			end)
			emoteButtons.MouseButton1Down:Connect(function()
				if emoteDebounce then
					return
				end
				local intValue = emoteButtons:FindFirstChild("AnimID") :: IntValue
				local animation = intValue.Value
				playAnim(animation)
				emoteDebounce = true
				task.delay(debounceDelay, function()
					emoteDebounce = false
				end)
			end)
		end
	end
end)

local emoteDebounce_a0 = false
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if emoteDebounce_a0 then
		return
	end
	task.spawn(function()
		if input.UserInputType == Enum.UserInputType.Keyboard then
			local defaultPosition = UDim2.fromScale(0.5, 0.5)
			if input.KeyCode == Enum.KeyCode.Tab then
				if HolderFrame.Visible == true then
					task.wait()
					local goal = { Position = UDim2.fromScale(0.5, defaultPosition.Y.Scale + 0.2) }
					createAndPlayTween(HolderFrame, TInfo, goal)
					HolderFrame.Visible = false
					SoundManager:Play(audioTable.Leave)
					emoteDebounce_a0 = true
					task.delay(debounceDelay, function()
						emoteDebounce_a0 = false
					end)
				else
					HolderFrame.Visible = true
					SoundManager:Play(audioTable.Hover)
					task.wait()
					local goal = { Position = UDim2.fromScale(0.5, defaultPosition.Y.Scale + 0.2) }
					createAndPlayTween(HolderFrame, TInfo, goal)
					HolderFrame.Visible = true
					emoteDebounce_a0 = true
					task.delay(debounceDelay, function()
						emoteDebounce_a0 = false
					end)
				end
			end
		end
	end)
end)

print(`UI is halfway executing.`)

-- Info
local infoGui = PlayerGui:FindFirstChild("Info") :: ScreenGui
local infoCanvas = infoGui:FindFirstChild("CanvasGroup") :: CanvasGroup
local infoOpen = infoGui:FindFirstChild("FAB") :: TextButton -- Floating Action Button
local infoFrame = infoCanvas:FindFirstChild("Frame") :: Frame

local infoDebounce = false
infoOpen.MouseButton1Click:Connect(function()
	if infoDebounce == true then
		return
	end
	if infoCanvas.Visible == false then
		changeVisibility(true, infoCanvas)
		task.wait()
		changeFOV(70)
		SoundManager:Play(audioTable.Click)
	elseif infoCanvas.Visible == true then
		changeVisibility(false, infoCanvas)
		task.wait()
		SoundManager:Play(audioTable.Leave)
		changeFOV(60)
	end
	infoDebounce = true
	task.delay(debounceDelay, function()
		infoDebounce = false
	end)
end)
infoOpen.MouseEnter:Connect(function()
	showHint("Not Finished", "Blog")
	SoundManager:Play(audioTable.Hover)
end)
infoOpen.MouseLeave:Connect(function()
	hideHint()
	SoundManager:Play(audioTable.Leave)
end)
local infoTitleBar = infoFrame:FindFirstChild("TitleBar") :: Frame
local infoLeave = infoTitleBar:FindFirstChild("Back") :: TextButton
infoLeave.MouseButton1Click:Connect(function()
	changeVisibility(false, infoCanvas)
	changeFOV(60)
	SoundManager:Play(audioTable.Leave)
end)

-- Dialog
local dialogGui = PlayerGui:FindFirstChild("Dialog") :: ScreenGui
local dialogCanvas = dialogGui:FindFirstChild("CanvasGroup") :: CanvasGroup
local dialogFrame = dialogCanvas:FindFirstChild("Frame") :: Frame
local dialogText: TextLabel = dialogFrame:FindFirstChild("TextLabel") :: TextLabel

local dialogPositons = {
	[1] = UDim2.fromScale(0.5, 0.94),
	[2] = UDim2.fromScale(0.5, 3),
}

local function _commenceDialog(sender: string, text: string)
	changeFOV(60)
	local goal = { Position = dialogPositons[1] }
	local tween = createAndPlayTween(dialogFrame, TInfo, goal)
	tween.Completed:Once(function()
		-- Proceed
		dialogText.Text = "<b>" .. sender .. "</b>"
		typewriterEffect(dialogText, tostring("<br />" .. text), 0.05)
		local characters = string.len(sender .. text) / 20
		task.wait(characters)
		goal = { Position = dialogPositons[2] }
		tween = createAndPlayTween(dialogFrame, TInfo, goal)
	end)
end

-- Rank

local leaderstats = player:WaitForChild("leaderstats") :: Folder
local rank = leaderstats:WaitForChild("Rank") :: StringValue
local experiencePoints = leaderstats:WaitForChild("Experience") :: IntValue

local rankGui = PlayerGui:FindFirstChild("Rank") :: ScreenGui
local rankCanvas = rankGui:FindFirstChild("CanvasGroup") :: CanvasGroup
local rankFrame = rankCanvas:FindFirstChild("Frame") :: Frame
local experienceLabel = rankFrame:FindFirstChild("Experience") :: TextLabel
local rankLabel = rankFrame:FindFirstChild("Rank") :: TextLabel

type rankTypes = "Bronze I" | "Gold II" | "Platinum III" | "Master IV" | "Sparking V"

local function updateRankUI()
	local rankValue = rank.Value :: rankTypes
	local experienceValue = experiencePoints.Value :: number
	task.spawn(function()
		assert(RankStructure[rankValue], "Invalid rank value: " .. tostring(rankValue))

		local experience = RankStructure[rankValue].Experience :: number
		experienceLabel.Text = tostring(experienceValue) .. "/" .. tostring(experience)
	end)
	rankLabel.Text = rank.Value
	print("Updated Rank UI: ", rank.Value)
end

local rankChangedSignal = rank:GetPropertyChangedSignal("Value") :: RBXScriptSignal
local experienceChangedSignal = experiencePoints:GetPropertyChangedSignal("Value") :: RBXScriptSignal
rankChangedSignal:Connect(updateRankUI)
experienceChangedSignal:Connect(updateRankUI)

print(`UI is almost done executing.`)

local interfaceEndTime = os.clock()
local totalExecutionTime = math.round((interfaceEndTime - interfaceStartTime) * 10000) / 10000
-- This results in four decimal places.

print("UI has finished with an execution time of:", totalExecutionTime)
