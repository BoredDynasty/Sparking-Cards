--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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
	active_gliders = {} :: active_gliders,
	ratelimit = ratelimit(2, 1),
	check_distance = 5,
	cast_params = RaycastParams.new(),
}

type active_gliders = {
	{
		player: playerMarshaller.player,
		config: typemarshaller.GlidingConfig,
	}
}

module.cast_params.FilterType = Enum.RaycastFilterType.Exclude

-- should be ran on the server

function module:Toggle(player: playerMarshaller.player, config: typemarshaller.GlidingConfig)
	if module.ratelimit(player) then
		print("Glider cooldown")
		return
	end

	local character = characterMarshaller.get(player)

	local humanoid = character.Humanoid
	local root_part = character:FindFirstChild("HumanoidRootPart") :: BasePart

	local needle = table.find(module.active_gliders, {
		player = player,
		config = config,
	})
	if needle then
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

		table.remove(module.active_gliders, needle)

		return
	end

	config.glider_model = config.glider_model or fetchAsset("BasicGlider") :: Model

	local primary_part = config.glider_model.PrimaryPart

	module.cast_params:AddToFilter(character)

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
		Name = "Glider_Velocity",
		VelocityConstraintMode = Enum.VelocityConstraintMode.Vector,
	}

	Packet.ReplicateAnimation.sendTo({
		identification = "",
	}, player)

	table.insert(module.active_gliders, {
		player = player,
		config = config,
	})
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

function module:Update(deltaTime: number)
	if next(module.active_gliders) == nil then
		-- empty, avoid unecesarry computation
		return
	end

	for i, glider_data in ipairs(module.active_gliders) do
		local player = glider_data.player
		local character = player.Character :: characterMarshaller.Character
		-- we can't afford to use characterMarshaller.get() because we need to be quick

		if not character then
			-- no character

			table.remove(module.active_gliders, i)

			return
		end

		local humanoid = character.Humanoid
		if humanoid.Health <= 0 then
			-- the player got slapped lmao

			table.remove(module.active_gliders, i)

			return
		end

		local root_part = character.HumanoidRootPart

		local linear_velocity = root_part:FindFirstChild("Glider_Velocity") :: LinearVelocity
		if not linear_velocity then
			table.remove(module.active_gliders, i)

			return
		end

		local look_vector = root_part.CFrame.LookVector
		local speed = glider_data.config.speed
		local down_force = glider_data.config.down_force

		local velocity = look_vector * Vector3.new(1, 0, 1).Unit * (speed or 25)
		velocity *= Vector3.yAxis * -(down_force or 5)

		linear_velocity.VectorVelocity = velocity

		local ray_result =
			workspace:Raycast(root_part.Position, Vector3.yAxis * -module.check_distance, module.cast_params)

		if not ray_result then
			return
		end

		-- we have landed!
		-- disengage.

		local glider = character:FindFirstChild("Glider")
		if glider then
			glider:Destroy()
		end

		linear_velocity:Destroy()

		Packet.CancelAnimation.sendTo({
			identification = "",
		}, player)

		table.remove(module.active_gliders, i)
	end
end

RunService.Heartbeat:Connect(function(deltaTime: number)
	debug.profilebegin("glider-update")
	module:Update(deltaTime)
	debug.profileend()
end)
