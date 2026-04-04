--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local CardLibrary = require(ReplicatedStorage.Combat.CardLibrary)
local audio = require(ReplicatedStorage.Modules.audio)
local fetchProfile = require(StarterPlayer.StarterPlayerScripts.Utilities.fetchProfile)
local hint = require(StarterPlayer.StarterPlayerScripts.Components.hint)
local image_mask = require(ReplicatedStorage.Modules.Imagery["image-mask"])
local leventine = require(ReplicatedStorage.Utility.leventine)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)

-- loadout-frontend.luau

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local loadout_screen = playerGui:WaitForChild("LoadoutScreen")

local module = {}

-- heres the plan:
-- we are going to put a list of all the items in the game, and then we are going to filter that list based on what the player has unlocked
-- then we are going to display that list in the loadout screen, and allow the player to select which items they want to equip
-- we are also going to allow the player to save their loadout, so that they can easily switch between different loadouts

-- next for the UI, we need to mask the card backgrounds with the frame behind it.
-- an imagemask will be good for this, but we need to make sure that the card backgrounds are all the same size and aspect ratio for it to work well
-- TODO: make the card backgrounds the same size and aspect ratio, and then use an imagemask to mask them with the frame
-- note: the backgrounds are the shape of a rhombus, so we can use an imagemask with a rhombus shape to mask them
-- we are going to position the rhombuses next to eachother in a list that can be scrolled through,
-- and then we are going to have a separate area that shows the details of the selected item

-- for the loadout background, i want to add some parallax to it to make it more visually interesting, and to give it some depth
-- we can do this using the parallax.luau module
-- TODO: add more parallax backgrounds

local profile = fetchProfile()

local function createCardRhombus()
	return ReplicatedStorage.Interfaces.CardRhombus:Clone()
end

function module:UnloadCards()
	-- Implementation for unloading cards from the UI
	for _, card_ui in ipairs(loadout_screen.CanvasGroup.CardHolder:GetChildren()) do
		if card_ui:IsA("Frame") then
			card_ui:Destroy()
		end
	end
end

function module:HydrateCards()
	-- Implementation for hydrating cards

	profile = fetchProfile()
	if not profile then
		warn("Failed to fetch profile for card hydration.")

		local snackbar = hint.new()
		snackbar:SetText("Failed to load your profile. Please try again later.")
		snackbar:SetExpiry(2)
		snackbar:SetCanClick(true)
		snackbar:SetAction(function()
			module:HydrateCards()
		end, "Retry")

		audio:PlayVariation("cancel", 1)

		if RunService:IsStudio() then
			profile = { Data = profilestructure }
			print("reverting to profilestructure")
		else
			return
		end
	end

	for card_name, quantity in pairs(profile.Data.cards) do
		if quantity <= 0 then
			-- If the player doesn't have any of this card, we can choose to hide it or show it as locked
			-- For now, let's just skip it
			continue
		end

		print("yay!")

		-- we need to find out if the card_name is similar to one of the cards in the CardLibrary, and if so, we need to get the details of that card from the CardLibrary
		-- use a levenshtein distance algorithm to find the closest match for the card_name in the CardLibrary, and then use that card's details to populate the UI
		local all_card_names = {}
		for name, _ in pairs(CardLibrary) do
			table.insert(all_card_names, name)
		end

		local closest_card_name, j = leventine.closest(card_name, all_card_names)
		local card_details = CardLibrary[closest_card_name or j]

		local card_ui = createCardRhombus()
		card_ui.Name = (closest_card_name or card_name) .. "_CardUI"
		card_ui.Parent = loadout_screen.CanvasGroup.CardHolder
	end
end

return module
