local Party = {
	QuenedParties = {} :: {[string]: Party},
	LoadedParties = {} :: {[string]: Party},
}

local HttpsService = game:GetService("HttpService")

local TeleportService = game:GetService("TeleportService")

local RunService = game:GetService("RunService")

local Players = game:GetService("Players")

local ServerScriptService = game:GetService("ServerScriptService")

local DataManager = ServerScriptService:WaitForChild("DataManager")

local Modules = ServerScriptService:WaitForChild("Modules")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LobbyRemotes = ReplicatedStorage:WaitForChild("LobbyRemotes")

local SafeTeleport = require(Modules:WaitForChild("SafeTeleport"))

local PlayerData = require(DataManager:WaitForChild("Data"))

Party.__index = Party

--[[ Party Remotes ]]


local JoinParty = LobbyRemotes:WaitForChild("JoinParty")

local LeaveParty = LobbyRemotes:WaitForChild("LeaveParty")

local UpdatePartyList = LobbyRemotes:WaitForChild("UpdatePartyList")

local UpdatePartySettings = LobbyRemotes:WaitForChild("UpdatePartySettings")

local StartMatchEvent = LobbyRemotes:WaitForChild("StartParty")

local ShowLoadingScreenEvent = LobbyRemotes:WaitForChild("ShowLoadingScreen")

local ClosePartyInterface = LobbyRemotes:WaitForChild("ClosePartyInterface")

local Configuration = require(ServerScriptService:WaitForChild("CONFIGURATION"))

-- [[ Stores ]]

local DataStoreService = game:GetService("DataStoreService")

local MemoryStoreService = game:GetService("MemoryStoreService")

local PartyIDStore = DataStoreService:GetDataStore("PartyIDStore")

local DataManager = ServerScriptService:WaitForChild("DataManager")

local ProfileStore = require(DataManager:WaitForChild("ProfileStore"))

local PartyData = ProfileStore.New("PartyData", {})

local ReserveIDKeys = MemoryStoreService:GetHashMap("ReserveIDKeys")

export type Gamemodes = "CAMPAIGN" | "SANDBOX" | "ENDLESS" | "PVPBATTLE" | "ZOMBIESURVIVAL"

export type PartySettings = {
	Modifiers: {},
	Gamemode:Gamemodes,
	Sandbox: boolean,
	MaxPlayers: number,
	Name: string,
	Act: string,
	Layer: string,
	Stage: string,
	Blacklist: { number },
	Whitelist: { number },
	FriendsOnly: boolean,
	BlacklistEnabled: boolean,
	WhitelistEnabled: boolean,
	SaveToFile: boolean,
	SpectatingAllowed: boolean
}

export type Party = {
	Owner: number,
	PartyMembers: { number },
	TeleportedMembers: { number },
	PartyID : string,
	PrivServerID: string,
	JoinCode: string,
	PartySettings: PartySettings,
	ProgressionIndex: number, -- the entire progress in a stage can be represented with a number
	
	PlayerBackpacks: {[number] : {}},
	
	DisconnectConnections: { RBXScriptConnection },
	CurrentProfile: typeof(PartyData:StartSessionAsync("", { Party }))?,
	
	UpdateBackpacks: (self:Party, BackpackList: {[Player]: {}}) -> nil,
	RefreshReserveAccessCode: (self:Party) -> nil,
	GetClientPartyData: (self:Party) -> nil,
	Publish: (self:Party) -> nil,
	AddPlayer: (self:Party, Player:Player) -> boolean,
	RemovePlayer: (self:Party, Player:Player) -> boolean,
	GenerateSpectateLink: (self:Party) -> nil,
	GenerateJoinLink: (self:Party) -> nil,
	Reconfigure: (self:Party, NewSettings: PartySettings) -> nil,
	Teleport: (self:Party) -> nil,
	Save: (self:Party) -> nil,
	Cleanup: (self:Party) -> nil,
	Destroy: (self:Party) -> nil,
}

local DEEPLINKURL = "https://www.roblox.com/games/start?placeId=%d&launchData=%s"

function Party.GetFromID(ID: string): Party
	local PublishedID = Party.LoadedParties[ID]

	if not PublishedID then
		return Party.QuenedParties[ID]
	else
		return PublishedID
	end
end

function Party.create(Owner: Player): Party
	local self: Party = setmetatable({} :: any, Party)

	for _, NextParty:Party in pairs(Party.QuenedParties) do
		if table.find(NextParty.PartyMembers, Owner.UserId) then
			return nil :: any
		end
	end

	self.PartyID = HttpsService:GenerateGUID(false)

	self.PartyMembers = {Owner.UserId}
	
	self.TeleportedMembers = {}
	
	self.DisconnectConnections = {}
	
	self:RefreshReserveAccessCode()

	self.PlayerBackpacks = {}
	
	self.Owner = Owner.UserId

	self.PartySettings = {
		Modifiers = {},
		Name = Owner.DisplayName .."'s Party",
		Act = Configuration.default_act,
		Layer = Configuration.default_layer,
		Stage = Configuration.default_stage,
		Blacklist = {},
		Whitelist = {},
		FriendsOnly = false,
		BlacklistEnabled = false,
		WhitelistEnabled = false,
		MaxPlayers = 8,
		SaveToFile = false,
		SpectatingAllowed = false,
		Gamemode = "CAMPAIGN",
	}

	UpdatePartyList:FireAllClients(Party.GetParties())
	
	Party.QuenedParties[self.PartyID] = self
	
	self.DisconnectConnections[Owner.UserId] = Owner.Destroying:Once(function()
		self:Destroy()
	end)
	
	return self
