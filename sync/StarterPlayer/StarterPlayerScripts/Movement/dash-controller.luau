--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local MovementConfig = require(ReplicatedStorage.Structures.MovementConfig)
local animate = require(StarterPlayer.StarterPlayerScripts.Utilities.animate)

local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local hydration = require(ReplicatedStorage.Utility.hydration)
local input = require(ReplicatedStorage.Packages.input)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local speed_lines = require(ReplicatedStorage.Effects["speed-lines"])
local trove = require(ReplicatedStorage.Packages.trove)

-- dash-controller.luau

local _trove = trove.new()

local controller = {}
controller._trove = _trove

local keyboard = input.Keyboard.new()

_trove:Add(keyboard :: any)

local player = playerMarshaller.get()
local character = player.Character or player.CharacterAdded:Wait()

local humanoid = character:FindFirstChild("Humanoid") :: Humanoid

animate.load(MovementConfig.Animations.Dash.Id)

local mouse = input.Mouse.new()
local camera = workspace.CurrentCamera

local rate_limit = ratelimit(1, MovementConfig.Dash.Cooldown)

_trove:Add(mouse :: any)

local function onBegan()
	if not rate_limit(player.UserId) then
		return
	end

	if not character then
		return
	end

	if humanoid.Health <= 0 then
		return
	end

	local primary_part = character.PrimaryPart

	if not primary_part then
		return
	end

	local current_stamina = character:GetAttribute("Stamina") :: number or 0
	local stamina_cost = MovementConfig.Dash.StaminaCost

	if current_stamina < stamina_cost then
		return
	end

	-- get dash direction

	local direction = camera.CFrame.LookVector.Unit

	-- negate stamina
	local new_stamina = current_stamina - stamina_cost

	character:SetAttribute("Stamina", new_stamina)
	character:SetAttribute("AntiRegenerate", true)

	-- add the velocity

	-- yeah its deprecated; who cares
	local velocity = _trove:Construct(Instance, "BodyVelocity", primary_part)
	hydration(velocity) {
		MaxForce = Vector3.new(1, 0, 1) * math.huge,
		Velocity = direction * MovementConfig.Dash.Force,
		Parent = primary_part,
	}

	local lines = fetchAsset("Speedlines") :: speed_lines.lines

	speed_lines:On(workspace.CurrentCamera, lines)

	animate.play(MovementConfig.Animations.Dash.Id)

	task.delay(MovementConfig.Dash.Duration, function()
		_trove:Clean()

		speed_lines:Off()

		if character then
			character:SetAttribute("AntiRegenerate", false)
		end
	end)
end

(keyboard.KeyDown :: RBXScriptSignal<Enum.KeyCode, boolean>):Connect(function(key)
	if key ~= MovementConfig.Keybinds.Dash then
		return
	end

	onBegan()
end)

return controller
