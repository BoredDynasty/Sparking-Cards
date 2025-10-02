--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local CameraController = require("../Camera/Shake")
local Shake = require(StarterPlayer.StarterPlayerScripts.Camera.Shake)
local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local gamecamera = require(StarterPlayer.StarterPlayerScripts.Modules.gamecamera)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local trove = require(ReplicatedStorage.Packages.trove)

-- freefalling.luau

local player = playerMarshaller.get()
local character = characterMarshaller.get(player)

local humanoid = character.Humanoid

local camera = gamecamera.camera

-- flags

local falling = observer.new(false)
local debounce = observer.new(false)
local state = observer.new(humanoid:GetState())
local conn = observer.None :: observer.Observer<SignalPlus.Connection?>

local singleton = Shake.new(CameraController)
local _trove = trove.new()

_trove:Connect(humanoid.StateChanged, function(newState)
	state:Set(newState)
end)

state:Watch(function(newValue: Enum.HumanoidStateType, oldValue: Enum.HumanoidStateType)
	falling:Set(if newValue == Enum.HumanoidStateType.Freefall then true else false)

	if falling:Get() and not debounce:Get() then
		debounce:Set(true)
		-- local start_time = os.clock()

		conn:Set(_trove:Connect(RunService.PreRender, function(deltaTime: number)
			-- local current_time = os.clock()
			-- local n = current_time - start_time

			-- local air_time = math.clamp(n, 0, 10)

			-- being in the air for 10s is crazy work ngl
			singleton:Update(deltaTime, camera.CFrame)
		end))
	elseif newValue == Enum.HumanoidStateType.Landed then
		if conn:Get() or conn:Get() ~= nil then
			_trove:Remove(conn:Get())
		end

		conn:Set(nil)
		debounce:Set(false)
	end
end)

_trove:Add(conn)
_trove:Add(debounce)
_trove:Add(falling)
_trove:Add(state)

return {
	falling = falling,
	debounce = debounce,
	_trove = _trove,
}
