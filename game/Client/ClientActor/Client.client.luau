--!nonstrict
--!optimize 2

-- Client.client.luau

print(script.Name)

-- // Services -- //
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

-- // Requires -- //

local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient") :: ModuleScript) :: any
local Packet = require(ReplicatedStorage.Packet)
local achievement = require(StarterPlayer.StarterPlayerScripts.Components.achievement)
local animate = require("../Utilities/animate")
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local damage = require(ReplicatedStorage.Combat.Strike.damage)
local displayorder = require(StarterPlayer.StarterPlayerScripts.Interface.displayorder)
local dropper = require(ReplicatedStorage.ClientModules.dropper)
local frame_rate = require(ReplicatedStorage.Utility["frame-rate"])
local future = require(ReplicatedStorage.Packages.future)
local glare = require(StarterPlayer.StarterPlayerScripts.Interface.glare)
local glove = require(StarterPlayer.StarterPlayerScripts.Gameplay.glove)
local health_pulse = require(StarterPlayer.StarterPlayerScripts.Gameplay["health-pulse"])
local hint = require(StarterPlayer.StarterPlayerScripts.Components.hint)
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
local navigation_rail = require(StarterPlayer.StarterPlayerScripts.Components["navigation-rail"])
local number_abbreviation = require(ReplicatedStorage.Modules.Serialization["number-abbreviation"])
local objective = require("../Components/objective")
local observer = require(ReplicatedStorage.Utility.observer)
local options = require(StarterPlayer.StarterPlayerScripts.Components.options)
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
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)
local wiggle = require(StarterPlayer.StarterPlayerScripts.Interface.wiggle)

local keyboard = input.Keyboard.new()
local mouse = input.Mouse.new()

print("Client Requirements")

-- // Events -- //
local events = ReplicatedStorage.Events
local get_profile = events.GetProfile

-- // Variables -- //

local player = playerMarshaller.get()
local profile = nil

local _trove = trove.new()

local character = characterMarshaller.get(player)
local humanoid = character.Humanoid

-- // Functions -- //
local function expectProfile()
	local fut = future.Try(function()
		return get_profile:InvokeServer() :: typemarshaller.Profile
	end)

	local ok, result = fut:Await()
	assert(ok, "Couldn't fetch profile from Server: " .. result)

	return result
end

---------------------------------- Client --------------------------------

local PlayerGui = player.PlayerGui

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
	local shopGui = PlayerGui.Shop
	local shopCanvas = shopGui:WaitForChild("CanvasGroup") :: CanvasGroup
	local shopFrame = shopCanvas:WaitForChild("Frame") :: Frame

	displayorder.new(shopCanvas)

	local shopNavigation = shopFrame:WaitForChild("Navigation") :: Frame
	local itemHolder = shopFrame:WaitForChild("Holder") :: Frame
	local spendings = shopFrame:FindFirstChild("Spendings") :: Frame

	local spendings_icon = spendings:FindFirstChild("SpendingsIcon", true) :: ImageLabel

	print("got market gui")

	local function callback()
		market:DisplaySpendings(expectProfile())
		market:LoadItems()
		displayorder:Toggle(shopCanvas)
		wiggle(spendings_icon, function()
			print("completed wiggle animation.")
		end)
	end

	hud.new("Market", callback, lucide.GetAsset("shopping-cart"))

	local function populateNavigation()
		-- home, inventory, passive
		local navi_btns = {
			{
				name = "Home",
				icon = Content.fromAssetId(73790023098856),
				callback = function()
					market:Unload()
					market:LoadItems()
				end,
				holder = shopNavigation,
			},
			{
				name = "Inventory",
				icon = Content.fromAssetId(10709769841),
				callback = function()
					market:Unload()
					market:LoadInventory(expectProfile())
				end,
				holder = shopNavigation,
			},
		}

		for i, data in ipairs(navi_btns) do
			navigation_rail.new(data)
		end

		navigation_rail:Render()

		shopNavigation.Visible = true
	end

	populateNavigation()
end
local function initializeOptions()
	print("init options")
	local optionsGui = PlayerGui.Options
	local optionsCanvas = optionsGui.CanvasGroup
	local optionsFrame = optionsCanvas.Frame

	displayorder.new(optionsCanvas)

	shadow(optionsFrame)
end
local function initializeMatchmaking()
	print("init matchmaking")
	local matchmakingGui = PlayerGui.NewMatch
	local matchmakingCanvas = matchmakingGui.CanvasGroup
	local matchmakingFrame = matchmakingCanvas.Frame

	local statusText = matchmakingFrame.Time
	local pulseImage = matchmakingFrame.Pulse

	--displayorder:add(matchmakingCanvas)

	shadow(matchmakingFrame)

	local state = observer.new(false) :: observer.Observer<boolean>
	local clock = timer.new()

	local function showMatchmakingFrame()
		spr.target(matchmakingFrame, 0.3, 8, {
			Position = UDim2.fromScale(0.5, 0.1),
		})

		state:Set(true)

		clock:Start()
		-- every 0.33_ seconds
		clock:interval(1 / 3, function()
			local total_seconds = clock:GetTime()

			local minutes = math.floor(total_seconds / 60)

			local seconds = total_seconds % 60
			statusText.Text = string.format(
				'Searching...<br/><font transparency="0.5"><font size="14">%02d:%02d</font></font>',
				minutes,
				seconds
			)

			pop(pulseImage, 1.8)
		end)
	end

	local function hideMatchmakingFrame()
		spr.stop(matchmakingFrame)
		spr.target(matchmakingFrame, 1, 2, {
			Position = UDim2.fromScale(0.5, -0.5),
		})

		state:Set(false)

		clock:Reset()
		clock:Stop()

		hud:Toggle("Matchmaking")
	end

	state:Watch(function(newValue)
		matchmakingCanvas.Visible = newValue :: boolean
	end)

	local swipeDetector = swipe.new(matchmakingFrame)
	swipeDetector.OnSwipe:Connect(function(direction: swipe.direction, delta: Vector3)
		if not state:Get() then
			-- how sir

			return
		end

		if direction == "up" then
			state:Set(false)
			-- audio:SFX("leave")

			future.new(hideMatchmakingFrame)
		else
			return
		end
	end)

	hud.new("Matchmaking", showMatchmakingFrame, lucide.GetAsset("play-circle"))
