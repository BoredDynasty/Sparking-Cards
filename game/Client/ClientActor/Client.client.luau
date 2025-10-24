--!nonstrict
--!optimize 2

-- Client.client.luau

print(script.Name)
task.wait()

-- // Services -- //
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

-- // Requires -- //

local CameraController = require("../Camera/CameraController")
local CardLibrary = require(ReplicatedStorage.Combat.CardLibrary)
local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient") :: ModuleScript)
local Dash = require(script.Parent.Parent.Movement.Dash)
local DynamicFOV = require("../Camera/DynamicFOV")
local ItemTags = require(ReplicatedStorage.Market.ItemTags)
local Items = require(ReplicatedStorage.Market.Items)
local Joint = require("../Movement/Joint")
local Jump = require(script.Parent.Parent.Movement.Jump)
local Letterbox = require("../Components/Letterbox")
local MovementController = require(script.Parent.Parent.Movement.MovementController)
local Navi = require("../Components/Navi")
local Options = require("../Components/Options")
local Packet = require(ReplicatedStorage.Packet)
local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local Slide = require(script.Parent.Parent.Movement.Slide)
local Sprint = require(script.Parent.Parent.Movement.Sprint)
local Stamina = require(script.Parent.Parent.Movement.Stamina)
local Sway = require("../Camera/Sway")
local TextPlus = require(ReplicatedStorage.Utility.TextPlus)
local Trail = require("../Camera/Trail")
local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local Walk = require(script.Parent.Parent.Movement.Walk)
local animate = require("../Utilities/animate")
local audio = require(ReplicatedStorage.Modules.audio)
local badges = require(ReplicatedStorage.Structures.badges)
local beats = require(ReplicatedStorage.Modules.beats)
local bloxstrap_rpc_sdk = require(ReplicatedStorage.Kits["bloxstrap-rpc-sdk"])
local bounds = require(StarterPlayer.StarterPlayerScripts.Utilities.bounds)
local characterIteration = require(ReplicatedStorage.ClientModules.characterIteration)
local characterUtility = require(ReplicatedStorage.Utility.characterMarshaller)
local custom_lighting = require(ReplicatedStorage.ClientModules["custom-lighting"])
local damage = require(ReplicatedStorage.Combat.Strike.damage)
local dialogue = require(ReplicatedStorage.ClientModules.dialogue)
local displayorder = require(script.Parent.Parent.Interface.displayorder)
local dropper = require(ReplicatedStorage.ClientModules.dropper)
local gamecamera = require(script.Parent.Parent.Modules.gamecamera)
local glare = require(StarterPlayer.StarterPlayerScripts.Interface.glare)
local glove = require(StarterPlayer.StarterPlayerScripts.Gameplay.glove)
local hud = require(script.Parent.Parent.Components.hud)
local hydration = require(ReplicatedStorage.Utility.hydration)
local input = require(ReplicatedStorage.Packages.input)
local keybindlink = require(ReplicatedStorage.ClientModules.keybindlink)
local lucide = require(ReplicatedStorage.Packages.lucide)
local markdown = require(ReplicatedStorage.ClientModules.markdown)
local market = require("../Components/market")
local music = require("../Gameplay/music")
local notify = require("../Components/notify")
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
local ragdoll = require("../Modules/ragdoll")
local rbx_thumb = require(ReplicatedStorage.Modules.Serialization["rbx-thumb"])
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

Cmdr:SetActivationKeys({ Enum.KeyCode.Equals })
Cmdr:SetActivationUnlocksMouse(true)

glove:Apply(character)

print("client starting")

