--!strict
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local spr = require(ReplicatedStorage.Modules.spr)

-- custom-lighting.luau
-- a module used to nicely manipulate lighting
-- for **very nice** effects and immersion.

local lighting_module = {
	-- constants
	damping_ratio = 0.7,
	frequency = 2.5,
	default_color = Color3.fromRGB(255, 255, 255),
	default_decay = Color3.fromRGB(124, 124, 124),
	presets = {
		lunar = {
			color = Color3.fromRGB(20, 18, 24),
			decay = Color3.new(),
			glare = 10,
			haze = 3.46,
			time = 4,
		},
	},
}

function lighting_module.blur(i: number?)
	local blur = Lighting:FindFirstChildOfClass("BlurEffect") or Instance.new("BlurEffect")
	blur.Parent = Lighting
	blur.Enabled = true

	spr.stop(blur, "Size")

	spr.target(blur, lighting_module.damping_ratio, lighting_module.frequency, {
		Size = i or 24,
	})
end

function lighting_module.unblur()
	local blur = Lighting:FindFirstChildOfClass("BlurEffect")
	if blur then
		spr.stop(blur, "Size")

		spr.target(blur, lighting_module.damping_ratio, lighting_module.frequency, {
			Size = 0,
		})

		spr.completed(blur, function()
			blur.Enabled = false
		end)
	end
end

function lighting_module.set_color(color: Color3)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		warn("where is the atmosphere???")

		return
	end

	spr.target(atmosphere, lighting_module.damping_ratio, lighting_module.frequency, {
		Color = color,
	})
end

function lighting_module.set_decay(color: Color3)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		warn("where is the atmosphere???")

		return
	end

	spr.target(atmosphere, lighting_module.damping_ratio, lighting_module.frequency, {
		Decay = color,
	})
end

return table.freeze(lighting_module)
