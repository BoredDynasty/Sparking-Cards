--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local MovementConfig = require(ReplicatedStorage.Structures.MovementConfig)
local animate = require(StarterPlayer.StarterPlayerScripts.Utilities.animate)

local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local input = require(ReplicatedStorage.Packages.input)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local speed_lines = require(ReplicatedStorage.Effects["speed-lines"])
local spr = require(ReplicatedStorage.Modules.spr)
local trove = require(ReplicatedStorage.Packages.trove)

-- sprint-controller.luau

local _trove = trove.new()

local controller = {}
controller._trove = _trove

local keyboard = input.Keyboard.new()

_trove:Add(keyboard :: any)

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

local is_sprinting = false
local character_trove = _trove:Extend()

local function setupCharacter(new_character: Model)
	character_trove:Clean()
	character = new_character
	humanoid = character:WaitForChild("Humanoid") :: Humanoid
	is_sprinting = false

	character_trove:Connect(humanoid.Died, function()
		is_sprinting = false
	end)
end

if character then
	setupCharacter(character)
end

player.CharacterAdded:Connect(setupCharacter)

local rate_limit = ratelimit(1, 0.5)

animate.load(MovementConfig.Animations.Run.Id)

local function onBegan()
	if not rate_limit(player.UserId) then
		return
	end

	if humanoid:GetState() ~= Enum.HumanoidStateType.Running then
		return
	end

	local stamina = character:GetAttribute("Stamina") :: number or 0

	if stamina <= 0 then
		return
	end

	if humanoid.MoveDirection.Magnitude == 0 then
		return
	end

	local base_speed = MovementConfig.Character.BaseSpeed
	local speed_increase = MovementConfig.Sprint.SpeedIncrease

	local new_speed = base_speed + speed_increase

	spr.target(humanoid, 0.8, 5, {
		WalkSpeed = new_speed,
	})

	spr.completed(humanoid, function()
		humanoid.WalkSpeed = new_speed
	end)

	is_sprinting = true
	character:SetAttribute("AntiRegenerate", true)

	animate.stop(MovementConfig.Animations.Walk.Id)
	animate.play(MovementConfig.Animations.Run.Id)

	local lines = fetchAsset("speed_lines") :: speed_lines.lines

	speed_lines:On(workspace.CurrentCamera, lines)
end

local function onEnded()
	if not is_sprinting then
		return
	end

	is_sprinting = false

	local new_speed = MovementConfig.Character.BaseSpeed

	spr.stop(humanoid, "WalkSpeed")
	spr.target(humanoid, 0.8, 5, {
		WalkSpeed = new_speed,
	})

	spr.completed(humanoid, function()
		humanoid.WalkSpeed = new_speed
	end)

	character:SetAttribute("AntiRegenerate", false)

	animate.stop(MovementConfig.Animations.Run.Id)

	speed_lines:Off()
end

function controller:Update(deltaTime: number)
	if not is_sprinting then
		return
	end

	if humanoid:GetState() ~= Enum.HumanoidStateType.Running then
		onEnded()
		return
	end

	local current_stamina = character:GetAttribute("Stamina") :: number or 0

	local drain_rate = MovementConfig.Sprint.StaminaDrainRate

	local new_stamina = math.max(0, current_stamina - (drain_rate * deltaTime))

	character:SetAttribute("Stamina", new_stamina)

	if new_stamina <= 0 or humanoid.MoveDirection.Magnitude == 0 then
		onEnded()
	end
end

(keyboard.KeyDown :: RBXScriptSignal<Enum.KeyCode, boolean>):Connect(function(key)
	if key ~= MovementConfig.Keybinds.Sprint then
		return
	end

	onBegan()
end);
(keyboard.KeyUp :: RBXScriptSignal<Enum.KeyCode, boolean>):Connect(function(key)
	if key ~= MovementConfig.Keybinds.Sprint then
		return
	end

	onEnded()
end)

return controller
