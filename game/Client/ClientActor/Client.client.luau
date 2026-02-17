--!nonstrict
--!optimize 2

-- Client.client.luau

print(script.Name)

-- // Services -- //
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

task.wait(5) -- wait for the player to load

-- // Requires -- //
local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient") :: ModuleScript) :: any
local bobbing = require(StarterPlayer.StarterPlayerScripts.Camera.bobbing)
local camera_controller = require(StarterPlayer.StarterPlayerScripts.Camera["camera-controller"])
local over_shoulder = require(StarterPlayer.StarterPlayerScripts.Camera["over-shoulder"])

local Packet = require(ReplicatedStorage.Packet)

local achievement = require(StarterPlayer.StarterPlayerScripts.Components.achievement)

local animate = require("../Utilities/animate")

local damage = require(ReplicatedStorage.Combat.Strike.damage)

local displayorder = require(StarterPlayer.StarterPlayerScripts.Interface.displayorder)

local dropper = require(ReplicatedStorage.ClientModules.dropper)

local future = require(ReplicatedStorage.Packages.future)

local glove = require(StarterPlayer.StarterPlayerScripts.Gameplay.glove)

local health_pulse = require(StarterPlayer.StarterPlayerScripts.Gameplay["health-pulse"])

local hint = require(StarterPlayer.StarterPlayerScripts.Components.hint)
local hud = require(StarterPlayer.StarterPlayerScripts.Components.hud)

local hydration = require(ReplicatedStorage.Utility.hydration)

local input = require(ReplicatedStorage.Packages.input)

local joint_controller = require(StarterPlayer.StarterPlayerScripts.Movement["joint-controller"])

local logger = require(ReplicatedStorage.ClientModules.logger)

local lucide = require(ReplicatedStorage.Packages.lucide)

-- local markdown = require(ReplicatedStorage.ClientModules.markdown)

local market = require("../Components/market")

local motion_blur = require(StarterPlayer.StarterPlayerScripts.Graphics["motion-blur"])

local movement_controller = require(StarterPlayer.StarterPlayerScripts.Movement["movement-controller"])

local music = require("../Gameplay/music")

local navigation_rail = require(StarterPlayer.StarterPlayerScripts.Components["navigation-rail"])

local number_abbreviation = require(ReplicatedStorage.Modules.Serialization["number-abbreviation"])

local observer = require(ReplicatedStorage.Utility.observer)

local options = require(StarterPlayer.StarterPlayerScripts.Components.options)
local party_frontend = require(StarterPlayer.StarterPlayerScripts.Components["party-frontend"])
local physical_bar = require(StarterPlayer.StarterPlayerScripts.Components["physical-bar"])
local pop = require(StarterPlayer.StarterPlayerScripts.Interface.pop)
local spectate = require(StarterPlayer.StarterPlayerScripts.Components.spectate)
local tooltip = require("../Components/tooltip")

local orion = require(ReplicatedStorage.Combat.orion) -- Orion Combat Framework

local parallax = require("../Interface/parallax")

local parallaxLayers = require(ReplicatedStorage.Structures.parallaxLayers)

local profilestructure = require(ReplicatedStorage.Structures.profilestructure)

local rbx_thumb = require(ReplicatedStorage.Modules.Serialization["rbx-thumb"])

local retryer = require(ReplicatedStorage.Utility.retryer)

local ripple = require(StarterPlayer.StarterPlayerScripts.Interface.ripple)

local safeteleport = require(ReplicatedStorage.Modules.safeteleport)

local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)

local spr = require(ReplicatedStorage.Modules.spr)

local sway = require("../Interface/sway")

local swipe = require("../Interface/swipe")

local audio = require(ReplicatedStorage.Modules.audio)

local throbber = require("../Components/throbber")

local tablekit = require(ReplicatedStorage.Packages.tablekit)
local timer = require(ReplicatedStorage.Modules.timer)