end
local function initializeBadges()
	print("init badges")

	local badgesGui = PlayerGui.Badges
	local badgesCanvas = badgesGui.CanvasGroup
	local badgeFrame = badgesCanvas.Frame

	local itemHolder = badgeFrame.Holder
	local totalBadges = badgeFrame.Total
	shadow(badgeFrame)
	shadow(totalBadges)

	displayorder.new(badgesCanvas)

	local function callback()
		displayorder:Toggle(badgesCanvas)
		achievement:DisplayTotal(expectProfile())
		achievement:Load(expectProfile())
	end

	hud.new("Badges", callback, lucide.GetAsset("trophy", 48))
end
local function initializeNotifiers()
	print("init notifiers")

	Packet.SendNotification.listen(function(data)
		local hint_ = hint.new()
		hint_:SetText(data.message)
		hint_:SetExpiry(data.duration)
		hint_:SetCanClick(false)
	end)
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
		music.new(track.biome, {
			track,
		}, track.coordinates.position, track.coordinates.size)

		print("added biome track: " .. i .. ` {tracks[i]}`)
	end

	music:Start()

	local musicGui = PlayerGui:WaitForChild("Music") :: ScreenGui & {
		CanvasGroup: any & CanvasGroup & {
			Disc: ImageLabel,
			Note: ImageLabel,
			SongName: TextLabel,
			Artist: TextLabel,
		},
	} & any
	local musicCanvas = musicGui.CanvasGroup
	local disc = musicCanvas.Disc
	local note_image = musicCanvas.Note

	local song_name = musicCanvas.SongName
	local artist_display = musicCanvas.Artist

	music.Playing.Changed:Connect(function(track: music.Track)
		if not track then
			return
		end

		song_name.Text = track.name
		artist_display.Text = track.artist or "none"
	end)

	local average_framerate = frame_rate:GetFrameRate(math.pow(10, 2))

	-- rotate effect on disc
	local rotation_thread = task.spawn(retryer.infdelay, average_framerate, function()
		disc.Rotation += RunService.PreRender:Wait()
	end)
end

local function initializeLoadouts()
	print("init loadouts")
	local loadoutsGui = PlayerGui.Loadout
	local loadoutCanvas = loadoutsGui.CanvasGroup
end

local function initializeObjectives()
	print("init objectives")

	local objectiveGui = PlayerGui.Objective
	displayorder.new(objectiveGui.CanvasGroup)

	local completed_value = observer.new(0)
	local uncompleted_value = observer.new(0)

	local rank = observer.new("") :: observer.Observer<string>

	future.new(function(profile: typemarshaller.Profile)
		if profile and profile.Data then
			rank:Set(profile.Data.level)
		else
			rank:Set("Bronze I")
			local rank_hint = hint.new()
			rank_hint:SetText("Couldn't fetch Rank")
			rank_hint:SetCanClick(false)
		end
	end, expectProfile())

	local function toggleUI()
		displayorder:Toggle(objectiveGui.CanvasGroup)
	end

	hydration(objectiveGui.CanvasGroup.Frame.Completed.Value) {
		Text = completed_value,
	}
	hydration(objectiveGui.CanvasGroup.Frame.Uncompleted.Value) {
		Text = uncompleted_value,
	}

	hud.new("Quests", toggleUI, lucide.GetAsset("clipboard-list"))
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
hud:Render()
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

do
	local char_folder = ReplicatedStorage.Characters
	char_folder.Name = "Characters"
	char_folder.Parent = ReplicatedStorage
end

-- control

local function getAttackTypeFromKey(key: Enum.KeyCode)
	-- profile = yoink.client:grab("profile_data")
	profile = expectProfile()
	if not profile or not profile.Data then
		return
	end

	local attack_types = {}
	for i, value in pairs(profile.Data.keybinds) do
		attack_types[i] = Enum.KeyCode:FromValue(value)
	end

	return attack_types[key]
end

keyboard.KeyDown:Connect(function(key: Enum.KeyCode)
	local attack_type = getAttackTypeFromKey(key)
	if attack_type then
		orion:Execute(player, attack_type)
	end
end)

mouse.LeftDown:Connect(function()
	local attack_type = "M1"
	orion:Execute(player, attack_type)
end)

humanoid.HealthChanged:Connect(function(health)
	local minimum_health = 20

	if health <= minimum_health then
		health_pulse:On()
	else
		health_pulse:Off()
	end
end)

orion.new(player, expectProfile())

Packet.ReplicateAnimation.listen(function(data)
	animate.loadAnimation(data.identification, {
		Id = "rbxassetid://" .. data.identification,
		Weight = 1,
	})
	animate.play(`rbxassetid://{data.identification}`, 0.25)
end)

Packet.CleanupCharacter.listen(function()
	animate.cleanup()
	music:Destroy()
	options:Clear()
	hud:Clear()
	dropper._trove:Clean()
end)

-- This results in four decimal places.

print("Client has finished")
