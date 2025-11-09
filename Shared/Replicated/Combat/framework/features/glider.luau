--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.Packet)
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local hydration = require(ReplicatedStorage.Utility.hydration)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- glider.luau
-- unlockable

local module = {
	_connections = {},
	active_gliders = {},
	ratelimit = ratelimit(2, 1),
}

-- should be ran on the server

function module:Toggle(player: playerMarshaller.player, config: typemarshaller.GlidingConfig)
	if module.ratelimit(player) then
		print("Glider cooldown")
		return
	end

	local character = characterMarshaller.get(player)

	local humanoid = character.Humanoid
	local root_part = character:FindFirstChild("HumanoidRootPart") :: BasePart

	local needle = table.find(module.active_gliders, player)
	if needle then
		local conn = module._connections[player]
		if conn then
			conn:Disconnect()
		end

		local glider = character:FindFirstChild("Glider")
		if glider then
			glider:Destroy()
		end

		local velocity = root_part:FindFirstChild("GliderVelocity") :: LinearVelocity
		if velocity then
			velocity:Destroy()
		end

		Packet.CancelAnimation.sendTo({
			identification = "",
		}, player)

		table.remove(module.active_gliders[needle])

		return
	end

	local raycast_params = RaycastParams.new()
	raycast_params.FilterDescendantsInstances = { character }
	raycast_params.FilterType = Enum.RaycastFilterType.Exclude

	config.glider_model = config.glider_model or fetchAsset("BasicGlider") :: Model

	local primary_part = config.glider_model.PrimaryPart

	if not primary_part then
		warn("missing primary part for glider")

		return
	end

	hydration(config.glider_model) {
		Parent = character,
		Name = "Glider",
	}

	local weld = Instance.new "Weld"
	hydration(weld) {
		Parent = primary_part,
		Part0 = primary_part,
		Part1 = root_part,
	}

	local velocity = Instance.new("LinearVelocity")
	hydration(velocity) {
		MaxForce = Vector3.one * math.huge,
		Parent = root_part,
	}

	Packet.ReplicateAnimation.sendTo({
		identification = "",
	}, player)

	table.insert(module.active_gliders, player)
end

function module:Attach(glider_model: Model)
	local primary_part = glider_model.PrimaryPart

	if not primary_part then
		warn("missing primary part for glider")

		return
	end

	for i, base_part in ipairs(glider_model:GetChildren()) do
		if not base_part:IsA("BasePart") then
			continue
		end

		hydration(base_part) {
			CanCollide = false,
			CanQuery = false,
			Massless = true,
		}

		if base_part == primary_part then
			continue
		end

		local weld = Instance.new("Weld")
		hydration(weld) {
			Parent = primary_part,
			Part0 = base_part,
			Part1 = primary_part,
		}
	end
end
