--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local MovementConfig = require(ReplicatedStorage.Structures.MovementConfig)
local animate = require(StarterPlayer.StarterPlayerScripts.Utilities.animate)
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local gamecamera = require(StarterPlayer.StarterPlayerScripts.Modules.gamecamera)
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
local character = characterMarshaller.get(player)

local humanoid = character:WaitForChild("Humanoid") :: Humanoid

animate.loadAnimation("dash", MovementConfig.Animations.Dash :: any)

local mouse = input.Mouse.new()
local camera = gamecamera.camera

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

	local direction = nil

	local head = character:FindFirstChild("Head") :: BasePart
	if not head then
		return
	end

	if head.LocalTransparencyModifier == 1 then
		-- we are in first person
		direction = camera.CFrame.LookVector
	else
		-- we are NOT in first person
		local ray = mouse:GetRay()
		if not ray then
			direction = camera.CFrame.LookVector -- lmao
		end

		direction = ray.Unit.Direction
		-- getting the (unit::Ray) then after that we get direction;
		-- it gives us the normalized vec3!
	end

	-- negate stamina
	local new_stamina = current_stamina - stamina_cost

	character:SetAttribute("Stamina", new_stamina)
	character:SetAttribute("AntiRegenerate", true)

	-- add the velocity

	local attachment0 = _trove:Construct(Instance, "Attachment", primary_part)

	local velocity = _trove:Construct(Instance, "LinearVelocity")
	hydration(velocity) {
		Attachment0 = attachment0,
		MaxForce = math.huge,
		VectorVelocity = direction * MovementConfig.Dash.Force,
		Parent = primary_part,
	}

	local lines = fetchAsset("Speedlines") :: speed_lines.lines

	speed_lines:On(gamecamera.camera, lines)

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
