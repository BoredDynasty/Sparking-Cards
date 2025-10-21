--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packet = require(ReplicatedStorage.Packet)
local bufferencoder = require(ReplicatedStorage.Packages.bufferencoder)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local profilestore = require(ReplicatedStorage.Packages.profilestore)
local profilestructure = require(ReplicatedStorage.Structures.profilestructure)
local promise = require(ReplicatedStorage.Packages.promise)
local random = require(ReplicatedStorage.Utility.random)
local retryer = require(ReplicatedStorage.Utility.retryer)

-- stores.luau
-- a wrapper for profilestore

local stores = {
	server = {},
	profile_key = "playerdata",
}

local profiles = stores.server

local player_related = profilestore.New(stores.profile_key, profilestructure)

if RunService:IsStudio() then
	player_related = player_related.Mock
end

function stores.load(player: playerMarshaller.player)
	-- Start profile session with timeout
	local profile: typeof(player_related:StartSessionAsync("", {}))?

	profile = retryer.infdelay(random.integer(0, 5), function(...)
		return player_related:StartSessionAsync(`player_{player.UserId}`, {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})
	end)

	print(typeof(profile))

	if profile then
		-- Set up profile
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		-- Handle session end
		profile.OnSessionEnd:Connect(function()
			profiles[player] = nil
			player:Kick("Session Locked, rejoin")
		end)

		if player:FindFirstAncestorOfClass("Players") then
			profiles[player] = profile

			profile.Data.LastLogin = DateTime.now().UnixTimestampMillis

			local encoded_data, size = bufferencoder:write(profile.Data)
			print(encoded_data, typeof(encoded_data), table.unpack(size))

			profile.Data = encoded_data

			profile:Reconcile()
			profile:Save()
		else
			profile:EndSession()

			warn("Data not loaded for " .. player.DisplayName .. ", session ended.")
		end
	elseif not profile then
		player:Kick("The Roblox Servers are on fire, try rejoining.")
	end

	return profile
end

function stores.get(player: playerMarshaller.player)
	local value = nil

	value = promise
		.new(function(resolve, reject)
			local profile = profiles[player]

			if not profile and profile == nil then
				Packet.SendNotification.sendTo({
					message = "Couldn't get data",
					title = "Profile not found",
					type = "error",
				}, player)

				reject("no profile???")

				return nil
			end

			print(profile)

			profile = bufferencoder:read(profile)

			resolve(profile)

			return profile
		end)
		:catch(warn)
		:expect()

	return value :: typeof(player_related:StartSessionAsync("", {}))
end

function stores.wrapSave(player: playerMarshaller.player)
	local profile = stores.get(player)
	if not profile then
		Packet.SendNotification.sendTo({
			message = "Couldn't get & save data",
			title = "Your data did not load.",
			type = "error",
		}, player)
		return
	end

	if typeof(profile.Data) == "table" then
		profile.Data = bufferencoder:write(profile.Data)
	end

	Packet.SendNotification.sendTo({
		message = "Your data has just been saved.",
		title = "Data Saved",
		type = "info",
	}, player)

	return promise.new(function()
		profile:Reconcile()
		profile:Save()
	end)
end

local function notifyWarning(player: playerMarshaller.player)
	Packet.SendNotification.sendTo({
		message = "Something went wrong with the current operation.",
		title = "Task failed.",
		type = "warning",
	}, player)
end

-- native methods

function stores:deductPrims(player: playerMarshaller.player, amount: number)
	local profile = stores.get(player)
	if not profile then
		Packet.SendNotification.sendTo({
			message = "Couldn't get data",
			title = "Your data did not load.",
			type = "error",
		}, player)
		return nil
	end

	return promise
		.new(function()
			profile.Data.Prisms -= amount
		end)
		:andThen(nil)
		:catch(function()
			notifyWarning(player)
		end)
end

function stores:addPrisms(player: playerMarshaller.player, amount: number)
	local profile = stores.get(player)
	if not profile then
		Packet.SendNotification.sendTo({
			message = "Couldn't get data",
			title = "Your data did not load.",
			type = "error",
		}, player)
		return
	end

	return promise
		.new(function()
			profile.Data.Prisms += amount
		end)
		:andThen(nil)
		:catch(function()
			notifyWarning(player)
		end)
