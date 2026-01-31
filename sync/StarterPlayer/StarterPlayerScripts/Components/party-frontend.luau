--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local StarterPlayer = game:GetService("StarterPlayer")

local Packet = require(ReplicatedStorage.Packet)
local confetti = require(StarterPlayer.StarterPlayerScripts.Interface.confetti)
local future = require(ReplicatedStorage.Packages.future)
local hint = require(StarterPlayer.StarterPlayerScripts.Components.hint)
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
local PartyRemotes = events:WaitForChild("Party")

local party_gui = player_gui.Party
local party_canvas = party_gui.CanvasGroup
local party_frame = party_canvas.Frame

shadow(party_frame.Create)
shadow(party_frame.InviteFriend)
shadow(party_frame)

local function inviteFriend()
	local fut = future.Try(function()
		return SocialService:CanSendGameInviteAsync(player)
	end)

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

		-- [party_name], [#players or max_players], [friends_only], [mode/modifiers]
		local str = "%s<br/><font weight='Regular'><font transparency='0.5'>%s<br/>%s<br/>%s</font></font>"

		local state_text = if party.state == "searching"
			then "Searching"
			elseif party.state == "in_match" then "In Match"
			else "Idle"

		-- Obsidian's Party<br/><font weight="Regular"><font transparency="0.5">+4<br/>Friends only<br/>Diddy Rush, Outrageous, Armored Fist</font></font>

		future.Try(function()
			display.Title.Text = string.format(
				str :: any,
				leader.DisplayName .. "'s Party",
				(
					#party.members .. "/" .. party.settings.mode :: string == "Solo" and "1"
					or party.settings.mode == "Duo" and "2"
					or "4"
				),
				if party.settings.friends_only then "Friends only" else "Everyone",
				state_text
			)
		end)

		task.spawn(function()
			if leader == player then
				display.Leave.ImageLabel.ImageContent = Content.fromAssetId(10709819059)
			else
				display.Leave.ImageLabel.ImageContent = Content.fromAssetId(10723434906)
			end

			shadow(display.Image)

			local avatar_headshot = rbx_thumb.avatar_headshot(leader.UserId)

			print(avatar_headshot.Uri, avatar_headshot.Object, avatar_headshot.SourceType)

			display.Image.ImageContent = avatar_headshot
		end)

		pop(display)
		shadow(display)

		display:SetAttribute("leader", leader.UserId)
		-- wire enter/leave buttons
		display.Enter.MouseButton1Click:Connect(function()
			if debounce(display.Enter) then
				local leader_id = display:GetAttribute("leader") :: number
				if leader_id == player.UserId then
					return
				end

				local ok = PartyRemotes.Join:InvokeServer({ party_id = party.party_id })

				if not ok then
					local hint_ = hint.new()
					hint_:SetText("Failed to join party.")
					hint_:SetCanClick(false)
				else
					pop(display.Enter)
				end
			end
		end)

		display.Leave.MouseButton1Click:Connect(function()
			if debounce(display.Leave) then
				local leader_id = display:GetAttribute("leader") :: number

				if leader_id == player.UserId then
					local ok = PartyRemotes.Delete:InvokeServer({ party_id = party.party_id })

					if not ok then
						local hint_ = hint.new()
						hint_:SetText("Failed to delete your party.")
						hint_:SetCanClick(false)
					end
				else
					local ok = PartyRemotes.Leave:InvokeServer({ party_id = party.party_id })

					if not ok then
						local hint_ = hint.new()
						hint_:SetText("Failed to leave party.")
						hint_:SetCanClick(false)
					end
				end

				-- we can no longer use any interface effects
				-- because the gui has been destroyed
			end
		end)
	end

	-- remove the join button from parties the player is in

	for _, display in ipairs(party_frame.Holder:GetChildren() :: typeof({ createPartyDisplay() })) do
		if display:IsA("Frame") then
			future.Try(function()
				local leader_id = display:GetAttribute("leader") :: number
				if leader_id then
					if leader_id == player.UserId then
						display.Enter.Interactable = false
					else
						display.Enter.Interactable = true
					end
				end
			end)
		end
	end
end

task.spawn(function()
	while true do
		task.wait(math.random(3, 5))

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
		local res = PartyRemotes.Create:InvokeServer()

		if res and not res.success then
			local hint_ = hint.new()
			hint_:SetText(res.message or "Failed to create party.")
			hint_:SetCanClick(false)
		else
			party_frame.Create.Interactable = false

			pop(party_frame.Create)
		end
	end
end)

events.UpdatePartyList.OnClientEvent:Connect(function(data: { typemarshaller.Party })
	unload()
	onPartiesChanged(data)

	-- if the player is in a party, disable the create button
	local in_party = false

	for _, party in ipairs(data) do
		for _, member_id in ipairs(party.members) do
			if member_id == player.UserId then
				in_party = true
				break
			end
		end
		if in_party then
			break
		end
	end

	party_frame.Create.Interactable = not in_party
end)

return module
