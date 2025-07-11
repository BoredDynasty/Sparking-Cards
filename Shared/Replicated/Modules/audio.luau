--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Utility.SignalPlus)
local dictionary = require(ReplicatedStorage.Utility.dictionary)

local Audio = {}
Audio.__index = Audio

type self = {
	player: Player,
	currentAudio: nil,
	miscellaneous: { [string]: string },
	playlist: {},
	events: {
		playing: SignalPlus.Signal<Sound, string>,
		stopped: SignalPlus.Signal<Sound, string>,
	},
	create: (data: create_data) -> Sound,
}

type create_data = {
	identification: string,
	volume: number?,
}

export type Audio = typeof(setmetatable({} :: self, Audio))

--[[
    Creates a new `Audio` object.
]]
function Audio.new(): Audio
	local self = setmetatable({
		player = Players.LocalPlayer,
		currentAudio = nil,
		playlist = table.create(100),
		miscellaneous = table.create(50),
		events = {
			played = SignalPlus(),
			stopped = SignalPlus(),
		},
		create = function(data: create_data): Sound
			local audio = Instance.new("Sound")
			audio.SoundId = data.identification
			data.volume = data.volume or 1 -- set default
			audio.Volume = data.volume
			return audio
		end,
	}, Audio)
	return self
end

--[[
    Writes a compiled `table` to the `miscellaneous` dictionary.
]]
function Audio:write_miscellaneous(self: self, compiled: { [string]: number })
	-- dictionary.merge(self.miscellaneous, compiled)
	for name, identification in pairs(compiled) do
		if not table.find(self.miscellaneous, name) then
			self.miscellaneous[name] = `rbxassetid://{identification}`
		end
	end
end

--[[
    Plays an `Audio` from the miscellaneous dictionary.
]]
function Audio:read_miscellaneous(self: self, name: string, data: create_data?)
	local create_data: create_data = {}
	data = data or {}
	data = dictionary.reconcile(data, {
		volume = 1,
		identification = self.miscellaneous[name],
	})
	create_data = dictionary.reconcile(create_data, data)
	task.wait()
	--print("create data: ", table.unpack(create_data))
	local audio = self.create(create_data)
	audio.Name = name
	audio.Parent = self.player
	audio:Play()
	self.events.playing:Fire(audio, audio.Name)
	task.delay(audio.TimeLength + math.random(), function()
		self.events.stopped:Fire(audio, audio.Name)
		audio:Destroy()
	end)
end

function Audio:remove(self: self, name: string)
	for sound_name, _ in pairs(self.miscellaneous) do
		if name:lower() == sound_name:lower() then
			self.miscellaneous[sound_name] = nil
		end
	end
end

return Audio
