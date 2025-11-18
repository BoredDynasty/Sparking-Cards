--!nonstrict
--!optimize 2

-- Client.client.luau

print(script.Name)
task.wait()

-- // Services -- //
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

-- // Requires -- //

local CameraController = require("../Camera/CameraController")
local CardLibrary = require(ReplicatedStorage.Combat.CardLibrary)
local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient") :: ModuleScript) :: any
local Navi = require("../Components/Navi")
local Options = require("../Components/Options")
local Packet = require(ReplicatedStorage.Packet)
local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local TextPlus = require(ReplicatedStorage.Utility.TextPlus)
local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local achievement = require(StarterPlayer.StarterPlayerScripts.Components.achievement)
local animate = require("../Utilities/animate")
local audio = require(ReplicatedStorage.Modules.audio)
local badges = require(ReplicatedStorage.Structures.badges)
local beats = require(ReplicatedStorage.Modules.beats)
local bloxstrap_rpc_sdk = require(ReplicatedStorage.Kits["bloxstrap-rpc-sdk"])
local bounds = require(StarterPlayer.StarterPlayerScripts.Utilities.bounds)
local characterIteration = require(ReplicatedStorage.ClientModules.characterIteration)
local characterUtility = require(ReplicatedStorage.Utility.characterMarshaller)
local compute_level = require(ReplicatedStorage.ClientModules["compute-level"])
local custom_lighting = require(ReplicatedStorage.ClientModules["custom-lighting"])
local damage = require(ReplicatedStorage.Combat.Strike.damage)
local displayorder = require(script.Parent.Parent.Interface.displayorder)
local dropper = require(ReplicatedStorage.ClientModules.dropper)
local gamecamera = require(script.Parent.Parent.Modules.gamecamera)
local glare = require(StarterPlayer.StarterPlayerScripts.Interface.glare)
local glove = require(StarterPlayer.StarterPlayerScripts.Gameplay.glove)
local hud = require(script.Parent.Parent.Components.hud)
local hydration = require(ReplicatedStorage.Utility.hydration)
local input = require(ReplicatedStorage.Packages.input)
local joint_controller = require(StarterPlayer.StarterPlayerScripts.Movement["joint-controller"])
local logger = require(ReplicatedStorage.ClientModules.logger)
local lucide = require(ReplicatedStorage.Packages.lucide)
local markdown = require(ReplicatedStorage.ClientModules.markdown)
local market = require("../Components/market")
local motion_blur = require(StarterPlayer.StarterPlayerScripts.Graphics["motion-blur"])
local movement_controller = require(StarterPlayer.StarterPlayerScripts.Movement["movement-controller"])
local music = require("../Gameplay/music")
local number_abbreviation = require(ReplicatedStorage.Modules.Serialization["number-abbreviation"])
local objective = require("../Components/objective")
local observer = require(ReplicatedStorage.Utility.observer)
local orion = require(ReplicatedStorage.Combat.orion) -- Orion Combat Framework
local parallax = require("../Interface/parallax")
local parallaxLayers = require(ReplicatedStorage.Structures.parallaxLayers)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local pop = require(script.Parent.Parent.Interface.pop)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local promise = require(ReplicatedStorage.Packages.promise)
local quest = require(ReplicatedStorage.ClientModules.quest)
local quest_ranking = require(ReplicatedStorage.ClientModules["quest-ranking"])
local rbx_thumb = require(ReplicatedStorage.Modules.Serialization["rbx-thumb"])
local retryer = require(ReplicatedStorage.Utility.retryer)
local ripple = require(StarterPlayer.StarterPlayerScripts.Interface.ripple)
local safeteleport = require(ReplicatedStorage.Modules.safeteleport)
local shadow = require(script.Parent.Parent.Interface.shadow)
local spr = require(ReplicatedStorage.Modules.spr)
local sway = require("../Interface/sway")
local swipe = require("../Interface/swipe")
local tag = require(ReplicatedStorage.Modules.Wrappers.tag)
local throbber = require("../Components/throbber")
local timer = require(ReplicatedStorage.Modules.timer)
local trove = require(ReplicatedStorage.Packages.trove)
local keyboard = input.Keyboard.new()
local mouse = input.Mouse.new()

print("Client Requirements")

-- // Variables -- //

local player = playerMarshaller.get()
local profile: {
	Data: profilestructure.profile,
} = promise
	.new(function(resolve: (any) -> ...unknown)
		local value = (ReplicatedStorage.Events.GetProfile :: RemoteFunction):InvokeServer()

		resolve(value)

		return value
	end)
	:expect()

local _trove = trove.new()

-- // Events -- //
local getProfileRF = ReplicatedStorage.Events:WaitForChild("GetProfile") :: RemoteFunction

