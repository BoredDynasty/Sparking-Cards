--!nonstrict
--2!optimize

--# selene: allow(incorrect_standard_library_use)

-- Client.client.luau

print(script.Name)

-- // Services -- //

local MarketPlaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

-- // Requires -- //

local CardAwarder = require(StarterPlayer.StarterPlayerScripts.Gameplay.CardAwarder)
local Cards = require(ReplicatedStorage.Market.Cards)
local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))
local CombatModes = require(ReplicatedStorage.Structures.CombatModes)
local Confetti = require(Players.LocalPlayer.PlayerScripts.Modules.Confetti)
local CustomCharacter = require(ReplicatedStorage.Managers.CustomCharacter)
local Dialog = require(StarterPlayer.StarterPlayerScripts.Components.Dialog)
local DisplayOrder = require(StarterPlayer.StarterPlayerScripts.Modules.DisplayOrder).new()
local Dropdown = require(Players.LocalPlayer.PlayerScripts.Components.Dropdown)
local Emphasis = require(ReplicatedStorage.Utility.Emphasis)
local GameCamera = require(StarterPlayer.StarterPlayerScripts.Modules.GameCamera)
local Hint = require("../Components/Hint")
local Keyboard = require(ReplicatedStorage.Utility.input.Keyboard).new()
local LightingManipulation = require(StarterPlayer.StarterPlayerScripts.Modules.LightingManipulation)
local Movement = require(StarterPlayer.StarterPlayerScripts.Movement.Movement)
local MovementStructure = require(ReplicatedStorage.Structures.MovementStructure)
local OverShoulder = require(StarterPlayer.StarterPlayerScripts.Modules.OverShoulder)
local Packet = require(ReplicatedStorage.Packet)
local Pop = require(Players.LocalPlayer.PlayerScripts.Modules.Pop)
local RankStructure = require(ReplicatedStorage.Structures.RankStructure)
local Saturation = require(StarterPlayer.StarterPlayerScripts.Modules.Saturation)
local SignalPlus = require(ReplicatedStorage.Utility.SignalPlus)
local TextPlus = require(ReplicatedStorage.Utility.TextPlus)
local TweenPlus = require(ReplicatedStorage.Utility.TweenPlus)
local alter = require(StarterPlayer.StarterPlayerScripts.Utilities.alter)
local audio = require(ReplicatedStorage.Modules.audio).new()
local characterUtility = require(ReplicatedStorage.Utility.character)
local dictionary = require(ReplicatedStorage.Utility.dictionary)
local indict = require(StarterPlayer.StarterPlayerScripts.Utilities.indict)
local leventine = require(ReplicatedStorage.Utility.leventine)
local limits = require(StarterPlayer.StarterPlayerScripts.Utilities.limits)
local observer = require(ReplicatedStorage.Utility.observer)
local playerzone = require(ReplicatedStorage.Utility.playerzone)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local promise = require(ReplicatedStorage.Packages.promise)
local random = require(ReplicatedStorage.Utility.random)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local retryer = require(ReplicatedStorage.Utility.retryer)
local sequence = require(StarterPlayer.StarterPlayerScripts.Interface.sequence).new()
local statemachine = require(ReplicatedStorage.Utility.statemachine)
local swipe = require(StarterPlayer.StarterPlayerScripts.Interface.swipe)
local timer = require(ReplicatedStorage.Modules.timer)

print("Client Requirements")

-- // Types -- //

type Character = Model & {
	Humanoid: Humanoid & {
		HumanoidDescription: HumanoidDescription,
		Animator: Animator,
	},
	HumanoidRootPart: BasePart,
	BodyColors: BodyColors,
	PrimaryPart: BasePart,
	Animate: LocalScript,
	Head: BasePart,
	LocalAnimation: Animation?,
}

-- // Variables -- //

local player = Players.LocalPlayer
local profile: typeof(profilestructure)
local character: Character = characterUtility.get(player) :: Character
local humanoid = character.Humanoid
local _rootPart = character.HumanoidRootPart
local animator = humanoid.Animator
local _assets = ReplicatedStorage:WaitForChild("Assets") :: Folder
local camera = game.Workspace.CurrentCamera
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents") :: Folder

---------------------------------- Client --------------------------------

