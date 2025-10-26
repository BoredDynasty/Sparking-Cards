--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local observer = require(ReplicatedStorage.Utility.observer)

-- beats.luau
-- beats-per-minute detector
-- taking control of the new audio API!

local beats_module = {}
beats_module.__index = beats_module

export type configuration = {
	analyzer: AudioAnalyzer,
	minimum_gap: number?,
	window_size: number?,
	threshold_multiplier: number?,
}

type self = {
	analyzer: AudioAnalyzer,
	_minimum_gap: number,
	_window_size: number,
	_threshold_multiplier: number,
	_beat_times: { number },
	_rms_history: { number },
	_last_beat_time: number,
	_last_rms: number,
	_last_bpm: number,
	_running: observer.Observer<boolean>,
	_conn: RBXScriptConnection?,
	Beat: SignalPlus.Signal<>,
	BPMUpdate: SignalPlus.Signal<>,
}

--[[
   Creates a new beats-per-minute detector.
   configuration:
      analyzer: AudioAnalyzer - the audio analyzer to use
      minimum_gap: number? - minimum gap between beats in seconds (default: 0.3)
      window_size: number? - size of the window to calculate BPM in seconds (default: 10)
      threshold_multiplier: number? - multiplier for the RMS threshold (default: 1.2)

   make sure you dont have too many of these instances running!

   ```luau
   local detector = beats_module.new({
      analyzer = audioAnalyzerInstance,
      minimum_gap = 0.3,
      window_size = 10, -- in seconds
      threshold_multiplier = 1.2,
   })

   detector.Beat:Connect(function()
      print("🎵")

      -- You can add more logic here, like updating a UI element or triggering an animation.

      spr.stop(camera, "FieldOfView")
      camera.FieldOfView = random:NextNumber(70, 90)
      spr.target(camera, 1, 4.12, { FieldOfView = 70 })
   end)

   detector.BPMUpdate:Connect(function(bpm)
      print(string.format("Current BPM: %.2f", bpm))
   end)
]]
function beats_module.new(configuration: configuration): setmetatable<self, typeof(beats_module)>
	local self = setmetatable({}, beats_module)

	self.analyzer = configuration.analyzer
	assert(self.analyzer, "AudioAnalyser is needed")

	self._minimum_gap = configuration.minimum_gap or 0.3
	self._window_size = configuration.window_size or 10
	self._threshold_multiplier = configuration.threshold_multiplier or 1.2

	self._beat_times = {}
	self._rms_history = {}

	self._last_beat_time = 0
	self._last_rms = 0
	self._last_bpm = 0

	self._running = observer.new(false)

	self._conn = nil

	self.Beat = SignalPlus()
	self.BPMUpdate = SignalPlus()

	return self
end

function beats_module:Start()
	if self._running:Get() then
		return
	end

	self._running:Set(true)

	self._conn = RunService.Heartbeat:Connect(function()
		debug.profilebegin("detect-bpm")
		self:_Process()
		debug.profileend()
	end)
end

function beats_module:Stop()
	if self._conn then
		self._conn:Disconnect()
		self._conn = nil
	end

	self._running:Set(false)
end

function beats_module:_Process()
	local now = os.time()

	local rms = self.analyzer.RmsLevel

	-- update rms history
	table.insert(self._rms_history, rms)
	if #self._rms_history > self._window_size * 60 then
		table.remove(self._rms_history, 1)
	end

	local sum = 0
	for i, v in ipairs(self._rms_history) do
		sum += v
	end

	local average = sum / math.max(1, #self._rms_history)
	local threshold = average * self._threshold_multiplier

	-- detect beat
	if rms > threshold and (now - self._last_beat_time) >= self._minimum_gap then
		self._last_beat_time = now

		table.insert(self._beat_times, now)

		self.Beat:Fire()

		while #self._beat_times > 0 and (now - self._beat_times[1]) > self._window_size do
			table.remove(self._beat_times, 1)
		end

		-- calculate BPM

		if #self._beat_times >= 2 then
			local total = 0
			for i = 2, #self._beat_times do
				total += (self._beat_times[i] - self._beat_times[i - 1])
			end
			local average_interval = total / (#self._beat_times - 1)
			local bpm = 60 / average_interval

			if bpm ~= self._last_bpm then
				self._last_bpm = bpm
				self.BPMUpdate:Fire(bpm)
			end
		end
	end
end

function beats_module:Destroy()
	self:Stop()

	self.Beat:Destroy()
	self.BPMUpdate:Destroy()

	table.clear(self)

	setmetatable(self, nil)
end

return beats_module
