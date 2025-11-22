--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerState = require(ReplicatedStorage.Shared.Replicated.Modules.PlayerState)
local grip = require(ReplicatedStorage.Shared.Replicated.Combat.framework.utils.grip)
local WeaponData = require(script.Parent.WeaponData)
local VFXController = require(ReplicatedStorage.Shared.Replicated.Effects.VFXController)

--- @class MeleeController
-- Handles client-side melee combat logic.
-- @client
local MeleeController = {}
MeleeController.__index = MeleeController

export type self = {
	player_state: PlayerState.self,
	character: Model,
	animator: Animator,
	current_weapon: Model?,
	grip_info: grip.GripInfo?,
	combo_count: number,
	last_attack_time: number,
	vfx_controller: VFXController.self,
}

--- Creates a new MeleeController.
-- @param character Model The character this controller will manage.
-- @param player_state PlayerState.self The player's state manager.
-- @return MeleeController The new MeleeController.
function MeleeController.new(character: Model, player_state: PlayerState.self): self
	local self = setmetatable({}, MeleeController)
	self.character = character
	self.animator = character.Humanoid.Animator
	self.player_state = player_state
	self.current_weapon = nil
	self.grip_info = nil
	self.combo_count = 0
	self.last_attack_time = 0
	self.vfx_controller = VFXController.new()

	return self
end

--- Equips a weapon.
-- @param weapon Model The weapon to equip.
function MeleeController:equipWeapon(weapon: Model)
	if self.current_weapon then
		self:unequipWeapon()
	end

	self.current_weapon = weapon
	self.grip_info = grip.createGrip(self.character, weapon, "Right")
end

--- Unequips the current weapon.
function MeleeController:unequipWeapon()
	if not self.current_weapon then
		return
	end

	grip.removeGrip(self.current_weapon)
	self.current_weapon = nil
	self.grip_info = nil
end

--- Initiates an attack.
function MeleeController:attack()
	if not self.current_weapon then
		return
	end

	local weapon_name = self.current_weapon:GetAttribute("WeaponType")
	if not weapon_name or typeof(weapon_name) ~= "string" then
		return
	end
	local weapon_config = WeaponData[weapon_name]

	if self.player_state:hasState("Attacking") then
		if time() - self.last_attack_time <= weapon_config.ComboWindow then
			self.combo_count += 1
		else
			self.combo_count = 1
		end
	else
		if not self.player_state:hasState("Idle") and not self.player_state:hasState("Moving") then
			return -- can't attack if not in a valid state
		end
		self.combo_count = 1
	end

	self.player_state:enterState("Attacking")
	self.last_attack_time = time()

	local attack_animation = weapon_config.Animations["Attack" .. self.combo_count]
	if not attack_animation then
		self.combo_count = 1
		attack_animation = weapon_config.Animations["Attack1"]
	end

	-- logic for playing animations, sounds, and vfx will go here
	self:playAnimation(attack_animation)
	local swing_sound = weapon_config.Sounds.Swing
	if swing_sound then
		self.vfx_controller:playSound(swing_sound, self.character.PrimaryPart)
	end
	local slash_effect = weapon_config.VFX.Slash
	if slash_effect then
		self.vfx_controller:createEffect(slash_effect, self.character.PrimaryPart.Position)
	end

	-- fire a remote event to the server for hit detection
	local MainNet = require(ReplicatedStorage.Shared.Replicated.Packet)
	MainNet.MeleeAttack:sendToServer({ weapon_name = weapon_name })

	task.delay(weapon_config.AttackSpeed, function()
		self.player_state:exitState("Attacking")
	end)
end

--- Plays an animation on the character.
-- @param animation_id string The asset ID of the animation to play.
function MeleeController:playAnimation(animation_id: string)
	local animation = Instance.new("Animation")
	animation.AnimationId = animation_id
	local animation_track = self.animator:LoadAnimation(animation)
	animation_track:Play()
	animation.Ended:Connect(function()
		animation_track:Destroy()
		animation:Destroy()
	end)
end

return MeleeController
