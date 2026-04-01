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
local dialogue = require(StarterPlayer.StarterPlayerScripts.Components.dialogue)

local Packet = require(ReplicatedStorage.Packet)

local animate = require("../Utilities/animate")

local displayorder = require(StarterPlayer.StarterPlayerScripts.Interface.displayorder)

local future = require(ReplicatedStorage.Packages.future)

local glove = require(StarterPlayer.StarterPlayerScripts.Gameplay.glove)

local health_pulse = require(StarterPlayer.StarterPlayerScripts.Gameplay["health-pulse"])

local hint = require(StarterPlayer.StarterPlayerScripts.Components.hint)
local hud = require(StarterPlayer.StarterPlayerScripts.Components.hud)
local keybindlink = require(StarterPlayer.StarterPlayerScripts.Components.keybindlink)

local input = require(ReplicatedStorage.Packages.input)

local joint_controller = require(StarterPlayer.StarterPlayerScripts.Movement["joint-controller"])

local flight = require(ReplicatedStorage.Combat.framework.features.flight)
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

local badge_frontend = require(StarterPlayer.StarterPlayerScripts.Components["badge-frontend"])
local health_bar = require(StarterPlayer.StarterPlayerScripts.Components["health-bar"])
local indicate_damage = require(StarterPlayer.StarterPlayerScripts.Components["indicate-damage"])
local options = require(StarterPlayer.StarterPlayerScripts.Components.options)
local party_frontend = require(StarterPlayer.StarterPlayerScripts.Components["party-frontend"])
local physical_bar = require(StarterPlayer.StarterPlayerScripts.Components["physical-bar"])
local pop = require(StarterPlayer.StarterPlayerScripts.Interface.pop)
local quest_frontend = require(StarterPlayer.StarterPlayerScripts.Components["quest-frontend"])
local skill_frontend = require(StarterPlayer.StarterPlayerScripts.Components["skill-frontend"])
local spectate = require(StarterPlayer.StarterPlayerScripts.Components.spectate)
local tooltip = require("../Components/tooltip")

local profilestructure = require(ReplicatedStorage.Structures.profilestructure)

local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local sway = require(StarterPlayer.StarterPlayerScripts.Interface.sway)

local spr = require(ReplicatedStorage.Modules.spr)

local swipe = require("../Interface/swipe")

local audio = require(ReplicatedStorage.Modules.audio)

local crosshair_service = require(ReplicatedStorage.Services["crosshair-service"])
local proximity_prompt = require(ReplicatedStorage.Modules["proximity-prompt"])
local tablekit = require(ReplicatedStorage.Packages.tablekit)
local timer = require(ReplicatedStorage.Modules.timer)

local command_whitelist = require(ReplicatedStorage.Structures["command-whitelist"])

local frame_rate = require(ReplicatedStorage.Utility["frame-rate"])
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

local ability_controller = require(StarterPlayer.StarterPlayerScripts.Movement["ability-controller"])
local expressive_shapes = require(StarterPlayer.StarterPlayerScripts.Interface["expressive-shapes"])
local fetchProfile = require(StarterPlayer.StarterPlayerScripts.Utilities.fetchProfile)
local wiggle = require(StarterPlayer.StarterPlayerScripts.Interface.wiggle)

local keyboard = input.Keyboard.new()
local mouse = input.Mouse.new()

print("Client Requirements")

-- // Variables -- //

local player = Players.LocalPlayer
local profile = nil

local character = player.Character or player.CharacterAdded:Wait() :: typemarshaller.Character
local humanoid = character.Humanoid

-- // Events -- //
local events = ReplicatedStorage.Events
local internal_remotes = player.PlayerScripts.Remotes
local get_profile = events.GetProfile

---------------------------------- Client --------------------------------

local PlayerGui = player.PlayerGui

print("client starting")

local function initializeRemotes()
	do
		local toggle_matchmaking_re = Instance.new("BindableEvent")
		toggle_matchmaking_re.Name = "ToggleMatchmakingUI"
		toggle_matchmaking_re.Parent = player.PlayerScripts.Remotes
	end
