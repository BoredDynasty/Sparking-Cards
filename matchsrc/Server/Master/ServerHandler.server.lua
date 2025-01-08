--!nonstrict

print("Server ID [ " .. game.JobId .. " ]: Match")

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService = game:GetService("AnalyticsService")
local ServerStorage = game:GetService("ServerStorage")

local DataStoreClass = require(ReplicatedStorage.Classes.DataStoreClass)
local RewardsClass = require(ReplicatedStorage.Classes.RewardsClass)
local SafeTeleporter = require(ReplicatedStorage.Modules.SafeTeleporter)
local MapSettings = require(ServerStorage.Modules.MapSettings)
local MapApply = require(ServerStorage.Modules.MapApply)

local DialogRE: RemoteEvent = ReplicatedStorage.RemoteEvents.NewDialogue

print("Economic Analytics are enabled.")
print("Custom Analytics are enabled.")

local elaspedTime = 0

local function touchDialog(otherPart: BasePart, player)
	if not player then
		player = Players:GetPlayerFromCharacter(otherPart.Parent)
	end
	local message = otherPart:GetAttribute("TouchDialog") or otherPart:GetAttribute("DialogText")
	if message then
		DialogRE:FireClient(player, message)
		print(`Sending Dialog to {player.DisplayName}: {message}`)
	end
end

local function chatted(player, message)
	if string.find(message, "@quit") or string.find(message, "@ggs") then
		player:Kick("You've quitted the match. ggs!")
	end
end

local function newMatchID(HTTP: HttpService)
	return HTTP:GenerateGUID(false)
end

local matchID = newMatchID(game:GetService("HttpService"))
game:SetAttribute("matchID", matchID)

local function decideMap(player)
	local map = MapSettings.newMap("Classic")
	MapApply(map, player)
end

local function onPlayerAdded(player: Player)
	DataStoreClass.PlayerAdded(player)
	local customFields = {
		[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = "SPARKING-MATCH",
	}
	AnalyticsService:LogOnboardingFunnelStepEvent(player, 1, "Player Joined", customFields)
	player.Character.Animate.walk.WalkAnim.AnimationId = "rbxassetid://14512867805"
	player.CharacterRemoving:Connect(function(character)
		task.defer(character.Destroy, character)
	end)
	player.Chatted:Connect(function(message)
		chatted(player, message)
	end)
	-- // Spawning the player to the map
	decideMap(player)
end

local function onPlayerRemoving(player: Player)
	DataStoreClass.PlayerRemoving()
	local customFields = {
		[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = "SPARKING-MATCH",
	}
	AnalyticsService:LogOnboardingFunnelStepEvent(player, 1, "Player Leaving", customFields)
	player:Destroy() -- performance reasons

	local winner = Players:GetPlayers()
	for _, _player: Player in winner do
		local addCards = elaspedTime / 5
		RewardsClass(player, addCards)
		customFields = {
			[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = `Winner: {_player.Name} AKA: {_player.DisplayName}`,
			[Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = `{_player.UserId}`,
			[Enum.AnalyticsCustomFieldKeys.CustomField03.Name] = `Earnings: {addCards}`,
		}
		AnalyticsService:LogProgressionCompleteEvent(_player, "Win", 5, "Card-Fighting", customFields)
		DataStoreClass.SaveData(_player)
		task.wait(15)
		SafeTeleporter(6125133811, _player)
	end
end

local function addDestinations()
	local cooldown = {}
	return task.spawn(function()
		for _, tag in pairs(CollectionService:GetTagged("TeleportPart")) do
			local Teleport: BasePart = tag
			local destination = Teleport:GetAttribute("Destination")
			Teleport.ClickDetector.MouseClick:Connect(function(player)
				player.Character.HumanoidRootPart:PivotTo(destination)
			end)
		end
		for _, tag in CollectionService:GetTagged("DialogTrigger") do
			local otherPart: BasePart? = tag
			otherPart.Touched:Connect(function(player)
				if not table.find(cooldown, player) then
					table.insert(cooldown, player)
					touchDialog(otherPart, player)
					task.wait(10)
					table.remove(cooldown, player)
				end
			end)
			if otherPart:FindFirstChildOfClass("ClickDetector") then
				local clickDetect = otherPart:FindFirstChildOfClass("ClickDetector")
				clickDetect.MouseClick:Connect(function(player)
					if not table.find(cooldown, player) then
						table.insert(cooldown, player)
						touchDialog(otherPart, player)
						task.wait(10)
						table.remove(cooldown, player)
					end
				end)
			end
		end
	end)
end

local function startTimer(remote: UnreliableRemoteEvent)
	local Timer = require(ReplicatedStorage.Modules.Timer)
	local newTimer = Timer.new()
	-- local frequency = 0
	-- loaded.OnClientEvent:Connect(function()
	-- frequency = frequency + 1
	-- end)
	-- if frequency >= 2 then
	newTimer:Start()
	while true do
		task.wait(0.5)
		local elasped = newTimer:FormatTime()
		game:SetAttribute("elaspedTime", elasped)
		remote:FireAllClients(elasped, newTimer)
	end
	--end
	return newTimer
end

DataStoreClass.StartBindToClose()
startTimer(ReplicatedStorage.RemoteEvents.UpdateTime)
addDestinations()
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