local interfaceStartTime = os.clock()

local PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui

--[[
local obsidianCharacter = workspace:WaitForChild("Obsidian") :: Model
local obsidian = CustomCharacter.new(obsidianCharacter)
print(obsidian.__tostring(obsidian))
obsidian:blink()
--]]
-- // Util -- //

local debounceDelay = 1

local compiledObjects = {
	mouse_enter = table.create(50),
	mouse_leave = table.create(50),
	mouse_click = table.create(50),
}

local gameCamera: GameCamera.GameCamera = GameCamera.new(character)
gameCamera:sway(gameCamera)
gameCamera:bobble(gameCamera)
--gameCamera:trail(gameCamera)
OverShoulder:Init()

local getProfileRF = remoteEvents:WaitForChild("GetProfile") :: RemoteFunction
local profile_data = getProfileRF:InvokeServer(player)
if profile_data then
	profile = profile_data
end

audio:write_miscellaneous(audio, {
	["click"] = 90092163763441,
	["hover"] = 119879668444252,
	["leave"] = 85897203168160,
	["success"] = 76288726968959,
})
Cmdr:SetActivationKeys({ Enum.KeyCode.F2 })

local templates = ReplicatedStorage:WaitForChild("Interfaces") :: Folder

local function typewriterEffect(textLabel: TextLabel | TextButton, text: string, typingSpeed: number)
	local length = string.len(text) or text:len() or #text -- does the same thing lmao
	local estimatedTime = length * typingSpeed
	local thread = task.spawn(function()
		for i = 1, length do
			if not textLabel.Parent then
				return
			end -- Check if UI still exists
			textLabel.Text = textLabel.Text .. string.sub(text, i, i)

			task.wait(typingSpeed)
		end
	end)
	return estimatedTime, thread
end

local function changeFOV(change: number)
	-- Usually 60 or 70.
	TweenPlus(
		camera,
		{ FieldOfView = change },
		{ Time = Emphasis.emphasized, EasingDirection = "Out", EasingStyle = "Circular" }
	):Start()
end

local debounce: { [GuiObject]: boolean } = {}
local function checkDebounce(obj: GuiObject)
	return debounce[obj]
end

local function initializeDebounce()
	for _, btn: GuiButton in PlayerGui:GetDescendants() :: { GuiButton } do
		if btn:IsA("GuiButton") then
			debounce[btn] = false
			btn.MouseButton1Down:Connect(function()
				debounce[btn] = true
				task.delay(debounceDelay, function()
					debounce[btn] = false
				end)
			end)
		end
	end
	--print("debounce table: ", debounce)
end

local function initializeRailNavigation(rail: Frame)
	local buttons = rail:GetChildren()
	for _, button in pairs(buttons) do
		if button:IsA("TextButton") then
			button.MouseButton1Click:Connect(function()
				--print("Clicked on: " .. button.Name)
				audio:read_miscellaneous(audio, "click")
				local goal =
					{ BackgroundColor3 = Color3.fromRGB(69, 69, 89), Size = UDim2.fromScale(0.877, 0.1) }
				TweenPlus(button, goal, { Time = Emphasis.standard }):Start()
				Pop(button)
				task.delay(0, function()
					local resolve = Color3.fromHex("#211f26")
					alter(buttons, function()
						goal = { BackgroundColor3 = resolve }
						for _, btn in buttons do
							if btn:IsA("UIAspectRatioConstraint") ~= true then
								--print("continue")
								continue
							end
							if btn:IsA("UIListLayout") ~= true then
								--print("continue")
								continue
							end
							if btn:IsA("UIPadding") ~= true then
								--print("continue")
								continue
							end
							if btn ~= button then
								TweenPlus(btn, goal, {
									Time = Emphasis.emphasized,
									EasingDirection = "Out",
									EasingStyle = "Sine",
								})
							end
						end
					end, { button })
				end)
			end)
			task.wait()
		end
	end
end

local shiftlockRemote = player:WaitForChild("ToggleShiftLock") :: BindableEvent

local shiftlockStatusImages = {
	enabled = "rbxassetid://10747374938",
	disabled = "rbxassetid://10747374721",
}

