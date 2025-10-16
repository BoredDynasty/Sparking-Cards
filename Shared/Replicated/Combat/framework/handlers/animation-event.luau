--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)

-- animation-event.luau
-- i made this because i want the animation events
-- to be supported by Roblox native ones(marker reacehd event) and by specifying them in code

local animation_event = {}

function animation_event.hit(animation: AnimationTrack, time_position: number?)
	local hit_signal = SignalPlus() :: SignalPlus.Signal<number, ...any?>

	if not time_position then
		local signal = animation:GetMarkerReachedSignal("Hit")
		if not signal then
			print("No 'Hit' marker found in animation: " .. tostring(animation.Animation))

			hit_signal:Destroy()

			return
		end
		signal:Once(function(...: any)
			local keyframe = animation.TimePosition
			hit_signal:Fire(keyframe, ...)

			task.delay(2, function()
				hit_signal:Destroy()
			end)
		end)
	else
		local conn = nil
		conn = RunService.Heartbeat:Connect(function()
			if animation.TimePosition >= time_position then
				hit_signal:Fire(animation.TimePosition)

				task.delay(2, function()
					hit_signal:Destroy()
				end)

				if conn then
					conn:Disconnect()
				end
			end
		end)
	end
end

return animation_event
