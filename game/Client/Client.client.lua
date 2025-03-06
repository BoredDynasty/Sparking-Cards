--!nonstrict

-- Client.client.lua

print(script.Name)

-- // Services -- //

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MarketPlaceService = game:GetService("MarketplaceService")

-- // Variables -- //

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local character = player.Character or player.CharacterAdded:Wait()
local Humanoid = character:WaitForChild("Humanoid") :: Humanoid
local TInfo = TweenInfo.new(0.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut)

local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents") :: Folder

---------------------------------- Camera --------------------------------

-- // Requires -- //

-- selene: allow(incorrect_standard_library_use)
local OverShoulder = require("./Modules/OverShoulder")

OverShoulder:Enable(true)

local ReplicateRE = RemoteEvents:FindFirstChild("ReplicateCutscene") :: RemoteEvent
local Camera = game.Workspace.CurrentCamera

local defaultCFrame = Camera.CFrame

-- Cutscenes

local replicateConnection: RBXScriptConnection = nil
local connection: RBXScriptConnection = nil
replicateConnection = ReplicateRE.OnClientEvent:Connect(function(cutsceneFolder: Folder)
	if not connection then
		connection = RunService.RenderStepped:Connect(function(delta: number)
			local frames = (delta * 60)
			local steppedFrames = cutsceneFolder:WaitForChild(tostring(math.ceil(frames))) :: CFrameValue
			Humanoid.AutoRotate = false
			Camera.CameraType = Enum.CameraType.Scriptable
			if steppedFrames then
				local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
				Camera.CFrame = humanoidRootPart.CFrame * steppedFrames.Value
			else
				if connection then
					connection:Disconnect()
				end
				Humanoid.AutoRotate = true
				Camera.CameraType = Enum.CameraType.Custom
				Camera.CFrame = defaultCFrame
			end
		end)
	end
end)

-- Sway

local function lerp(a: number, b: number, t: number)
	return a + (b - a) * t
end

local RenderPriority = Enum.RenderPriority.Camera.Value + 1
RunService:BindToRenderStep("Camera-Sway", RenderPriority, function(delta)
	local mouseDelta = UserInputService:GetMouseDelta()
	local sway = 0
	sway = lerp(sway, math.clamp(mouseDelta.X, -6, 6), (15 * delta))
	local rz = math.rad(sway)
	if not replicateConnection then
		Camera.CFrame = Camera.CFrame * CFrame.Angles(0, 0, rz)
	end
end)

-- Head Bobbing

local function bobble(humanoid: Humanoid)
	if humanoid.MoveDirection.Magnitude > 0 then
		local currentTime = tick()
		local x = math.cos(currentTime * 5) * 0.25
		local y = math.abs(math.sin(currentTime * 5)) * 0.25
		local offset = Vector3.new(x, y, 0)
		humanoid.CameraOffset = humanoid.CameraOffset:Lerp(offset, 0.25)
		-- print("bobbling")
	else
		humanoid.CameraOffset = humanoid.CameraOffset * 0.25
	end
end