local function toggleShiftlock(image: ImageLabel)
	shiftlockRemote:Fire(true or false)
	audio:read_miscellaneous(audio, "hover")
	assert(image, "no camera status image :frown:")
	if OverShoulder.IsEnabled() then
		image.Image = shiftlockStatusImages.enabled
		Pop(image.Parent)
	else
		image.Image = shiftlockStatusImages.disabled
		Pop(image.Parent)
	end
end

local signals: { any } = table.create(50) -- '50' being the preallocated signals allowed

print("UI is executing.")

-- // Everything else -- //

-- Battle Gui

local BattleGui = PlayerGui:WaitForChild("NewMatch") :: ScreenGui
local BattleCanvas = BattleGui:WaitForChild("CanvasGroup") :: CanvasGroup
local BattleFrame = BattleCanvas:WaitForChild("Status") :: Frame
local NewBattle = BattleFrame:WaitForChild("HitBox") :: TextButton

local BattleModes = BattleCanvas:FindFirstChild("List") :: Frame

local ActiveStatus = BattleCanvas:WaitForChild("ActiveStatus") :: Frame
local ExitMatch = ActiveStatus:WaitForChild("Exit") :: ImageButton
local StatusTime = ActiveStatus:WaitForChild("Time") :: TextLabel

local cancelMatchmaking = SignalPlus()

local function initializeActiveStatus()
	TweenPlus(
		ActiveStatus,
		{ Position = DisplayOrder.canvasPositions.higher },
		{ Time = 1, EasingStyle = "Back", EasingDirection = "InOut" }
	):Start()
	local elapsed: string
	local clock = timer.new()
	clock:Start()
	task.wait()
	local connection = RunService.Heartbeat:Connect(function()
		if limits.subsequent_limit("format_time") then
			elapsed = clock:FormatTime() or "00:00:00"
			local activeText = tostring(elapsed)
			StatusTime.Text = activeText
			Pop(StatusTime, 2)
		end
	end)
	local routine = task.spawn(function()
		-- cleanup crew
		local otherPlayer = Players.PlayerRemoving:Wait()
		if not (otherPlayer ~= player) then
			--[[ 
				If the other player is the player
				I know, I worded it freakishly :freaky:
			--]]
			if connection and timer then
				connection:Disconnect()
				clock:Destroy()
			end
		end
	end)
	local onSwipe = swipe.new(ActiveStatus) :: swipe.SwipeDetector
	local swiped = false
	onSwipe:SetThreshold(onSwipe, ActiveStatus.AbsoluteSize.Y * 0.2) -- 20% of the height
	onSwipe.OnSwipe:Connect(function(direction: string)
		print("swiped")
		if direction == "up" then
			print("swiped up")
			swiped = true
			if connection and clock then
				connection:Disconnect()
				-- use a promise try
				promise
					.try(function()
						clock:Stop()
						clock:Destroy()
					end)
					:catch(function(err)
						warn("Error stopping clock: ", err)
					end)
			end
			Pop(ExitMatch)
			audio:read_miscellaneous(audio, "leave")
			StatusTime.Text = "Cancelled!"
			cancelMatchmaking:Fire()
			TweenPlus(
				ActiveStatus,
				{ Position = DisplayOrder.canvasPositions.offscreen_high },
				{ Time = Emphasis.emphasized + 0.5 }
			):Start()
		end
	end)
	if swiped == true then
		onSwipe:Destroy()
		task.cancel(routine)
	end
end

local function newMatch()
	Packet.createMatch.send({ nil })
	Pop(NewBattle)
	--[[
		We need to send the player to the server.
		We'll also guess you want solos.
		The server will then create a new match for the player.
			Lets pack it up!
	]]

	NewBattle.Interactable = false

	audio:read_miscellaneous(audio, "success")

	initializeActiveStatus()

	local preloader: {
		heartbeatconnetion: RBXScriptConnection,
		icon: ImageLabel,
	}? = nil
	local thread = task.spawn(function()
		local signal = SignalPlus()
		preloader = indict(NewBattle, signal)
		local otherPlayer = Players.PlayerRemoving:Wait()
		if otherPlayer == player then
			signal:Fire()
		end
	end)

	-- memory leak prevention
	local signal_footprint = "cancel_matchmaking"
	local footprint = table.find(signals, signal_footprint)
	if footprint then
		-- 'footprint' is the index.
		signals[footprint]:Disconnect()
		signals[footprint] = nil or table.remove(signals, footprint)
	end
	local signal = cancelMatchmaking:Connect(function()
		print("cancel matchmaking - client")
		NewBattle.Interactable = true

		preloader.heartbeat_connection:Disconnect()
		preloader.icon:Destroy()

		if thread then
			task.cancel(thread)
		end

		Packet.cancelMatch.send({ player })
	end)
	signals[signal_footprint] = signal

	print("new match: ", player.DisplayName)