local function initializeMarket()
	print("init marker")
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

	local holder = optionsFrame:WaitForChild("Holder") :: Frame
	--local templatesFolder = templates:FindFirstChild("Options") :: Folder

	shadow(optionsFrame)

	local optionsList = {
		-- add new options here

		[1] = {
			name = "Shadows",
			description = "Toggle shadows on or off.",
			toggleFunctions = {
				on = function()
					Lighting.GlobalShadows = true
				end,
				off = function()
					Lighting.GlobalShadows = false
				end,
			},
			override = "on",
		},
		[2] = {
			name = "Time",
			description = "Adjust the in-game time.",
			toggleFunctions = {
				on = function()
					TweenPlus(
						Lighting,
						{ ClockTime = 12 },
						{ Time = 1, EasingStyle = "Back", EasingDirection = "Out" }
					):Start()
				end,
				off = function()
					TweenPlus(
						Lighting,
						{ ClockTime = 4 },
						{ Time = 1, EasingStyle = "Back", EasingDirection = "Out" }
					):Start()
				end,
			},
			override = "off",
			icons = {
				on = "rbxassetid://10734974297",
				off = "rbxassetid://10734897102",
			},
		},
		[3] = {
			name = "Show Other Players",
			description = "Toggle visibility of other players.",
			toggleFunctions = {
				on = function()
					local characterFolder = ReplicatedStorage:WaitForChild("Characters") :: Folder
					for _, character in ipairs(characterFolder:GetChildren()) do
						if character:IsA("Model") and character:FindFirstChild("HumanoidRootPart") then
							character.Parent = workspace
						end
					end
				end,
				off = function()
					local characterFolder = workspace:GetChildren() :: Folder
					for _, otherCharacter: Instance in ipairs(characterFolder) :: { Model } do
						local condition = otherCharacter:IsA("Model")
							and playerMarshaller.getByName(otherCharacter.Name)

						if condition and otherCharacter.Name ~= player.Name then
							character.Parent = ReplicatedStorage:WaitForChild("Characters")
						end
					end
				end,
			},
			override = "on",
		},
		[4] = {
			name = "Clouds",
			description = "Toggle clouds on or off.",
			toggleFunctions = {
				on = function()
					local clouds = workspace.Terrain:FindFirstChildWhichIsA("Clouds")
					assert(clouds, "Clouds not found")
					clouds.Enabled = true
				end,
				off = function()
					local clouds = workspace.Terrain:FindFirstChildWhichIsA("Clouds")
					assert(clouds, "Clouds not found")
					clouds.Enabled = false
				end,
			},
			override = "on",
		},
		[5] = {
			name = "Music",
			description = "Toggle music on or off",
			toggleFunctions = {
				on = function()
					promise.new(function()
						music:stopCurrentTrack()

						RunService.Heartbeat:Wait()

						music:startTracking()
					end)
				end,
				off = function()
					promise.new(function()
						music:stopCurrentTrack()
					end)
				end,
			},
			override = "on",
		},
	}

	for i, option in pairs(optionsList) do
		Options.new({
			name = option.name,
			description = option.description,
			functions = option.toggleFunctions,
			icons = option.icons or nil,
			state = observer.new(if option.override == "on" then true else false),
		})

		Options:render(optionsFrame.Holder :: ScrollingFrame)
	end

	hud:create("Options", function()
		displayorder:toggle(optionsCanvas)
	end, lucide.GetAsset("cog"))
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
		task.delay(5, spr.target, matchmakingFrame, 0.8, 8, {
			Position = UDim2.fromScale(0.5, 0.1),
		})

		state:Set(true)

		Letterbox:on():andThen("Searching for a match...", "Top")
		custom_lighting.blur()
		task.delay(4, function()
			Letterbox:off()
			custom_lighting.unblur()
		end)

		clock:Start()
		-- every 0.33_ seconds
		clock.interval(clock, 1 / 3, function()
			local totalSeconds = clock:GetTime()

			local minutes = math.floor(totalSeconds / 60)

			local seconds = totalSeconds % 60
			statusText.Text = string.format(
				'Searching...<br/><font transparency="0.5"><font size="14">%02d:%02d</font></font>',
				minutes,
				seconds
			)

			-- Pulse effect
			spr.target(pulseImage, 1, 8, {
				Size = UDim2.fromScale(1.1, 1.1),
				ImageTransparency = 0.2,
			})
			task.delay(1, spr.target, pulseImage, 1, 9, {
				Size = UDim2.fromScale(1, 1),
				ImageTransparency = 0.5,
			})
		end)
	end

	local function hideMatchmakingFrame()
		spr.target(matchmakingFrame, 0.8, 2, {
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
			task.delay(0.5, function()
				matchmakingCanvas.Visible = false
				notify.info("Matchmaking", "You have left the queue.", 5, "info")

				print("Stopped matchmaking")

				Packet.CancelMatch.send({ matchInstance = player }, player)
			end)
		end
	end)

	local swipeDetector = swipe.new(matchmakingFrame)
	swipeDetector.OnSwipe:Connect(function(direction: swipe.direction, delta: Vector3)
		if state:Get() == false then
			return
		end

		if direction == "up" then
			state:Set(false)
			audio:SFX("leave")

			promise
				.new(function(resolve: (boolean) -> ...unknown)
					hideMatchmakingFrame()
					resolve(true)
				end)
				:catch(warn)
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

	profile = expectProfile()

	local function unloadBadges()
		for _, item in itemHolder:GetChildren() do
			if item and item:IsA("Frame") then
				item:Destroy()
				task.wait()
			end
		end

		return #(itemHolder:GetChildren()) * RunService.Heartbeat:Wait()
	end

	local function loadBadges()
		if not profile then
			return
		end

		for i, badge_data in pairs(profile.Data.achievements :: { badges.badge }) do
			-- print("got item: " .. item.Name)
			local itemTemplate = badgeFolder:FindFirstChild("ItemTemplate") :: Frame & {
				Title: Frame,
				Price: Frame,
				Buy: TextButton & {
					TextHolder: Frame,
				},
				Test: TextButton,
				Tags: Frame,
			}
			itemTemplate = itemTemplate:Clone()
			itemTemplate:SetAttribute("name", badge_data.name)
			itemTemplate.Parent = itemHolder

			shadow(itemTemplate, Color3.new(), 0, 14)

			local title = itemTemplate.Title
			local price = itemTemplate.Price

			local purchaseButton = itemTemplate.Buy
			local experimentButton = itemTemplate.Test

			TextPlus.Create(title, badge_data.name, {
				Font = Font.new(
					"rbxasset://fonts/families/Montserrat.json", -- Family.
					Enum.FontWeight.SemiBold, -- Weight.
					Enum.FontStyle.Normal -- Style.
				),
				Size = 16,
				Color = Color3.fromHex("#f5f5f5"),
				XAlignment = "Left",
				YAlignment = "Center",
				LineSorting = true,
				WordSorting = true,
				Dynamic = true,
			})

			local description =
				`{badge_data.description}\n\n Data Achieved: {DateTime.fromUnixTimestampMillis(
					badge_data.date_acquired
				)
					:FormatUniversalTime("LL", "en-us")}`

			-- LL means MM/DD/YYYY

			TextPlus.Create(price, description, {
				Font = Font.new(
					"rbxasset://fonts/families/Montserrat.json", -- Family.
					Enum.FontWeight.Regular, -- Weight.
					Enum.FontStyle.Normal -- Style.
				),
				Size = 12.5,
				Color = Color3.fromHex("#f5f5f5"),
				XAlignment = "Left",
				YAlignment = "Center",
				LineSorting = true,
				WordSorting = true,
				Dynamic = true,
			})

			characterIteration:jump(title)
			characterIteration:jump(price)

			itemTemplate.Visible = true
			purchaseButton.Visible = false
			experimentButton.Visible = false
		end
	end

	if profile and profile ~= nil then
		TextPlus.Create(totalBadges, `Total Achievements: {#profile.Data.achievements}`, {
			Font = Font.new(
				"rbxasset://fonts/families/Montserrat.json", -- Family.
				Enum.FontWeight.SemiBold, -- Weight.
				Enum.FontStyle.Normal -- Style.
			),
			Size = 16,
			Color = Color3.fromHex("#f5f5f5"),
			XAlignment = "Left",
			YAlignment = "Center",
			LineSorting = true,
			WordSorting = true,
			Dynamic = true,
		})
	end

	local function callback()
		displayorder:toggle(badgesCanvas)
		unloadBadges()
		loadBadges()
	end

	hud:create("Badges", callback, lucide.GetAsset("trophy", 48))
end
local function initializeNotifiers()
	print("init notifiers")

	Packet.SendNotification.listen(function(data)
		notify[data.type or "info"](
			data.title or "Notification",
			data.message or "",
			data.duration or 5,
			data.type
		)
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

	for i, track in pairs(tracks) do
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
	sway:on(disc);

	(mouse.LeftDown :: RBXScriptSignal):Connect(function()
		local position = mouse:GetPosition()

		if bounds.inner(disc.AbsolutePosition, disc.AbsoluteSize, position) then
			ripple(disc)
			pop(disc)
		end
	end)

	glare:Watch(disc, {
		once = false,
		corner_radius = UDim.new(1, 0),
	})

	-- rotate effect on disc
	TweenPlus(disc, { Rotation = 360 }, { Time = 7, RepeatCount = -1, EasingStyle = "Linear" }):Start()

	-- pulse effect using BPM
	local analyzer = Instance.new("AudioAnalyzer")
	local detector = beats.new({
		analyzer = analyzer,
		minimum_gap = 0.3,
		window_size = 10,
		threshold_multiplier = 1.2,
	})
	analyzer.Parent = musicGui
	detector:Start()
	detector.Beat:Connect(function()
		spr.stop(disc, "Size")
		spr.target(disc, 0.3, 8, {
			Size = UDim2.fromScale(1.1, 1.1),
		})
		task.delay(0.3, spr.target, disc, 0.3, 9, {
			Size = UDim2.fromScale(1, 1),
		})
		-- Add any additional effects or animations here
	end)
end
local function initializeKeybinds()
	print("init keybinds")

	local keybinds = {
		M1 = {
			name = "M1",
			key = Enum.KeyCode.MouseLeftButton,
		},
		E = {
			name = "E",
			key = Enum.KeyCode.E,
		},
		R = {
			name = "R",
			key = Enum.KeyCode.R,
		},
		Q = {
			name = "Q",
			key = Enum.KeyCode.Q,
		},
		F = {
			name = "F",
			key = Enum.KeyCode.F,
		},
	}

	local active_list: { [string]: keybindlink.metatable } = table.create(#keybinds)

	for i: string, v: { name: string, key: Enum.KeyCode } in pairs(keybinds :: typeof(keybinds)) do
		local link = keybindlink.new(v.key, keyboard)

		shadow(link._interface, Color3.new(), 0, 14)

		link:setText(link, v.name)
		link:autoSetImage(link)

		active_list[v.name] = link
	end
end
local function initializeLoadouts()
	print("init loadouts")
	local loadoutsGui = PlayerGui:FindFirstChild("Loadout") :: ScreenGui
	local loadoutCanvas = loadoutsGui:FindFirstChild("CanvasGroup") :: CanvasGroup
	local loadoutFrame = loadoutCanvas:FindFirstChild("Background") :: Frame

	local navigation = loadoutFrame:FindFirstChild("Navigation") :: Frame

	local detailsHolder = loadoutFrame:FindFirstChild("Details") :: Frame
	local shopShortcut = detailsHolder.ShopShortcut :: Frame & {
		Button: TextButton, -- press to open shop
		ImageLabel: ImageLabel,
	}
	local holder = detailsHolder.Holder :: Frame
	local card_image = detailsHolder.CardImage :: ImageLabel
	local moveset_display = detailsHolder.MovesetName :: TextLabel

	local playerPicture = loadoutFrame.ProfilePicture :: Frame
	local playerPictureInner = playerPicture.Inner :: Frame
	local profilePicture = playerPictureInner.Image :: ImageLabel

	local loadoutFolder = templates.Loadout :: Folder

	shadow(navigation)
	shadow(detailsHolder)
	shadow(profilePicture)

	ripple(loadoutCanvas)
	ripple:Watch(profilePicture)

	local _parallax = parallax.new(Vector2.one * 10)
	local layers = parallaxLayers.Desert -- placeholder

	for i, data in ipairs(layers) do
		_parallax:AddLayer(nil, data.depthFactor, "rbxassetid://" .. data.image)
	end

	_parallax:Setup(loadoutCanvas)
	--_parallax:Enable()
	local function updatePfp()
		return promise.new(function(resolve: () -> ...unknown, reject: (string) -> ...unknown)
			task.spawn(function()
				local userId = player.UserId

				local image = rbx_thumb.avatar_headshot(userId, "420x420")

				if image then
					profilePicture.ImageContent = image

					pop(playerPicture, 1.2)

					resolve(image)
				else
					reject("Failed to get user thumbnail: " .. tostring(image))

					notify.error("User thumbnail", "Failed to fetch user thumbnail.", 5, "error")
				end
			end)
		end)
	end

	-- alright so this entire system uses TextLabel
	-- in favor of TextPlus
	-- because i do NOT want to use textplus.
	-- for obvious reasons :blush:

	profile = expectProfile() -- we def need this.

	local equippedCard = promise
		.new(function(resolve: (string?) -> ...unknown)
			local value = nil

			if profile ~= nil then
				value = profile.Data.EquippedCard
			else
				value = nil
			end

			resolve(value)

			return value
		end)
		:expect() :: string?

	type card_display = Frame & {
		TextLabel: TextLabel,
		ImageLabel: ImageLabel?,
	}

	local function creatCard(ancestor: Instance?, icon: string?): card_display
		-- dont worry abt the variable names
		local base = nil
		if icon then
			local WeaponType = Instance.new("Frame")
			local ImageLabel = Instance.new("ImageLabel")
			local AspectRatio = Instance.new("UIAspectRatioConstraint")
			local UICorner = Instance.new("UICorner")
			local TextLabel = Instance.new("TextLabel")
			local AspectRatio_2 = Instance.new("UIAspectRatioConstraint")
			local AspectRatio_3 = Instance.new("UIAspectRatioConstraint")

			--Properties:

			WeaponType.Name = ""
			WeaponType.Parent = ancestor or ReplicatedStorage
			WeaponType.AnchorPoint = Vector2.new(0.5, 0.5)
			WeaponType.BackgroundColor3 = Color3.fromRGB(35, 25, 23)
			WeaponType.BorderColor3 = Color3.fromRGB(0, 0, 0)
			WeaponType.BorderSizePixel = 0
			WeaponType.Position = UDim2.new(0.757278681, 0, 0.0858655497, 0)
			WeaponType.Size = UDim2.new(0.476953149, 0, 0.171731099, 0)

			ImageLabel.Parent = WeaponType
			ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
			ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			ImageLabel.BackgroundTransparency = 1.000
			ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
			ImageLabel.BorderSizePixel = 0
			ImageLabel.Position = UDim2.new(0.293805778, 0, 0.484785527, 0)
			ImageLabel.Size = UDim2.new(0.103226088, 0, 0.269325286, 0)
			ImageLabel.Image = "rbxassetid://10734975486"

			AspectRatio.Name = "AspectRatio"
			AspectRatio.Parent = ImageLabel

			UICorner.CornerRadius = UDim.new(0.139130428, 0)
			UICorner.Parent = WeaponType

			TextLabel.Parent = WeaponType
			TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
			TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			TextLabel.BackgroundTransparency = 1.000
			TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
			TextLabel.BorderSizePixel = 0
			TextLabel.Position = UDim2.new(0.547556996, 0, 0.4953219, 0)
			TextLabel.Size = UDim2.new(0.40460676, 0, 0.355981946, 0)
			TextLabel.Font = Enum.Font.Gotham
			TextLabel.Text = "Sword"
			TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			TextLabel.TextSize = 12.000
			TextLabel.TextWrapped = true

			AspectRatio_2.Name = "AspectRatio"
			AspectRatio_2.Parent = TextLabel
			AspectRatio_2.AspectRatio = 2.965

			AspectRatio_3.Name = "AspectRatio"
			AspectRatio_3.Parent = WeaponType
			AspectRatio_3.AspectRatio = 2.609

			base = WeaponType
		else
			local FlavorText = Instance.new("Frame")
			local UICorner = Instance.new("UICorner")
			local TextLabel = Instance.new("TextLabel")
			local AspectRatio = Instance.new("UIAspectRatioConstraint")
			local AspectRatio_2 = Instance.new("UIAspectRatioConstraint")

			--Properties:

			FlavorText.Name = ""
			FlavorText.Parent = ancestor or ReplicatedStorage
			FlavorText.AnchorPoint = Vector2.new(0.5, 0.5)
			FlavorText.BackgroundColor3 = Color3.fromRGB(35, 25, 23)
			FlavorText.BorderColor3 = Color3.fromRGB(0, 0, 0)
			FlavorText.BorderSizePixel = 0
			FlavorText.Position = UDim2.new(0.238476574, 0, 0.0858655497, 0)
			FlavorText.Size = UDim2.new(0.476953149, 0, 0.171731099, 0)

			UICorner.CornerRadius = UDim.new(0.139130428, 0)
			UICorner.Parent = FlavorText

			TextLabel.Parent = FlavorText
			TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
			TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			TextLabel.BackgroundTransparency = 1.000
			TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
			TextLabel.BorderSizePixel = 0
			TextLabel.Position = UDim2.new(0.50702697, 0, 0.497070491, 0)
			TextLabel.Size = UDim2.new(0.98594588, 0, 1.00585902, 0)
			TextLabel.Font = Enum.Font.Unknown
			TextLabel.Text = ""
			TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			TextLabel.TextSize = 12.000
			TextLabel.TextWrapped = true

			AspectRatio.Name = "AspectRatio"
			AspectRatio.Parent = TextLabel
			AspectRatio.AspectRatio = 2.557

			AspectRatio_2.Name = "AspectRatio"
			AspectRatio_2.Parent = FlavorText
			AspectRatio_2.AspectRatio = 2.609

			base = FlavorText
		end

		return base
	end

	local function updateDetails()
		if not equippedCard then
			return promise.reject("No card equipped")
		end

		return promise
			.new(function(resolve: () -> ...unknown, reject: (string) -> ...unknown)
				local foundLib = CardLibrary[equippedCard]
				if foundLib then
					resolve(foundLib)
				else
					reject(`Card "{equippedCard}" not found in CardLibrary.`)

					notify.error("Data", "Couldn't get your Equipped_Card.", 5, "error")
				end
			end)
			:andThen(function(lib)
				-- Clear existing cards
				for _, child in ipairs(holder:GetChildren()) do
					if child:IsA("Frame") then
						child:Destroy()
					end
				end

				-- attack, flavortext, M1, passive, skill, support, ultimate, weapontype(icon)
				local markdown_controller = {
					attack_controller = markdown.new(lib.MovesetName),
					flavor_controller = markdown.new(lib.FlavorText),
					m1_controller = markdown.new(lib.Moveset.M1),
					passive_controller = markdown.new(lib.PassiveModuleName),
					skill_controller = markdown.new(lib.Moveset.Skill),
					support_controller = markdown.new(lib.Moveset.Support),
					ultimate_controller = markdown.new(lib.Moveset.Ultimate),
					weapon_controller = markdown.new(lib.WeaponType),
				}

				local cardCreationPromise = promise.new(
					function(resolve: ({ { label: TextLabel, text: string } }) -> ...unknown)
						local cardsToCreate = {
							{ Title = "Attack", Text = lib.MovesetName },
							{
								Title = "Flavor Text",
								Text = lib.FlavorText,
								HighlightedTags = lib.HighlightedFlavorTextTags,
							},
							{ Title = "Passive", Text = lib.PassiveModuleName },
							{ Title = "Skill", Text = lib.Moveset.Skill },
							{ Title = "Support", Text = lib.Moveset.Support },
							{ Title = "Ultimate", Text = lib.Moveset.Ultimate },
							{ Title = "Weapon", Text = lib.WeaponType, Icon = "rbxassetid://10734975486" }, -- Placeholder Icon
						}

						local textLabels = {}

						for _, cardData in ipairs(cardsToCreate) do
							if cardData.Text then
								-- Handle highlighted text
								if cardData.HighlightedTags and type(cardData.Text) == "string" then
									for _, tag in ipairs(cardData.HighlightedTags) do
										cardData.Text = string.gsub(cardData.Text, tag, `<b>{tag}</b>`)
									end
								end
								local card = creatCard(detailsHolder)
								local textLabel = card.TextLabel

								-- create the card
								table.insert(textLabels, { label = textLabel, text = cardData.Text })
							end
						end

						resolve(textLabels)
					end
				)

				return cardCreationPromise:andThen(function(textLabels: {})
					-- This promise will be the start of our animation chain.
					local animationChain = promise.resolve()

					for _, data in ipairs(textLabels) do
						-- Chain the next typewriter animation onto the end of the chain.
						animationChain = animationChain:andThen(function()
							-- This function will not execute until the previous promise in the chain resolves.
							-- It returns a new promise that resolves when the typewriter effect is complete.
							return promise.new(function(resolve: () -> ...unknown)
								task.spawn(function()
									-- Each animation gets its own controller to avoid state conflicts.
									local typewriteController = markdown.typewriter.new()
									typewriteController:Play(data.label, data.text, {
										cps = 45,
										instantFinishKey = Enum.KeyCode.Space,
										cursor = "|",
										cursorTween = true,
										perCharSound = audio:_getSoundById(9055474333),
										respectNewlines = false,
										punctuationPauses = {
											[","] = 0.06,
											["."] = 0.25,
											["?"] = 0.18,
											["!"] = 0.18,
										},
									})
									-- Resolve the promise once the animation is done.
									resolve()

									task.defer(typewriteController.Destroy, typewriteController)
								end)
							end)
						end)
					end

					return animationChain
				end)
			end)
	end

	updatePfp():catch(warn)
	updateDetails():catch(warn)

	UserInputService.WindowFocusReleased:Connect(function()
		local signal = SignalPlus()

		profilePicture.ImageContent = Content.none

		throbber(profilePicture, signal)

		updatePfp()
			:andThen(function()
				signal:Fire()
			end)
			:catch(warn)
	end)

	shopShortcut.Button.MouseButton1Click:Connect(function()
		hud:toggle("Market")
	end)
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

	rank:Set(profile.Data.Level or "Bronze I")

	local availiable_objectives = quest_ranking:getObjectivesFromRank(rank:Get())
	for i, objective_name in ipairs(availiable_objectives) do
		quest.new(player, objective_name)
	end

	local quest_list = quest:Get(player):expect()

	for i, data in pairs(quest_list :: { quest.quest }) do
		objective.new(data)
	end

	quest:Track(player)
end
initializeMarket()
initializeOptions()
initializeMatchmaking()
initializeBadges()
initializeNotifiers()
initializeMusic()
initializeKeybinds()
initializeLoadouts()
hud:render()
displayorder:Watch()

print("client almost done")

local movementController = MovementController.new()
movementController:Add("Walk", Walk)
movementController:Add("Jump", Jump)
movementController:Add("Sprint", Sprint)
movementController:Add("Slide", Slide)
movementController:Add("Dash", Dash)
movementController:Add("Stamina", Stamina)
movementController:Add("Joint", Joint)
movementController:Start()

print("client movement")
print("game camera")

animate.initialize()
print("animate initialized")

-- local rain_controller = rain.new()
-- rain_controller:Start(rain_controller)

print("rain controller")

-- control

local function getAttackTypeFromKey(key: Enum.KeyCode)
	-- profile = yoink.client:grab("profile_data")
	profile = expectProfile()

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

_trove:Add(damage.incoming:Connect(function(a0: damage.Damage)
	dialogue:speak("You", "yoooowch!")
end))

profile = expectProfile()
orion.registerPlayer(player, profile)

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

local characterFolder = ReplicatedStorage:FindFirstChild("Characters") or Instance.new("Folder")
characterFolder.Name = "Characters"
characterFolder.Parent = ReplicatedStorage

Packet.CleanupCharacter.listen(function()
	animate.cleanup()
	movementController:Destroy()
	music.cleanup()
	Options:destroy()
	hud:clear()
	dropper._trove:Clean()
	dialogue._trove:Clean()
end)

local interfaceEndTime = os.clock()
local totalExecutionTime = math.round((interfaceEndTime - interfaceStartTime) * 10000) / 10000
-- This results in four decimal places.

print("Client has finished with an execution time of: ", totalExecutionTime)