task.spawn(function()
	RunService.RenderStepped:Connect(function()
		if character then
			local humanoid = character:WaitForChild("Humanoid") :: Humanoid
			if humanoid and humanoid.Health > 0 then
				bobble(Humanoid)
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

RunService:BindToRenderStep("Tilt", RenderPriority, function()
	-- print("tilting")
	if character then
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		if humanoid then
			roll(humanoid)
		end
	end
end)

print("Camera has finished executing.")

---------------------------------- UI --------------------------------

-- // Requires -- //

local CameraService = require(ReplicatedStorage.Modules.CameraService)
local Timer = require(ReplicatedStorage.Modules.Timer)
local UIEffect = require(ReplicatedStorage.Modules.UIEffect)
local UserInputType = require(ReplicatedStorage.Modules.UserInputType)

-- local Interactions = require(ReplicatedStorage.Modules.Interactions)

local PlayerGui = player:WaitForChild("PlayerGui")

-- // Remotes -- //
local DataSavedRE = RemoteEvents:FindFirstChild("DataSaved") :: RemoteEvent

-- // Functions -- //

local function showTooltip(text: string, more: string)
	local tooltipGui = PlayerGui:FindFirstChild("ToolTip") :: ScreenGui
	local canvasGroup = tooltipGui:FindFirstChild("CanvasGroup") :: CanvasGroup
	local tooltipFrame = canvasGroup:FindFirstChild("Frame") :: Frame

	local details = tooltipFrame:WaitForChild("Details") :: TextLabel
	local accept = tooltipFrame:WaitForChild("Accept") :: TextButton
	details.Text = text -- Update the tooltip text
	tooltipFrame.Visible = true
	accept.Text = more
end

local function hideTooltip()
	local tooltipGui = PlayerGui:FindFirstChild("ToolTip") :: ScreenGui
	local canvasGroup = tooltipGui:FindFirstChild("CanvasGroup") :: CanvasGroup
	local tooltipFrame = canvasGroup:FindFirstChild("Frame") :: Frame
	tooltipFrame.Visible = false
end

local function setCameraView(view: unknown)
	CameraService:SetCameraView(view)
end

local function getProducts(): { [string]: Configuration }
	local products = {}
	local purchasables = ReplicatedStorage:FindFirstChild("Purchaseables") :: Folder
	for _, product in pairs(purchasables:GetChildren()) do
		if product:IsA("Configuration") then
			products[product.Name] = product
		end
	end
	print(products)
	return products
end
--[[
local function getDeviceOS()
	return player:GetPlatform() -- deprecated
	-- but still works!
end
--]]
--[[
local function checkMobileDevice()
	if
		UserInputService.TouchEnabled
		and not UserInputService.KeyboardEnabled
		and not UserInputService.MouseEnabled
	then
		print("Player is using a mobile device")
		return true
	end
end
--]]
mouse.Move:Connect(function()
	local tooltipGui = PlayerGui:FindFirstChild("ToolTip") :: ScreenGui
	local canvas = tooltipGui:FindFirstChild("CanvasGroup") :: Frame | CanvasGroup
	local tooltipFrame: Frame = canvas:FindFirstChild("Frame") :: Frame
	if tooltipFrame.Visible then
		-- local xOffset, yOffset = 0, 0 -- Add some padding
		local position: UDim2
		position = UDim2.new(0.5, 0, 0.5, 0)
		tooltipFrame.Position = position
		tooltipFrame.Position = position

		CameraService:ChangeFOV(70, false)
		-- local position = UDim2.new(0, mouse.X + xOffset, 0, mouse.Y + yOffset)
	else
		CameraService:ChangeFOV(60, false)
	end
end)

-- // Everything else -- //

-- Main Menu
task.spawn(function()
	local MainMenu = PlayerGui:WaitForChild("MainHud") :: ScreenGui
	local canvas = MainMenu:WaitForChild("Canvas") :: CanvasGroup
	local MainMenuFrame = canvas:FindFirstChild("Frame") :: Frame
	canvas.Visible = true
	canvas.GroupTransparency = 0
	MainMenuFrame.Visible = true
	repeat
		task.wait() --  We use spawn so we don't yield the cur. thread
		Camera.CameraType = Enum.CameraType.Scriptable
	until Camera.CameraType == Enum.CameraType.Scriptable

	--- 1604.172, 267.097, 6215.333, 24.286, 65.438, 0 -- the roads

	local cameraPositions = {
		CFrame.new(-1721.989, 270.293, 182.625), -- Baseplate
	} :: { CFrame }

	player:RequestStreamAroundAsync(
		Vector3.new(
			cameraPositions[1].Position.X,
			cameraPositions[1].Position.Y,
			cameraPositions[1].Position.Z
		),
		20
	)
	Camera.CFrame = CFrame.new(cameraPositions[1]) -- Baseplate

	local playButton = MainMenuFrame:FindFirstChild("PlayButton") :: TextButton

	playButton.MouseButton1Click:Once(function()
		task.spawn(function() -- so we don't yield the current thread
			repeat
				task.wait()
				Camera.CameraType = Enum.CameraType.Custom
			until Camera.CameraType == Enum.CameraType.Custom
		end)
		UIEffect:changeVisibility(canvas, false)
	end)
end)

-- PlayerHud
local PlayerHud = PlayerGui:FindFirstChild("PlayerHud") :: ScreenGui
local PlayerProfile = PlayerHud:WaitForChild("Player")
local ProfileCanvas = PlayerHud:WaitForChild("CanvasGroup")
local OpenProfile = PlayerProfile.Design.Background -- im not sure why i labelled this as background
local Profile = ProfileCanvas.Frame :: Frame
local playerProfileImage =
	Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)

local DialogRemote = ReplicatedStorage.RemoteEvents.NewDialogue :: RemoteEvent

local LargeDialog = player.PlayerGui.Dialog.CanvasGroup.Frame :: Frame

local function reloadProfileImg(img: string)
	PlayerHud.Player.PlayerImage.Image = img
	Profile.Frame.PlayerImage.Image = img
	print("Reloaded: " .. player.DisplayName .. "'s profile image. {img}")
end

local function newDialog(dialog: string)
	UIEffect.TypewriterEffect(dialog, LargeDialog.TextLabel)
	UIEffect.getModule("Curvy"):Curve(LargeDialog, TInfo, "Position", UDim2.new(0.5, 0, 0.944, 0))
	UIEffect.changeColor("Blue", PlayerHud.Player.Design.Radial)
	print(`New Dialog for {player.DisplayName}: {dialog}`)
	task.delay(10, function()
		UIEffect.changeColor("Green", PlayerHud.Player.Design.Radial)
		UIEffect.getModule("Curvy"):Curve(LargeDialog, TInfo, "Position", UDim2.new(0.5, 0, 1.5, 0))
		LargeDialog.TextLabel.Text = "" -- cleanup
	end)
end

local function dataSaved(message: string)
	task.spawn(function()
		local PH_Player = PlayerHud:FindFirstChild("Player") :: Frame
		local playerImage = PH_Player:FindFirstChild("PlayerImage") :: ImageLabel
		local design = PH_Player:FindFirstChild("Design") :: Frame
		local radial = design:FindFirstChild("Radial") :: any
		if not message then
			local saveStatus = PH_Player:FindFirstChild("Check") :: any
			UIEffect.changeColor("#ccb6ff", radial)
			UIEffect.changeColor("#ccb6ff", saveStatus)
			UIEffect.getModule("Curvy"):Curve(playerImage, TInfo, "ImageTransparency", 1)
			UIEffect.getModule("Curvy"):Curve(saveStatus, TInfo, "ImageTransparency", 0)
			saveStatus.Visible = true
			UIEffect.TypewriterEffect("Saved!", PH_Player.TextLabel)
			task.wait(5)
			UIEffect.changeColor("Green", radial)
			UIEffect.changeColor("Green", saveStatus)
			UIEffect.getModule("Curvy"):Curve(playerImage, TInfo, "ImageTransparency", 0)
			UIEffect.getModule("Curvy"):Curve(saveStatus, TInfo, "ImageTransparency", 1)
			saveStatus.Visible = false
		elseif message then
			local saveStatus = PH_Player:FindFirstChild("Check") :: any
			UIEffect.changeColor("#ccb6ff", radial)
			UIEffect.changeColor("#ccb6ff", saveStatus)
			UIEffect.getModule("Curvy"):Curve(PH_Player.PlayerImage, TInfo, "ImageTransparency", 1)
			UIEffect.getModule("Curvy"):Curve(saveStatus, TInfo, "ImageTransparency", 0)
			saveStatus.Visible = true
			UIEffect.TypewriterEffect(message, PH_Player.TextLabel)
			task.wait(5)
			UIEffect.changeColor("Green", radial)
			UIEffect.changeColor("Green", saveStatus)
			UIEffect.getModule("Curvy"):Curve(playerImage, TInfo, "ImageTransparency", 0)
			UIEffect.getModule("Curvy"):Curve(saveStatus, TInfo, "ImageTransparency", 1)
			saveStatus.Visible = false
		end
	end)
end

local function openProfileGui()
	if Profile.Visible == false then
		UIEffect.changeColor("Blue", OpenProfile)
		UIEffect:changeVisibility(Profile.Parent, true)
		CameraService:ChangeFOV(60, false)
		-- UIEffect:BlurEffect(true)
		reloadProfileImg(playerProfileImage)
	elseif Profile.Visible == true then
		UIEffect.changeColor("Green", OpenProfile)
		UIEffect:changeVisibility(Profile.Parent, false)
		CameraService:ChangeFOV(70, false)
		-- UIEffect:BlurEffect(false)
		reloadProfileImg(playerProfileImage)
	end
end

OpenProfile.MouseButton1Click:Connect(openProfileGui)
OpenProfile.MouseEnter:Connect(function()
	--onHover(OpenProfile)
end)
DialogRemote.OnClientEvent:Connect(newDialog)
DataSavedRE.OnClientEvent:Connect(dataSaved)
PlayerHud.Player.MouseEnter:Connect(function()
	showTooltip(`That's you! <br></br><font size="8">this also doesn't work</font>`, player.DisplayName)
end)
PlayerHud.Player.MouseLeave:Connect(function()
	hideTooltip()
	--onLeave(OpenProfile)
end)
PlayerHud.Player.MouseButton1Click:Connect(openProfileGui)

print(`UI is executing.`)

-- Battle Gui
local BattleGui = player.PlayerGui.NewMatch.CanvasGroup :: CanvasGroup
local NewBattle = BattleGui.Status.TextButton :: TextButton

local function newMatch()
	local EnterMatchRE: RemoteEvent = ReplicatedStorage.RemoteEvents.EnterMatch
	EnterMatchRE:FireServer()
	NewBattle.Text = "Finding Battle..."
	NewBattle.Interactable = false
	-- UIEffect.changeColor(newBackgroundColor, NewBattle) this wouldn't work
	local goal = { BackgroundColor3 = Color3.fromHex("#000000") }
	TweenService:Create(NewBattle, TInfo, goal):Play()
	print(`New Match for: {player.DisplayName}`)
end

NewBattle.MouseButton1Click:Connect(newMatch)
NewBattle.MouseEnter:Connect(function()
	showTooltip("This probably doesn't work yet.", "Battle")
end)
NewBattle.MouseLeave:Connect(function()
	hideTooltip()
	-- onLeave(NewBattle)
end)

-- Gamepasses

local DynamicUI = PlayerGui:FindFirstChild("DynamicUI") :: Folder
local BuyCards = DynamicUI:FindFirstChild("BuyCards") :: ScreenGui
local BuyCanvas = BuyCards:FindFirstChild("CanvasGroup") :: CanvasGroup
local BuyFrame = BuyCanvas:FindFirstChild("Frame") :: Frame
local BuyButton = BuyFrame:FindFirstChild("Buy") :: TextButton

local buyLabel = [[Purchase Cards <br></br><font color="#21005d">\s</font>]]

local function getLastLogin(lastLogin)
	local currentDate = os.date("*t") -- Get current date table
	local lastDate = os.date("*t", lastLogin) -- Convert last login timestamp to date table

	-- Check if the last login was on a different day
	return currentDate.year ~= lastDate.year or currentDate.yday ~= lastDate.yday
end

local function promptPurchase(ID)
	MarketPlaceService:PromptProductPurchase(player, ID)
	print("Prompted Purchase for ID: ", ID)
end

local showModal = true

if player.MembershipType == Enum.MembershipType.Premium then
	BuyButton.Text = string.format(buyLabel, "") -- Premium Icon
	local lastLoginRE = RemoteEvents:FindFirstChild("GetLastLogin") :: RemoteFunction
	local lastLogin = lastLoginRE:InvokeServer(player)
	if getLastLogin(lastLogin) then
		local giveCardsRE = RemoteEvents:FindFirstChild("GiveCards") :: RemoteEvent
		BuyButton.MouseButton1Click:Once(function()
			giveCardsRE:FireServer(50, "Premium")
		end)
	end
else
	BuyButton.Text = string.format(buyLabel, "15") -- Robux Icon
	-- Show purchase modal, using debounce to show once every few seconds at most
	if not showModal then
		return
	end
	showModal = false
	task.delay(5, function()
		showModal = true
	end)
	BuyButton.MouseButton1Click:Connect(function()
		promptPurchase(1904591683) -- Buying Cards
		print("Prompted purchase: ", player, tostring(1904591683))
	end)
	MarketPlaceService:PromptPremiumPurchase(player)
	print("Prompted Premium Purchase ", player)
end

local function onMembershipChanged()
	print("Membership Changed for: ", player, player.MembershipType)
	if player.MembershipType == Enum.MembershipType.Premium then
		local lastLoginRE = RemoteEvents:FindFirstChild("GetLastLogin") :: RemoteFunction
		local lastLogin = lastLoginRE:InvokeServer(player)
		if getLastLogin(lastLogin) then
			local giveCardsRE = RemoteEvents:FindFirstChild("GiveCards") :: RemoteEvent
			giveCardsRE:FireServer(50, "Premium")
		end
	else
		BuyButton.Text = string.format(buyLabel, "15") -- Robux Icon
		-- Show purchase modal, using debounce to show once every few seconds at most
		if not showModal then
			return
		end
		showModal = false
		task.delay(5, function()
			showModal = true
		end)
		MarketPlaceService:PromptPremiumPurchase(player)
		print("Prompted Premium Purchase ", player)
	end
end

player.Changed:Connect(function(property)
	if property == "MembershipType" then
		onMembershipChanged()
	end
end)

-- Emotes

local EmoteGui = PlayerGui:FindFirstChild("EmoteGui") :: ScreenGui

local playingAnimation = nil :: AnimationTrack?

local function playAnim(AnimationID)
	if character and Humanoid then
		local anim = "rbxassetid://" .. tostring(AnimationID)
		local oldnim = character:FindFirstChild("LocalAnimation") :: Animation
		Humanoid.WalkSpeed = 0
		if playingAnimation ~= nil then
			playingAnimation:Stop()
		end
		if oldnim then
			if oldnim.AnimationId == anim then
				oldnim:Destroy() -- no memory leak today!
				Humanoid.WalkSpeed = 14
				return
			end
			oldnim:Destroy()
		end
		local animation = Instance.new("Animation")
		animation.Parent = character
		animation.Name = "LocalAnimation"
		animation.AnimationId = anim

		local animator = Humanoid:FindFirstChild("Animator") :: Animator

		playingAnimation = animator:LoadAnimation(animation)
		playingAnimation:Play()
		Humanoid.WalkSpeed = 0
	end
end

local HolderFrame = EmoteGui:FindFirstChild("HolderFrame") :: Frame
local HolderCircle = HolderFrame:FindFirstChild("Circle") :: ImageLabel

for _, emoteButtons in HolderCircle:GetChildren() do
	if emoteButtons:IsA("GuiButton") then
		emoteButtons.MouseButton1Down:Connect(function()
			local intValue = emoteButtons:FindFirstChild("AnimID") :: IntValue
			playAnim(intValue.Value)
		end)
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Tab then
				if HolderFrame.Visible == true then
					HolderFrame.Visible = false
				else
					HolderFrame.Visible = true
				end
			end
		end
	end
end)

