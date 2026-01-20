--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local hydration = require(ReplicatedStorage.Utility.hydration)
local url = require(ReplicatedStorage.Modules.Serialization.url)

-- prism-spawner.luau

local module = {
	Tracking = {},
	update_conn = nil :: RBXScriptConnection?,
}

function module:Spawn(position: Vector3)
	local prism_model = fetchAsset("Prism_OBJ") :: MeshPart

	-- put it in position
	hydration(prism_model) {
		Parent = Workspace,
		CFrame = CFrame.new(position),
		Name = url.generateShortUniqueId(),
		Anchored = true,
	}

	table.insert(module.Tracking, prism_model)

	prism_model.Destroying:Connect(function()
		for i, v in ipairs(module.Tracking) do
			if v == prism_model then
				table.remove(module.Tracking, i)

				break
			end
		end
	end)
end

function module:Update()
	if module.update_conn then
		return
	end

	local lastCheck: number = 0.0
	local checkInterval = 1.2 -- seconds

	local amplitude = 5.0 -- the max distance from the center
	local frequency = 1.0 -- how fast the part moves back and forth

	module.update_conn = RunService.Heartbeat:Connect(function(deltaTime: number)
		debug.profilebegin("track-prisms")

		lastCheck += deltaTime :: number
		if lastCheck < checkInterval then
			debug.profileend()

			return
		end

		lastCheck = 0

		-- Calculate the sine wave, scaled by amplitude
		local wave = amplitude * math.sin(deltaTime * frequency)

		for i, prism_model in ipairs(self.Tracking :: { BasePart }) do
			local base_y = prism_model.CFrame.Y

			prism_model.CFrame *= CFrame.new(1, base_y + wave, 1) * CFrame.Angles(45, 0, 0)
		end

		debug.profileend()
	end)
end

return module
