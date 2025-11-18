--!nonstrict
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local promise = require(ReplicatedStorage.Packages.promise)
local rbx_thumb = require(ReplicatedStorage.Modules.Serialization["rbx-thumb"])

-- leaderboard.luau

-- this code is stinky

local player = playerMarshaller.get()
local playerGui = player.PlayerGui

export type leaderboardGui = ScreenGui & {
	Leaderboard: Frame & {
		LeaderboardInfo: Frame & {
			Stats: Frame & {
				Stat1: TextLabel,
				Stat2: TextLabel,
			},
			PlayersTag: TextLabel,
		},
		ScrollingFrame: ScrollingFrame,
	},
	PlayerSelection: ScrollingFrame & {
		ChoiceList: choiceList,
		UserInformation: Frame & {
			Main: Frame & {
				DisplayName: TextLabel,
				Username: TextLabel,
			},
			UserAvatar: ImageLabel,
		},
	},
}

export type choiceList = {
	AddFriend: TextButton,
	BlockUser: TextButton,
	UnblockUser: TextButton,
	Close: TextButton,
	Unfriend: TextButton,
	ViewAvatar: TextButton,
}

export type PlayerTemplate = TextButton & {
	Info: Frame & {
		Avatar: ImageLabel,
		DisplayName: TextLabel,
	},
	Stats: Frame & {
		Stat1: TextLabel,
		Stat2: TextLabel,
	},
}

local leaderboard = playerGui:WaitForChild("Leaderboard") :: leaderboardGui

local self = {
	selecting = observer.new(false),
	selecting_conns = {} :: { RBXScriptConnection },
}

local function getAllProfiles()
	return promise.new(function(resolve)
		local getAllProfilesRF = ReplicatedStorage.Events:WaitForChild("GetAllProfiles") :: RemoteFunction

		local profiles =
			getAllProfilesRF:InvokeServer() :: { [Player]: { ["Data"]: profilestructure.profile } }

		resolve(profiles)
	end)
end

function self:PlayerSelected(otherPlayer: Player)
	if self.selecting:Get() then
		for i, conn in ipairs(self.selecting_conns) do
			conn:Disconnect()
		end

		table.clear(self.selecting_conns)

		return
	end

	self.selecting:Set(true)

	local selection_position_old = UDim2.new(1, 0, 0, 10)
	local selection_position_new = UDim2.new(1, -590, 0, 10)

	local player_selection = leaderboard.PlayerSelection

	-- is the player friends with the other player?
	local isFriend = player:IsFriendsWith(otherPlayer.UserId)
	player_selection.ChoiceList.AddFriend.Visible = not isFriend
	player_selection.ChoiceList.Unfriend.Visible = isFriend
	player_selection.ChoiceList.BlockUser.Visible = true
	player_selection.ChoiceList.UnblockUser.Visible = false

	if player == otherPlayer then
		player_selection.ChoiceList.AddFriend.Visible = false
		player_selection.ChoiceList.Unfriend.Visible = false
		player_selection.ChoiceList.BlockUser.Visible = false
		player_selection.ChoiceList.UnblockUser.Visible = false
	end

	player_selection.Visible = true

	player_selection.Position = selection_position_old

	TweenPlus(player_selection, {
		Position = selection_position_new,
	}, {
		Time = 0.3,
		EasingStyle = "Quad",
		EasingDirection = "Out",
	}):Start()

	player_selection.UserInformation.Main.DisplayName.Text = otherPlayer.DisplayName
	player_selection.UserInformation.Main.Username.Text = "@" .. otherPlayer.Name

	task.spawn(function()
		local thumbnail = rbx_thumb.avatar_headshot(otherPlayer.UserId, "420×420", true)
		player_selection.UserInformation.UserAvatar.ImageContent = thumbnail
	end)

	local choice_list = player_selection.ChoiceList
	local tween_info = {
		Time = 0.15,
		EasingStyle = "Quad",
		EasingDirection = "In",
	}

	local function revertSelection()
		return promise.new(function(resolve)
			local tween = TweenPlus(player_selection, {
				Position = selection_position_old,
			}, tween_info)

			tween:Start()

			task.delay(0.15, function()
				player_selection.Visible = false
				self.selecting:Set(false)
				resolve()
			end)
		end)
	end

	table.insert(
		self.selecting_conns,
		choice_list.Close.MouseButton1Click:Connect(function()
			revertSelection()
		end)
	)
	table.insert(
		self.selecting_conns,
		choice_list.AddFriend.MouseButton1Click:Connect(function()
			StarterGui:SetCore("PromptSendFriendRequest", otherPlayer)
			revertSelection()
		end)
	)
	table.insert(
		self.selecting_conns,
		choice_list.Unfriend.MouseButton1Click:Connect(function()
			StarterGui:SetCore("PromptUnfriend", otherPlayer)
			revertSelection()
		end)
	)
	table.insert(
		self.selecting_conns,
		choice_list.BlockUser.MouseButton1Click:Connect(function()
			StarterGui:SetCore("PromptBlockPlayer", otherPlayer)
			revertSelection()
		end)
	)
	table.insert(
		self.selecting_conns,
		choice_list.UnblockUser.MouseButton1Click:Connect(function()
			StarterGui:SetCore("PromptUnblockPlayer", otherPlayer)
			revertSelection()
		end)
	)
	table.insert(
		self.selecting_conns,
		choice_list.ViewAvatar.MouseButton1Click:Connect(function()
			GuiService:InspectPlayerFromUserId(otherPlayer.UserId)
		end)
	)
end

function self:UpdateStatistics(template: PlayerTemplate, otherPlayer: Player)
	local statistics = template.Stats
	local ok, profiles = getAllProfiles():await()
	if not ok then
		return
	end

	local otherPlayerProfile = profiles[otherPlayer] :: { ["Data"]: profilestructure.profile }
	if not otherPlayerProfile then
		return
	end

	statistics.Stat1.Text = tostring(otherPlayerProfile.Data.victories or 0) .. " wins"
	statistics.Stat2.Text = otherPlayerProfile.Data.Level or "Bronze I"
end

-- ofc
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