end

function Party.LoadFromReserveID(OverrideID:number?)
	
	local ReserveID = OverrideID or game.PrivateServerId
	
	local success, err
	
	local FoundPartyData: Party
	
	while not success do
		success, err = pcall(function()
			FoundPartyData = ReserveIDKeys:GetAsync(ReserveID)
		end)

		if not success then
			task.wait(1)
		else
			if FoundPartyData then
				FoundPartyData = HttpsService:JSONDecode(FoundPartyData)
			else
				return nil
			end
		end
	end
	
	local self: Party = setmetatable({} :: any, Party)
	
	for index, value in FoundPartyData do
		self[index] = value
	end
	
	return self
	
end

function Party.LoadFromKey(Key: string)
	local FoundPartyProfile = PartyData:StartSessionAsync(Key, {})

	local PartyData = FoundPartyProfile.Data :: Party

	local self: Party = setmetatable({} :: any, Party)

	self.Owner = PartyData.Owner
	self.PartySettings = PartyData.PartySettings
	self.PartyID = Key
	self:RefreshReserveAccessCode()
	self.PartyMembers = PartyData.PartyMembers

	self.CurrentProfile = FoundPartyProfile

	return self
end

function Party.RefreshReserveAccessCode(self:Party)
	local success, errMessage = pcall(function()
		local JoinCode, PrivServerID = TeleportService:ReserveServer(Configuration.GAMEPLACEID)
		
		self.JoinCode = JoinCode
		self.PrivServerID = PrivServerID
		
	end)
end

function Party.Publish(self:Party)
	Party.LoadedParties[self.PartyID] = self
	
	UpdatePartyList:FireAllClients(Party.GetParties())
	
	local FoundPlayer = Players:GetPlayerByUserId(self.Owner)
		
	if FoundPlayer then
		local FoundPlayerData = PlayerData.Profiles[FoundPlayer]

		if FoundPlayerData and FoundPlayerData.Data then
			FoundPlayerData["Data"].ActiveParty = self.PrivServerID

			FoundPlayerData:Save()
		end
	end
	
end

function Party.Reconfigure(self:Party, NewSettings: PartySettings)
	self.PartySettings = NewSettings
end

function Party.GetParties()
	local LoadedParties = Party.LoadedParties

	local Send = {}

	for _, NextParty in pairs(Party.LoadedParties) do
		local NewSend = NextParty:GetClientPartyData()		
		table.insert(Send, NewSend)
	end

	return Send
end

function Party.GetClientPartyData(self:Party)
	local NewSend = {}

	NewSend.Owner = self.Owner
	NewSend.PartyID = self.PartyID
	NewSend.PartyMembers = self.PartyMembers
	NewSend.PartySettings = self.PartySettings

	return NewSend
end

function Party.AddPlayer(self:Party, Player:Player): boolean
	local FoundPlayer = table.find(self.PartyMembers, Player.UserId)

	local BlacklistEnabled = self.PartySettings.BlacklistEnabled
	local WhitelistEnabled = self.PartySettings.WhitelistEnabled

	if BlacklistEnabled then
		local Blacklist = self.PartySettings.Blacklist

		local PlayerFound = table.find(Blacklist, Player.UserId)

		if PlayerFound then
			return false
		end
	end

	if WhitelistEnabled then
		local Whitelist = self.PartySettings.Whitelist

		local PlayerFound = table.find(Whitelist, Player.UserId)

		if not PlayerFound then
			return false
		end
	end

	print(Player)

	if not FoundPlayer then
				
		local FoundPlayerData = PlayerData.Profiles[Player]
		
		if FoundPlayerData and FoundPlayerData.Data then
			FoundPlayerData["Data"].ActiveParty = self.PrivServerID

			FoundPlayerData:Save()
		end
		
		table.insert(self.PartyMembers, Player.UserId)

		self.DisconnectConnections[Player.UserId] = Player.Destroying:Once(function()
			self:RemovePlayer(Player)
		end)

		return true
	end

	UpdatePartyList:FireAllClients(Party.GetParties())

	return false
end