print(`UI is halfway executing.`)

-- Main Menu
local function mainHud()
	local MainHudGui = PlayerGui:FindFirstChild("MainHud") :: ScreenGui
	local Canvas = MainHudGui:FindFirstChild("CanvasGroup") :: CanvasGroup
	local Frame = Canvas:FindFirstChild("Frame") :: Frame

	Canvas.GroupTransparency = 0

	local function continueGameplay()
		UIEffect:changeVisibility(Canvas, false)
		task.spawn(function()
			repeat
				task.wait()
				Camera.CameraType = Enum.CameraType.Custom
			until Camera.CameraType == Enum.CameraType.Custom
		end)
	end
	local playButton = Frame:FindFirstChild("PlayButton") :: TextButton
	playButton.MouseButton1Down:Once(continueGameplay)
end

mainHud()

-- Info
local infoGui = PlayerGui:FindFirstChild("Info") :: ScreenGui
local infoCanvas = infoGui:FindFirstChild("CanvasGroup") :: CanvasGroup
local infoOpen = infoCanvas:FindFirstChild("FAB") :: TextButton -- Floating Action Button
local infoFrame = infoCanvas:FindFirstChild("Frame") :: Frame
infoOpen.MouseButton1Click:Connect(function()
	if infoCanvas.Visible == false then
		UIEffect:changeVisibility(infoGui, true, {
			UDim2.fromScale(0.5, 0.5),
		})
		CameraService:ChangeFOV(70, false)
	elseif infoCanvas.Visible == true then
		UIEffect:changeVisibility(infoGui, false, {
			UDim2.fromScale(0.5, infoCanvas.Position.Y.Scale - 0.2),
		})
		CameraService:ChangeFOV(60, false)
	end
end)
infoOpen.MouseEnter:Connect(function()
	showTooltip("Not Finished", "Blog")
	--onHover(infoOpen)
end)
infoOpen.MouseLeave:Connect(function()
	hideTooltip()
	--onLeave(infoOpen)
end)
local infoLeave = infoFrame:FindFirstChild("Checkout") :: TextButton
infoLeave.MouseButton1Click:Connect(function()
	UIEffect:changeVisibility(infoGui, false)
end)

