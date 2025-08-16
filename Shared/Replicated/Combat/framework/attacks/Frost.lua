--!nonstrict

--[[
	Frost.lua
	Combat module for Frost-based abilities (e.g., FrostGauntlet).
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Packet = require(ReplicatedStorage.Packet) -- For sending effects
local PlayerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local Projectile = require(ReplicatedStorage.Modules.Projectile)
local damage = require(ReplicatedStorage.Combat.Strike.damage)
local debounce = require(ReplicatedStorage.Combat.framework.utils.debounce).new({
	M1 = 0.23,
	Skill = 10,
	Ultimate = 14,
	Support = 15,
})
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local nearest = require(ReplicatedStorage.Combat.framework.utils.nearest)
local orion = require(ReplicatedStorage.Combat.orion)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local promise = require(ReplicatedStorage.Packages.promise)
local random = require(ReplicatedStorage.Utility.random)
local timer = require(ReplicatedStorage.Modules.timer)
local trove = require(ReplicatedStorage.Packages.trove)

type Player = PlayerMarshaller.player

-- ==== Private Helper Functions for Frost Abilities ====

-- ==== Moveset Implementation ====
-- Frost.moveset[move](player, ...)
local Frost = {
	moveset = {
		M1 = nil, -- Gauntlet
		Skill = nil, -- Ice Shards
		Ultimate = nil, -- Blizzard Rush (Placeholder)
		Support = nil, -- Cryo Barrier (Placeholder)
	},
	_trove = trove.new(),
}

-- Skill: Snowball
function Frost.moveset.Skill(player: playerMarshaller.player, direction: Vector3)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart

	local snowball = fetchAsset("Snowball") :: BasePart

	print(fetchAsset("Snowball"))

	direction = direction or rootPart.CFrame.LookVector

	local position2Object = Frost._trove:Construct(Instance, "Part")
	position2Object.Transparency = 1
	position2Object.Position = rootPart.Position + Vector3.new(0, -5, 50)

	Projectile.new(snowball, {
		position1 = rootPart.Position + Vector3.new(0, 2, 0),
		position2 = position2Object.Position,
		duration = 5,
		position2Object = position2Object,
	})

	Frost._trove:Connect(snowball.Touched, function(hit)
		if not hit:IsA("BasePart") then
			return
		end
		local otherPlayer = playerMarshaller.getByName(hit.Parent.Name)
		if otherPlayer then
			damage.__call({
				amount = 4,
				source = player,
				target = otherPlayer,
			})
		end
	end)

	Frost._trove:Connect(snowball.Destroyed, function()
		Frost._trove:Clean()
	end)
end

-- Ultimate: Blizzard Rush (Placeholder)
function Frost.moveset.Ultimate(player: Player, attackData, targetInfo)
	--
end

-- Support: Cryo Barrier (Placeholder)
function Frost.moveset.Support(player: Player, attackData, targetInfo)
	--
end

return Frost