local RankStructure = require(ReplicatedStorage.Structures.RankStructure)
local command_whitelist = require(ReplicatedStorage.Structures["command-whitelist"])
local trove = require(ReplicatedStorage.Packages.trove)

local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

local ability_controller = require(StarterPlayer.StarterPlayerScripts.Movement["ability-controller"])
local bounds = require(StarterPlayer.StarterPlayerScripts.Utilities.bounds)
local fetchProfile = require(StarterPlayer.StarterPlayerScripts.Utilities.fetchProfile)
local wiggle = require(StarterPlayer.StarterPlayerScripts.Interface.wiggle)

local keyboard = input.Keyboard.new()
local mouse = input.Mouse.new()

print("Client Requirements")

-- // Events -- //
local events = ReplicatedStorage.Events
local get_profile = events.GetProfile

-- // Variables -- //

local player = Players.LocalPlayer
local profile = nil

local _trove = trove.new()

local character = player.Character or player.CharacterAdded:Wait() :: typemarshaller.Character
local humanoid = character.Humanoid

---------------------------------- Client --------------------------------

local PlayerGui = player.PlayerGui

if RunService:IsStudio() then
	logger.new()
end

task.spawn(glove.Apply, glove, character)

print("client starting")

local function initializeCommands()
	--print("init commands")

	Cmdr:SetActivationKeys({ Enum.KeyCode.Equals })
	Cmdr:SetActivationUnlocksMouse(true)
	Cmdr:SetPlaceName("Sparking Cards Lobby")
	Cmdr:SetActivationUnlocksMouse(true)
	Cmdr:SetHideOnLostFocus(false)

	local function showUI()
		Cmdr:Show()
	end

	if RunService:IsStudio() or table.find(command_whitelist, player.UserId) then
		task.delay(15, function()
			local snack_bar = hint.new()
			snack_bar:SetText("Welcome, Developer. Press the '=' symbol to open Cmdr.")
			snack_bar:SetAction(showUI, "Open")
			snack_bar:SetCanDismiss(false)
			snack_bar:SetCanClick(true)
		end)
	end
end

local function initializeAudio()
	--print("init audio")

	task.spawn(function()
		audio:AddSFX("wood-block-1", 9120917813)
		audio:AddSFX("wood-block-2", 9120917604)
		audio:AddSFX("wood-block-3", 9120917605)
		audio:AddSFX("wood-block-4", 9120917794)
		audio:AddSFX("wood-block-5", 9120917978)

		audio:AddSFX("continue", 92647604633081)

		audio:AddSFX("click", 90092163763441)
		audio:AddSFX("hover", 119879668444252)
		audio:AddSFX("leave", 85897203168160)
		audio:AddSFX("success", 76288726968959)
	end)
end

local function initializeMarket()
	--print("init market")

	local shopGui = PlayerGui.Shop
	local shopCanvas = shopGui.CanvasGroup
	local shopFrame = shopCanvas.Frame

	displayorder.new(shopCanvas)

	local spendings = shopFrame.Spendings

	local spendings_icon = spendings.SpendingsIcon

	local navigation = market:GetNavigation()

	local function callback()
		displayorder:Toggle(shopCanvas)

		if displayorder:GetState(shopCanvas) then
			task.spawn(market.LoadItems, market)

			navigation:Show()

			market:DisplaySpendings(fetchProfile())

			local new_hint = hint.new()
			new_hint:SetText("Loading Market...")
			new_hint:SetExpiry(1.5)

			wiggle(spendings_icon, function()
				--print("completed wiggle")
			end)
		else
			navigation:Hide()
			market:Unload()
		end
	end

	displayorder.Changed:Connect(function(canvas_data, visible)
		if canvas_data.canvas == shopCanvas then
			if visible then
				return
			end

			navigation:Hide()
		end
	end)

	market:StartNavigation()

	hud.new("Market", callback, lucide.GetAsset("shopping-cart"))
