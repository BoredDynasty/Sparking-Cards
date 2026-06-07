--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local future = require(ReplicatedStorage.Packages.future)
local hydration = require(ReplicatedStorage.Utility.hydration)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local trove = require(ReplicatedStorage.Packages.trove)
local url = require(ReplicatedStorage.Modules.Serialization.url)

-- temporary-layercollector.luau
-- a utility for creating a temporary ScreenGui.
-- managed by trove

local module = {}

local _trove = trove.new()

local player = playerMarshaller.get()
local player_gui = player.PlayerGui

function module.new(name: string?)
	local layer_collector = _trove:Construct(Instance, "ScreenGui", player_gui)
	hydration(layer_collector) {
		IgnoreGuiInset = true,
		Name = name or url.generateShortUniqueId(),
		Parent = player_gui,
	}

	return layer_collector
end

function module:Remove(layer_collector: LayerCollector)
	return future.Try(_trove.Remove, _trove, layer_collector :: any)
end

return module
