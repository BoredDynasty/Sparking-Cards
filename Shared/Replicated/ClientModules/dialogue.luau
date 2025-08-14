--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TextPlus = require(ReplicatedStorage.Utility.TextPlus)
local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local characterIteration = require(script.Parent.characterIteration)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local random = require(ReplicatedStorage.Utility.random)

-- dialogue.luau

local dialogue = {
	client = {},
	server = {},
}

export type dialogueParams = {
	speaker: string,
	text: string,
	id: number?,
}

local function toggle(dialog_frame: Frame, visible: boolean)
	if dialog_frame.Visible == visible then
		return
	end

	dialog_frame.Visible = visible
	if visible then
		local tween = TweenPlus(dialog_frame, { BackgroundTransparency = visible and 0 or 1 }, {
			Time = 0.2,
			EasingDirection = "In",
			EasingStyle = "Sine",
		})
		tween:Start()
		tween.Completed:Wait()
	else
		local tween = TweenPlus(dialog_frame, { BackgroundTransparency = visible and 1 or 0 }, {
			Time = 0.2,
			EasingDirection = "In",
			EasingStyle = "Sine",
		})
		tween:Start()
		tween.Completed:Wait()
	end
end

--[[
	Displays a dialogue message in the player's GUI.
	@param params: dialogueParams
		- speaker: The name of the speaker.
		- text: The text to display.
		- id: Optional player ID for server-side calls.
]]
function dialogue.client:speak(params: dialogueParams)
	local player = playerMarshaller.get()
	local dialogue_gui = player.PlayerGui:WaitForChild("Dialog") :: ScreenGui
	local dialog_canvas = dialogue_gui:WaitForChild("CanvasGroup") :: CanvasGroup
	local dialog_frame = dialog_canvas:WaitForChild("Frame") :: Frame

	toggle(dialog_frame, true)
	local text = "<b>" .. params.speaker .. "</b>" .. ":\n" .. params.text
	TextPlus.Create(dialog_frame, text, {
		Font = Font.fromName("Montserrat"),
		Size = 20,
		Dynamic = true,
		StrokeTransparency = 1,
		XAlignment = "Center",
		YAlignment = "Center",
		LineSorting = true,
		WordSorting = true,
		Color = Color3.fromRGB(226, 224, 249),
	})
	characterIteration:fadeIn(dialog_frame)
	task.wait(random.integer(6, 9)) -- Wait for 6 to 9 seconds before hiding the dialogue
	toggle(dialog_frame, false)
end

--[[
	Displays a dialogue message in the player's GUI on the server side.
	@param params: dialogueParams
		- speaker: The name of the speaker.
		- text: The text to display.
		- id: The player ID to send the message to.
]]
function dialogue.server:speak(params: dialogueParams)
	assert(params.id, "No player ID provided for dialogue.speak")
	local player = playerMarshaller.getByUserId(params.id) :: Player
	if not player then
		warn("No player provided for dialogue.speak, and no player could be marshalled.")
		return
	end

	local dialogue_gui = player.PlayerGui:WaitForChild("Dialog") :: ScreenGui
	local dialog_canvas = dialogue_gui:WaitForChild("CanvasGroup") :: CanvasGroup
	local dialog_frame = dialog_canvas:WaitForChild("Frame") :: Frame

	toggle(dialog_frame, true)
	local text = "<b>" .. params.speaker .. "</b>" .. ":\n" .. params.text
	TextPlus.Create(dialog_frame, text, {
		Font = Font.fromName("Montserrat"),
		Size = 20,
		Dynamic = true,
		StrokeTransparency = 1,
		XAlignment = "Center",
		YAlignment = "Center",
		LineSorting = true,
		WordSorting = true,
	})
	characterIteration:fadeIn(dialog_frame)
	task.wait(random.integer(2, 5)) -- Wait for 2 to 5 seconds before hiding the dialogue
	toggle(dialog_frame, false)
end

return dialogue