print(`UI is almost done executing.`)

-- Shop
local ShopGui = PlayerGui:FindFirstChild("Shop") :: ScreenGui
local ShopCanvas = ShopGui:FindFirstChild("CanvasGroup") :: CanvasGroup
local ShopFrame = ShopCanvas:FindFirstChild("Frame") :: Frame
local ShopOpen = ShopCanvas:FindFirstChild("FAB") :: TextButton -- Floating Action Button

local function openShop()
	if ShopCanvas.Visible == false then
		UIEffect:changeVisibility(ShopCanvas, true, {
			UDim2.fromScale(0.5, 0.5),
		})
		CameraService:ChangeFOV(70, false)
	elseif ShopCanvas.Visible == true then
		UIEffect:changeVisibility(ShopCanvas, false, {
			UDim2.fromScale(0.5, ShopFrame.Position.Y.Scale - 0.2),
		})
		CameraService:ChangeFOV(60, false)
	end
end

local products = getProducts()

--[[
-- Function to convert UDim2 to Vector2
local function UDim2ToVector2(udim2: UDim2)
	local x = udim2.X.Scale * workspace.CurrentCamera.ViewportSize.X + udim2.X.Offset
	local y = udim2.Y.Scale * workspace.CurrentCamera.ViewportSize.Y + udim2.Y.Offset
	return Vector2.new(x, y)
end
--]]

