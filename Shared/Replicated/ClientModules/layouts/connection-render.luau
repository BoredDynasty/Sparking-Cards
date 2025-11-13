--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local hydration = require(ReplicatedStorage.Utility.hydration)

-- connection-render.luau

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
		Position = UDim2.fromOffset(
			(nodeA.AbsolutePosition.X + nodeB.AbsolutePosition.X) / 2,
			(nodeA.AbsolutePosition.Y + nodeB.AbsolutePosition.Y) / 2
		),
		Rotation = math.deg(
			math.atan2(
				nodeB.AbsolutePosition.Y - nodeA.AbsolutePosition.Y,
				nodeB.AbsolutePosition.X,
				nodeA.AbsolutePosition.X
			)
		),
		Size = UDim2.new(0, (nodeA.AbsolutePosition - nodeB.AbsolutePosition).Magnitude, 0, 2),

		Parent = ancestor,
	}
end