local character = characterUtility.get(player)
local _rootPart = character.HumanoidRootPart
local _assets = ReplicatedStorage:WaitForChild("Assets") :: Folder
local remoteEvents = ReplicatedStorage.Events

-- // Functions -- //
local function expectProfile()
	return promise
		.new(function(resolve: (any) -> ...unknown)
			local value = getProfileRF:InvokeServer()

			resolve(value)
		end)
		:expect() :: {
		Data: profilestructure.profile,
	}
end

---------------------------------- Client --------------------------------

local interfaceStartTime = os.clock()

local PlayerGui = player.PlayerGui
local templates = ReplicatedStorage:WaitForChild("Interfaces", 5) :: Folder

local characterFolder = ReplicatedStorage:FindFirstChild("Characters") or Instance.new("Folder")
characterFolder.Name = "Characters"
characterFolder.Parent = ReplicatedStorage

logger.new()
glove:Apply(character)

print("client starting")

local function initializeCommands()
	print("init commands")

	Cmdr:SetActivationKeys({ Enum.KeyCode.Equals })
	Cmdr:SetActivationUnlocksMouse(true)
	Cmdr:SetPlaceName("Sparking Cards Lobby")
	Cmdr:SetActivationUnlocksMouse(true)
	Cmdr:SetHideOnLostFocus(false)
end

local function initializeMarket()
	print("init market")
	local shopGui = PlayerGui:WaitForChild("Shop") :: ScreenGui
	local shopCanvas = shopGui:WaitForChild("CanvasGroup") :: CanvasGroup
	local shopFrame = shopCanvas:WaitForChild("Frame") :: Frame

	displayorder.new(shopCanvas)

	local shopNavigation = shopFrame:WaitForChild("Navigation") :: Frame
	local itemHolder = shopFrame:WaitForChild("Holder") :: Frame
	local shopFolder = templates:FindFirstChild("Shop") :: Folder
	local spendings = shopFrame:FindFirstChild("Spendings") :: Frame

	print("got market gui")

	local function callback()
		market:display_spendings(expectProfile())
		market:load_items()
		displayorder:toggle(shopCanvas)
	end

	hud:create("Market", callback, lucide.GetAsset("shopping-cart"))

	local function populateNavigation()
		-- home, inventory, passive
		local navi_btns = {
			{
				name = "Home",
				icon = "rbxassetid://73790023098856",
				callback = function()
					market:unload()
					market:load_items()
				end,
				disabledCallback = function()
					market:unload()
				end,
			},
			{
				name = "Inventory",
				icon = "rbxassetid://10709769841",
				callback = function()
					market:unload()
					market:load_inventory(expectProfile())
				end,
				disabledCallback = function()
					market:unload()
				end,
			},
		}
		for i, data in ipairs(navi_btns) do
			Navi:add(
				shopNavigation,
				data.name,
				data.icon,
				data.callback,
				data.disabledCallback,
				if data.name == "Home" then true else false
			)
		end
		Navi:render(shopNavigation)
		shopNavigation.Visible = true
	end

	populateNavigation()
end
local function initializeOptions()
	print("init options")
	local optionsGui = PlayerGui:WaitForChild("Options") :: ScreenGui
	local optionsCanvas = optionsGui:WaitForChild("CanvasGroup") :: CanvasGroup
	local optionsFrame = optionsCanvas:WaitForChild("Frame") :: Frame

	displayorder.new(optionsCanvas)

	shadow(optionsFrame)
end
local function initializeMatchmaking()
	print("init matchmaking")
	local matchmakingGui = PlayerGui:WaitForChild("NewMatch") :: ScreenGui
	local matchmakingCanvas = matchmakingGui:WaitForChild("CanvasGroup") :: CanvasGroup
	local matchmakingFrame = matchmakingCanvas:WaitForChild("Frame") :: Frame

	local statusText = matchmakingFrame:WaitForChild("Time") :: TextLabel
	local pulseImage = matchmakingFrame:WaitForChild("Pulse") :: ImageLabel

	--displayorder:add(matchmakingCanvas)

	shadow(matchmakingFrame, Color3.new(), 0, 14)

	local state = observer.new(false)
	local clock = timer.new()

	local function showMatchmakingFrame()
		spr.target(matchmakingFrame, 0.3, 8, {
			Position = UDim2.fromScale(0.5, 0.1),
		})
		state:Set(true)

		clock:Start()
		-- every 0.33_ seconds
		clock:interval(clock, 1 / 3, function()
			local totalSeconds = clock:GetTime()

			local minutes = math.floor(totalSeconds / 60)

			local seconds = totalSeconds % 60
			statusText.Text = string.format(
				'Searching...<br/><font transparency="0.5"><font size="14">%02d:%02d</font></font>',
				minutes,
				seconds
			)

			pop(pulseImage, 1.8)
		end)
	end

	local function hideMatchmakingFrame()
		spr.target(matchmakingFrame, 1, 2, {
			Position = UDim2.fromScale(0.5, -0.5),
		})

		state:Set(false)

		clock:Reset()
		clock:Stop()

		hud:toggle("Matchmaking")
	end

	state:Watch(function(newValue: boolean)
		if newValue == true then
			matchmakingCanvas.Visible = true

			print("Starting matchmaking")

			Packet.CreateMatch.send({}, player)
		else
			matchmakingCanvas.Visible = false
			--notify.info("Matchmaking", "You have left the queue.", 5, "info")

			print("Stopped matchmaking")

			Packet.CancelMatch.send({ matchInstance = player }, player)
		end
	end)

	local swipeDetector = swipe.new(matchmakingFrame)
	swipeDetector.OnSwipe:Connect(function(direction: swipe.direction, delta: Vector3)
		if state:Get() == false then
			-- how sir

			return
		end

		if direction == "up" then
			state:Set(false)
			-- audio:SFX("leave")

			pcall(hideMatchmakingFrame)
		else
			return
		end
	end)

	hud:create("Matchmaking", showMatchmakingFrame, lucide.GetAsset("play-circle"))
