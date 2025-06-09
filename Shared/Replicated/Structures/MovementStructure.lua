--!strict

return {
	Character = {
		BaseWalkspeed = 14,
		BaseFieldofView = 70,
	},
	Slide = {
		DefaultCooldown = 0.1,
		BaseSpeed = 0.1,
		DefaultKey = Enum.KeyCode.RightShift,
		PositionCheck = nil, -- utility
		IsSliding = false,
		CanSlide = true,
		stopSlide = function(params: { boolean | RBXScriptConnection | BodyVelocity })
			for _, param in pairs(params) do
				if type(param) == "boolean" then
					param = false
				elseif typeof(param) == "RBXScriptConnection" then
					if param then
						param:Disconnect()
					end
				elseif typeof(param) == "BodyVelocity" then
					param:Destroy()
				end
			end
		end,
	},
}
