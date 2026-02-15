--!strict

-- bounds.luau

local bounds_module = {}

--[[
   Checks if the mouse position is outside the given bounds.

   @param position The top-left position of the bounds (Vector2).
   @param size The size of the bounds (Vector2).
   @param mousePos The mouse position (Vector2).
   @return boolean True if the mouse is outside the bounds, false otherwise.
]]
function bounds_module.outer(position: Vector2, size: Vector2, mousePos: Vector2)
	if not position or not size or not mousePos then
		return false
	end

	if
		not (
			mousePos.X >= position.X
			and mousePos.X <= position.X + size.X
			and mousePos.Y >= position.Y
			and mousePos.Y <= position.Y + size.Y
		)
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
   @return boolean True if the mouse is inside the bounds, false otherwise.
]]
function bounds_module.inner(position: Vector2, size: Vector2, mousePos: Vector2)
	if not position or not size or not mousePos then
		return false
	end

	if
		mousePos.X >= position.X
		and mousePos.X <= position.X + size.X
		and mousePos.Y >= position.Y
		and mousePos.Y <= position.Y + size.Y
	then
		return true
	end

	return false
end

return bounds_module
