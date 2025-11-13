--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local hydration = require(ReplicatedStorage.Utility.hydration)

-- force-directed-layout
-- uses a force-directed graph drawing algorithm to position nodes

export type Edge = { source: GuiObject, target: GuiObject }
export type Node = GuiObject

export type config = {
	nodes: {Node},
	edges: {Edge},
	canvas: GuiObject,
	stiffness: number?,
	repulsion: number?,
	damping: number?,
	energy_threshold: number?,
}

return function(config: config)
	-- a simple force-directed graph drawing algorithm
	-- based on the Fruchterman-Reingold algorithm

	local nodes = config.nodes
	local edges = config.edges
	local canvas_size = config.canvas.AbsoluteSize

	local stiffness = config.stiffness or 50
	local repulsion = config.repulsion or 400
	local damping = config.damping or 0.5
	local energy_threshold = config.energy_threshold or 0.1

	local node_data = {}

	for _, node in ipairs(nodes) do
		table.insert(node_data, {
			node = node,
			position = vector.create(math.random() * canvas_size.X, math.random() * canvas_size.Y),
			velocity = vector.create(0, 0),
			force = vector.create(0, 0),
		})
	end

	local function compute_forces()
		-- repulsive forces
		for i, data1 in ipairs(node_data) do
			for j, data2 in ipairs(node_data) do
				if i == j then
					continue
				end

				local delta = data2.position - data1.position
				local distance = delta.magnitude
				local direction = delta.unit

				if distance > 0 then
					local force = direction * (repulsion / distance)
					data1.force = data1.force - force
					data2.force = data2.force + force
				end
			end
		end

		-- attractive forces
		for _, edge in ipairs(edges) do
			local source_data = node_data[table.find(nodes, edge.source)]
			local target_data = node_data[table.find(nodes, edge.target)]

			if not source_data or not target_data then
				continue
			end

			local delta = target_data.position - source_data.position
			local distance = delta.magnitude
			local direction = delta.unit

			if distance > 0 then
				local force = direction * (distance * stiffness / 100)
				source_data.force = source_data.force + force
				target_data.force = target_data.force - force
			end
		end
	end

	local function update_positions()
		local total_energy = 0

		for _, data in ipairs(node_data) do
			data.velocity = (data.velocity + data.force) * damping
			data.position = data.position + data.velocity

			total_energy = total_energy + data.velocity.magnitude
		end

		return total_energy
	end

	local function reset_forces()
		for _, data in ipairs(node_data) do
			data.force = vector.create(0, 0)
		end
	end

	local iterations = 0
	while true do
		reset_forces()
		compute_forces()
		local total_energy = update_positions()
		iterations = iterations + 1

		if total_energy < energy_threshold or iterations > 1000 then
			break
		end

		task.wait()
	end

	-- update the node positions
	for _, data in ipairs(node_data) do
		hydration(data.node) {
			Position = UDim2.fromOffset(data.position.x, data.position.y),
		}
	end
end
