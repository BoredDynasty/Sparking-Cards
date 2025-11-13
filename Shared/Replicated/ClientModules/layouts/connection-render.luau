--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local hydration = require(ReplicatedStorage.Utility.hydration)

-- connection-render.luau

type connections = { { nodeA: GuiObject, nodeB: GuiObject, line: GuiObject } }

local connections = {} :: connections

RunService.Heartbeat:Connect(function()
	debug.profilebegin("update-line-connections")

	for _, connection in ipairs(connections) do
		local nodeA = connection.nodeA
		local nodeB = connection.nodeB
		local line = connection.line

		if not nodeA.Parent or not nodeB.Parent or not line.Parent then
			table.remove(connections, table.find(connections, connection))
			continue
		end

		line.Position = UDim2.fromOffset(
			(nodeA.AbsolutePosition.X + nodeB.AbsolutePosition.X) / 2,
			(nodeA.AbsolutePosition.Y + nodeB.AbsolutePosition.Y) / 2
		)

		line.Rotation = math.deg(
			math.atan2(
				nodeB.AbsolutePosition.Y - nodeA.AbsolutePosition.Y,
				nodeB.AbsolutePosition.X - nodeA.AbsolutePosition.X
			)
		)

		line.Size = UDim2.new(0, (nodeA.AbsolutePosition - nodeB.AbsolutePosition).Magnitude, 0, 2)
	end

	debug.profileend()
end)

--[[
   Each node should draw a line to connect to another node.

   ```luau
   local connection_render = require(path.to.connection_render)

   connection_render(ancestor, nodeA, nodeB, function()
      local line = Instance.new("Frame")
      line.Size = UDim2.new(0, 2, 0, 50)
      line.BackgroundColor3 = Color3.new(1, 1, 1)
      return line
   end)
   ```

   You can call this function multiple times to visually connect multiple nodes.
]]
return function(ancestor: Instance, nodeA: GuiObject, nodeB: GuiObject, create_line: () -> GuiObject)
	local line = create_line()
	hydration(line) {
		Parent = ancestor,
	}

	table.insert(connections, {
		nodeA = nodeA,
		nodeB = nodeB,
		line = line,
	})
end