end
local function initializeOptions()
	--print("init options")
	local optionsGui = PlayerGui.Options
	local optionsCanvas = optionsGui.CanvasGroup
	local optionsFrame = optionsCanvas.Frame

	displayorder.new(optionsCanvas)

	shadow(optionsFrame)

	local function toggleUI()
		displayorder:Toggle(optionsCanvas)

		if displayorder:GetState(optionsCanvas) then
			options:Render()
		end
	end

	hud.new("Options", toggleUI, lucide.GetAsset("cog"))
end
local function initializeMatchmaking()
	print("init matchmaking")

	local queue_updated = events.Matchmaking.QueueUpdated

	queue_updated.OnClientEvent:Connect(function(info)
		print("Matchmaking.QueueUpdated:", tablekit.ToString(info))
	end)

	local matchmakingGui = PlayerGui.NewMatch
	local matchmakingCanvas = matchmakingGui.CanvasGroup
	local matchmakingFrame = matchmakingCanvas.Frame

	local statusText = matchmakingFrame.Time
	local pulseImage = matchmakingFrame.Pulse

	shadow(matchmakingFrame)

	local state = observer.new(false) :: observer.Observer<boolean>
	local clock = timer.new()

	local interval_thread
	local performed_hint = 0

	local function showMatchmakingFrame()
		if interval_thread then
			task.cancel(interval_thread)
		end

		-- send request to server to join matchmaking
		local join_res = events.Matchmaking.JoinQueue:InvokeServer()
		if join_res and not join_res.success then
			local hint_ = hint.new()
			hint_:SetText(join_res.message or "Failed to join matchmaking.")
			hint_:SetCanClick(false)

			return
		end

		-- request a snapshot of the queue for the frontend
		local info = events.Matchmaking.RequestQueueInfo:InvokeServer()
		print(tablekit.ToString(info))

		spr.target(matchmakingFrame, 0.6, 8, {
			Position = UDim2.fromScale(0.5, 0.1),
		})

		if performed_hint <= 2 then
			local new_hint = hint.new()
			new_hint:SetText("Swipe up on the bar to cancel matchmaking. [" .. performed_hint .. "/3]")
			new_hint:SetExpiry(3)

			performed_hint += 1
		end

		state:Set(true)

		clock:Start()
		-- every 0.33_ seconds
		interval_thread = clock:interval(1 / 3, function()
			local total_seconds = clock:GetTime()

			local minutes = math.floor(total_seconds / 60)
			local hours = math.floor(minutes / 60) -- its very unlikely we will reach this
			minutes = minutes % 60

			local seconds = total_seconds % 60
			statusText.Text = string.format(
				'Searching...<br/><font transparency="0.5"><font size="14">%02d:%02d:%02d</font></font>',
				hours,
				minutes,
				seconds
			)

			pop(pulseImage, 1.8)
		end)

		audio:PlaySFX("success")
	end

	local function hideMatchmakingFrame()
		-- notify server to cancel matchmaking
		local leave_res = events.Matchmaking.LeaveQueue:InvokeServer()
		if leave_res and not leave_res.success then
			local hint_ = hint.new()
			hint_:SetText("Failed to leave matchmaking.")
			hint_:SetCanClick(false)

			return
		end

		task.wait(1 / 8)

		spr.target(matchmakingFrame, 1, 2.5, {
			Position = UDim2.fromScale(0.5, -0.5),
		})

		state:Set(false)

		clock:Reset()
		clock:Stop()

		if interval_thread then
			task.cancel(interval_thread)
		end

		audio:PlaySFX("leave")
	end

	state:Watch(function(newValue)
		matchmakingCanvas.Visible = newValue
	end)

	local swipeDetector = swipe.new(matchmakingFrame)
	swipeDetector.OnSwipe:Connect(function(direction: swipe.direction, delta: Vector3)
		if not state:Get() then
			-- how sir

			return
		end

		if direction == "up" then
			future.Try(hideMatchmakingFrame)
		else
			return
		end
	end)

	hud.new("Play", showMatchmakingFrame, lucide.GetAsset("play"), true)
