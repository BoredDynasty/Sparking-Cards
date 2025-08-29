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
local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient") :: ModuleScript)
local notify = require(StarterPlayer.StarterPlayerScripts.Components.notify)
print(1)
local ItemTags = require(ReplicatedStorage.Market.ItemTags)
local Items = require(ReplicatedStorage.Market.Items)
local Navi = require("../Components/Navi")
local Options = require("../Components/Options")
local animate = require("../Utilities/animate")
local swipe = require(StarterPlayer.StarterPlayerScripts.Interface.swipe)
local yoink = require(StarterPlayer.StarterPlayerScripts.Utilities.yoink)
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
local packer = require(ReplicatedStorage.Modules.packer)
print(1)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
print(2)
local pop = require(script.Parent.Parent.Interface.pop)
local profileMarshaller = require(ReplicatedStorage.Datastore.profileMarshaller)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
print(3)
local promise = require(ReplicatedStorage.Packages.promise)
local shadow = require(script.Parent.Parent.Interface.shadow)
print(4)
local statemachine = require(ReplicatedStorage.Utility.statemachine)
local sway = require(script.Parent.Parent.Interface.sway)
print(5)
local timer = require(ReplicatedStorage.Modules.timer)
print(6)
local keyboard = input.Keyboard.new()
local mouse = input.Mouse.new()

print("Client Requirements")

-- // Variables -- //

local player = playerMarshaller.get()
local profile: typeof(profilestructure) = profileMarshaller.client[player]
local character = characterUtility.get(player)
local _rootPart = character.HumanoidRootPart
local _assets = ReplicatedStorage:WaitForChild("Assets") :: Folder
local remoteEvents = ReplicatedStorage.Events

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
		yoink.getAsync("profile_data"):andThen(function(response)
			if response.success then
				print("Player stats:", response.value)
				profile = response.value
			else
				warn("Error:", response.error)
			end
		end)

		local big_cards = tostring(profile.Data["Big-Cards"])

		TextPlus.Create(moneyFrame, big_cards, {
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
	end

	task.spawn(displaySpendings)

	shadow(shopFrame, Color3.new(), 0, 14)
	shadow(shopNavigation, Color3.new(), 0, 14)
	shadow(spendings, Color3.new(), 0, 14)

	local function populateShop(t: {}?)
		local newRelease = shopFrame:FindFirstChild("NewRelease") :: TextLabel
		task.wait(unloadShop())
		t = Items
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

			coroutine.wrap(function()
				characterIteration:jump(title)
				characterIteration:jump(price)
			end)

			itemTemplate.Visible = true
			coroutine.wrap(function()
				if item.ExperimentsEnabled == true then
					experimentButton.Visible = true
					experimentButton:FindFirstChildOfClass("ImageLabel").Visible = true
					experimentButton.MouseButton1Click:Connect(function()
						print("Testing card: " .. item.Name)
					end)
				else
					experimentButton.Visible = false
				end
			end)

			itemTemplate.Tags.Visible = false
			coroutine.wrap(function()
				if item.Tags then
					itemTemplate.Tags.Visible = true
					for _, tagName in pairs(item.Tags) do
						if ItemTags[tagName] then
							local tag = ItemTags[tagName]

							local image = Instance.new("ImageLabel")
							local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")

							--Properties:

							image.Parent = itemTemplate.Tags
							image.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
							image.BackgroundTransparency = 1.000
							image.BorderColor3 = Color3.fromRGB(0, 0, 0)
							image.BorderSizePixel = 0
							image.Size = UDim2.new(0, 20, 0, 20)
							image.Visible = false
							image.Image = tag.Identification
							--[[
						local thread = task.spawn(Hint, tag.Description, itemTemplate.Tags)
						itemTemplate.Destroying:Once(function()
							-- cleaner
							task.cancel(thread)
						end)
						--]]
							UIAspectRatioConstraint.Parent = image
						end
					end
				end
			end)

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
				--ripple(Color3.new())
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
		profile = yoink.client:grab("profile_data")
		assert(profile, "Profile does not exist on the client!")
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
					else
						return
					end
				end)
			end)
			task.wait()
		end
	end
	local debounce = false
	local function callback()
		if debounce then
			return
		end
		limits.debounce(debounce)
		displayorder:changeVisibility(not shopCanvas.Visible, shopCanvas)
		if shopCanvas.Visible then
			populateShop()
			sway:on(shopCanvas)
		else
			sway:off(shopCanvas)
		end
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
			overrideState = "on",
			toggleFunctions = {
				on = function()
					Lighting.GlobalShadows = true
				end,
				off = function()
					Lighting.GlobalShadows = false
				end,
			},
			overrideIcons = {},
		},
		[2] = {
			name = "Time",
			description = "Adjust the in-game time.",
			overrideState = "on",
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
			overrideIcons = {
				on = "rbxassetid://10734974297",
				off = "rbxassetid://10734897102",
			},
		},
		[3] = {
			name = "Show Other Players",
			description = "Toggle visibility of other players.",
			overrideState = "on",
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
					for _, otherCharacter: Instance in ipairs(characterFolder) do
						local condition = otherCharacter:IsA("Model")
							and playerMarshaller.getByName(otherCharacter.Name)

						if condition and otherCharacter.Name ~= player.Name then
							character.Parent = ReplicatedStorage:WaitForChild("Characters")
						end
					end
				end,
			},
			overrideIcons = {},
		},
		[4] = {
			name = "Clouds",
			description = "Toggle clouds on or off.",
			overrideState = "on",
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
			overrideIcons = {},
		},
	}

	for _, option in pairs(optionsList) do
		local onToggle, optionTemplate = Options.createOption(
			option.name,
			option.description,
			option.overrideState,
			option.toggleFunctions,
			option.overrideIcons
		)
		onToggle:Connect(function(state: boolean)
			if state then
				notify.success(option.name, " is enabled")
			else
				notify.success(option.name, " is disabled")
			end
		end)
	end

	hud:create("Options", function()
		displayorder:changeVisibility(not optionsCanvas.Visible, optionsCanvas)
		if optionsCanvas.Visible then
			sway:on(optionsCanvas)
		else
			sway:off(optionsCanvas)
		end
	end, lucide.GetAsset("cog"))