end

NewBattle.MouseButton1Click:Connect(newMatch)
NewBattle.MouseEnter:Connect(function()
	audio:read_miscellaneous(audio, "hover")
	Hint("Create new match", NewBattle)
	--LightingManipulation:blur(true)
end)
NewBattle.MouseLeave:Connect(function()
	audio:read_miscellaneous(audio, "leave")
	--LightingManipulation:blur(false)
end)

-- Gamepasses

local DynamicUI = PlayerGui:WaitForChild("DynamicUI") :: Folder
local GamePasses = DynamicUI:WaitForChild("GamePasses") :: ScreenGui
local GamePassesCanvas = GamePasses:WaitForChild("CanvasGroup") :: CanvasGroup
local GamePassesFrame = GamePassesCanvas:WaitForChild("Frame") :: Frame

local productIdentifications = {
	Extra_Cards = 1904591683,
	Donations = 1906572512,
}
local _passesIdentifications = {
	Double_Cards = 891181374,
}

local function promptPurchase(id: number)
	MarketPlaceService:PromptProductPurchase(player, id)
	audio:read_miscellaneous(audio, "success")
	print("Purchaseded product for player.")
end

local function openGamepasses()
	-- We're gonna have a whole sequence for this.
	local getStartedSVG = GamePassesFrame:FindFirstChild("GetStarted") :: ImageLabel -- For engagement
	getStartedSVG.Rotation = 4
	local tipFrame = GamePassesFrame:FindFirstChild("Tip") :: Frame
	local tipText = tipFrame:FindFirstChild("Information") :: TextLabel

	local learnMoreText = [[
	Show that you care & donate a couple bucks to the developer! 
	In return, you recieve a most <i>wonderful</i> <b>50 Cards</b> prize!
	]]
	task.wait()
	typewriterEffect(tipText, learnMoreText, 0.05)
	local goal = { Rotation = 0 }
	TweenPlus(getStartedSVG, goal, { Time = Emphasis.emphasized }):Start()
end

local gamepassesTipFrame = GamePassesFrame:FindFirstChild("Tip") :: Frame
local gamepassesLearnMore = gamepassesTipFrame:FindFirstChild("More") :: TextButton
gamepassesLearnMore.MouseEnter:Connect(function()
	audio:read_miscellaneous(audio, "hover")
end)
gamepassesLearnMore.MouseLeave:Connect(function()
	audio:read_miscellaneous(audio, "leave")
end)

-- TODO add support for more products & gamepasses

local purchaseProduct = GamePassesFrame:FindFirstChild("Purchase") :: TextButton
local closePassesFrame = GamePassesFrame:FindFirstChild("Close") :: TextButton
purchaseProduct.MouseButton1Click:Connect(function()
	if checkDebounce(purchaseProduct) then
		return
	end
	promptPurchase(productIdentifications.Extra_Cards)
	audio:read_miscellaneous(audio, "success")
	DisplayOrder:changeVisibility(false, GamePassesCanvas)

	print("Prompted product purchase for player.")
end)
local confettiDebounce = false -- only exception
purchaseProduct.MouseEnter:Connect(function()
	if confettiDebounce then
		return
	end
	local amount = random.integer(4, 8)
	local confettiColors = Saturation.generateRandomColors(amount)
	local confettiFolder = Instance.new("Folder")
	confettiFolder.Name = "ConfettiFolder"
	confettiFolder.Parent = GamePassesFrame
	Confetti(confettiColors, confettiFolder)
	local possibleConfetti = confettiFolder:GetChildren()
	task.wait(2)
	if not possibleConfetti then
		task.delay(10, confettiFolder.Destroy, confettiFolder)
		-- no memory leak ma'am.
	end
	confettiDebounce = true
	task.delay(debounceDelay, function()
		confettiDebounce = false
		confettiFolder:Destroy()
	end)
	audio:read_miscellaneous(audio, "hover")
end)
purchaseProduct.MouseLeave:Connect(function()
	audio:read_miscellaneous(audio, "leave")
end)
closePassesFrame.MouseButton1Click:Connect(function()
	DisplayOrder:changeVisibility(false, GamePassesCanvas)
	audio:read_miscellaneous(audio, "leave")
end)

