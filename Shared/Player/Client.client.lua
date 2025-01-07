--!nonstrict

-- Client.client.lua

print(script.Name)

-- // Services -- //

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MarketPlaceService = game:GetService("MarketplaceService")

-- // Variables -- //

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local character = player.Character or player.CharacterAdded:Wait()
local Humanoid = character:WaitForChild("Humanoid")
local TInfo = TweenInfo.new(0.5, Enum.EasingStyle.Circular, Enum.EasingDirection.InOut)

---------------------------------- Camera --------------------------------

local ReplicateRE = ReplicatedStorage.RemoteEvents.ReplicateCutscene
local Camera = game.Workspace.CurrentCamera

local defaultCFrame = Camera.CFrame

-- Cutscenes

local replicateConnection = nil
local connection: RBXScriptConnection = nil
replicateConnection = ReplicateRE.OnClientEvent:Connect(function(cutsceneFolder: Folder)
	if not connection then
		connection = RunService.RenderStepped:Connect(function(delta)
			local frames = (delta * 60)
			local steppedFrames: CFrameValue | IntValue =
				cutsceneFolder:FindFirstChild(tonumber(math.ceil(frames)))
			character.Humanoid.AutoRotate = false
			Camera.CameraType = Enum.CameraType.Scriptable
			if steppedFrames then
				Camera.CFrame = character.HumanoidRootPart.CFrame * steppedFrames.Value
			else
				connection:Disconnect()
				connection = nil
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

---------------------------------- UI --------------------------------

-- // Requires -- /

local UIEffect = require(ReplicatedStorage.Packages.UIEffect)
local CameraService = require(ReplicatedStorage.Modules.CameraService)
local Timer = require(ReplicatedStorage.Modules.Timer)

-- local Interactions = require(ReplicatedStorage.Modules.Interactions)

-- // Remotes -- //
local DataSavedRE = ReplicatedStorage.RemoteEvents.DataSaved

-- // Functions -- //
local function handleAction(actionName, _, _, gui)
	if actionName == "Emote" then
		if gui.Visible == true then
			gui.Visible = false
		else
			gui.Visible = true
		end
	end
end

local function showTooltip(text, more)
	local tooltipFrame = player.PlayerGui.ToolTip.CanvasGroup.Frame
	tooltipFrame.Details.Text = text -- Update the tooltip text
	tooltipFrame.Visible = true
	tooltipFrame.Accept.Text = more
end

local function hideTooltip()
	local tooltipFrame = player.PlayerGui.ToolTip.CanvasGroup.Frame
	tooltipFrame.Visible = false
end

local function onHover(imgButton: ImageButton)
	local onHoverImg: Rect | string = imgButton:GetAttribute("OnHover")
	if type(onHoverImg) == "string" then
		imgButton.Image = onHoverImg
	else
		imgButton.ImageRectOffset = onHoverImg.Width
		imgButton.ImageRectSize = onHoverImg.Height
	end
end

local function onLeave(imgButton: ImageButton)
	local onLeaveImg: Vector2 | Rect | string = imgButton:GetAttribute("OnLeave")
	if onLeaveImg then
		imgButton.Image = onLeaveImg
	end
end

local function setCameraView(view)
	CameraService:SetCameraView(view)
end

local function getProducts(): { Configuration }
	local products = {}
	for _, product: Configuration in ReplicatedStorage.Purchasables:GetChildren() do
		products[product.Name] = product
	end
	print(products)
	return products
end

mouse.Move:Connect(function()
	local tooltipFrame: Frame = player.PlayerGui.ToolTip.CanvasGroup.Frame
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
local MainMenu = player.PlayerGui.MainHud
local MainMenuFrame = MainMenu.CanvasGroup.Frame
MainMenu.CanvasGroup.Visible = true
MainMenu.CanvasGroup.GroupTransparency = 0
MainMenuFrame.Visible = true
task.spawn(function() -- so we don't yield the current thread
	repeat
		task.wait()
		Camera.CameraType = Enum.CameraType.Scriptable
	until Camera.CameraType == Enum.CameraType.Scriptable
end)

--- 1604.172, 267.097, 6215.333, 24.286, 65.438, 0 -- the roads
Camera.CFrame = CFrame.new(-1721.989, 270.293, 182.625) -- Baseplate

MainMenuFrame.PlayButton.MouseButton1Click:Once(function()
	task.spawn(function() -- so we don't yield the current thread
		repeat
			task.wait()
			Camera.CameraType = Enum.CameraType.Custom
		until Camera.CameraType == Enum.CameraType.Custom
	end)
	UIEffect:changeVisibility(MainMenu.CanvasGroup, false)
end)

-- PlayerHud
local PlayerHud = player.PlayerGui.PlayerHud
local OpenProfile = PlayerHud.Player.Design.Background -- im not sure why i labelled this as background
local Profile = PlayerHud.CanvasGroup.Frame
local playerProfileImage =
	Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)

local DialogRemote = ReplicatedStorage.RemoteEvents.NewDialogue

local LargeDialog = player.PlayerGui.Dialog.CanvasGroup.Frame

local function reloadProfileImg(img: string)
	PlayerHud.Player.PlayerImage.Image = img
	Profile.Frame.PlayerImage.Image = img
	print(`Reloaded: {player.DisplayName}'s profile image. {img}`) -- debug
end

local function newDialog(dialog: string)
	task.spawn(function()
		UIEffect.TypewriterEffect(dialog, LargeDialog.TextLabel)
		UIEffect.getModule("Curvy"):Curve(LargeDialog, TInfo, "Position", UDim2.new(0.5, 0, 0.944, 0))
		UIEffect.changeColor("Blue", PlayerHud.Player.Design.Radial)
		print(`New Dialog for {player.DisplayName}: {dialog}`)
		task.wait(10)
		UIEffect.changeColor("Green", PlayerHud.Player.Design.Radial)
		UIEffect.getModule("Curvy"):Curve(LargeDialog, TInfo, "Position", UDim2.new(0.5, 0, 1.5, 0))
		LargeDialog.TextLabel.Text = "" -- cleanup
	end)
end

local function dataSaved(message: string)
	task.spawn(function()
		if not message then
			local saveStatus = PlayerHud.Player.Check
			UIEffect.changeColor("#ccb6ff", PlayerHud.Player.Design.Radial)
			UIEffect.changeColor("#ccb6ff", saveStatus)
			UIEffect.getModule("Curvy"):Curve(PlayerHud.Player.PlayerImage, TInfo, "ImageTransparency", 1)
			UIEffect.getModule("Curvy"):Curve(saveStatus, TInfo, "ImageTransparency", 0)
			saveStatus.Visible = true
			UIEffect.TypewriterEffect("Saved!", PlayerHud.Player.TextLabel)
			task.wait(5)
			UIEffect.changeColor("Green", PlayerHud.Player.Design.Radial)
			UIEffect.changeColor("Green", saveStatus)
			UIEffect.getModule("Curvy"):Curve(PlayerHud.Player.PlayerImage, TInfo, "ImageTransparency", 0)
			UIEffect.getModule("Curvy"):Curve(saveStatus, TInfo, "ImageTransparency", 1)
			saveStatus.Visible = false
		elseif message then
			local saveStatus = PlayerHud.Player.Check
			UIEffect.changeColor("#ccb6ff", PlayerHud.Player.Design.Radial)
			UIEffect.changeColor("#ccb6ff", saveStatus)
			UIEffect.getModule("Curvy"):Curve(PlayerHud.Player.PlayerImage, TInfo, "ImageTransparency", 1)
			UIEffect.getModule("Curvy"):Curve(saveStatus, TInfo, "ImageTransparency", 0)
			saveStatus.Visible = true
			UIEffect.TypewriterEffect(message, PlayerHud.Player.TextLabel)
			task.wait(5)
			UIEffect.changeColor("Green", PlayerHud.Player.Design.Radial)
			UIEffect.changeColor("Green", saveStatus)
			UIEffect.getModule("Curvy"):Curve(PlayerHud.Player.PlayerImage, TInfo, "ImageTransparency", 0)
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
	onHover(OpenProfile)
end)
DialogRemote.OnClientEvent:Connect(newDialog)
DataSavedRE.OnClientEvent:Connect(dataSaved)
PlayerHud.Player.MouseEnter:Connect(function()
	showTooltip(`That's you! <br></br><font size="8">this also doesn't work</font>`, player.DisplayName)
end)
PlayerHud.Player.MouseLeave:Connect(function()
	hideTooltip()
	onLeave(OpenProfile)
end)

print(`UI is executing.`)

-- Battle Gui
local BattleGui = player.PlayerGui.NewMatch.CanvasGroup
local NewBattle = BattleGui.Status.TextButton

local function newMatch()
	local EnterMatchRE: RemoteEvent = ReplicatedStorage.RemoteEvents.EnterMatch
	EnterMatchRE:FireServer()
	NewBattle.Text = "Finding Battle..."
	NewBattle.Interactable = false
	-- UIEffect.changeColor(newBackgroundColor, NewBattle) this wouldn't work
	TweenService:Create(NewBattle, TInfo, { BackgroundColor3 = Color3.fromHex("#000000") }):Play()
	print(`New Match for: {player.DisplayName}`)
end

NewBattle.MouseButton1Click:Connect(newMatch)
NewBattle.MouseEnter:Connect(function()
	showTooltip("This probably doesn't work yet.", "Battle")
end)
NewBattle.MouseLeave:Connect(function()
	hideTooltip()
	onLeave(NewBattle)
end)

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

local function playAnim(AnimationID)
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

for _, emoteButtons: GuiButton in HolderFrame.Circle:GetChildren() do
	if emoteButtons:IsA("GuiButton") then
		emoteButtons.MouseButton1Down:Connect(function()
			playAnim(emoteButtons.AnimID.Value)
		end)
	end
end

EmoteGui.HolderFrame.Visible = false

ContextActionService:BindAction("Emote", function()
	handleAction("Emote", Enum.UserInputState.Begin, nil, EmoteGui.HolderFrame)
end, false, Enum.KeyCode.Tab)

print(`UI is halfway executing.`)

-- Main Menu
local function mainHud()
	local MainHudGui = player.PlayerGui.MainHud
	local Canvas = MainHudGui.CanvasGroup
	local Frame = Canvas:FindFirstChild("Frame")

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
	Frame.PlayButton.MouseButton1Down:Once(continueGameplay)
end

mainHud()

-- Info
local infoGui = player.PlayerGui.Info.CanvasGroup
local infoOpen = infoGui.Parent.FAB
local infoFrame = infoGui.Frame
infoOpen.MouseButton1Click:Connect(function()
	task.wait(1)
	if infoGui.Visible == false then
		UIEffect:changeVisibility(infoGui, true)
		CameraService:ChangeFOV(70, false)
	elseif infoGui.Visible == true then
		UIEffect:changeVisibility(infoGui, false)
		CameraService:ChangeFOV(60, false)
	end
end)
infoOpen.MouseEnter:Connect(function()
	showTooltip("Not Finished", "Blog")
	onHover(infoOpen)
end)
infoOpen.MouseLeave:Connect(function()
	hideTooltip()
	onLeave(infoOpen)
end)
infoFrame.Checkout.MouseButton1Click:Connect(function()
	UIEffect:changeVisibility(infoGui, false)
end)

print(`UI is almost done executing.`)

-- Shop
local ShopGui = player.PlayerGui.Shop.CanvasGroup
local ShopOpen = ShopGui.Parent.FAB -- Floating Action Button

local function openShop()
	if ShopGui.Visible == false then
		UIEffect:changeVisibility(ShopGui, true)
		CameraService:ChangeFOV(70, false)
	elseif ShopGui.Visible == true then
		UIEffect:changeVisibility(ShopGui, false)
		CameraService:ChangeFOV(60, false)
	end
end

local products = getProducts()

local function newProductFrame(name, price, quantity, isGamePass, parent)
	local Item = Instance.new("Frame")
	local UICorner = Instance.new("UICorner")
	local Viewport = Instance.new("ViewportFrame")
	local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
	local robuxcoin1_xxlarge = Instance.new("ImageLabel")
	local TextLabel = Instance.new("TextLabel")
	local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
	local UIAspectRatioConstraint_2 = Instance.new("UIAspectRatioConstraint")
	local Divider = Instance.new("Frame")
	local UIAspectRatioConstraint_3 = Instance.new("UIAspectRatioConstraint")
	local ShoppingCart = Instance.new("ImageButton")
	local UIAspectRatioConstraint_4 = Instance.new("UIAspectRatioConstraint")
	local UIAspectRatioConstraint_5 = Instance.new("UIAspectRatioConstraint")

	Item.Name = "Item"
	Item.Parent = parent
	Item.BackgroundColor3 = Color3.fromRGB(20, 18, 24)
	Item.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Item.BorderSizePixel = 0
	Item.Size = UDim2.new(0.16853933, 0, 0.517241359, 0)

	UICorner.CornerRadius = UDim.new(0.0533333346, 0)
	UICorner.Parent = Item

	Viewport.BackgroundTransparency = 1.000
	Viewport.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Viewport.BorderSizePixel = 0
	Viewport.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Viewport.Name = "Viewport"
	Viewport.Parent = Item

	UIAspectRatioConstraint.Parent = Viewport
	UIAspectRatioConstraint.AspectRatio = 1.500

	robuxcoin1_xxlarge.Name = "robuxcoin1_xxlarge"
	robuxcoin1_xxlarge.Parent = Viewport
	robuxcoin1_xxlarge.AnchorPoint = Vector2.new(0.5, 0.5)
	robuxcoin1_xxlarge.BackgroundTransparency = 1.000
	robuxcoin1_xxlarge.Position = UDim2.new(0.5, 0, 0.5, 0)
	robuxcoin1_xxlarge.Size = UDim2.new(0, 100, 0, 100)
	robuxcoin1_xxlarge.Image = "rbxassetid://14976968451"
	robuxcoin1_xxlarge.ImageRectOffset = Vector2.new(302, 0)
	robuxcoin1_xxlarge.ImageRectSize = Vector2.new(193, 192)

	TextLabel.Parent = Item
	TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TextLabel.BackgroundTransparency = 1.000
	TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TextLabel.BorderSizePixel = 0
	TextLabel.Position = UDim2.new(0, 0, 0.666666687, 0)
	TextLabel.Size = UDim2.new(1, 0, 0.333333343, 0)
	TextLabel.Font = Enum.Font.GothamBold
	TextLabel.Text = `{string.upper(name)} %s%s x2<br></br><font color="#ccb6ff">{isGamePass}{price}</font>`
	TextLabel.TextColor3 = Color3.fromRGB(226, 224, 249)
	TextLabel.TextScaled = true
	TextLabel.TextSize = 14.000
	TextLabel.TextTransparency = 0.200
	TextLabel.TextWrapped = true

	TextLabel.Text = string.format(TextLabel.Text, "x", quantity)

	UITextSizeConstraint.Parent = TextLabel
	UITextSizeConstraint.MaxTextSize = 14

	UIAspectRatioConstraint_2.Parent = TextLabel
	UIAspectRatioConstraint_2.AspectRatio = 3.000

	Divider.Name = "Divider"
	Divider.Parent = Item
	Divider.BackgroundColor3 = Color3.fromRGB(226, 224, 249)
	Divider.BackgroundTransparency = 0.500
	Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Divider.BorderSizePixel = 0
	Divider.Position = UDim2.new(0, 0, 0.666666687, 0)
	Divider.Size = UDim2.new(1, 0, 0.00666666683, 0)

	UIAspectRatioConstraint_3.Parent = Divider
	UIAspectRatioConstraint_3.AspectRatio = 150.000

	ShoppingCart.Name = "ShoppingCart"
	ShoppingCart.Parent = Item
	ShoppingCart.Active = false
	ShoppingCart.BackgroundTransparency = 1.000
	ShoppingCart.Position = UDim2.new(0.926666677, 0, 0.913333356, 0)
	ShoppingCart.Rotation = 5.000
	ShoppingCart.Selectable = false
	ShoppingCart.Size = UDim2.new(0.159999996, 0, 0.159999996, 0)
	ShoppingCart.Image = "rbxassetid://6764432408"
	ShoppingCart.ImageColor3 = Color3.fromRGB(103, 84, 150)
	ShoppingCart.ImageRectOffset = Vector2.new(50, 800)
	ShoppingCart.ImageRectSize = Vector2.new(50, 50)

	UIAspectRatioConstraint_4.Parent = ShoppingCart
	UIAspectRatioConstraint_4.DominantAxis = Enum.DominantAxis.Height

	UIAspectRatioConstraint_5.Parent = Item

	return Item
end

local function loadProducts()
	for _, product: Configuration in pairs(products) do
		local productsFrame = ShopGui.Frame.Frame.ScrollingFrame

		local productTitle = product:GetAttribute("title")
		local productPrice = product:GetAttribute("price")
		local productQuantity = product:GetAttribute("quantity")
		local isGamePass = product:GetAttribute("isProduct")

		local productFrame = nil

		task.defer(function()
			if isGamePass == true then
				productFrame.ShoppingCart.MouseButton1Click:Connect(function()
					promptPurchase(product:GetAttribute("id"))
				end)
			end
			isGamePass = "\u{E002}" -- robux syntax
		end)

		productFrame = newProductFrame(productTitle, productPrice, productQuantity, isGamePass, productsFrame)
		productFrame.ShoppingCart.MouseHover:Connect(function()
			showTooltip("Scroll <i>up</i> to add to checkout.", productTitle)
		end)
		print("Loaded products", product, product:GetAttributes())
		-- Not Finished
		-- [TODO) Finish Shop UI
	end
end

local function unloadProducts() -- to reset the products
	local productsFrame = ShopGui.Frame.Frame.ScrollingFrame
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
			task.wait(1)
			loadProducts()
			timer:Reset()
			timer:Start()
		end
	end
end)

ShopOpen.MouseButton1Click:Connect(openShop)
ShopOpen.MouseEnter:Connect(function()
	showTooltip("Buy yourself something!", "Market/Shop")
	onHover(ShopOpen)
end)

-- Other

local function setCameraHost(otherPart)
	if type(otherPart) == "string" then
		CameraService:SetCameraView(otherPart) -- "otherPart" is a string
	else
		CameraService:SetCameraHost(otherPart)
	end
end

local function windowReleased()
	UIEffect.changeColor("Red", PlayerHud.Player.Design.Radial)
	CameraService:ChangeFOV(70, false)
	-- UIEffect:BlurEffect(true)
	PlayerHud.Player.PlayerImage.Image = playerProfileImage
	PlayerHud.Player.TextLabel.Text = player.DisplayName
end

local function windowFocused()
	UIEffect.changeColor("Green", PlayerHud.Player.Design.Radial)
	CameraService:ChangeFOV(60, false)
	-- UIEffect:BlurEffect(false)
	PlayerHud.Player.PlayerImage.Image = playerProfileImage
	PlayerHud.Player.TextLabel.Text = player.DisplayName
end

UserInputService.WindowFocusReleased:Connect(windowReleased)
UserInputService.WindowFocused:Connect(windowFocused)
ReplicatedStorage.RemoteEvents.SetCameraHost.OnClientEvent:Connect(setCameraHost)
ReplicatedStorage.RemoteEvents.SetCameraView.OnClientEvent:Connect(setCameraView)

print(`UI has finished executing.`)
