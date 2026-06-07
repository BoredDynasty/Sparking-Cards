--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local hydration = require(ReplicatedStorage.Utility.hydration)

-- orbit-constellation.luau
-- wip

export type Config = {
	node_count: number,
	radius: number,
	height: number,
	connection_range: number,
	speed: number,
	max_connection_per_node: number?,
	LOD_distance: number?,
	update_rate: number?,
}

type NodeData = {
	position: Vector3,
	prev_position: Vector3,
	offset: Vector3,
	frequency: number,
}

type ConnectionData = {
	beam: Beam,
	A: number,
	B: number,
	distance: number,
	strength: number,
}

local module = {}
module.__index = module

local USE_SPATIAL_HASH = true
local CONNECTION_REFRESH_RATE = 120
local BATCH_UPDATE_SIZE = 1024
local SPATIAL_UPDATE_RATE = 60

type OrbitLattice = typeof(module.new(Vector3.one, {} :: Config))

function module.new(origin: Vector3, config: Config)
	local self = setmetatable({}, module)

	self.origin = origin
	self.config = {
		node_count = config.node_count or 20,
		radius = config.radius or 50,
		height = config.height or 10,
		connection_range = config.connection_range or 100,
		speed = config.speed or 1,
		max_connection_per_node = config.max_connection_per_node or 5,
		LOD_distance = config.LOD_distance or 200,
		update_rate = config.update_rate or 60,
	}

	self.time = 0
	self.frame_count = 0
	self.active = false

	self.node_data = table.create(self.config.node_count) :: { NodeData }
	self.node_parts = table.create(self.config.node_count) :: { BasePart }

	self._connections = {} :: { ConnectionData }

	self.spatial_hash = {} :: { [string]: number }
	self.hash_size = self.config.connection_range * 1.5

	self.connection_matrix = {} :: { [number]: { [number]: boolean } }
	self.potential_connections = {}

	self.node_model = nil :: Model?

	return self
end

-- Start the lattice animation
function module:Start(self: OrbitLattice)
	if self.active then return end
	self.active = true
	self.frame_count = 0
end

-- Stop the lattice animation
function module:Stop(self: OrbitLattice)
	self.active = false
end

-- Destroy all parts, beams, and cleanup
function module:Destroy(self: OrbitLattice)
	self:Stop(self)
	if self.node_model then
		self.node_model:Destroy()
		self.node_model = nil
	end
	for _, part in ipairs(self.node_parts) do
		if part and part.Parent then
			part:Destroy()
		end
	end
	for _, conn in ipairs(self._connections) do
		if conn.beam then
			conn.beam:Destroy()
		end
	end
	self.node_parts = {}
	self.node_data = {}
	self._connections = {}
	self.spatial_hash = {}
end

-- Main update loop (call this from a RunService loop)
function module:Step(self: OrbitLattice, dt: number, camera_pos: Vector3?)
	if not self.active then return end
	self.frame_count += 1
	-- Animate nodes
	self:UpdateNodes(self, dt)

	-- LOD: Only update connections every N frames
	if self.frame_count % CONNECTION_REFRESH_RATE == 0 then
		self:UpdateSpatialHash(self)
		self:UpdateConnections(self)
	end
	-- Optionally, hide distant nodes (simple LOD)
	if camera_pos and self.config.LOD_distance then
		for i, part in ipairs(self.node_parts) do
			local dist = (part.Position - camera_pos).Magnitude
			part.Transparency = dist > self.config.LOD_distance and 1 or 0
		end
	end
end

	-- Update node positions in an orbit/lattice pattern
	function module:UpdateNodes(self: OrbitLattice, dt: number)
		self.time += dt * self.config.speed
		for i, node in ipairs(self.node_data) do
			node.prev_position = node.position
			local t = i / self.config.node_count
			local angle = self.time * node.frequency + node.offset.X
			local radius = self.config.radius * math.sqrt(t)
			local x = math.sin(angle) * radius
			local y = (t - 0.5) * self.config.height * 2
			local z = math.cos(angle) * radius
			node.position = self.origin + Vector3.new(x, y, z)
			-- Move the part
			if self.node_parts[i] then
				self.node_parts[i].Position = node.position
			end
		end
	end

