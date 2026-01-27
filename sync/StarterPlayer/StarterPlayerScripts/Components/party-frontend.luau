--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local StarterPlayer = game:GetService("StarterPlayer")

local Packet = require(ReplicatedStorage.Packet)
local confetti = require(StarterPlayer.StarterPlayerScripts.Interface.confetti)
local future = require(ReplicatedStorage.Packages.future)
local pop = require(StarterPlayer.StarterPlayerScripts.Interface.pop)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local rbx_thumb = require(ReplicatedStorage.Modules.Serialization["rbx-thumb"])
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)
local wiggle = require(StarterPlayer.StarterPlayerScripts.Interface.wiggle)

-- party-frontend.luau
-- the frontend for the party system.
-- this module is designed to work autonomously; there is a lack of public functions

local module = {}

local debounce = ratelimit(1, 2.3)

local player = Players.LocalPlayer
local player_gui = player.PlayerGui

local templates = ReplicatedStorage.Interfaces
local events = ReplicatedStorage.Events

local party_gui = player_gui.Party
local party_canvas = party_gui.CanvasGroup
local party_frame = party_canvas.Frame

shadow(party_frame.Create)
shadow(party_frame.InviteFriend)
shadow(party_frame)

local function inviteFriend()
	local fut = future.Try(SocialService.CanSendGameInviteAsync, SocialService, player)

	local ok, can_send = fut:Await()

	if ok and can_send then
		SocialService:PromptGameInvite(player)

		print("prompting game invite")
	else
		print("cannot prompt game invite: ", can_send)
	end
end

local function createPartyDisplay()
	return templates.Party.ItemTemplate:Clone()
end

local function unload()
	for _, display in ipairs(party_frame.Holder:GetChildren()) do
		if display and display:IsA("Frame") then
			display:Destroy()
		end
	end
end

local function onPartiesChanged(data: { typemarshaller.Party })
	-- create displays
	for i, party in ipairs(data) do
		local display = createPartyDisplay()
		display.Parent = party_frame.Holder

		local leader = Players:GetPlayerByUserId(party.leader_id) :: Player
		assert(leader, "Couldn't fetch party leader: " .. party.leader_id)

		local str = "%s<br/>%s</br>%s<br/>%s"

		display.Title.Text = string.format(
			str :: any,
			leader.DisplayName .. "'s Party",
			party.settings.mode,
			if party.settings.friends_only then "Friends only" else "Everyone"
		)

		task.spawn(function()
			if leader == player then
				display.Leave.ImageLabel.ImageContent = Content.fromAssetId(10709819059)
			else
				display.Leave.ImageLabel.ImageContent = Content.fromAssetId(10723434906)
			end

			shadow(display.Image)
			display.Image.ImageContent = rbx_thumb.avatar_headshot(party.leader_id, "100×100", false)
		end)

		pop(display)
		shadow(display)

		display:SetAttribute("leader", party.leader_id)
	end

	-- remove the join button from parties the player is in

	for _, display in ipairs(party_frame.Holder:GetChildren() :: typeof({ createPartyDisplay() })) do
		if display:IsA("Frame") then
			local leader_id = display:GetAttribute("leader") :: number
			if leader_id then
				if leader_id == player.UserId then
					display.Enter.Interactable = false
				else
					display.Enter.Interactable = true
				end
			end
		end
	end
end

task.spawn(function()
	while true do
		task.wait(math.random(5, 9))

		if party_canvas.Visible then
			wiggle(party_frame.InviteFriend.ImageLabel, function()
				print("completed wiggle wiggle!")
			end)
		end
	end
end)

party_frame.InviteFriend.MouseButton1Click:Connect(function()
	if debounce(party_frame.InviteFriend) then
		inviteFriend()

		pop(party_frame.InviteFriend)
	end
end)

party_frame.Create.MouseButton1Click:Connect(function()
	if debounce(party_frame.Create) then
		print("create party")

		party_frame.Create.Interactable = not party_frame.Create.Interactable

		pop(party_frame.Create)
	end
end)

events.UpdatePartyList.OnClientEvent:Connect(function(data: { typemarshaller.Party })
	unload()
	onPartiesChanged(data)
end)

return module