local function getProductImg(product: Configuration): { Vector2 | Vector2 | string }
	local assets = ReplicatedStorage:WaitForChild("Assets")
	local assetImgs = assets:FindFirstChild("Images", true) :: Folder
	local returnValue = nil
	if not product:GetAttribute("isProduct") or product:GetAttribute("isProduct") == false then
		local assetName = `{product.Name}Img`
		local assetImage = assetImgs:FindFirstChild(assetName)
		if assetImage then
			local offset = assetImage:GetAttribute("offset") :: Vector2
			local size = assetImage:GetAttribute("size") :: Vector2
			local id: any = assetImage:GetAttribute("id") :: any
			returnValue = { offset, size, id }
		end
	end
	return returnValue
end

local function newProductFrame(name: string, price, quantity, isGamePass, parent)
	-- Instances:

	local Chip = Instance.new("Frame")
	local UICorner = Instance.new("UICorner")
	local ImageLabel = Instance.new("ImageLabel")
	local Element = Instance.new("TextLabel")

	local offset, size, id =
		getProductImg(products[name])[1], getProductImg(products[name])[2], getProductImg(products[name])[3]
	--Properties:

	Chip.Name = tostring(name)
	Chip.Parent = parent
	Chip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Chip.BackgroundTransparency = 1.000
	Chip.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Chip.BorderSizePixel = 0
	Chip.Size = UDim2.new(0, 80, 0, 27)

	UICorner.Parent = Chip

	ImageLabel.Parent = Chip
	ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ImageLabel.BackgroundTransparency = 1.000
	ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ImageLabel.BorderSizePixel = 0
	ImageLabel.Size = UDim2.new(0, 27, 0, 27)
	ImageLabel.ImageColor3 = Color3.fromRGB(226, 224, 249)
	ImageLabel.ImageTransparency = 0.200
	if not isGamePass or isGamePass == false then
		ImageLabel.Image = id
		ImageLabel.ImageRectOffset = Vector2.new(offset.X, offset.Y)
		ImageLabel.ImageRectSize = Vector2.new(size.X, size.Y)
	elseif isGamePass == true then
		ImageLabel.Image = "rbxassetid://14755021654"
		ImageLabel.ImageRectOffset = Vector2.new(904, 218)
		ImageLabel.ImageRectSize = Vector2.new(108, 108)
	end

	Element.Name = "Element"
	Element.Parent = Chip
	Element.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Element.BackgroundTransparency = 1.000
	Element.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Element.BorderSizePixel = 0
	Element.Position = UDim2.new(0.216000363, 0, 0, 0)
	Element.Size = UDim2.new(0, 60, 0, 27)
	Element.Font = Enum.Font.GothamBold
	Element.Text = tostring(string.upper(name))
	Element.TextColor3 = Color3.fromRGB(234, 221, 255)
	Element.TextSize = 14.000

	-- Accesibilty:
	Chip.MouseEnter:Connect(function()
		local content =
			`Scroll <i>up</i> to add to checkout.<br></br>Price: {price}<br></br>Quantity: {quantity}`
		showTooltip(content, name)
	end)
	Chip.MouseLeave:Connect(hideTooltip)
	print(Chip)
	return Chip
