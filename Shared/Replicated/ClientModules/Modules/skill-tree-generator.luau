--!strict

-- skill-tree-generator.luau
-- Generates a skill tree with organic branching and deterministic randomness.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SkillTreeGenerator = {}
SkillTreeGenerator.__index = SkillTreeGenerator

export type SkillNodeData = {
	name: string,
	next: { string },
}

export type SkillTreeData = { [string]: SkillNodeData }

-- Dummy data for testing branching and converging nodes
local DUMMY_DATA: SkillTreeData = {
	["Root"] = { name = "Root", next = { "A", "B", "C" } },
	["A"] = { name = "A", next = { "D", "E" } },
	["B"] = { name = "B", next = { "E", "F" } },
	["C"] = { name = "C", next = { "F", "G" } },
	["D"] = { name = "D", next = {} },
	["E"] = { name = "E", next = { "H" } },
	["F"] = { name = "F", next = { "H" } },
	["G"] = { name = "G", next = {} },
	["H"] = { name = "H", next = {} },
}

local NODE_SIZE = Vector2.new(50, 50)
local PADDING = 20
local MIN_DISTANCE = 80
local MAX_DISTANCE = 120
local MAX_RETRIES = 100

type NodePosition = {
	instance: GuiObject?,
	position: Vector2,
}

export type self = {
	random: Random,
	nodes: { [string]: NodePosition },
}

--- Creates a new SkillTreeGenerator with a seed based on the player's UserId.
--- @param userId number The player's UserId for consistent randomness.
--- @return self
function SkillTreeGenerator.new(userId: number): self
	local self = setmetatable({}, SkillTreeGenerator)
	self.random = Random.new(userId)
	self.nodes = {}
	return self
end

--- Generates the skill tree layout and instantiates the nodes.
--- @param container GuiObject The UI container where nodes will be placed.
--- @param rootName string The name of the starting node.
function SkillTreeGenerator:Generate(container: GuiObject, rootName: string)
	local interface_folder = ReplicatedStorage:FindFirstChild("Interfaces")
	local node_template = interface_folder and interface_folder:FindFirstChild("Node")

	if not node_template then
		warn("Node template not found in ReplicatedStorage.Interfaces. Generation will only calculate positions.")
	end

	-- 1. Initialize Root position at the center of the container
	local container_size = container.AbsoluteSize
	if container_size.X == 0 or container_size.Y == 0 then
		-- Fallback size if container is not yet laid out
		container_size = Vector2.new(800, 600)
	end

	local root_pos = container_size / 2
	self.nodes[rootName] = {
		position = root_pos,
	}

	-- 2. Breadth-First placement
	local queue = { rootName }
	local processed = {}

	while #queue > 0 do
		local current_name = table.remove(queue, 1)
		if processed[current_name] then
			continue
		end
		processed[current_name] = true

		local current_node = self.nodes[current_name]
		local current_pos = current_node.position

		local node_data = DUMMY_DATA[current_name]
		if not node_data then continue end

		local children_names = node_data.next

		for _, child_name in children_names do
			if not self.nodes[child_name] then
				-- Find a position for the child node
				local found = false

				-- If child has multiple parents already placed, we should try to place it
				-- relative to their average position to keep the graph somewhat clean.
				local parents = self:GetParents(child_name)
				local placed_parents_pos = {}
				for _, p_name in parents do
					if self.nodes[p_name] then
						table.insert(placed_parents_pos, self.nodes[p_name].position)
					end
				end

				local origin_pos = current_pos
				if #placed_parents_pos > 1 then
					local sum = Vector2.new(0, 0)
					for _, p_pos in placed_parents_pos do
						sum += p_pos
					end
					origin_pos = sum / #placed_parents_pos
				end

				for _ = 1, MAX_RETRIES do
					local angle = self.random:NextNumber(0, math.pi * 2)
					local dist = self.random:NextNumber(MIN_DISTANCE, MAX_DISTANCE)
					local offset = Vector2.new(math.cos(angle) * dist, math.sin(angle) * dist)
					local target_pos = origin_pos + offset

					if not self:IsOverlapping(target_pos) then
						self.nodes[child_name] = {
							position = target_pos,
						}
						found = true
						break
					end
				end

				if not found then
					-- Forced placement if no spot found after retries
					local angle = self.random:NextNumber(0, math.pi * 2)
					local target_pos = origin_pos + Vector2.new(math.cos(angle) * MAX_DISTANCE, math.sin(angle) * MAX_DISTANCE)
					self.nodes[child_name] = {
						position = target_pos,
					}
					warn("Could not find non-overlapping position for node: " .. child_name .. ". Forced placement used.")
				end
			end

			if not processed[child_name] then
				table.insert(queue, child_name)
			end
		end
	end

	-- 3. Instantiate UI clones
	for name, data in self.nodes do
		if node_template then
			local clone = node_template:Clone() :: GuiObject
			clone.Name = name
			-- We use AbsolutePosition-like offset from the container's top-left.
			-- In Roblox UI, Position is relative to Parent.
			clone.Position = UDim2.fromOffset(data.position.X, data.position.Y)
			clone.AnchorPoint = Vector2.new(0.5, 0.5)
			clone.Parent = container
			data.instance = clone
		end
	end
end

--- Checks if a position overlaps with any existing nodes.
function SkillTreeGenerator:IsOverlapping(pos: Vector2): boolean
	local min_dist = NODE_SIZE.X + PADDING
	for _, node in self.nodes do
		if (pos - node.position).Magnitude < min_dist then
			return true
		end
	end
	return false
end

--- Retrieves all parent node names for a given child node from DUMMY_DATA.
function SkillTreeGenerator:GetParents(child_name: string): { string }
	local parents = {}
	for name, data in DUMMY_DATA do
		for _, next_name in data.next do
			if next_name == child_name then
				table.insert(parents, name)
			end
		end
	end
	return parents
end

return SkillTreeGenerator
