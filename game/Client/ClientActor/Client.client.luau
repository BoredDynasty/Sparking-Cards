--!nonstrict

-- Client.client.luau

print(script.Name)
task.wait()

-- // Services -- //
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

-- // Requires -- //

require("../Gameplay/CardAwarder")()
local CameraController = require("../Camera/CameraController")
local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient") :: ModuleScript)
local DynamicFOV = require(StarterPlayer.StarterPlayerScripts.Camera.DynamicFOV)
local Sway = require(StarterPlayer.StarterPlayerScripts.Camera.Sway)
local Trail = require(StarterPlayer.StarterPlayerScripts.Camera.Trail)
local footsteps = require("../Gameplay/footsteps")
local music = require("../Gameplay/music")
local notify = require("../Components/notify")
local screen = require(StarterPlayer.StarterPlayerScripts.Gameplay.hint.screen)
local sparkle = require(StarterPlayer.StarterPlayerScripts.Interface.sparkle)
print(1)
local ItemTags = require(ReplicatedStorage.Market.ItemTags)
local Items = require(ReplicatedStorage.Market.Items)
local Joint = require("../Movement/Joint")
local Navi = require("../Components/Navi")
local Options = require("../Components/Options")
local animate = require("../Utilities/animate")
local ragdoll = require("../Modules/ragdoll")
local swipe = require("../Interface/swipe")
-- local typography = require(ReplicatedStorage.Packages.typography)
print(1)

-- Movement System

local Dash = require(script.Parent.Parent.Movement.Dash)
local Jump = require(script.Parent.Parent.Movement.Jump)
local MovementController = require(script.Parent.Parent.Movement.MovementController)
local Slide = require(script.Parent.Parent.Movement.Slide)
local Sprint = require(script.Parent.Parent.Movement.Sprint)
local Stamina = require(script.Parent.Parent.Movement.Stamina)
local Walk = require(script.Parent.Parent.Movement.Walk)
print(1)

local Packet = require(ReplicatedStorage.Packet)
local TextPlus = require(ReplicatedStorage.Utility.TextPlus)
local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local audio = require(ReplicatedStorage.Modules.audio)
print(1)
local characterIteration = require(ReplicatedStorage.ClientModules.characterIteration)
local characterUtility = require(ReplicatedStorage.Utility.characterMarshaller)
local dialog = require(script.Parent.Parent.Components.Dialog)
local displayorder = require(script.Parent.Parent.Interface.displayorder)
local gamecamera = require(script.Parent.Parent.Modules.gamecamera)
print(1)
require(script.Parent.Parent.Modules.gamecamera)
local hud = require(script.Parent.Parent.Components.hud)
local input = require(ReplicatedStorage.Packages.input)
local limits = require(script.Parent.Parent.Utilities.limits)
local lucide = require(ReplicatedStorage.Packages.lucide)
print(1)
local orion = require(ReplicatedStorage.Combat.orion) -- Orion Combat Framework
local safeteleport = require(ReplicatedStorage.Modules.safeteleport)
local spr = require(ReplicatedStorage.Modules.spr)
local tag = require(ReplicatedStorage.Modules.Wrappers.tag)
print(1)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
print(2)
local pop = require(script.Parent.Parent.Interface.pop)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
print(3)
local promise = require(ReplicatedStorage.Packages.promise)
local shadow = require(script.Parent.Parent.Interface.shadow)
print(4)
local statemachine = require(ReplicatedStorage.Utility.statemachine)
local sway = require(script.Parent.Parent.Interface.sway)
print(5)
local badges = require(ReplicatedStorage.Structures.badges)
local observer = require(ReplicatedStorage.Utility.observer)
local timer = require(ReplicatedStorage.Modules.timer)
print(6)
local keyboard = input.Keyboard.new()
local mouse = input.Mouse.new()

print("Client Requirements")

-- // Variables -- //