end

local function loadProducts()
	for _, product: Configuration in pairs(products) do
		local productsFrame = ShopGui.Frame.Frame.ScrollingFrame :: ScrollingFrame

		local productTitle = product:GetAttribute("title") :: any
		local productPrice = product:GetAttribute("price") :: number
		local productQuantity = product:GetAttribute("quantity") :: number
		local isGamePass = product:GetAttribute("isProduct") :: any

		local productFrame: Frame = nil

		task.defer(function()
			if isGamePass == true then
				productFrame.MouseWheelForward:Connect(function()
					promptPurchase(product:GetAttribute("id"))
				end)
			end
			isGamePass = "\u{E002}" -- robux syntax
		end)

		productFrame = newProductFrame(productTitle, productPrice, productQuantity, isGamePass, productsFrame)
		print("Loaded products", product, product:GetAttributes())
		-- Not Finished
		-- [TODO) Finish Shop UI
	end
end

local function unloadProducts() -- to reset the products
	local productsFrame = ShopGui.Frame.Frame.ScrollingFrame :: ScrollingFrame
	print("Unloading products")
	for _, item in productsFrame:GetChildren() do
		if item.Name == "Item" then
			print("Product unloaded", item)
			item:Destroy()
		end
	end
end

task.spawn(function() -- run in its own thread
	local timer = Timer.new()
	timer:Start()
	while true do
		task.wait(1)
		if timer.elapsedTime >= 60 then
			unloadProducts()
			task.wait(3)
			loadProducts()
			timer:Reset()
			timer:Start()
		end
	end
end)

