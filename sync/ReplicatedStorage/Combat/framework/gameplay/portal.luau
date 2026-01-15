--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local hydration = require(ReplicatedStorage.Utility.hydration)

-- portal.luau

export type PortalData = {
	position: Vector3,
	destination: Vector3,
	cooldown: number,
}

local module = {}

local portal_model = fetchAsset("Portal-01")
local portal_entered = fetchAsset("Portal-Enter-01")

function module.new(position: Vector3, destination: Vector3, cooldown: number): PortalData
	return {
		position = position,
		destination = destination,
		cooldown = cooldown,
	}
end

function module:Activate(portal: PortalData, player: Player)
	-- Teleport the player to the destination
	local character = characterMarshaller.get(player)
	local root_part = character:FindFirstChild("HumanoidRootPart") :: BasePart

	if character and root_part then
		root_part.CFrame = CFrame.new(portal.destination)

		-- TODO) add some SFX

		local enter_effect = portal_entered:Clone()
		hydration(enter_effect) {
			Position = portal.destination,
			Parent = workspace,
		}

		-- Optionally, you can add logic to remove the effect after some time
		local instances = workspace:GetPartBoundsInBox(CFrame.new(portal.destination), Vector3.one * 10)

		for i, instance in ipairs(instances) do
			if not instance:GetAttribute("Portal_Instance") then
				continue
			end

			for j, emitter in ipairs(instance:GetDescendants()) do
				if emitter:IsA("ParticleEmitter") then
					emitter.Enabled = false
				end
			end

			task.delay(4, function()
				for j, emitter in ipairs(instance:GetDescendants()) do
					if emitter:IsA("ParticleEmitter") then
						emitter.Enabled = true
					end
				end
			end)
		end
	end
end

function module:Render(portal: PortalData)
	-- Rendering logic for the portal can be implemented here

	local portal_instance = portal_model:Clone()
	hydration(portal_instance) {
		Position = portal.position,
		Anchored = true,
		CanCollide = false,
		Parent = workspace,
	}

	portal_instance:SetAttribute("Portal_Instance", true)
end

return module