end

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

	local log = logger.new()
	log:disable()

	if RunService:IsStudio() or table.find(command_whitelist, player.UserId) then
		task.spawn(function()
			frame_rate:WaitUntilFramesAreStable(0.03)

			local snack_bar = hint.new()
			snack_bar:SetText("Welcome, Developer. Press the '=' to open Cmdr.")
			snack_bar:SetAction(showUI, "Cmdr")
			snack_bar:SetCanDismiss(true)
			snack_bar:SetCanClick(true)

			log:enable()
		end)

		local is_log_enabled = true

		--[[
		hud.new("Log", function()
			if is_log_enabled then
				log:disable()
			else
				log:enable()
			end
		end, lucide.GetAsset("clipboard-list"))
		--]]
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

		audio:AddSFX("cancel-1", 127645399844758)

		audio:AddSFX("train_brakes", 185857550)
		audio:AddSFX("train_clattering", 149026377)

		audio:AddMusic("flight-wind", 3308152153)
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

	market:InitializeTabs()

	local function callback()
		displayorder:Toggle(shopCanvas)

		if displayorder:GetState(shopCanvas) then
			market:LoadItems()

			market:DisplaySpendings()

			wiggle(spendings_icon, function()
				--print("completed wiggle")
			end)
		end
	end

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
			options:LoadItems()
		end
	end

	hud.new("Options", toggleUI, lucide.GetAsset("settings"))
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

	local shape = matchmakingFrame.Shape
	local shape_image = shape.ImageLabel

	shadow(matchmakingFrame)

	local state = observer.new(false) :: observer.Observer<boolean>
	local clock = timer.new()

	local interval_thread
	local performed_hint = 0

	local function showMatchmakingFrame(is_party)
		if interval_thread then
			task.cancel(interval_thread)
		end

		-- send request to server to join matchmaking
		if not is_party then
			local join_res = events.Matchmaking.JoinQueue:InvokeServer()
			if join_res and not join_res.success then
				local hint_ = hint.new()
				hint_:SetText(join_res.message or "Failed to join matchmaking.")
				hint_:SetCanClick(false)

				audio:PlaySFX("cancel-1")

				return
			elseif join_res and join_res.success then
				if string.find(string.lower(join_res.message), "party") then
					-- if it says something about a party then...
					is_party = true
				end
			end
		end

		-- request a snapshot of the queue for the frontend
		local info = events.Matchmaking.RequestQueueInfo:InvokeServer()
		print(tablekit.ToString(info))
		if string.find(tablekit.ToString(info):lower(), "party_id") then
			-- if it says something about a party then...
			is_party = true
		end

		spr.target(matchmakingFrame, 0.6, 4, {
			Position = UDim2.fromScale(0.5, 0.115),
		})

		if performed_hint <= 3 then
			local new_hint = hint.new()
			new_hint:SetText("Swipe up on the bar to cancel matchmaking. [" .. performed_hint .. "/3]")
			new_hint:SetExpiry(3)

			performed_hint += 1
		end

		state:Set(true)

		expressive_shapes.register(shape, shape_image)

		if is_party then
			shape_image.Image = "rbxassetid://115169602847111"
			shape_image.Frame.Visible = true
		else
			shape_image.Image = "rbxassetid://118451897423804"
			shape_image.Frame.Visible = false
		end

		clock:Start()
		-- every 0.33_ seconds
		interval_thread = clock:interval(1 / 3, function()
			local total_seconds = clock:GetTime()

			-- maybe we should buffer serialize this later...
			events.SendMatchmakingTime:FireServer(total_seconds)

			local minutes = math.floor(total_seconds / 60)
			local hours = math.floor(minutes / 60) -- its very unlikely we will reach this
			minutes = minutes % 60

			local seconds = total_seconds % 60

			-- add in the loading dots "." ".." "..." effect thingy
			local dots = string.rep(".", math.floor(total_seconds * 3) % 4)
			statusText.Text = string.format(
				'Searching%s<br/><font transparency="0.5"><font size="14">%02d:%02d:%02d</font></font>',
				dots,
				hours,
				minutes,
				seconds
			)
		end)

		audio:PlaySFX("success")
	end

	local function hideMatchmakingFrame(is_party)
		if not is_party then
			-- notify server to cancel matchmaking
			local leave_res = events.Matchmaking.LeaveQueue:InvokeServer()
			if leave_res and not leave_res.success then
				local hint_ = hint.new()
				hint_:SetText("Failed to leave matchmaking.")
				hint_:SetCanClick(false)

				audio:PlaySFX("cancel-1")

				return
			end
		end

		task.wait(1 / 8)

		spr.target(matchmakingFrame, 0.6, 2.5, {
			Position = UDim2.fromScale(0.5, -0.5),
		})

		state:Set(false)

		clock:Reset()
		clock:Stop()

		expressive_shapes.unregister(shape)

		if interval_thread then
			task.cancel(interval_thread)
		end

		audio:PlaySFX("leave")
	end

	local toggle = internal_remotes:WaitForChild("ToggleMatchmakingUI")

	toggle.Event:Connect(function(boolean: boolean)
		if boolean then
			showMatchmakingFrame(boolean)
		else
			hideMatchmakingFrame(true)
		end
	end)

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
			-- nudge the frame towards the delta direction as a fun little effect
			spr.target(matchmakingFrame, 0.3, 3, {
				Position = matchmakingFrame.Position + UDim2.fromOffset(delta.X * 0.1, delta.Y * 0.1),
			})

			-- then spring back to the center
			task.wait(1 / 8)
			spr.stop(matchmakingFrame, "Position")
			spr.target(matchmakingFrame, 0.5, 5, {
				Position = UDim2.fromScale(0.5, 0.115),
			})
		end
	end)

	hud.new("Play", showMatchmakingFrame, lucide.GetAsset("play"), true)