end
local function initializeMatchmaking()
	print("init matchmaking")
	local matchmakingGui = PlayerGui:WaitForChild("NewMatch") :: ScreenGui
	local matchmakingCanvas = matchmakingGui:WaitForChild("CanvasGroup") :: CanvasGroup
	local matchmakingFrame = matchmakingCanvas:WaitForChild("Frame") :: Frame

	local timeLabel = matchmakingFrame:WaitForChild("Time") :: TextLabel

	local state = statemachine.new({
		searching = {
			name = "searching",
			onEnter = function()
				print("Entering searching state")
			end,
			onExit = function()
				print("Exiting searching state")
			end,
			transitions = {
				notSearching = "notSearching",
			},
		},
		notSearching = {
			name = "notSearching",
			onEnter = function()
				print("Entering notSearching state")
			end,
			onExit = function()
				print("Exiting notSearching state")
			end,
			transitions = {
				searching = "searching",
			},
		},
	}, "notSearching")

	--displayorder:add(matchmakingCanvas)

	shadow(matchmakingFrame, Color3.new(), 0, 14)

	local function remove(clock: timer.Timer, _swipe: swipe.SwipeDetector)
		Packet.CancelMatch.send({ player })
		state:transition("notSearching")
		promise
			.new(function(resolve, reject)
				TweenPlus(matchmakingFrame, {
					Position = UDim2.fromScale(0.5, -0.2),
				}, {
					Time = 0.9,
					EasingDirection = "Out",
					EasingStyle = "Back",
				}):Start()
				clock:Stop()
				clock:Destroy()
				_swipe:Destroy()
				resolve("cleaned up matchmaking")
			end)
			:andThen(print)
			:catch(warn)
	end

	local callback = function()
		if state:getCurrentState() == "notSearching" then
			state:transition("searching")
			-- tween into position
			TweenPlus(matchmakingFrame, {
				Position = UDim2.fromScale(0.5, 0.1),
			}, {
				Time = 0.9,
				EasingDirection = "Out",
				EasingStyle = "Back",
			}):Start()
			-- start a timer
			local clock = timer.new()
			clock:Start()
			promise
				.new(function(resolve, reject)
					if not clock then
						reject("Clock does not exist.")
					end
					clock.onIncrement:Connect(function(currentTime: number)
						local formatted = clock:FormatTime()
						timeLabel.Text = formatted
					end)
					resolve("yay")
				end)
				:andThen(print)
				:catch(warn)
			-- enable swipe functionality
			local _swipe: swipe.SwipeDetector = swipe.new(matchmakingFrame)
			_swipe.OnSwipe:Connect(function(direction: swipe.direction)
				if direction == "up" then
					Packet.CancelMatch.send({ player })
					remove(clock, _swipe)
				end
			end)
		end
	end

	hud:create("Matchmaking", callback, lucide.GetAsset("gamepad-2"))
end
local function initializeBadges()
	print("init badges")
end
initializeMarket()
initializeOptions()
initializeMatchmaking()
hud:render()

print("client almost done")

local movementController = MovementController.new()
movementController:Add("Walk", Walk)
movementController:Add("Jump", Jump)
movementController:Add("Sprint", Sprint)
movementController:Add("Slide", Slide)
movementController:Add("Dash", Dash)
movementController:Add("Stamina", Stamina)
movementController:Start()

print("client movement")
print("game camera")

animate.initialize(character)
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
	local attackType = attackTypes[key]
	--assert(attackType, "Invalid key for attack type: " .. tostring(key))
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
	end
end)

orion.registerPlayer(player)

Packet.ReplicateAnimation.listen(function(data: { identification: string })
	animate.loadAnimation(data.identification, {
		Id = "rbxassetid://" .. data.identification,
		Weight = 1,
	})
	animate.play(`rbxassetid://{data.identification}`, 0.25)
end)

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
end)
