--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local hydration = require(ReplicatedStorage.Utility.hydration)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local sound_ids = require(script["sound-ids"])
local url = require(ReplicatedStorage.Modules.Serialization.url)

-- movement-sounds.luau

local player = playerMarshaller.get()
local character = characterMarshaller.get(player)

local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
local root_part = character:FindFirstChild("HumanoidRootPart") :: BasePart

-- we'll use the old audio api
-- *ahem* for simplicity!

local sound_id = observer.new(0)
local volume = observer.new(0)
local playback_speed = observer.new(0)

local floor_material = observer.new(Enum.Material.Air)
local material = observer.new("")

local function newSound()
	local sound = PoolerPlus
	hydration(sound) {
		Name = "movement-sound" .. url.generateShortUniqueId(),
		Parent = SoundService,
	}

	return sound
end

local sound_pool = PoolerPlus:CreatePool("", newSound, nil, nil, {
	maxSize = 5,
	preloadCount = 4,
})

-- remove the defualt running sound
do
	local default_sound = root_part:FindFirstChild("Running")
	if default_sound then
		default_sound:Destroy()
	end
end

local function getFloorMaterial()
	floor_material:Set(humanoid.FloorMaterial)

	local str = string.split(floor_material:Get().Name, "Enum.Material.")

	local i = 2

	material:Set(str[i])

	return material
end

local function getSoundProperties()
	for i, sound_data in pairs(sound_ids) do
		if i ~= material:Get() then
			return
		end

		sound_id:Set(sound_data.id)
		volume:Set(sound_data.volume)
		playback_speed:Set((humanoid.WalkSpeed / 14) * sound_data.speed)

		break -- lets take a "break", heh.
	end
end

local function update()
	--
end
