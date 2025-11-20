--!strict

--- @class VFXController
-- Handles playing sounds and creating visual effects.
-- @client
local VFXController = {}
VFXController.__index = VFXController

export type self = {}

--- Creates a new VFXController.
-- @return VFXController The new VFXController.
function VFXController.new(): self
	return setmetatable({}, VFXController)
end

--- Plays a sound.
-- @param sound_id string The asset ID of the sound to play.
-- @param parent Instance The parent for the sound object.
function VFXController:playSound(sound_id: string, parent: Instance)
	local sound = Instance.new("Sound")
	sound.SoundId = sound_id
	sound.Parent = parent
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

--- Creates a visual effect.
-- @param effect_name string The name of the effect to create.
-- @param position Vector3 The position to create the effect at.
function VFXController:createEffect(effect_name: string, position: Vector3)
	local effect = game.ReplicatedStorage.Effects:FindFirstChild(effect_name)
	if not effect then
		warn("Could not find effect: " .. effect_name)
		return
	end

	local new_effect = effect:Clone()
	new_effect.Parent = workspace
	new_effect:MoveTo(position)
	task.delay(5, function()
		new_effect:Destroy()
	end)
end

return VFXController