end
local function initializeBadges()
	--print("init badges")

	local badgesGui = PlayerGui.Badges
	local badgesCanvas = badgesGui.CanvasGroup
	local badgeFrame = badgesCanvas.Frame

	shadow(badgeFrame)

	displayorder.new(badgesCanvas)

	local function callback()
		displayorder:Toggle(badgesCanvas)
		badge_frontend:LoadItems()
		badge_frontend:DisplayTotalPoints()
		task.wait(5)
		if displayorder:GetState(badgesCanvas) then
			badge_frontend:DisplayTotalAchievements()
		end
	end

	hud.new("Badges", callback, lucide.GetAsset("award", 48), true)
end
local function initializeNotifiers()
	--print("init notifiers")

	local function handleNotification(data)
		if RunService:IsStudio() then
			print("Notification received: ", tablekit.ToString(data))
		else
			local hint_ = hint.new()
			hint_:SetText(data.message)
			hint_:SetExpiry(data.duration or 4)
			hint_:SetCanClick(false)

			local negative_outcomes = {
				"failed",
				"couldnt",
				"couldn't",
				"could not",
				"attempted",
				"tried",
				"no",
				"not",
				"n't",
				"unsuccessful",
				"error",
				"mistake",
				"wrong",
				"declined",
				"refused",
			}
			-- if we find these words in the data message, play the 'cancel' sound

			for i, word in ipairs(negative_outcomes) do
				if string.find(string.lower(data.message), word) then
					audio:PlaySFX("cancel-1")
					return
				end
			end
		end
	end

	Packet.SendNotification.listen(handleNotification)
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
			id = 133345791762540,
			name = "Tariro",
			artist = "Pufino | Freetouse",
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

	musicGui.Enabled = not RunService:IsStudio()

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
	local objectiveGui = PlayerGui.Objective
	displayorder.new(objectiveGui.CanvasGroup)

	local function toggleUI()
		displayorder:Toggle(objectiveGui.CanvasGroup)

		if displayorder:GetState(objectiveGui.CanvasGroup) then
			quest_frontend:LoadItems()
			quest_frontend:DisplayCompletions()
		else
			quest_frontend:Unload()
		end
	end

	hud.new("Quests", toggleUI, lucide.GetAsset("clipboard-list"), true)
