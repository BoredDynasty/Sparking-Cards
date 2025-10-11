--!strict
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local spr = require(ReplicatedStorage.Modules.spr)

-- custom-lighting.luau
-- a module used to nicely manipulate lighting
-- for **very nice** effects and immersion.

local lighting_module = {
	-- constants
	damping_ratio = 0.8,
	frequency = 1.5,
}

function lighting_module.blur(i: number?)
	local blur = Lighting:FindFirstChildOfClass("BlurEffect") or Instance.new("BlurEffect")
	blur.Parent = Lighting

	spr.target(blur, lighting_module.damping_ratio, lighting_module.frequency, {
		Size = i or 24,
	})
end

function lighting_module.unblur()
	local blur = Lighting:FindFirstChildOfClass("BlurEffect")
	if blur then
		spr.target(blur, lighting_module.damping_ratio, lighting_module.frequency, {
			Size = 0,
		})
	end
end

return table.freeze(lighting_module)