print(`UI is halfway executing.`)

print(`UI is almost done executing.`)

-- Shop

local shopGui = PlayerGui:FindFirstChild("Shop") :: ScreenGui
local shopOpenFrame = shopGui:FindFirstChild("Open") :: TextButton -- Floating Action Button
local shopOpenButton = shopOpenFrame:FindFirstChild("HitBox") :: TextButton
local shopCanvas = shopGui:FindFirstChild("CanvasGroup") :: CanvasGroup
local shopFrame = shopCanvas:FindFirstChild("Frame") :: Frame

DisplayOrder.compiled["shop"] = shopCanvas

local shopNavigation = shopFrame:FindFirstChild("Navigation") :: Frame
local itemHolder = shopFrame:FindFirstChild("Holder") :: Frame

local shopRail: { [string]: TextButton } = {}

local function unloadShop()
	for _, item in itemHolder:GetChildren() do
		if item and item:IsA("Frame") then
			item:Destroy()
			task.wait()
		end
	end
	return #(itemHolder:GetChildren()) * task.wait()
end

local function populateShop(t: {}?)
	local shopFolder = templates:FindFirstChild("Shop") :: Folder
	local newRelease = shopFrame:FindFirstChild("NewRelease") :: TextLabel
	unloadShop()
	t = t or Cards
	for _, item in pairs(t) do
		-- print("got item: " .. item.Name)
		local itemTemplate = shopFolder:FindFirstChild("ItemTemplate") :: Frame & {
			Title: TextLabel,
			Price: TextLabel,
			Buy: TextButton,
			Test: TextButton,
		}
		itemTemplate = itemTemplate:Clone()
		itemTemplate:SetAttribute("name", item.Name)
		itemTemplate.Parent = itemHolder

		local title = itemTemplate.Title
		local price = itemTemplate.Price

		local purchaseButton = itemTemplate.Buy
		local experimentButton = itemTemplate.Test

		title = TextPlus.Create(title, item.Name, {
			Font = Font.new(
				"rbxasset://fonts/families/Montserrat.json", -- Family.
				Enum.FontWeight.SemiBold, -- Weight.
				Enum.FontStyle.Normal -- Style.
			),
			Size = 16,
			Color = Color3.fromHex("#ffffff"),
			XAlignment = "Left",
			YAlignment = "Center",
			Dynamic = true,
		})
		price.Text = "$" .. tostring(item.Price)
		itemTemplate.Visible = true
		if item.ExperimentsEnabled == true then
			experimentButton.Visible = true
			experimentButton.MouseButton1Click:Connect(function()
				Pop(experimentButton)
				print("Testing card: " .. item.Name)
			end)
		else
			experimentButton.Visible = false
		end
		local purchaseDebounce = false -- exception too
		purchaseButton.MouseEnter:Connect(function()
			audio:read_miscellaneous(audio, "hover")
		end)
		purchaseButton.MouseLeave:Connect(function()
			audio:read_miscellaneous(audio, "leave")
		end)
		purchaseButton.MouseButton1Click:Connect(function()
			if purchaseDebounce == true then
				return
			end
			print("Purchasing card: " .. item.Name)
			Packet.buyCard.send({
				item.Name,
			})
			Pop(purchaseButton)
			purchaseDebounce = true
			task.delay(debounceDelay, function()
				purchaseDebounce = false
			end)
		end)
		task.wait()
	end
	local itemMenu = shopNavigation:FindFirstChild("New") :: TextButton
	if string.find(newRelease.Text, "0", 1) then
		itemMenu.Transparency = 1
		newRelease.Visible = false
	else
		itemMenu.Transparency = 0
		newRelease.Visible = true
	end