ShopOpen.MouseButton1Click:Connect(openShop)
ShopOpen.MouseEnter:Connect(function()
	showTooltip("Buy yourself something!", "Market/Shop")
	--onHover(ShopOpen)
end)

-- Mobile Support

local Navigation = player.PlayerGui.Mobile.Navigation.CanvasGroup :: CanvasGroup

if UserInputType() == "Touch" then --[TODO) Fix this
	print("Mobile Detected", UserInputType())
	Navigation.Visible = true
	local navigationRail = Navigation.Frame :: Frame
	local isNavigationOpen = false
	local Curvy = UIEffect.getModule("Curvy")
	task.spawn(function()
		-- Remove the PC Navigation
		ShopOpen.Visible = false
		infoOpen.Visible = false
		NewBattle.Parent.Parent.Visible = false
		OpenProfile.Parent.Parent.Visible = false
		task.wait(30 * 2)
		showTooltip("Navigation is available on mobile devices.", "Mobile")
		task.wait(15 * 2)
		showTooltip("Long press for more info.", "Mobile")
	end)
	-- Add the Mobile Navigation
	Navigation.FAB.MouseButton1Click:Connect(function() -- navigation
		if isNavigationOpen == false then
			isNavigationOpen = true
			local background = Navigation.Background :: Frame -- design
			local newTInfo = TweenInfo.new(0.1)
			background.AnchorPoint = Vector2.new(1, 0.5)
			Curvy:Curve(navigationRail, newTInfo, "Size", UDim2.fromScale(0.243, 0.071))
			Curvy:Curve(background, TweenInfo.new((newTInfo.Time - 0.05)), "Transparency", 0)
			Curvy:Curve(background, newTInfo, "Size", UDim2.fromScale(0.276, 0.071))
		elseif isNavigationOpen == true then
			isNavigationOpen = false
			local background = Navigation.Background -- design
			local newTInfo = TweenInfo.new(0.1)
			background.AnchorPoint = Vector2.new(1, 0.5)
			Curvy:Curve(navigationRail, newTInfo, "Size", UDim2.fromScale(0, 0.071))
			Curvy:Curve(background, TweenInfo.new((newTInfo.Time - 0.05)), "Transparency", 1)
			local a: Tween = Curvy:Curve(background, newTInfo, "Size", UDim2.fromScale(0, 0.071))
			a.Completed:Connect(function()
				background.AnchorPoint = Vector2.new(0.5, 0.5)
			end)
		end
	end)
	-- RBXScriptSignal Events
	navigationRail.Shop.TouchTap:Connect(openShop)
	navigationRail.Shop.TouchLongPress:Connect(function()
		showTooltip("Buy yourself something!", "Market/Shop")
	end)
	navigationRail.Info.TouchTap:Connect(function()
		if infoGui.Visible == false then
			UIEffect:changeVisibility(infoGui, true, {
				UDim2.fromScale(0.5, 0.5),
			})
			CameraService:ChangeFOV(70, false)
		elseif infoGui.Visible == true then
			UIEffect:changeVisibility(infoGui, false, {
				UDim2.fromScale(0.5, infoGui.Position.Y.Scale - 0.2),
			})
			CameraService:ChangeFOV(60, false)
		end
	end)
	navigationRail.Info.TouchLongPress:Connect(function()
		showTooltip("Not Finished", "Blog")
	end)
	navigationRail.Battle.TouchTap:Connect(newMatch)
	navigationRail.Battle.TouchLongPress:Connect(function()
		showTooltip("This probably doesn't work yet.", "Battle")
	end)
	navigationRail.Profile.TouchTap:Connect(openProfileGui)
	navigationRail.Profile.TouchLongPress:Connect(function()
		showTooltip(`That's you! <br></br><font size="8">this also doesn't work</font>`, player.DisplayName)
	end)
