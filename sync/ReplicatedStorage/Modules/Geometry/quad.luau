--!strict
local triangle = require(script.Parent.triangle)

-- quad.luau

local quad_module = {}

function quad_module.draw(v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3, parts: { BasePart })
	parts[1], parts[2] = triangle.draw(v1, v2, v3, parts[1], parts[2])
	parts[3], parts[4] = triangle.draw(v3, v2, v4, parts[3], parts[4])
end

return quad_module