end

local function searchShop(keyword: string)
	-- compile everything
	local allocation = 1000
	local items: { string } = table.create(allocation)
	for _, item in Cards do
		table.insert(items, item.Name)
	end
	-- map out the items similar to the keyword
	local sorted_map = leventine.map(keyword, items)
	-- unload
	unloadShop()
	local concatenation = table.concat(sorted_map, ", ")
	print(concatenation)

	local matching = sorted_map[1]
	local compiled_map: { nil } = table.create(allocation)
	-- nefarious work goin' on here
	for i, item in Cards do
		local name = { Name = sorted_map[i] }
		local string_index = dictionary.findKeyIndex(Cards, item.Name)
		assert(Cards[string_index], "couldnt find string index")
		local restored = dictionary.reconcile(name, Cards[string_index])
		compiled_map[restored.Name or name.Name] = restored
	end
	print("compiled_map: ", compiled_map)
	local isEmpty = false
	if isEmpty == true then
		warn(compiled_map)
	end
	isEmpty = not assert(dictionary.empty(compiled_map), "absolutely diabolical, the compiled map is nil: ")
	populateShop(compiled_map)
	return {
		matching = matching,
		compiled_map = compiled_map,
		sorted_map = sorted_map,
	}
end

local function populateOwnedFolder()
	local shopFolder = templates:FindFirstChild("Shop") :: Folder
	local unloaded = unloadShop()
	task.wait(unloaded)
	profile = getProfileRF:InvokeServer()
	assert(profile, "Profile does not exist on the client!")
	for itemName: string, i in pairs(profile.Data.Cards) do
		-- print("got item: " .. itemName)
		local itemTemplate = shopFolder:FindFirstChild("ItemTemplate") :: Frame
		itemTemplate = itemTemplate:Clone()
		itemTemplate.Parent = itemHolder

		local title = itemTemplate:FindFirstChild("Title") :: TextLabel
		local quantity = itemTemplate:FindFirstChild("Price") :: TextLabel

		local sellButton = itemTemplate:FindFirstChild("Buy") :: TextButton -- lol
		local experimentButton = itemTemplate:FindFirstChild("Test") :: TextButton

		title = TextPlus.Create(title, itemName, {
			Font = Font.new(
				"rbxasset://fonts/families/Montserrat.json", -- Family.
				Enum.FontWeight.SemiBold, -- Weight.
				Enum.FontStyle.Normal -- Style.
			),
			Size = 20,
			Color = Color3.fromHex("#ffffff"),
			XAlignment = "Left",
			YAlignment = "Center",
			Dynamic = true,
		})
		--title.Text = itemName
		quantity.Text = "( <b>" .. tostring(i) .. "</b> )"
		itemTemplate.Visible = true
		quantity.RichText = true

		experimentButton.Visible = false
		sellButton.Visible = true
		sellButton.Text = "Sell"
		sellButton.MouseButton1Click:Connect(function()
			local dialog_title = "Slow down there!"
			local description = [[
			Are you sure you want to sell this Card? 
			]] .. itemName
			local folder_minus_icon = "rbxassetid://10723386127"
			local result = Dialog(dialog_title, description, folder_minus_icon)
			if result and result == true then
				print("selling card: " .. itemName)
				Packet.sellCard.send({ player, itemName })
			end
		end)
		task.wait()
	end
end

Packet.buyCard.listen(function(data: { string })
	local condition = "success"
	--print("got condition: ", data[1], " for buying Cards. (server > client)")
	if data[1] == condition then
		local allotedColors = 10
		local colors = Saturation.generateRandomColors(allotedColors)
		local folder = Instance.new("Folder")
		folder.Name = "ConfettiFolder"
		folder.Parent = shopFrame
		audio:read_miscellaneous(audio, "success")
		Confetti(colors, folder)
	end
end)

