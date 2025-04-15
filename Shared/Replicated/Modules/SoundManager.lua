--!strict

--[=[
    @class Audio
--]=]
local Audio = {}

-- // Services

local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

-- // Functions

--[=[
    @function Play
        @param sound table
        @param directory Instance?
--]=]
function Audio:Play(sound: number): Sound
	local audio = Instance.new("Sound")
	audio.Parent = SoundService
	audio.Volume = 1
	audio.SoundId = tostring(sound)
	task.wait()
	audio:Play()
	Debris:AddItem(audio, audio.TimeLength + math.random(1, 5))
	return audio
end

return Audio
