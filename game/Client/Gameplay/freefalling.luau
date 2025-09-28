--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local damage = require(ReplicatedStorage.Combat.Strike.damage)
local gamecamera = require(StarterPlayer.StarterPlayerScripts.Modules.gamecamera)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local random = require(ReplicatedStorage.Utility.random)
local trove = require(ReplicatedStorage.Packages.trove)

-- freefalling.luau

local player = playerMarshaller.get()
local character = characterMarshaller.get(player)

local rootPart = character.HumanoidRootPart
local humanoid = character.Humanoid

-- flags

local falling = observer.new(false)
local debounce = observer.new(false)
local state = observer.new(humanoid:GetState())

local _trove = trove.new()

_trove:Connect(humanoid.StateChanged, function(newState)
	state:Set(newState)
end)

state:Watch(function(newValue: Enum.HumanoidStateType, oldValue: Enum.HumanoidStateType)
	falling:Set(if newValue == Enum.HumanoidStateType.Freefall then true else false)

	if falling:Get() and not debounce:Get() then
		debounce:Set(true)

		local low_fall_height = random.integer(18, 25)

		local maxHeight, minHeight = 0, math.huge

		local conn = nil
		conn = _trove:Connect(RunService.PreRender, function(deltaTime)
			local start_time = os.clock()

			local height = rootPart.Position.Y
			if height > maxHeight then
				maxHeight = height
			end
			if height < minHeight then
				minHeight = height
			end

			local conn2 = nil
			conn2 = falling:Watch(function(newValue: boolean, oldValue: boolean)
				if newValue and not oldValue and conn ~= nil and conn2 ~= nil then
					_trove:Remove(conn)
					conn2:Disconnect()
				end
			end)

			local air_time = math.clamp(os.clock() - start_time, 0, 10)
			-- being in the air for 10s is crazy work ngl

			gamecamera:Shake(air_time, deltaTime)
		end)

		local fall_height = maxHeight - minHeight
		local impact_height = fall_height - low_fall_height

		if impact_height > 0 then
			damage.__call({
				amount = impact_height,
				target = player,
			})

			gamecamera:Shake(impact_height, 0.2)
		end
	end
end)

return {
	falling = falling,
	debounce = debounce,
	_trove = _trove,
}