shopOpenButton.MouseButton1Click:Connect(function()
	if checkDebounce(shopOpenButton) then
		return
	end
	if shopCanvas.Visible == false then
		DisplayOrder:changeVisibility(true, shopCanvas)
		changeFOV(60)
		audio:read_miscellaneous(audio, "click")
		DisplayOrder:setDisplayOrder("shop")
		populateShop()
		Pop(shopOpenButton)
		Pop(shopFrame)
	elseif shopCanvas.Visible == true then
		DisplayOrder:changeVisibility(false, shopCanvas)
		audio:read_miscellaneous(audio, "leave")
		changeFOV(70)
		unloadShop()
		Pop(shopOpenButton)
		Pop(shopFrame)
	end
end)
shopOpenButton.MouseEnter:Connect(function()
	audio:read_miscellaneous(audio, "hover")
	Hint("Buy Items in the Market", shopOpenButton)
end)
shopOpenButton.MouseLeave:Connect(function()
	audio:read_miscellaneous(audio, "leave")
end)

for _, item: GuiObject in shopNavigation:GetChildren() do
	if item:IsA("GuiButton") then
		shopRail[item.Name] = item
	end
end

shopRail.New.MouseButton1Click:Connect(function()
	if checkDebounce(shopRail.New) then
		return
	end
	populateShop()
end)
shopRail.Owned.MouseButton1Click:Connect(function()
	if checkDebounce(shopRail.New) then
		return
	end
	populateOwnedFolder()
end)

initializeRailNavigation(shopNavigation)

-- Shiftlock

local ShiftlockToggleGui = PlayerGui:FindFirstChild("Shiftlock") :: ScreenGui
local shiftlockOpenFrame = ShiftlockToggleGui:FindFirstChild("Open") :: Frame
local shiftlockBtn = shiftlockOpenFrame:FindFirstChild("HitBox") :: TextButton

shiftlockBtn.MouseButton1Click:Connect(function()
	local image = shiftlockOpenFrame:FindFirstChildOfClass("ImageLabel")
	toggleShiftlock(image)
end)

shiftlockOpenFrame.MouseEnter:Connect(function()
	audio:read_miscellaneous(audio, "hover")
	Hint("Toggle Shiftlock", shiftlockOpenFrame)
	--LightingManipulation:blur(true)
end)
shiftlockOpenFrame.MouseLeave:Connect(function()
	audio:read_miscellaneous(audio, "leave")
	--LightingManipulation:blur(false)
end)

print("UI is almost done executing.")

-- Rank UI

local RankGui = PlayerGui:FindFirstChild("Rank") :: ScreenGui
local RankCanvas = RankGui:FindFirstChild("CanvasGroup") :: CanvasGroup
local RankFrame = RankCanvas:FindFirstChild("Frame") :: Frame

local RankText = RankFrame:FindFirstChild("Rank") :: TextLabel
local ExperienceText = RankFrame:FindFirstChild("Experience") :: TextLabel

-- periodically update the rank
local function updateRank()
	profile = getProfileRF:InvokeServer()
	assert(profile, "Profile does not exist on the client!")
	local rank: string = profile.Data.Level
	local experience = profile.Data.Experience
	local indexStructure: { [number]: string } = {
		[1] = "Bronze I",
		[2] = "Gold II",
		[3] = "Platinum III",
		[4] = "Master IV",
		[5] = "Sparking V",
	}
	local _, nextRank: string = dictionary.findKey(indexStructure, rank)
	task.wait()
	nextRank = RankStructure[nextRank]
	task.delay(0, function()
		local neededExperience: number = nextRank.Experience
		RankText.Text = rank
		ExperienceText.Text = tostring(experience) or "null" .. "/" .. tostring(neededExperience) or "null"
	end)
end

task.spawn(function()
	retryer.delay(10, math.huge, function()
		-- lmao math.huge infinite loop
		if limits.update_limit("update_rank") then
			updateRank()
		end
	end)
end)

initializeDebounce()
local movementSingleton = Movement.new()
movementSingleton:sprint(movementSingleton)
movementSingleton:jump(movementSingleton)
movementSingleton:slide(movementSingleton)

local interfaceEndTime = os.clock()
local totalExecutionTime = math.round((interfaceEndTime - interfaceStartTime) * 10000) / 10000
-- This results in four decimal places.

print("UI has finished with an execution time of: ", totalExecutionTime)

CardAwarder()

local defaultFootstep = _rootPart:FindFirstChild("Running")
if defaultFootstep then
	defaultFootstep:Destroy()
end