end
local function initializeBadges()
	print("init badges")

	local badgesGui = PlayerGui:FindFirstChild("Badges") :: ScreenGui
	local badgesCanvas = badgesGui:FindFirstChild("CanvasGroup") :: CanvasGroup
	local badgeFrame = badgesCanvas:FindFirstChild("Frame") :: Frame

	local itemHolder = badgeFrame:WaitForChild("Holder") :: Frame
	local badgeFolder = templates:FindFirstChild("Shop") :: Folder -- lmao
	local totalBadges = badgeFrame:FindFirstChild("Total") :: Frame

	shadow(badgeFrame, Color3.new(), 0, 14)
	shadow(totalBadges, Color3.new(), 0, 14)

	displayorder.new(badgesCanvas)

	local function callback()
		displayorder:toggle(badgesCanvas)
		achievement:DisplayTotal(expectProfile())
		achievement:Load(expectProfile())
	end

	hud:create("Badges", callback, lucide.GetAsset("trophy", 48))
end
local function initializeNotifiers()
	print("init notifiers")
	--[[
	Packet.SendNotification.listen(function(data)
		notify[data.type or "info"](
			data.title or "Notification",
			data.message or "",
			data.duration or 5,
			data.type
		)
	end)
	--]]
end
local function initializeMusic()
	print("init music")

	local tracks = {
		{
			biome = "Baseplate",
			id = "106260784933266",
			name = "Gentle Groove",
			artist = "Distrokid",
			coordinates = {
				position = vector.create(-1845, 228, 139),
				size = vector.create(2048, 64, 2048),
			},
		},
	}

	for i, track in ipairs(tracks) do
		music.newBiome(track.biome, {
			track,
		}, track.coordinates.position, track.coordinates.size)

		print("added biome track: " .. i .. ` {tracks[i]}`)
	end

	music.startTracking()

	local musicGui = PlayerGui:WaitForChild("Music") :: ScreenGui & {
		CanvasGroup: CanvasGroup & {
			Disc: ImageLabel,
			Note: ImageLabel,
			SongName: TextLabel,
			Artist: TextLabel,
		},
	}
	local musicCanvas = musicGui.CanvasGroup
	local disc = musicCanvas.Disc
	local note_image = musicCanvas.Note

	local songNameDisplay = musicCanvas.SongName
	local artistDisplay = musicCanvas.Artist

	music.playing:Watch(function()
		local currentlyPlaying = music.playing:Get()
		if not currentlyPlaying then
			return
		end

		songNameDisplay.Text = currentlyPlaying.name
		artistDisplay.Text = currentlyPlaying.artist
	end)

	sway:on(note_image)
	sway:on(disc)

	glare:Watch(disc, {
		once = false,
		corner_radius = UDim.new(1, 0),
	})

	-- rotate effect on disc
	local rotation_tween = TweenPlus(
		disc,
		{ Rotation = 360 },
		{ Time = 7, RepeatCount = -1, EasingStyle = "Linear" }
	)
	rotation_tween:Start()

	retryer.infdelay(3, function()
		print("getting analyzer for beat detection")
		-- pulse effect using BPM
		local analyzer = music.analyzer
		if not analyzer then
			return false
		end

		local detector = beats.new({
			analyzer = analyzer,
			minimum_gap = 0.3,
			window_size = 10,
			threshold_multiplier = 1.2,
		})
		analyzer.Parent = musicGui
		detector:Start()

		local lastCheck: number = 0.0
		local checkInterval = 1 / 1.5

		detector.Beat:Connect(function(deltaTime: number)
			lastCheck += deltaTime
			if lastCheck < checkInterval then
				return
			end

			lastCheck = 0

			pop(disc, 1.4)
			-- Add any additional effects or animations here
		end)

		return true
	end)