function Party.RemovePlayer(self:Party, Player: Player): boolean
	local FoundPlayer = table.find(self.PartyMembers, Player.UserId)

	local FoundConnection = self.DisconnectConnections[Player.UserId]

	if FoundConnection then
		FoundConnection:Disconnect()
	end

	if FoundPlayer then

		local PlayerObject = Players:GetPlayerByUserId(FoundPlayer)

		if PlayerObject then
			ClosePartyInterface:FireClient(PlayerObject)
		end

		table.remove(self.PartyMembers, FoundPlayer)
			
		local FoundPlayerData = PlayerData.Profiles[Player]
		
		if FoundPlayerData and FoundPlayerData.Data then
			FoundPlayerData["Data"].ActiveParty = ""

			FoundPlayerData:Save()
		end
		
		return true
	end
	
	UpdatePartyList:FireAllClients(Party.GetParties())

	return false
end

function Party.GenerateSpectateLink(self:Party)
	local Encoded = HttpsService:JSONEncode({
		["PartyID"] = self.PartyID,
		["JoinMode"] = "SPECTATE"
	})

	local DEEPLINK = DEEPLINKURL:format(game.PlaceId, Encoded)

	return DEEPLINK
end

function Party.GenerateJoinLink(self:Party)
	local Encoded = HttpsService:JSONEncode({
		["PartyID"] = self.PartyID,
		["JoinMode"] = "SPECTATE"
	})

	local DEEPLINK = DEEPLINKURL:format(game.PlaceId, Encoded)

	return DEEPLINK
end

function Party.UpdateBackpacks(self:Party, BackpackList: {[Player]: {}})
	for player, backpack in BackpackList do
		self.PlayerBackpacks[player.UserId] = backpack
	end
	
	self:Save()
end

function Party.Save(self:Party)	
	if not self.PartySettings.SaveToFile then
		return nil
	end
	
	if not self.CurrentProfile then
		self.CurrentProfile = PartyData:StartSessionAsync(self.PartyID, {})
	end

	if self.CurrentProfile then
		local PartyData = table.clone(self)

		PartyData.CurrentProfile = nil
		PartyData.DisconnectConnections = nil

		self.CurrentProfile["Data"] = HttpsService:JSONEncode(PartyData)

		self.CurrentProfile:Save()
	end
end

function Party.Teleport(self:Party)
	
	for _, connection in self.DisconnectConnections do
		connection:Disconnect()
	end
	
	if not RunService:IsStudio() then
	
		self:RefreshReserveAccessCode()

		local GatheredPlayers = {}
		
		if self.PartySettings["SaveToFile"] then
			self:Save()
		end
		
		for _, userId in pairs(self.PartyMembers) do
			table.insert(GatheredPlayers, Players:GetPlayerByUserId(userId))
		end
		
		for _, player in pairs(GatheredPlayers) do
			table.insert(self.TeleportedMembers, player.UserId)
			
			local FoundPlayerData = PlayerData.Profiles[player]

			if FoundPlayerData and FoundPlayerData.Data then
				FoundPlayerData["Data"].ActiveParty = self.PrivServerID

				FoundPlayerData:Save()
			end
			
		end
		
		local PartyData = table.clone(self)
		
		self.CurrentProfile = nil :: any
		self.DisconnectConnections = nil :: any
		
		local success, err

		while not success do
			success, err = pcall(function()					
				return ReserveIDKeys:SetAsync(self.PrivServerID, HttpsService:JSONEncode(PartyData), 3888000)
			end)

			if not success then
				task.wait(1)
			else
				break
			end
		end

		local TeleportOptions = Instance.new("TeleportOptions")

		TeleportOptions.ReservedServerAccessCode = self.JoinCode
		
		Party.LoadedParties[self.PartyID] = nil :: any

		for _, player in pairs(self.PartyMembers) do
			local FoundPlayer = Players:GetPlayerByUserId(player)

			if FoundPlayer then
				ShowLoadingScreenEvent:FireClient(FoundPlayer)
			end
		end

		SafeTeleport(Configuration.GAMEPLACEID, GatheredPlayers, TeleportOptions)

		self:Cleanup()
	else
		print("Teleporting Mock")
	end
end

function Party.Cleanup(self:Party, RemoveActiveParty: boolean?)

	Party.QuenedParties[self.PartyID] = nil
	Party.LoadedParties[self.PartyID] = nil

	for _, partyMember in pairs(self.PartyMembers) do
		local FoundPlayer = Players:GetPlayerByUserId(partyMember)

		if FoundPlayer then
						
			if RemoveActiveParty then
				local FoundPlayerData = PlayerData.Profiles[FoundPlayer]

				if FoundPlayerData and FoundPlayerData.Data then
					FoundPlayerData["Data"].ActiveParty = ""
				end
			end
			
			ClosePartyInterface:FireClient(FoundPlayer)
			--piece of SHI
		end
	end

	for index, _ in pairs(self) do
		self[index] = nil
	end

	setmetatable(self, nil)

	self = nil :: any

	UpdatePartyList:FireAllClients(Party.GetParties())
end

function Party.Destroy(self:Party)
	PartyData:RemoveAsync(self.PartyID)

	if self.PrivServerID then
		ReserveIDKeys:RemoveAsync(self.PrivServerID)
	end
	
	self:Cleanup()
end

return Party