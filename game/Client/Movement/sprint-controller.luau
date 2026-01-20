--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local MovementConfig = require(ReplicatedStorage.Structures.MovementConfig)
local animate = require(StarterPlayer.StarterPlayerScripts.Utilities.animate)

local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local input = require(ReplicatedStorage.Packages.input)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
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

local player = playerMarshaller.get()
local character = player.Character or player.CharacterAdded:Wait()

local humanoid = character:FindFirstChild("Humanoid") :: Humanoid

local rate_limit = ratelimit(1, 0.5)

animate.load(MovementConfig.Animations.Run.Id)

local function onBegan()
	if not rate_limit(player.UserId) then
		return
	end

	if humanoid:GetState() == Enum.HumanoidStateType.Running then
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

	spr.target(humanoid, 1, 1 / 0.3, {
		WalkSpeed = new_speed,
	})

	character:SetAttribute("AntiRegenerate", true)
	animate.play(MovementConfig.Animations.Run.Id)

	local lines = fetchAsset("speed_lines") :: speed_lines.lines

	speed_lines:On(workspace.CurrentCamera, lines)
end

local function onEnded()
	if humanoid:GetState() ~= Enum.HumanoidStateType.Running then
		return
	end

	local new_speed = MovementConfig.Character.BaseSpeed

	spr.target(humanoid, 1, 1 / 0.3, {
		WalkSpeed = new_speed,
	})

	character:SetAttribute("AntiRegenerate", false)

	animate.stop(MovementConfig.Animations.Run.Id)

	speed_lines:Off()
end

function controller:Update(deltaTime: number)
	if humanoid:GetState() ~= Enum.HumanoidStateType.Running then
		return
	end

	local current_stamina = character:GetAttribute("Stamina") :: number or 0

	if current_stamina >= 100 then
		return
	end

	local drain_rate = MovementConfig.Sprint.StaminaDrainRate

	local new_stamina = current_stamina - (drain_rate * deltaTime)

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
