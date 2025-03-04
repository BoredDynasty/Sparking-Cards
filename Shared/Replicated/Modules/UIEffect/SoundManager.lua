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
        @param sound string | number
        @param directory any
--]=]
function Audio.Play(sound: string | number, directory)
	if not directory then
		directory = SoundService
	end
	local audio = nil
	if type(sound) == "string" then
		local any: Sound = directory[sound] or SoundService[sound]
		audio = any:Clone()
		audio.Parent = SoundService
		audio:SetAttribute(script.Name, true)
		audio:Play()
		Debris:AddItem(audio, audio.TimeLength)
	elseif type(sound) == "number" then
		audio = Instance.new("Sound")
		audio.SoundId = "rbxassetid://" .. sound
		audio.Parent = SoundService
		audio:SetAttribute(script.Name, true)
		audio:Play()
		Debris:AddItem(audio, audio.TimeLength)
	end
	return audio
end
--[=[
    @function Music
        @param playlist table
        @param client boolean
--]=]
function Audio.Music(playlist: { Sound }, client: boolean)
	local currentlyPlaying = nil
	if client == true then
		for i, sound: Sound in playlist do
			local newSound = sound:Clone()
			newSound.Playing = true
			newSound.Volume = 1
			newSound.Parent = SoundService
			currentlyPlaying = newSound
			Debris:AddItem(newSound, newSound.TimeLength)
			task.wait(newSound.TimeLength + 5)
			next(playlist, i)
		end
	end
	return currentlyPlaying
end

--[=[
    @function Stop
        @param sound string
        @param directory Instance?
--]=]
function Audio.Stop(sound: string, directory: Instance?)
	if table.find(directory:GetDescendants(), sound) then
		directory[sound]:Destroy()
		print(`Removing {sound.Name} sound from {directory.Name}.`)
	end
end

return Audio
