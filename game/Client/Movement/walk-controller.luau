--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local MovementConfig = require(ReplicatedStorage.Structures.MovementConfig)
local animate = require(StarterPlayer.StarterPlayerScripts.Utilities.animate)
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- walk-controller.luau

local controller = {}

local player = playerMarshaller.get()
local character = characterMarshaller.get(player)

local humanoid = character:WaitForChild("Humanoid") :: Humanoid

animate.loadAnimation("walk", MovementConfig.Animations.Walk :: any)

local is_animating = observer.new(false)

function controller:Update()
	local move_direction = humanoid.MoveDirection
	local is_moving = move_direction.Magnitude > 0

	if is_moving and not is_animating:Get() then
		local track = animate.play("walk")
		if not track then
			return
		end

		if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
			track:AdjustSpeed(0.25)
		else
			track:AdjustSpeed(1)
		end
	elseif not is_moving and is_animating:Get() then
		animate.stop("walk")
	end
end

return controller