end

function stores:deductCards(player: playerMarshaller.player, name: string, amount: number)
	local profile = stores.get(player)
	if not profile then
		Packet.SendNotification.sendTo({
			message = "Couldn't get data",
			title = "Your data did not load.",
			type = "error",
		}, player)
		return
	end

	return promise
		.new(function()
			if table.find(profile.Data.Cards, name) then
				if profile.Data.Cards[name] <= 0 then
					return
				end
				profile.Data.Cards[name] -= amount or 1
			end
		end)
		:andThen(nil)
		:catch(function()
			notifyWarning(player)
		end)
end

function stores:resetCards(player: playerMarshaller.player)
	local profile = stores.get(player)
	if not profile then
		Packet.SendNotification.sendTo({
			message = "Couldn't get data",
			title = "Your data did not load.",
			type = "error",
		}, player)
		return
	end

	return promise
		.new(function()
			profile.Data.Cards = {}
		end)
		:andThen(nil)
		:catch(function()
			notifyWarning(player)
		end)
end

function stores:addCard(player: playerMarshaller.player, name: string, amount: number)
	local profile = stores.get(player)
	if not profile then
		Packet.SendNotification.sendTo({
			message = "Couldn't get data",
			title = "Your data did not load.",
			type = "error",
		}, player)
		return
	end

	return promise
		.new(function()
			if table.find(profile.Data.Cards, name) then
				profile.Data.Cards[name] += amount or 1
			else
				profile.Data.Cards[name] = amount or 1
			end
		end)
		:andThen(nil)
		:catch(function()
			notifyWarning(player)
		end)
end

function stores:addQuest(
	player: playerMarshaller.player,
	quest: {
		name: string,
		description: string,
		inquirer_img: string | Instance, -- img id or a model
		progress: number,
		date_acquired: number, -- unix timestamp millis
		date_completed: number?,
		module: ModuleScript?,
	}
	-- we js slap the typechecking here bcuz requiring both modules would error
	-- cyclic module dependency very annoying
)
	local profile = stores.get(player)
	if not profile then
		Packet.SendNotification.sendTo({
			message = "Couldn't get data",
			title = "Your data did not load.",
			type = "error",
		}, player)
		return
	end

	return promise.new(function(resolve: () -> ...unknown)
		table.insert(profile.Data.quests, quest)

		resolve()
	end) -- hopefully we dont need a :catch()
end

-- native functions

function stores.getPrisms(player: playerMarshaller.player)
	local profile = stores.get(player)
	if not profile then
		Packet.SendNotification.sendTo({
			message = "Couldn't get data",
			title = "Your data did not load.",
			type = "error",
		}, player)
		return 0
	end

	if not profile then
		return 0
	end

	return profile.Data.Prisms
end

function stores.getQuests(player: playerMarshaller.player): {
	name: string,
	description: string,
	inquirer_img: string | Instance, -- img id or a model
	progress: number,
	date_acquired: number, -- unix timestamp millis
	date_completed: number?,
	module: ModuleScript?,
}?
	local profile = stores.get(player)
	if not profile then
		Packet.SendNotification.sendTo({
			message = "Couldn't get data",
			title = "Your data did not load.",
			type = "error",
		}, player)
		return nil
	end

	if not profile then
		return nil
	end

	return promise
		.new(function(resolve)
			resolve(profile.Data.quests)
		end)
		:expect()
end

profilestore.OnError:Connect(function(error_message, store_name, profile_key)
	warn(`profilestore error: msg:{error_message}, store_name:{store_name}: profile_key:{profile_key}`)
end)

profilestore.OnOverwrite:Connect(function(store_name: string, profile_key: string)
	print(`Overwrite has occurred for Store:{store_name}, Key:{profile_key}`)
end)

profilestore.OnCriticalToggle:Connect(function(is_critical)
	if is_critical then
		print(`ProfileStore entered critical state`)
	else
		print(`ProfileStore critical state is over`)
	end
end)

stores.mock = profilestructure

return stores
