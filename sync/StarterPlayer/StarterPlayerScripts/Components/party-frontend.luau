--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local StarterPlayer = game:GetService("StarterPlayer")

local Packet = require(ReplicatedStorage.Packet)
local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local audio = require(ReplicatedStorage.Modules.audio)
local confetti = require(StarterPlayer.StarterPlayerScripts.Interface.confetti)
local dialogue = require(StarterPlayer.StarterPlayerScripts.Components.dialogue)
local fade = require(StarterPlayer.StarterPlayerScripts.Interface.fade)
local future = require(ReplicatedStorage.Packages.future)
local hint = require(StarterPlayer.StarterPlayerScripts.Components.hint)
local image_mask = require(ReplicatedStorage.Modules.Imagery["image-mask"])
local lucide = require(ReplicatedStorage.Packages.lucide)
local pop = require(StarterPlayer.StarterPlayerScripts.Interface.pop)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local rbx_thumb = require(ReplicatedStorage.Modules.Serialization["rbx-thumb"])
local ripple = require(StarterPlayer.StarterPlayerScripts.Interface.ripple)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local spr = require(ReplicatedStorage.Modules.spr)
local tablekit = require(ReplicatedStorage.Packages.tablekit)
local throbber = require(StarterPlayer.StarterPlayerScripts.Components.throbber)
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

local internal_remotes = player.PlayerScripts.Remotes

local party_gui = player_gui.Party
local party_canvas = party_gui.CanvasGroup
local party_frame = party_canvas.Frame

local is_creating_party = false

shadow(party_frame.Create)
shadow(party_frame.InviteFriend)
shadow(party_frame)

local friend_invites = 0

local function inviteFriend()
	local fut = future.Try(function()
		return SocialService:CanSendGameInviteAsync(player)
	end)

	local ok, can_send = fut:Await()

	if ok and can_send then
		SocialService:PromptGameInvite(player)

		friend_invites += 1

		events.LogAnalytic:FireServer("custom", "Friend Invite", friend_invites)

		local snackbar = hint.new()
		snackbar:SetText("Invite someone to your party!")
		snackbar:SetCanDismiss(false)
		snackbar:SetExpiry(3)

		--print("prompting game invite")
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
		if not leader then
			local snackbar = hint.new()
			snackbar:SetText("Couldn't fetch party leader.")
			snackbar:SetAction(function()
				leader = Players:GetPlayerByUserId(party.leader_id) :: Player
			end, "Retry")
			snackbar:SetCanClick(true)
			snackbar:SetCanDismiss(true)
		end

		-- [party_name], [#players or max_players], [friends_only], [mode/modifiers]
		local str = "%s<br/><font weight='Regular'><font transparency='0.5'>%s<br/>%s<br/>%s</font></font>"

		local state_text = if party.state == "searching"
			then "Searching"
			elseif party.state == "in_match" then "In Match"
			else "Idle"

		-- Obsidian's Party<br/><font weight="Regular"><font transparency="0.5">+4<br/>Friends only<br/>Diddy Rush, Outrageous, Armored Fist</font></font>
		local members = {}
		for i, member in ipairs(party.members) do
			local plr = Players:GetPlayerByUserId(member)
			if plr then
				table.insert(members, plr)
			else
				warn("what happened?")
			end
		end

		-- add player images to the holder
		local member_holder = display.MemberHolder
		member_holder.BackgroundTransparency = 1
		for i, member in ipairs(members) do
			local thumb = rbx_thumb.avatar_headshot(member.UserId)

			local img = templates.Party.PlayerImage:Clone()
			img.BackgroundTransparency = 1
			-- use an image mask

			local uri = thumb.Uri

			-- TODO: expand this to support more shapes and stuff.
			local clipped = image_mask.new(uri, "Rhombus")
			clipped.Parent = img
			clipped.SizeConstraint = Enum.SizeConstraint.RelativeYY
			clipped.Size = UDim2.new(1, 0, 1, 0)

			img.Parent = member_holder
		end

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

			local avatar_headshot = rbx_thumb.avatar_headshot(player.UserId)

			--print(avatar_headshot.Uri, avatar_headshot.Object, avatar_headshot.SourceType)

			display.Image.ImageColor3 = Color3.new(255, 255, 255) -- ez fix
			display.Image.ImageContent = avatar_headshot
			display.Image.Image = avatar_headshot.Uri :: string
		end)

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

					audio:PlaySFX("error")
				else
					pop(display.Enter)

					audio:PlaySFX("success")

					local toggle = internal_remotes:WaitForChild("ToggleMatchmakingUI")

					toggle:Fire(true)
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
					else
						local toggle = internal_remotes:WaitForChild("ToggleMatchmakingUI")
						toggle:Fire(false)
					end
				else
					local ok = PartyRemotes.Leave:InvokeServer({ party_id = party.party_id })

					if not ok then
						local hint_ = hint.new()
						hint_:SetText("Failed to leave party.")
						hint_:SetCanClick(false)
					else
						local toggle = internal_remotes:WaitForChild("ToggleMatchmakingUI")
						toggle:Fire(false)
					end
				end

				-- we can no longer use any interface effects
				-- because the gui has been destroyed

				audio:PlayVariation("cancel", 1)
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
				--print("completed wiggle wiggle!")
			end)
		end
	end
