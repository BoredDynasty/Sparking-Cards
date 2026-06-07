--!strict

-- slerp.luau
-- a module for spherical linear interpolation (slerp) between CFrames.
-- this is useful for smooth camera transitions and other interpolations in 3D space.

return function(a: CFrame, b: CFrame, t: number)
	-- Get the delta rotation matrix between two CFrames
	local delta = a:ToObjectSpace(b)

	-- Decompose delta into Axis-Angle
	local axis, angle = delta:ToAxisAngle()

	-- Apply interpolation factor to the angle
	local slerp = a * CFrame.fromAxisAngle(axis, angle * t)

	return slerp
end
