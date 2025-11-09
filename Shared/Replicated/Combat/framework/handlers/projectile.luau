--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local explosion = require(ReplicatedStorage.Combat.framework.effects.explosion)
local hydration = require(ReplicatedStorage.Utility.hydration)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- projectile.luau

local projectile_module = {
	active_projectiles = {},
}

type active_projectiles = {
	speed: number,
	gravity: Vector3,
	projectile: BasePart,
	total_distance: number,
	max_distance: number,
	velocity: Vector3,
	origin: Vector3,
	raycast_params: RaycastParams,
}

-- TODO) add hit detection

function projectile_module:Fire(player: playerMarshaller.player, config: typemarshaller.ProjectileConfig)
	local character = characterMarshaller.get(player)

	local root_part = character.HumanoidRootPart

	local origin = root_part.Position

	local gravity_factor = 1

	-- reconcile
	config.speed = config.speed or 250
	config.gravity = config.gravity or Vector3.new(0, -workspace.Gravity, 0) * gravity_factor
	if not config.projectile then
		-- wow what a lazy fatty
		config.projectile = Instance.new("Part")
		hydration(config.projectile) {
			CFrame = CFrame.new(origin, origin + config.direction),
			Size = Vector3.one,
			CanCollide = true,
			Shape = Enum.PartType.Ball,
			Anchored = true,
			Parent = workspace,
		}
	end

	local velocity = config.direction.Unit * (config.speed :: number)

	local max_distance = 500
	local total_distance = 0

	local raycast_params = RaycastParams.new()
	raycast_params.RespectCanCollide = true
	raycast_params.FilterType = Enum.RaycastFilterType.Exclude

	table.insert(projectile_module.active_projectiles, {
		speed = config.speed :: number,
		gravity = config.gravity :: Vector3,
		projectile = config.projectile :: BasePart,
		total_distance = total_distance,
		max_distance = max_distance,
		velocity = velocity,
		origin = origin,
		raycast_params = raycast_params,
	})
end

function projectile_module:Update(deltaTime: number)
	if next(projectile_module.active_projectiles) == nil then
		-- empty
		return
	end

	for i, projectile_data in ipairs(projectile_module.active_projectiles :: { active_projectiles }) do
		local step_velocity = projectile_data.velocity + projectile_data.gravity * deltaTime
		local step_displacement = (projectile_data.velocity + step_velocity) / 2 * deltaTime

		projectile_data.velocity = step_velocity

		local next_position = projectile_data.origin + step_displacement
		local ray_direction = next_position - projectile_data.origin

		local raycast_result =
			workspace:Raycast(projectile_data.origin, ray_direction, projectile_data.raycast_params)

		if raycast_result then
			local hit_position = raycast_result.Position
			explosion.kaboom({
				position = hit_position,
				duration = 1.5,
				colors = {
					Color3.fromRGB(255, 89, 0), -- Orange
					Color3.fromRGB(255, 0, 0), -- Red
					Color3.fromRGB(255, 255, 0), -- Yellow
				},
			})

			projectile_data.projectile:Destroy()

			table.remove(projectile_module.active_projectiles[i])
		else
			projectile_data.origin = next_position
			projectile_data.projectile.CFrame =
				CFrame.new(projectile_data.origin, projectile_data.origin + projectile_data.velocity.Unit)
			projectile_data.total_distance += ray_direction.Magnitude

			if projectile_data.total_distance >= projectile_data.max_distance then
				explosion.kaboom({
					position = projectile_data.projectile.Position,
					duration = 1.5,
					colors = {
						Color3.fromRGB(255, 89, 0), -- Orange
						Color3.fromRGB(255, 0, 0), -- Red
						Color3.fromRGB(255, 255, 0), -- Yellow
					},
				})

				projectile_data.projectile:Destroy()

				table.remove(projectile_module.active_projectiles[i])
			end
		end
	end
end

-- start tracking

RunService.Heartbeat:Connect(function(deltaTime)
	debug.profilebegin("simulate-projectiles")
	projectile_module:Update(deltaTime)
	debug.profileend()
end)