end

local function initializeSkills()
	local skillGui = PlayerGui.SkillTree
	displayorder.new(skillGui.CanvasGroup)

	skill_frontend:Unload()

	local function toggleUI()
		displayorder:Toggle(skillGui.CanvasGroup)

		if displayorder:GetState(skillGui.CanvasGroup) then
			skill_frontend:LoadCatagories()
		else
			skill_frontend:Unload()
		end
	end

	hud.new("Skills", toggleUI, lucide.GetAsset("currency"), true)
end

local function initializeParties()
	--print("init parties")

	local party_gui = PlayerGui.Party
	local party_canvas = party_gui.CanvasGroup

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
		if not profile then
			profile = profilestructure -- use a sample profile
		end

		if profile then
			-- proceed

			holder.Affinity.Text = string.format(fancy_str, "Affinity", profile.Data.affinity)
			holder.Prisms.Text = string.format(fancy_str, "Prisms", profile.Data.prisms)
			holder.Victories.Text = string.format(fancy_str, "Victories", profile.Data.victories)
			--holder.Level.Text = string.format(fancy_str, "Rank", profile.Data.level)
			holder.LastLogin.Text = string.format(
				fancy_str,
				"Last Login",
				DateTime.fromUnixTimestampMillis(profile.Data.last_login):FormatLocalTime("", "en-us")
			)
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

initializeRemotes()
initializeCommands()
initializeMarket()
initializeOptions()
initializeMatchmaking()
initializeBadges()
initializeNotifiers()
initializeMusic()
initializeLoadouts()
initializeObjectives()
initializeSkills()
initializeParties()
initializeSpectating()
initializeAudio()

hud:Render()
--motion_blur:On()

camera_controller.new("bobbing", bobbing)

movement_controller:Add(script.Parent.Parent.Movement["sprint-controller"])
movement_controller:Add(script.Parent.Parent.Movement["jump-controller"])
movement_controller:Add(script.Parent.Parent.Movement["stamina-controller"])
movement_controller:Add(script.Parent.Parent.Movement["walk-controller"])
movement_controller:Add(script.Parent.Parent.Movement["joint-controller"])
movement_controller:Start()

local function getAttackTypeFromKey(key: Enum.KeyCode): string?
	profile = fetchProfile()
	if not profile or not profile.Data then
		profile = {
			Data = profilestructure,
		}
	end

	local attack_types = {}
	for i, value in pairs(profile.Data.keybinds) do
		local j = Enum.KeyCode:FromValue(value)

		attack_types[j] = i
	end

	print(attack_types[key])

	return attack_types[key]
end

do
	profile = fetchProfile()
	if not profile or not profile.Data then
		profile = {
			Data = profilestructure,
		}
	end

	for i, value in pairs(profile.Data.keybinds) do
		-- if needed, format the name
		-- e.g "enable_spectating" to "Enable Spectating"
		-- switch the cases and replace underscores with spaces
		local formatted_name = i:gsub("_", " "):gsub("(%a)(%a*)", function(first, rest)
			return first:upper() .. rest:lower()
		end)

		keybindlink.register(value, formatted_name)
	end
end

keyboard.KeyDown:Connect(function(key: Enum.KeyCode, processed: boolean)
	if processed then
		return
	end

	local attack_type = getAttackTypeFromKey(key)
	if attack_type then
		events.ExecuteAttack:InvokeServer(attack_type)

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

	local root = humanoid.RootPart
	if not root then
		return
	end

	--events.FireGroundCrack:FireServer("crack", root.CFrame)

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

glove:Apply(character)

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
		snack_bar:SetExpiry(4)
		snack_bar:SetCanClick(true)
		snack_bar:SetAction(function()
			future.Try(function()
				--user_game_settings.SavedQualityLevel = min_quality_enum
			end)
		end, "Set")
	end)
end

--[[
do
	local crosshair = crosshair_service.new(4)
	crosshair:Enable()
end
--]]

-- over_shoulder:Enable()

player.CharacterAdded:Connect(function(model)
	flight.setup()
end)

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
end)

print("Client has finished")