end
local function initializeLoadouts()
	print("init loadouts")
	local loadoutsGui = PlayerGui:FindFirstChild("Loadout") :: ScreenGui
	local loadoutCanvas = loadoutsGui:FindFirstChild("CanvasGroup") :: CanvasGroup
end

local function initializeObjectives()
	print("init objectives")

	local objectiveGui = PlayerGui:WaitForChild("Objective") :: objective.objectiveGui
	displayorder.new(objectiveGui.CanvasGroup)

	local completed_value = observer.new(0)
	local uncompleted_value = observer.new(0)

	local rank = observer.new("")
	local profile = expectProfile()
	profile = expectProfile()

	promise
		.new(function(resolve: () -> ...unknown)
			if profile and profile.Data then
				rank:Set(profile.Data.Level)
			else
				rank:Set("Bronze I")

				--notify.error("Data", "Couldn't get your Rank.", 5, "error")
			end

			resolve()
		end)
		:catch(print)

	promise
		.new(function(resolve: () -> ...unknown, reject: (string) -> ...unknown)
			local rank_number = compute_level:rankNameToNumber(rank:Get())
			rank_number = rank_number or 1 -- DEBUG
			if not rank_number then
				reject("no rank number for some reason. invalid rank?: ", rank:Get())
			end

			local availiable_objectives = quest_ranking:getObjectivesFromRank(rank:Get())
			if not availiable_objectives then
				reject("no availiable_objectives??")

				return
			end

			for i, objective_name in ipairs(availiable_objectives) do
				print(objective_name)
				quest.new(player, objective_name)
			end

			resolve()
		end)
		:catch(print)

	local quest_list = quest:Get(player):expect()
	if not quest_list then
		print("no quest list")
		return
	end

	for i, data in ipairs(quest_list :: { quest.quest }) do
		objective.new(data)
	end

	quest:Track(player)

	local function toggleUI()
		displayorder:toggle(objectiveGui.CanvasGroup)
	end

	hud:create("Quests", toggleUI, lucide.GetAsset("clipboard-list"))
end
initializeCommands()
initializeMarket()
initializeOptions()
initializeMatchmaking()
initializeBadges()
initializeNotifiers()
initializeMusic()
initializeLoadouts()
initializeObjectives()
hud:render()
displayorder:Watch()

print("client almost done")

movement_controller:Add(script.Parent.Parent.Movement["dash-controller"])
movement_controller:Add(script.Parent.Parent.Movement["sprint-controller"])
movement_controller:Add(script.Parent.Parent.Movement["jump-controller"])
movement_controller:Add(script.Parent.Parent.Movement["stamina-controller"])
movement_controller:Add(script.Parent.Parent.Movement["walk-controller"])
movement_controller:Add(script.Parent.Parent.Movement["joint-controller"])

movement_controller:Start()

print("client movement")

-- local rain_controller = rain.new()
-- rain_controller:Start(rain_controller)

print("rain controller")

-- control

local function getAttackTypeFromKey(key: Enum.KeyCode)
	-- profile = yoink.client:grab("profile_data")
	profile = expectProfile()
	if not profile or not profile.Data then
		return
	end

	local attackTypes = table.create(4) :: { [string]: Enum.KeyCode }
	for i, value in pairs(profile.Data.combatBindings) do
		attackTypes[i] = Enum.KeyCode:FromValue(value)
	end

	local attackType: string = promise
		.new(function()
			return attackTypes[key]
		end)
		:expect()

	return attackType
end

_trove:Add(keyboard.KeyDown:Connect(function(key: Enum.KeyCode)
	local attack_type = getAttackTypeFromKey(key)
	if attack_type then
		orion:execute(player, attack_type)
	end
end))

_trove:Add(mouse.LeftDown:Connect(function()
	local attack_type = "M1"
	if attack_type then
		orion:execute(player, attack_type)
	end
end))

orion.registerPlayer(player, expectProfile())

Packet.ReplicateAnimation.listen(function(data: { identification: string })
	animate.loadAnimation(data.identification, {
		Id = "rbxassetid://" .. data.identification,
		Weight = 1,
	})
	animate.play(`rbxassetid://{data.identification}`, 0.25)
end)

local defaultFootstep = _rootPart:FindFirstChild("Running")
if defaultFootstep then
	defaultFootstep:Destroy()
end

Packet.CleanupCharacter.listen(function()
	animate.cleanup()
	music.cleanup()
	Options:destroy()
	hud:clear()
	dropper._trove:Clean()
end)

local interfaceEndTime = os.clock()
local totalExecutionTime = math.round((interfaceEndTime - interfaceStartTime) * 10000) / 10000
-- This results in four decimal places.

print("Client has finished with an execution time of: ", totalExecutionTime)