local player = playerMarshaller.get()
local profile: {
	Data: profilestructure.profile,
} = promise
	.new(function(resolve)
		local value = (ReplicatedStorage.Events.GetProfile :: RemoteFunction):InvokeServer()

		resolve(value)

		return value
	end)
	:expect()

-- // Events -- //
local getProfileRF = ReplicatedStorage.Events.GetProfile :: RemoteFunction

local character = characterUtility.get(player)
local _rootPart = character.HumanoidRootPart
local _assets = ReplicatedStorage:WaitForChild("Assets") :: Folder
local remoteEvents = ReplicatedStorage.Events

-- // Functions -- //
local function expectProfile()
	return promise
		.new(function(resolve)
			local value = (ReplicatedStorage.Events.GetProfile :: RemoteFunction):InvokeServer()

			resolve(value)

			return value
		end)
		:expect()
end

---------------------------------- Client --------------------------------

local interfaceStartTime = os.clock()

local PlayerGui = player.PlayerGui
local templates = ReplicatedStorage:WaitForChild("Interfaces", 5) :: Folder

Cmdr:SetActivationKeys({ Enum.KeyCode.Equals })
Cmdr:SetActivationUnlocksMouse(true)

print("client starting")

local function initializeMarket()
	print("init marker")
	local shopGui = PlayerGui:WaitForChild("Shop") :: ScreenGui
	local shopCanvas = shopGui:WaitForChild("CanvasGroup") :: CanvasGroup
	local shopFrame = shopCanvas:WaitForChild("Frame") :: Frame

	displayorder:add(shopCanvas)

	local shopNavigation = shopFrame:WaitForChild("Navigation") :: Frame
	local itemHolder = shopFrame:WaitForChild("Holder") :: Frame
	local shopFolder = templates:FindFirstChild("Shop") :: Folder
	local spendings = shopFrame:FindFirstChild("Spendings") :: Frame

	print("got market gui")

	local navigationBtnSignals = nil

	local function populateNavigation()
		Navi.new(shopNavigation, {
			name = "Home",
			icon = "rbxassetid://10723407389",
		})
		Navi.new(shopNavigation, {
			name = "Inventory",
			icon = "rbxassetid://10709769841",
		})
		Navi.new(shopNavigation, {
			name = "Passives",
			icon = "rbxassetid://10734951847",
		})
		navigationBtnSignals = Navi:render()
	end

	local function unloadShop()
		for _, item in itemHolder:GetChildren() do
			if item and item:IsA("Frame") then
				item:Destroy()
				task.wait()
			end
		end

		return #(itemHolder:GetChildren()) * RunService.Heartbeat:Wait()
	end

	local function displaySpendings()
		local moneyFrame = spendings:FindFirstChild("Money") :: Frame

		profile = expectProfile()

		promise.new(function()
			local text = ""
			if profile then
				text = tostring(profile.Data.Prisms)
			else
				text = "..."
			end

			TextPlus.Create(moneyFrame, text, {
				Font = Font.new(
					"rbxasset://fonts/families/Montserrat.json", -- Family.
					Enum.FontWeight.SemiBold, -- Weight.
					Enum.FontStyle.Normal -- Style.
				),
				Size = 16,
				Color = Color3.fromHex("#ffffff"),
				XAlignment = "Left",
				YAlignment = "Center",
				LineSorting = true,
				WordSorting = true,
				Dynamic = true,
			})
		end)
	end

	task.spawn(displaySpendings)

	shadow(shopFrame, Color3.new(), 0, 14)
	shadow(shopNavigation, Color3.new(), 0, 14)
	shadow(spendings, Color3.new(), 0, 14)

	local function populateShop(t: Items.dataType?)
		local newRelease = shopFrame:FindFirstChild("NewRelease") :: TextLabel
		task.wait(unloadShop())
		t = t or Items
		for _, item in pairs(t) do
			-- print("got item: " .. item.Name)
			local itemTemplate = shopFolder:FindFirstChild("ItemTemplate") :: Frame & {
				Title: Frame,
				Price: Frame,
				Buy: TextButton & {
					TextHolder: Frame,
				},
				Test: TextButton,
				Tags: Frame,
			}
			itemTemplate = itemTemplate:Clone()
			itemTemplate:SetAttribute("name", item.Name)
			itemTemplate.Parent = itemHolder

			shadow(itemTemplate, Color3.new(), 0, 14)

			local title = itemTemplate.Title
			local price = itemTemplate.Price

			local purchaseButton = itemTemplate.Buy
			local experimentButton = itemTemplate.Test

			TextPlus.Create(title, item.Name, {
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
			TextPlus.Create(price, "$" .. tostring(item.Price), {
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

			sparkle:on(itemTemplate, {
				rotation = true,
			})

			itemTemplate.Destroying:Once(function()
				sparkle:off(itemTemplate)
			end)

			if item.ExperimentsEnabled == true then
				experimentButton.Visible = true
				experimentButton:FindFirstChildOfClass("ImageLabel").Visible = true
				experimentButton.MouseButton1Click:Connect(function()
					print("Testing card: " .. item.Name)
					-- ts dont work yet lmao
					-- but lets add a function
					if not player then
						return
					end

					local placeId = 90845913624517 -- Match

					safeteleport(placeId, { player }, {
						reserve_server = true,
						data = {
							identification1 = player.UserId,
							testing_card = {
								item,
							},
						},
					})
				end)
			else
				experimentButton.Visible = false
			end

			itemTemplate.Tags.Visible = false

			print("setting up buttons")
			local purchaseDebounce = false -- exception too
			TextPlus.Create(purchaseButton:FindFirstChild("TextHolder") :: Frame, "Purchase", {
				Font = Font.new(
					"rbxasset://fonts/families/Montserrat.json", -- Family.
					Enum.FontWeight.Bold, -- Weight.
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
			purchaseButton.MouseEnter:Connect(function()
				audio:SFX("hover")
			end)
			purchaseButton.MouseLeave:Connect(function()
				audio:SFX("leave")
			end)
			purchaseButton.MouseButton1Click:Connect(function()
				if purchaseDebounce == true then
					return
				end
				print("Purchasing card: " .. item.Name)

				Packet.BuyCard.send({ cardName = item.Name })

				pop(purchaseButton)

				audio:SFX("success")

				purchaseDebounce = true

				task.delay(0.5, function()
					purchaseDebounce = false
				end)
			end)
			print("done")
			--task.wait()
		end
		return #(itemHolder:GetChildren()) * RunService.Heartbeat:Wait()
	end
	local function populateInventory()
		local unloaded = unloadShop()
		task.wait(unloaded)

		profile = expectProfile()
		if not profile then
			return
		end

		for itemName: string, i in pairs(profile.Data.Cards) do
			-- print("got item: " .. itemName)
			local itemTemplate = shopFolder:FindFirstChild("ItemTemplate") :: Frame & {
				Title: Frame,
				Price: Frame,
				Buy: TextButton & {
					TextHolder: Frame,
				},
				Test: TextButton,
				Tags: Frame,
			}
			itemTemplate = itemTemplate:Clone()
			itemTemplate.Parent = itemHolder

			local title = itemTemplate.Title
			local quantity = itemTemplate.Price

			local sellButton = itemTemplate.Buy -- lol
			local experimentButton = itemTemplate.Test

			TextPlus.Create(title, itemName, {
				Font = Font.new(
					"rbxasset://fonts/families/Montserrat.json", -- Family.
					Enum.FontWeight.SemiBold, -- Weight.
					Enum.FontStyle.Normal -- Style.
				),
				Size = 20,
				Color = Color3.fromHex("#ffffff"),
				XAlignment = "Left",
				YAlignment = "Center",
				LineSorting = true,
				WordSorting = true,
				Dynamic = true,
			})
			--title.Text = itemName
			TextPlus.Create(quantity, "( <b>" .. tostring(i) .. "</b> )", {
				Font = Font.new(
					"rbxasset://fonts/families/Montserrat.json", -- Family.
					Enum.FontWeight.Regular, -- Weight.
					Enum.FontStyle.Normal -- Style.
				),
				Size = 12.5,
				Color = Color3.fromHex("#39302e"),
				XAlignment = "Left",
				YAlignment = "Center",
				LineSorting = true,
				WordSorting = true,
				Dynamic = true,
			})

			characterIteration:jump(title)
			characterIteration:jump(quantity)

			itemTemplate.Visible = true

			experimentButton.Visible = false
			sellButton.Visible = true
			sellButton.Text = "Sell"
			sellButton.MouseButton1Click:Connect(function()
				local dialog_title = "Slow down there!"
				local description = [[
				Are you sure you want to sell this Card? 
				]] .. itemName
				-- local folder_minus_icon = "rbxassetid://10723386127"
				local result = dialog(dialog_title, description)
				result:Once(function(a0: boolean)
					if a0 == true then
						Packet.SellCard.send({ cardName = itemName, playerInstance = player })
						notify.success("Sold Card", `Successfully sold card`)
					else
						return
					end
				end)
			end)
			task.wait()
		end
	end
	local function callback()
		displayorder:toggle(shopCanvas)
	end

	hud:create("Market", callback, lucide.GetAsset("shopping-cart"))

	populateNavigation()

	navigationBtnSignals.Home:Connect(function()
		print("Home button clicked")
		populateShop()
	end)

	navigationBtnSignals.Inventory:Connect(function()
		print("Inventory button clicked")
		populateInventory()
	end)
end
local function initializeOptions()
	print("init options")
	local optionsGui = PlayerGui:WaitForChild("Options") :: ScreenGui
	local optionsCanvas = optionsGui:WaitForChild("CanvasGroup") :: CanvasGroup
	local optionsFrame = optionsCanvas:WaitForChild("Frame") :: Frame

	displayorder:add(optionsCanvas)

	local holder = optionsFrame:WaitForChild("Holder") :: Frame
	--local templatesFolder = templates:FindFirstChild("Options") :: Folder

	shadow(optionsFrame, Color3.new(), 0, 14)

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
			icons = {},
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
			icons = {},
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
			icons = {},
		},
		[5] = {
			name = "Camera Sway",
			description = "Toggle camera sway on or off.",
			toggleFunctions = {
				on = function()
					promise.new(function()
						CameraController:Add("Sway", Sway)
					end)
				end,
				off = function()
					promise.new(function()
						CameraController:Get("Sway"):Destroy()
					end)
				end,
			},
		},
		[6] = {
			name = "Camera Trail",
			description = "Toggle camera trail on or off.",
			toggleFunctions = {
				on = function()
					promise.new(function()
						CameraController:Add("Trail", Trail)
					end)
				end,
				off = function()
					promise.new(function()
						CameraController:Get("Trail"):Destroy()
					end)
				end,
			},
		},
		[7] = {
			name = "Dynamic FOV",
			description = "Toggle dynamic FOV on or off.",
			toggleFunctions = {
				on = function()
					promise.new(function()
						CameraController:Add("DynamicFOV", DynamicFOV)
					end)
				end,
				off = function()
					promise.new(function()
						CameraController:Get("DynamicFOV"):Destroy()
					end)
				end,
			},
		},
		[8] = {
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
		},
	}

	for _, option in pairs(optionsList) do
		local onToggle, optionTemplate =
			Options.create(option.name, option.description, option.toggleFunctions, option.icons)

		onToggle.reactor:Watch(function(newValue)
			notify.success("Options", `{option.name} is {newValue} now.`)
		end)
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

	displayorder:add(matchmakingCanvas)

	shadow(matchmakingFrame, Color3.new(), 0, 14)

	local state = observer.new(false)
	local clock = timer.new()

	local function showMatchmakingFrame()
		spr.target(matchmakingFrame, 0.8, 8, {
			Position = UDim2.fromScale(0.5, 0.1),
		})

		state:Set(true)

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
			spr.target(pulseImage, 0.5, 8, {
				Size = UDim2.fromScale(1.1, 1.1),
				ImageTransparency = 0.2,
			})
			task.delay(0.5, function()
				spr.target(pulseImage, 0.5, 8, {
					Size = UDim2.fromScale(1, 1),
					ImageTransparency = 0.5,
				})
			end)
		end)
	end

	local function hideMatchmakingFrame()
		spr.target(matchmakingFrame, 0.8, 8, {
			Position = UDim2.fromScale(0.5, -0.5),
		})

		state:Set(false)

		clock:Stop()
		clock:Reset()
	end

	state:Watch(function(newValue)
		if newValue == true then
			matchmakingCanvas.Visible = true

			print("Starting matchmaking")

			Packet.CreateMatch.send({}, player)
		else
			task.delay(0.5, function()
				matchmakingCanvas.Visible = false
				notify.info("Matchmaking", "You have left the queue.")

				print("Stopped matchmaking")

				Packet.CancelMatch.send({ matchInstance = player }, player)
			end)
		end
	end)

	local swipeDetector = swipe.new(matchmakingFrame)
	swipeDetector.OnSwipe:Connect(function(direction: string, delta: Vector3)
		if state:Get() == false then
			return
		end

		if direction == "up" then
			state:Set(false)
			audio:SFX("leave")

			promise
				.new(function(resolve)
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

	displayorder:add(badgesCanvas)

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

	hud:create("Badges", callback, "trophy")
end
local function initializeNotifiers()
	print("init notifiers")

	Packet.SendNotification.listen(function(data: { message: string, title: string? }, player: Player?)
		notify.info(data.title, data.message)
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
end
initializeMarket()
initializeOptions()
initializeMatchmaking()
initializeBadges()
initializeNotifiers()
initializeMusic()
hud:render()

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
-- control

local function getAttackTypeFromKey(key: Enum.KeyCode)
	-- profile = yoink.client:grab("profile_data")
	local attackTypes = {
		[Enum.KeyCode.MouseLeftButton] = "M1",
		[Enum.KeyCode.E] = "Skill",
		[Enum.KeyCode.Q] = "Ultimate",
		[Enum.KeyCode.R] = "Support",
	}

	local attackType: string = promise
		.new(function()
			return attackTypes[key]
		end)
		:expect()

	return attackType
end

keyboard.KeyDown:Connect(function(key: Enum.KeyCode)
	local attack_type = getAttackTypeFromKey(key)
	if attack_type then
		orion:execute(player, attack_type)
	end
end)

mouse.LeftDown:Connect(function()
	local attack_type = "M1"
	if attack_type then
		orion:execute(player, attack_type)
		--ragdoll.SetRagdoll(character, true, true, Vector3.new(5, 6, -1))
	end
end)

profile = expectProfile()
orion.registerPlayer(player, profile)

Packet.ReplicateAnimation.listen(function(data: { identification: string })
	animate.loadAnimation(data.identification, {
		Id = "rbxassetid://" .. data.identification,
		Weight = 1,
	})
	animate.play(`rbxassetid://{data.identification}`, 0.25)
end)

tag.for_eachi("Tooltip", function(part: BasePart)
	screen:bind(part, "test tooltip")
end)

gamecamera:Bind("Tooltip_upd", screen.update)

local interfaceEndTime = os.clock()
local totalExecutionTime = math.round((interfaceEndTime - interfaceStartTime) * 10000) / 10000
-- This results in four decimal places.

print("UI has finished with an execution time of: ", totalExecutionTime)

local defaultFootstep = _rootPart:FindFirstChild("Running")
if defaultFootstep then
	defaultFootstep:Destroy()
end

local characterFolder = Instance.new("Folder")
characterFolder.Name = "Characters"
characterFolder.Parent = ReplicatedStorage

Packet.CleanupCharacter.listen(function()
	-- Handle character cleanup logic here
	animate.cleanup()
	--audio:Cleanup()
	movementController:Destroy()
	footsteps._trove:Clean()
	music.cleanup()
end)
