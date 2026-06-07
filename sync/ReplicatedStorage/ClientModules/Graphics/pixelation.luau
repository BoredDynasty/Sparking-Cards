--!strict
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local hydration = require(ReplicatedStorage.Utility.hydration)
local posterize = require(script.Parent.posterize)

-- pixelation.luau

local module = {}

local tag = "PixelationEffect"

function module:Clear()
	for i, post_processing in ipairs(Lighting:GetChildren()) do
		if post_processing:IsA("BlurEffect") then
			if not string.find(post_processing.Name, tag) then
				continue
			end

			post_processing:Destroy()
		end
	end
end

--[[
   This should also be possible with Color Quantization.
   but we're not going to do allat
   ```luau
   -- example usage

   local pixelation = require(path.to.pixelation)

   pixelation:Clear()

   -- turns on both the pixelation and posterization effects.

   -- note that it clears the existing posterize effect initially. 
   pixelation:On(24)
   ```

   @param intensity number? - The pixelation intensity.
]]
function module:On(intensity: number?)
	intensity = intensity or 24

	posterize:Clear()

	posterize:On()

	local pixelation = Instance.new("BlurEffect")
	hydration(pixelation, {
		Name = tag,
		Parent = Lighting,
		Size = intensity,
	})
end

return module
