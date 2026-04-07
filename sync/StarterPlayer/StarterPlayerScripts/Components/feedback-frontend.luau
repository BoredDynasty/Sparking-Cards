--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local displayorder = require(StarterPlayer.StarterPlayerScripts.Interface.displayorder)
local fade = require(StarterPlayer.StarterPlayerScripts.Interface.fade)
local hud = require(StarterPlayer.StarterPlayerScripts.Components.hud)
local spr = require(ReplicatedStorage.Modules.spr)
local wiggle = require(StarterPlayer.StarterPlayerScripts.Interface.wiggle)

-- feedback-frontend.luau
-- there are gonna be multiple type of feedbacks.
-- e.g: polls, user inputs

-- we prolly need to use a webhook or analytics

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local feedback_screen = playerGui.Feedback
local feedback_canvas = feedback_screen.CanvasGroup
local feedback_frame = feedback_canvas.Frame

local submit_btn = feedback_frame.TextButton

local module = {}

displayorder.new(feedback_canvas)

export type Feedback = "Poll" | "UserInput"

function module:Fire(feedback_type: Feedback, question: string?)
	hud:Hide()
	displayorder:Open(feedback_canvas)

	if feedback_type == "UserInput" then
		feedback_frame.UserInput.Visible = true

		local text_box = feedback_frame.UserInput.TextBox

		submit_btn.Activated:Connect(function()
			if text_box.Text == "" then
				print("No input provided.")
			else
				local user_input = text_box.Text
				print("User input received: ", user_input)

            -- we also needa setup the backend for this, but for now we will just print it to the console
			end
		end)
	end
end

return module