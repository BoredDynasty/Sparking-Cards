--!strict

-- bounds.luau

local module = {}

--[[
   Checks if the mouse position is outside the given bounds.

   @param position The top-left position of the bounds (Vector2).
   @param size The size of the bounds (Vector2).
   @param mouse_position The mouse position (Vector2).
   @return boolean true if the mouse is outside the bounds, false otherwise.
]]
function module.outer(position: Vector2, size: Vector2, mouse_position: Vector2)
	if not position or not size or not mouse_position then
		return false
	end

	if
		mouse_position.X < position.X
		or mouse_position.X > position.X + size.X
		or mouse_position.Y < position.Y
		or mouse_position.Y > position.Y + size.Y
	then
		return true
	end

	return false
end

--[[
   Checks if the mouse position is inside the given bounds.

   @param position The top-left position of the bounds (Vector2).
   @param size The size of the bounds (Vector2).
   @param mousePos The mouse position (Vector2).
   @return boolean true if the mouse is inside the bounds, false otherwise.
]]
function module.inner(position: Vector2, size: Vector2, mouse_position: Vector2)
	if not position or not size or not mouse_position then
		return false
	end

	if
		mouse_position.X >= position.X
		and mouse_position.X <= position.X + size.X
		and mouse_position.Y >= position.Y
		and mouse_position.Y <= position.Y + size.Y
	then
		return true
	end

	return false
end

return module