end
local function initializeBadges()
	--print("init badges")

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
		achievement:DisplayTotal(fetchProfile())
		achievement:Load(fetchProfile())
	end

	hud.new("Badges", callback, lucide.GetAsset("trophy", 48), true)
end
local function initializeNotifiers()
	--print("init notifiers")

	Packet.SendNotification.listen(function(data)
		local hint_ = hint.new()
		hint_:SetText(data.message)
		hint_:SetExpiry(data.duration or 4)
		hint_:SetCanClick(false)
	end)
end
local function initializeMusic()
	--print("init music")

	local tracks = {
		{
			biome = "Baseplate",
			id = 85255924043591,
			name = "Maui",
			artist = "Hazelwood",
			coordinates = {
				position = vector.create(-1845, 228, 139),
				size = vector.create(2048, 64, 2048),
			},
		},
		{
			biome = "Route 17",
			id = 12385329420,
			name = "Greenlight Valley",
			artist = "Dynasty",
			coordinates = {
				position = vector.create(-1791, 323, -3444),
				size = vector.create(580, 254, 761),
			},
		},
	}

	for i, track in ipairs(tracks) do
		task.spawn(music.new, track.biome, {
			track,
		}, track.coordinates.position, track.coordinates.size)

		--print("added biome track: " .. i .. ` {tracks[i]}`)
	end

	music:Start()

	local musicGui = PlayerGui.Music
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

	local function rotate()
		while true do
			local frame = RunService.RenderStepped:Wait()
			disc.Rotation += math.deg(frame)
		end
	end

	-- rotate effect on disc
	local rotation_coroutine = coroutine.create(rotate)
	coroutine.resume(rotation_coroutine)

	local swipe_controller = swipe.new(disc)
	swipe_controller.OnSwipe:Connect(function(direction, delta)
		future.Try(function()
			if coroutine.status(rotation_coroutine) == "running" then
				coroutine.close(rotation_coroutine)
			elseif
				coroutine.status(rotation_coroutine) == "suspended"
				or coroutine.status(rotation_coroutine) == "dead"
			then
				return
			end

			-- a fun little effect:
			-- spin the disc based on the swipe delta
			spr.target(disc, 0.5, 5, {
				Rotation = disc.Rotation + delta.X * 5,
			})

			-- restart rotation after the player is done interacting
			rotation_coroutine = coroutine.create(rotate)
			coroutine.resume(rotation_coroutine)
		end)
	end)
end

local function initializeLoadouts()
	--print("init loadouts")
	local loadoutsGui = PlayerGui.Loadout
	local loadoutCanvas = loadoutsGui.CanvasGroup

	local sample_card = loadoutCanvas.Card

	local arc = 60
	local radius = 80
end

local function initializeObjectives()
	--print("init objectives")

	local objectiveGui = PlayerGui.Objective
	displayorder.new(objectiveGui.CanvasGroup)

	local completed_value = observer.new(0)
	local uncompleted_value = observer.new(0)

	local rank = observer.new("") :: observer.Observer<string>

	task.spawn(future.Try, function()
		profile = fetchProfile()

		if profile then
			orion.new(player, profile)
		end

		if profile and profile.Data then
			rank:Set(profile.Data.level)
		else
			rank:Set("Bronze I")
			local rank_hint = hint.new()
			rank_hint:SetText("Couldn't fetch Rank")
			rank_hint:SetCanClick(false)
		end
	end)

	local function toggleUI()
		displayorder:Toggle(objectiveGui.CanvasGroup)
	end

	hydration(objectiveGui.CanvasGroup.Frame.Completed.Value) {
		Text = completed_value,
	}
	hydration(objectiveGui.CanvasGroup.Frame.Uncompleted.Value) {
		Text = uncompleted_value,
	}

	hud.new("Quests", toggleUI, lucide.GetAsset("clipboard-list"), true)
end

