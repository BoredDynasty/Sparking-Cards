--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local damage = require(ReplicatedStorage.Combat.Strike.damage)
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local random = require(ReplicatedStorage.Utility.random)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local spr = require(ReplicatedStorage.Modules.spr)

-- Cryo.luau

local module = {}

local pool = PoolerPlus:CreatePool("ShardPool", function()
	return fetchAsset("IceShard") :: MeshPart
end)

pool:AdaptivePreload()

local random_position = random.create()

local touch_limit = ratelimit(1, 2)

function module:Skill(player: Player)
	local character = player.Character or player.CharacterAdded:Wait()

	local mouse = player:GetMouse()

	local mouse_coordinate = mouse.Hit

	local root_part = character.PrimaryPart :: BasePart

	local start_pos = CFrame.new(root_part.Position, mouse_coordinate.Position)

	local goal = start_pos.LookVector * 70

	local shards_num = random.integer(8, 15)

	local shard_increment = 70 / shards_num

	local function createShard(i: number)
		local shard = pool:Get()
		shard.Parent = workspace

		local x, y, z =
			random_position:integer(30, 50) / 30 * i,
			random_position:integer(30, 50) / 30 * i * 2,
			random_position:integer(30, 50) / 30 * i

		local size = Vector3.zero

		local orientation = Vector3.new(
			random_position:integer(-30, 30),
			random_position:integer(-180, 180),
			random_position:integer(-30, 30)
		)

		local position = root_part.Position + start_pos.LookVector * (shard_increment * i)

		local new_size = vector.create(x, y, z)
		local new_position = shard.Position + Vector3.new(0, y / 2.5, 0)

		spr.target(shard, 0.9, 2.1, {
			Size = new_size,
			Position = new_position,
		})

		shard.Touched:Connect(function(other_part)
			local touch_parent = other_part.Parent :: Model

			if not touch_parent:FindFirstChild("Humanoid") then
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

			damage.__call({
				amount = 10,
				source = player,
				target = other_player,
			})
		end)

		return shard
	end

	local shards = {} :: { MeshPart }

	for i = 1, shards_num do
		local shard = createShard(i)

		table.insert(shards, shard)
	end

	-- reverse the shards after a short delay

	task.delay(0.5, function()
		for i, shard in ipairs(shards) do
			spr.target(shard, 0.9, 2.1, {
				Position = shard.Position - start_pos.LookVector * (shard_increment * shards_num),
			})

			task.wait(1)
		end
	end)

	task.delay(shards_num + 0.5, table.clear, shards)
end

return module
