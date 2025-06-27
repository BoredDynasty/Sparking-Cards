--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local dialogue = require(ReplicatedStorage.ClientModules.dialogue)
local random = require(ReplicatedStorage.Utility.random)
local retryer = require(ReplicatedStorage.Utility.retryer)
local timer = require(ReplicatedStorage.Modules.timer)

-- OnIdle.luau

-- fires once the player idles

local dialogues = {
	[1] = {
		speaker = "You",
		text = "How boring...",
	},
	[2] = {
		speaker = "You",
		text = "I should do something.",
	},
	[3] = {
		speaker = "You",
		text = "Maybe I should get a snack?",
	},
	[4] = {
		speaker = "You",
		text = "I wonder if anyone else is bored?",
	},
}

local thread = nil

return function()
	local clock = timer.new()
	clock:Start()
	local divisor = 20 -- can 20 fit into the elapsedTime
	if thread then
		task.cancel(thread)
		thread = nil
	end
	task.wait()
	thread = task.spawn(function()
		retryer.inf(function()
			if clock:GetTime() % divisor == 0 then
				local elapsed = clock:GetTime()
				local seconds = elapsed % 60
				local minutes = (elapsed // 60) % 60
				local hours = elapsed // 3600
				print(string.format("Idle for %02d:%02d:%02d", hours, minutes, seconds))
				local dialog = dialogues[random.dict_random(dialogues)]
				print(string.format("%s: %s", dialog.speaker, dialog.text))
				local params = {
					speaker = dialog.speaker,
					text = dialog.text,
				}
				dialogue.client:speak(params)
			end
			task.wait(1) -- wait for a second before checking again
		end)
	end)
end
