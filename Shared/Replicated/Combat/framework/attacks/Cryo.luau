--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local damage = require(ReplicatedStorage.Combat.Strike.damage)
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local gauntlet = require(ReplicatedStorage.Combat["combat-styles"].gauntlet)
local nearest = require(ReplicatedStorage.Combat.hitbox.nearest)
local random = require(ReplicatedStorage.Utility.random)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local spr = require(ReplicatedStorage.Modules.spr)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- Cryo.luau
-- Moveset for the Cryo gauntlet combat style
-- Contains skill implementations specific to the Cryo gauntlet

local module = {
	moveset = {},
}

local pool = PoolerPlus:CreatePool("ShardPool", function()
	return fetchAsset("IceShard") :: MeshPart
end)

pool:AdaptivePreload()

local random_position = random.create()
local touch_limit = ratelimit(1, 2)

local events = ReplicatedStorage.Events

function module.moveset:M1(player: Player)
	local character = player.Character or player.CharacterAdded:Wait()

	local combat_data = events.GetPlayerCombatData:Invoke(player) :: typemarshaller.PlayerData

	local singleton = combat_data.style :: gauntlet.Gauntlet

	singleton:Activate()

	local nearest_players = nearest(character.PrimaryPart, 10)
	for _, other_player in ipairs(nearest_players) do
		singleton:OnTouched(other_player.Character.PrimaryPart)
	end
end

function module.moveset:Skill(player: Player)
	local character = player.Character
	if not character then
		return
	end

	local root_part = character.PrimaryPart :: BasePart?
	if not root_part then
		return
	end

	local mouse = player:GetMouse()
	local mouse_hit = mouse.Hit
	local direction = CFrame.new(root_part.Position, mouse_hit.Position)

	local shards_num = random.integer(8, 15)
	local shard_increment = 70 / shards_num

	local function createShard(i: number)
		local shard = pool:Get()
		shard.Parent = workspace

		-- Generate random offsets for varied positioning
		local x_offset = random_position:integer(30, 50) / 30 * i
		local y_offset = random_position:integer(30, 50) / 30 * i * 2
		local z_offset = random_position:integer(30, 50) / 30 * i

		local new_size = Vector3.new(x_offset, y_offset, z_offset)
		local shard_position = root_part.Position + direction.LookVector * (shard_increment * i)
		local new_position = shard_position + Vector3.new(0, y_offset / 2.5, 0)

		-- Animate shard growth
		spr.target(shard, 0.9, 2.1, {
			Size = new_size,
			Position = new_position,
		})

		-- Setup hit detection
		local hit_connection: RBXScriptConnection?
		hit_connection = shard.Touched:Connect(function(other_part)
			local touch_parent = other_part.Parent :: Model?

			if not touch_parent or not touch_parent:FindFirstChild("Humanoid") then
				return
			end

			if touch_parent == character then
				return
			end

			if not touch_limit(touch_parent) then
				return
			end

			local other_player = Players:GetPlayerFromCharacter(touch_parent)
			if not other_player then
				return
			end

			damage:apply({
				amount = 10,
				source = player,
				target = other_player,
			})
		end)

		return shard
	end

	-- Create all shards
	local shards = {} :: { MeshPart }
	for i = 1, shards_num do
		local shard = createShard(i)
		table.insert(shards, shard)
	end

	-- Reverse shards back after a delay
	task.delay(0.5, function()
		for i, shard in ipairs(shards) do
			spr.target(shard, 0.9, 2.1, {
				Position = shard.Position - direction.LookVector * (shard_increment * shards_num),
			})

			task.wait(0.1)
		end
	end)

	-- Clean up shards after they complete their return animation
	task.delay(shards_num + 0.6, function()
		for _, shard in ipairs(shards) do
			if shard and shard.Parent then
				pool:Return(shard)
			end
		end
		table.clear(shards)
	end)
end

function module.moveset:Ultimate(player: Player)
	-- a big ice boulder that falls from the sky and creates an AOE on impact

	--[[
	local character = player.Character
	if not character then
		return
	end

	local root_part = character.PrimaryPart :: BasePart?
	if not root_part then
		return
	end

	local boulder = fetchAsset("Snowball") :: MeshPart
	-- scale it up!

	boulder.Size *= 500
	boulder.CFrame = CFrame.new(root_part.Position + Vector3.new(0, 100, 0))
	boulder.Parent = workspace

	-- animate it falling down
	spr.target(boulder, 0.9, 2.1, {
		CFrame = CFrame.new(root_part.Position) * CFrame.Angles(0, math.rad(random.integer(0, 360)), 0),
	})
		--]]
end

return module
