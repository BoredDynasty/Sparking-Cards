--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- animate.luau
-- wip

--[[
    Animation utility module for playing animations on characters
    Provides a clean API for loading and playing animations
]]

local module = {}

type config = {
	fade_time: number?,
	weight: number?,
	priority: Enum.AnimationPriority?,
	stop_others: boolean?,
	loop: boolean?,
}
type animation_group = { name: string, members: { string }, default_config: config? }

-- variables

local player = playerMarshaller.get()
local character = characterMarshaller.get(player)

local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local animator = humanoid:WaitForChild("Animator") :: Animator

module.animations = {}
module.animation_tracks = {} :: { [string]: AnimationTrack }
module._connections = {}
module._animation_groups = {} :: { [string]: animation_group }

-- update the character when died

-- i dont usually use "do" statements; however,
-- i dont like too many scopes
do
	local died = humanoid.Died
	died:Connect(function(...: any)
		character = characterMarshaller.get(player)
		animator = nil
		-- load animations
		-- cache
	end)
end

local function deep_clone<A>(dict: A): A
	local clone_table = {}

	if not dict or not dict.animations then
		warn("animations table is nil or dict is invalid")

		return clone_table
	end

	if type(dict.animations) ~= "table" then
		warn(" animations is not a table, type is:", typeof(dict.animations))

		return clone_table
	end

	for i, animation in pairs(dict.animations) do
		if typeof(animation) ~= "Instance" then
			warn(`invalid animation object for "{i}"`)

			return clone_table
		end

		if not animation:IsA("Animation") then
			warn(`invalid animation object for "{i}"`)

			return clone_table
		end

		local ok, cloned = pcall(animation.Clone, animation)

		if ok then
			clone_table[i] = cloned
		else
			warn(`failed to clone animation "{i}"`)
		end
	end

	return clone_table
end

function module:IsAnimationLoaded(name: string)
	local track = module.animation_tracks[name]
	if not track then
		return false
	end

	return track.Length > 0
end

function module:CreateGroup(name: string, members: { string }, default_config: config?)
	module._animation_groups[name] = {
		name = name,
		members = members,
		default_config = default_config or {},
	}

	print("created animation group: ", module._animation_groups[name])
end

function module:PlayGroup(name: string, config: config?)
	local group = module._animation_groups[name]
	if not group then
		warn("group: ", name, " not found.")
	end

	group.default_config = group.default_config or {}

	local combined_config = table.clone(group.default_config)

	-- reconcile
	if config then
		for k, v in pairs(config) do
			combined_config[k] = v
		end
	end

	local result = {}

	for i, animation_name in ipairs(group.members) do
		local track = module:PlayAnimation(animation_name, combined_config) :: AnimationTrack

		result[animation_name] = track

		if track then
			local completed = SignalPlus() :: SignalPlus.Signal<>

			local conn = nil
			conn = track.Stopped:Connect(function()
				completed:Fire()

				if conn then
					conn:Disconnect()
				end
			end)

			completed:Wait()
		else
			warn(`{animation_name} failed to play in group {group.name}`)
		end
	end

	return result
end

function module:PlayAnimations(names: { string }, config: config?)
	local results = {}

	for i, name in ipairs(names) do
		results[name] = module:PlayAnimation(name, config)
	end

	return results
end

function module:StopAnimation(names: { string }, fade_time: number)
	local results = {}

	for i, name in ipairs(names) do
		results[name] = module:StopAnimation(name, fade_time)
	end

	return results
end

function module:GetProgress(name: string)
	local data = module.animation_tracks[name]
	local track = data.track

	if not data or not track then
		return 0
	end

	local time_position = track.TimePosition
	local length = track.Length

	local progress = time_position / length

	return progress
end

function module:GetAnimationsProgress(names: { string })
	local results = {}

	for i, name in ipairs(names) do
		local progress = module:GetProgress(name)

		results[name] = {
			progress = progress,
		}
	end
end