local function initializeParties()
	--print("init parties")

	local party_gui = PlayerGui.Party
	local party_canvas = party_gui.CanvasGroup
	local party_frame = party_canvas.Frame

	displayorder.new(party_canvas)

	local function toggleUI()
		displayorder:Toggle(party_canvas)
	end

	hud.new("Party", toggleUI, lucide.GetAsset("party-popper"))
end

local function initializeStatistics()
	--print("init stats")

	local stat_gui = PlayerGui.Stats
	local stat_canvas = stat_gui.CanvasGroup
	local holder = stat_canvas.Frame.Holder

	displayorder.new(stat_canvas)

	local rank_order = {
		["Bronze I"] = "AncientTotem",
		["Iron II"] = "StoneEgg",
		["Gold III"] = "OrangeDrop",
		["Platinum IV"] = "PurpleCrown",
		["Emerald V"] = "SmallEmerald",
		["Master VI"] = "GlowingAmulet",
		["Elite VII"] = "BlueDiamond",
		["Ruby VIII"] = "RunicCircle",
		["Prismatic IX"] = "IceShard",
		["Sparking X"] = "LargeAmethyst",
	}

	-- https://create.roblox.com/store/asset/18460365353/
	local rank_image = future
		.new(function()
			return Content.fromAssetId(18460365353)
		end)
		:Await()

	local fancy_str = "%s<br/><font size='13'><font transparency='0.4'>%s</font></font>"

	-- local typewriter = markdown.typewriter.new()

	local function updateStats()
		profile = fetchProfile()

		if profile then
			-- proceed

			holder.Affinity.Text = string.format(fancy_str, "Affinity", profile.Data.affinity)
			holder.Prisms.Text = string.format(fancy_str, "Prisms", profile.Data.prisms)
			holder.Victories.Text = string.format(fancy_str, "Victories", profile.Data.victories)
			--holder.Level.Text = string.format(fancy_str, "Rank", profile.Data.level)
			holder.LastLogin.Text =
				string.format(fancy_str, "Last Login", os.date("%Y-%m-%d %H:%M:%S", profile.Data.last_login))
		end
	end

	task.spawn(function()
		while true do
			task.wait(5)

			updateStats()
		end
	end)

	local function toggleUI()
		displayorder:Toggle(stat_canvas)

		updateStats()
	end

	hud.new("Stats", toggleUI, lucide.GetAsset("database"))
end

local function initializeSpectating()
	local spectate_gui = PlayerGui.Spectate

	keyboard.KeyDown:Connect(function(key: Enum.KeyCode, processed: boolean)
		if processed then
			return
		end

		-- get the keybind for spectating

		profile = fetchProfile()

		local keybind = nil

		if not profile then
			keybind = profilestructure.keybinds.enable_spectating
		else
			keybind = profile.Data.keybinds.enable_spectating
		end

		keybind = Enum.KeyCode:FromValue(keybind)
		assert(keybind, "couldn't get Enum keycode from value.")

		if key ~= keybind then
			return
		end

		if spectate:IsSpectating() then
			hud:Show()
			spectate:Stop()
		else
			spectate:On()
			hud:Hide()
		end
	end)
end

initializeCommands()
initializeAudio()
initializeMarket()
initializeOptions()
initializeMatchmaking()
initializeBadges()
initializeNotifiers()
initializeMusic()
initializeLoadouts()
initializeObjectives()
initializeParties()
initializeStatistics()
initializeSpectating()

hud:Render()
tooltip:Start()
--motion_blur:On()
task.delay(15, function()
	camera_controller.new("bobbing", bobbing)
end)

movement_controller:Add(script.Parent.Parent.Movement["sprint-controller"])
movement_controller:Add(script.Parent.Parent.Movement["jump-controller"])
movement_controller:Add(script.Parent.Parent.Movement["stamina-controller"])
movement_controller:Add(script.Parent.Parent.Movement["walk-controller"])
movement_controller:Add(script.Parent.Parent.Movement["joint-controller"])
movement_controller:Start()

-- local rain_controller = rain.new()
-- rain_controller:Start(rain_controller)

-- control

orion.register_player()

