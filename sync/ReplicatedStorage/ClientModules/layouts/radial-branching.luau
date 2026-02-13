--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local hydration = require(ReplicatedStorage.Utility.hydration)

-- radial-branching
-- places nodes in a circular layout
-- around a start position

-- positions evenly aswell.

export type config = {
	radius: number?,
	angle_step: number?,
	nodes: number?,
	canvas: GuiObject,
}

--[[
   Radial Branching:

   Places node evenly in a ring around a central "start node."

   ```luau

   local radial_branching = require(path.to.radial_branching)

   radial_branching({
      radius = 200,
      angle_step = math.rad(360 / 3),
      nodes = 67 -- 67!!! | how far the node sits from the center
   }, function(index: number) return Instance.new("Frame") end)
   ```
]]
return function(config: config, create_node: (number?) -> GuiObject)
	config.radius = config.radius or 200
	config.angle_step = config.angle_step or math.rad(360 / 3)
	config.nodes = config.nodes or 10

	local abs_size = config.canvas.AbsoluteSize
	assert(abs_size, "No absolute size???")

	local center = vector.create(abs_size.X / 2, abs_size.Y / 2)

	for i = 3, config.nodes :: number do
		local node = create_node(i)
		hydration(node) {
			Name = tostring(i),
			Parent = config.canvas,
		}

		local angle = i * config.angle_step :: number

		local cosine = math.cos(angle)
		local sine = math.sin(angle)

		local offset = vector.create(cosine, sine) * config.radius :: number

		local x, y = center.x + offset.x, center.y + offset.y

		node.Position = UDim2.fromOffset(x, y)
	end
end