function module:CreateNodes(self: OrbitLattice)
	self.node_model = Instance.new("Model")
	hydration(self.node_model) {
		Name = "OrbitLatticeNodes",
		Parent = workspace,
	}

	local template = Instance.new("Part")
	hydration(template) {
		Size = Vector3.one * 0.15,
		Anchored = true,
		CanCollide = false,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(140, 190, 255),
		CastShadow = false,
		TopSurface = Enum.SurfaceType.Smooth,
		Bottom = Enum.SurfaceType.Smooth,
	}

	local golden_ratio = (1 + math.sqrt(5)) / 2
	local angle_increment = math.pi * 2 * golden_ratio

	for i = 1, self.config.node_count do
		local part = template:Clone()
		hydration(part) {
			Name = "N" .. i,
			Parent = self.node_model,
		}

		self.node_parts[i] = part

		local t = i / self.config.node_count
		local angle = i * angle_increment
		local radius = self.config.radius * math.sqrt(t)

		local offset = Vector3.new(angle, t * math.pi * 2, (i * (golden_ratio - 1)) % (math.pi * 2))

		local x = math.sin(angle) * radius
		local y = (t - 0.5) * self.config.height * 2
		local z = math.cos(angle) * radius

		local initial_position = self.origin + Vector3.new(x, y, z)

		self.node_data[i] = {
			position = initial_position,
			prev_position = initial_position,
			offset = offset,
			frequency = 0.7 + (i % 10) * 0.05,
			last_connection_check = 0,
		}

		if i % 500 == 0 then
			task.wait()
		end
	end

	template:Destroy()
end

function module:GetHashKey(self: OrbitLattice, position: Vector3)
	local x = math.floor(position.X / self.hash_size)
	local y = math.floor(position.Y / self.hash_size)
	local z = math.floor(position.Z / self.hash_size)

	return `{x},{y},{z}`
end

function module:UpdateSpatialHash(self: OrbitLattice)
	table.clear(self.spatial_hash)

	for i, data in ipairs(self.node_data) do
		local key = self:GetHashKey(self, data.position)

		local bucket = self.spatial_hash[key]
		if not bucket then
			bucket = {}
			self.spatial_hash[key] = bucket
		end
		table.insert(bucket, i)
	end
end

-- Find nearby node indices for a given node index
function module:GetNearbyNodes(self: OrbitLattice, node_index: number)
	local node = self.node_data[node_index]
	local key = self:GetHashKey(self, node.position)
	local neighbors = {}
	local x, y, z = key:match("(-?%d+),(-?%d+),(-?%d+)")

	x, y, z = tonumber(x), tonumber(y), tonumber(z)
	-- Check this and adjacent buckets
	for dx = -1, 1 do
		for dy = -1, 1 do
			for dz = -1, 1 do
				local nkey = string.format("%d,%d,%d", x+dx, y+dy, z+dz)
				local bucket = self.spatial_hash[nkey]
				if bucket then
					for _, idx in ipairs(bucket) do
						if idx ~= node_index then
							table.insert(neighbors, idx)
						end
					end
				end
			end
		end
	end
	return neighbors
end

	-- Create or update connections (beams) between nodes
	function module:UpdateConnections(self: OrbitLattice)
		-- Clear previous connection matrix
		self.connection_matrix = {}
		for i = 1, #self.node_data do
			self.connection_matrix[i] = {}
		end

		-- Remove old beams
		for _, conn in ipairs(self._connections) do
			if conn.beam then
				conn.beam:Destroy()
			end
		end
		self._connections = {}

		-- For each node, find neighbors and create beams
		for i, node in ipairs(self.node_data) do
			local neighbors = self:GetNearbyNodes(self, i)
			local connections = 0
			for _, j in ipairs(neighbors) do
				if connections >= self.config.max_connection_per_node then break end
				if not self.connection_matrix[i][j] and not self.connection_matrix[j][i] then
					local other = self.node_data[j]
					local dist = (node.position - other.position).Magnitude
					if dist <= self.config.connection_range then
						-- Create attachments
						local a0 = Instance.new("Attachment")
						a0.Position = Vector3.zero
						a0.Parent = self.node_parts[i]
						local a1 = Instance.new("Attachment")
						a1.Position = Vector3.zero
						a1.Parent = self.node_parts[j]
						-- Create beam
						local beam = Instance.new("Beam")
						beam.Attachment0 = a0
						beam.Attachment1 = a1
						beam.Width0 = 0.05
						beam.Width1 = 0.05
						beam.Color = ColorSequence.new(Color3.fromRGB(140, 190, 255))
						beam.LightEmission = 1
						beam.Transparency = NumberSequence.new(0.1)
						beam.Parent = self.node_model
						-- Store connection
						table.insert(self._connections, {
							beam = beam,
							A = i,
							B = j,
							distance = dist,
							strength = 1,
						})
						self.connection_matrix[i][j] = true
						self.connection_matrix[j][i] = true
						connections += 1
					end
				end
			end
		end
	end
end