local function getAttackTypeFromKey(key: Enum.KeyCode)
	-- profile = yoink.client:grab("profile_data")
	profile = fetchProfile()
	if not profile or not profile.Data then
		return
	end

	local attack_types = {}
	for i, value in pairs(profile.Data.keybinds) do
		attack_types[i] = Enum.KeyCode:FromValue(value)
	end

	return attack_types[key]
end

keyboard.KeyDown:Connect(function(key: Enum.KeyCode, processed: boolean)
	if processed then
		return
	end

	local attack_type = getAttackTypeFromKey(key)
	if attack_type then
		local module = orion.execute()
		if not module then
			print("couldnt pull module from `orion.execute`.")

			return
		end

		local internal = require(module) :: typemarshaller.AttackModule
		internal.moveset[attack_type](player, {
			player_data = orion.get_player_data(),
		})

		--hud:Hide()
	end
end)

keyboard.KeyDown:Connect(function(key: Enum.KeyCode, processed: boolean)
	if processed then
		return
	end

	if key == Enum.KeyCode.K then
		ability_controller:Juke("Left")
	elseif key == Enum.KeyCode.L then
		ability_controller:Juke("Right")
	end
end)

--[[
keyboard.KeyUp:Connect(function(key: Enum.KeyCode, processed: boolean)
	if processed then
		return
	end

	task.wait(2)

	hud:Show()
end)
--]]
mouse.LeftDown:Connect(function(processed: boolean)
	if processed then
		return
	end

	--

	--hud:Hide()
end)
--[[
mouse.LeftUp:Connect(function(processed: boolean)
	if processed then
		return
	end

	hud:Show()
end)
--]]

local health_bar = physical_bar.new()
health_bar:SetAdornee(humanoid.RootPart :: BasePart)

local health_thread = nil

humanoid.HealthChanged:Connect(function(health)
	if health_thread then
		task.cancel(health_thread)
	else
		health_bar:Show()
	end

	health_bar:SetValue(health)

	health_thread = task.delay(4, function()
		health_bar:Hide()
	end)
end)

--[[
-- new scope
do
	-- hud bounds
	local size = Vector2.new(1011, 77 + (1 / 2))
	local position = Vector2.new(-0.5, 859 + (1 / 4))

	mouse.Moved:Connect(function(mouse_position: Vector2)
		if not mouse_position then
			return
		end

		local is_inside = bounds.inner(position, size, mouse_position)

		if not is_inside then
			return
		end

		hud:Show()
	end)
end
--]]

do
	-- send a notification when the graphics level
	-- is not at an "appropriate" value.

	local user_settings = UserSettings()
	local user_game_settings = user_settings:GetService("UserGameSettings")

	local function getGraphicsQuality()
		return user_game_settings.SavedQualityLevel.Value
	end

	local min_quality_level = 6
	local min_quality_enum = Enum.SavedQualitySetting.QualityLevel6

	user_game_settings.Changed:Connect(function()
		local quality_level = getGraphicsQuality()

		if quality_level >= min_quality_level then
			return
		end

		-- send a notification snackbar

		local str = "Set Quality Level to %s for the best experience."

		local snack_bar = hint.new()
		snack_bar:SetText(string.format(str, min_quality_level))
		snack_bar:SetExpiry(7)
		snack_bar:SetAction(function()
			future.Try(function()
				user_game_settings.SavedQualityLevel = min_quality_enum
			end)
		end, "Set")
	end)
end

-- over_shoulder:Enable()

Packet.ReplicateAnimation.listen(function(data)
	animate.load(tonumber(data.identification))
	animate.play(`rbxassetid://{data.identification}`, 0.25)
end)

events.PlayAnimation.OnClientEvent:Connect(function(...)
	animate.load(...)
	animate.play(..., 0.25)
end)

Packet.CleanupCharacter.listen(function()
	music:Destroy()
	options:Clear()
	hud:Clear()
	dropper._trove:Clean()
end)

print("Client has finished")