else
	Navigation.Visible = false
	print("Mobile Not Detected", UserInputType())
end

-- Other

local function setCameraHost(otherPart)
	if type(otherPart) == "string" then
		CameraService:SetCameraView(otherPart) -- "otherPart" is a string
	else
		CameraService:SetCameraHost(otherPart)
	end
end

local function windowReleased()
	print("Window Released")
	if UserInputType() ~= "Touch" then
		UIEffect.changeColor("Red", PlayerHud.Player.Design.Radial)
		CameraService:ChangeFOV(70, false)
		-- UIEffect:BlurEffect(true)
		PlayerHud.Player.PlayerImage.Image = playerProfileImage
		PlayerHud.Player.TextLabel.Text = player.DisplayName
	end
end

local function windowFocused()
	print("Window Focused")
	if UserInputType() ~= "Touch" then
		UIEffect.changeColor("Green", PlayerHud.Player.Design.Radial)
		CameraService:ChangeFOV(60, false)
		-- UIEffect:BlurEffect(false)
		PlayerHud.Player.PlayerImage.Image = playerProfileImage
		PlayerHud.Player.TextLabel.Text = player.DisplayName
	end
end

UserInputService.WindowFocusReleased:Connect(windowReleased)
UserInputService.WindowFocused:Connect(windowFocused)
RemoteEvents.SetCameraHost.OnClientEvent:Connect(setCameraHost)
RemoteEvents.SetCameraView.OnClientEvent:Connect(setCameraView)

print(`UI has finished executing.`)