end)

party_frame.InviteFriend.Activated:Connect(function()
	if debounce(party_frame.InviteFriend) then
		inviteFriend()

		pop(party_frame.InviteFriend)

		audio:PlaySFX("click")
	end
end)

party_frame.Create.Activated:Connect(function()
	if is_creating_party then
		warn("the player is still in the process of creating a party.")
		local hint_ = hint.new()
		hint_:SetText("Still creating your party...")
		hint_:SetCanClick(false)
		hint_:SetExpiry(2)
		return
	end

	if debounce(party_frame.Create) then
		ripple(party_frame.Create)

		-- use dialogues to ask the player about the kind of party they want.
		-- e.g friends only, duos or squads etc.
		-- TODO: for more complex options like modifiers, use some other module.

		is_creating_party = true

		local dialogue_ = dialogue.new()
		local pty_settings = {}

		dialogue_.Dialogs = {
			{
				Character = "System",
				Text = "What type of party would you like?",
				TypewriterOpts = {
					cps = 50,
				},
			},
			{
				Character = "System",
				Text = "Friends only?",
				Actions = {
					["Yes"] = function()
						pty_settings.friends_only = true
						print(true)
					end,
					["No"] = function()
						pty_settings.friends_only = false
						print(false)
					end,
				},
				TypewriterOpts = {
					cps = 50,
				},
			},
			{
				Character = "System",
				Text = "Allow spectators?",
				Actions = {
					["Yes"] = function()
						pty_settings.allow_spectators = true
						print(true)
					end,
					["No"] = function()
						pty_settings.allow_spectators = false
						print(false)
					end,
				},
				TypewriterOpts = {
					cps = 50,
				},
			},
			{
				Character = "System",
				Text = "Select a mode.",
				Actions = {
					["Solo"] = function()
						pty_settings.mode = "Solo"
						print("Solo")
					end,
					["Duo"] = function()
						pty_settings.mode = "Duo"
						print("Duo")
					end,
					["Squad"] = function()
						pty_settings.mode = "Squad"
						print("Squad")
					end,
				},
				TypewriterOpts = {
					cps = 50,
				},
			},
		}
		local controller = dialogue.start(dialogue_)
		controller.Dismissed:Wait()

		is_creating_party = false

		print("creating party with settings: ", tablekit.ToString(pty_settings))

		local res = PartyRemotes.Create:InvokeServer(pty_settings)

		if res and not res.success then
			local hint_ = hint.new()
			hint_:SetText(res.message or "Failed to create party.")
			hint_:SetCanClick(false)

			audio:PlaySFX("error")

			return
		else
			party_frame.Create.Interactable = false

			pop(party_frame.Create)

			audio:PlaySFX("click")

			local toggle = internal_remotes:WaitForChild("ToggleMatchmakingUI")
			toggle:Fire(false)
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

	local default_color = Color3.fromRGB(216, 197, 141)
	local dark_color = default_color:Lerp(Color3.new(), 0.5)
	print(default_color, dark_color)

	spr.target(party_frame.Create, 0.8, 5, {
		BackgroundColor3 = if in_party then dark_color else default_color,
	})

	if in_party then
		party_frame.Create.ImageLabel.Image = "rbxassetid://10734962600" -- a "cancel slash" typa image.
		ripple(party_frame.Create)
	else
		party_frame.Create.ImageLabel.Image = "rbxassetid://10734924532"
	end

	party_frame.Create.Interactable = not in_party
end)

return module
