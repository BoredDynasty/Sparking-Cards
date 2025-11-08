--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local TweenPlus = require(script.Parent.TweenPlus)
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local hydration = require(ReplicatedStorage.Utility.hydration)
local url = require(ReplicatedStorage.Modules.Serialization.url)

-- prism-spawner.luau

local self = {
	Tracking = {},
	update_conn = nil :: RBXScriptConnection?,
}

function self:Spawn(position: Vector3)
	local prism_model = fetchAsset("Prism_OBJ") :: MeshPart

	-- put it in position
	hydration(prism_model) {
		Parent = Workspace,
		CFrame = CFrame.new(position),
		Name = url.generateShortUniqueId(),
		Anchored = true,
	}

	table.insert(self.Tracking, prism_model)
end

function self:Update()
	if self.update_conn then
		return
	end

	local lastCheck: number = 0.0
	local checkInterval = 1.2 -- seconds

	local amplitude = 5.0 -- the max distance from the center
	local frequency = 1.0 -- how fast the part moves back and forth

	self.update_conn = RunService.Heartbeat:Connect(function(deltaTime: number)
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

return self
