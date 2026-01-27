--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local spr = require(ReplicatedStorage.Modules.spr)

local hydration = require(ReplicatedStorage.Utility.hydration)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local random = require(ReplicatedStorage.Utility.random)

-- collector.luau

local module = {
	default = {
		shape = Enum.PartType.Ball,
		material = Enum.Material.Neon,
		color = Color3.fromRGB(255, 215, 0),
		size = Vector3.one,
		speed = 5,
	},
}

export type props = {
	shape: Enum.PartType,
	material: Enum.Material,
	color: Color3,
	size: Vector3,
	speed: number,
}

local player = playerMarshaller.get()
local character = player.Character or player.CharacterAdded:Wait()

function module:Fire(position: Vector3, props: props)
	props = props or {}
	-- reconcile props with defaults
	for key, value in pairs(self.default) do
		if props[key] == nil then
			props[key] = value
		end
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
	if not rootPart then
		return
	end

	local x_y = random.float(-2, 2)
	local offset = Vector3.new(x_y, random.float(1, 3), x_y)

	for i = 1, random.integer(5, 15) do
		local part = Instance.new("Part")
		hydration(part) {
			Anchored = true,
			CanCollide = false,
			Shape = props.shape,
			Material = props.material,
			Color = props.color,
			Size = props.size,
			Position = position + offset,
			Transparency = 0,
			Parent = Workspace,
		}

		local mid_point = position + Vector3.new(x_y, random.float(5, 8), x_y)

		spr.target(part, 0.6, 6, {
			Position = mid_point,
		})

		spr.completed(part, function()
			local speed = math.max(props.speed, 1)

			local conn = nil
			local threshold = 1

			conn = RunService.RenderStepped:Connect(function(deltaTime: number)
				if not part.Parent or not rootPart or not character then
					return
				end

				local goal = rootPart.Position

				local direction = (goal - part.Position).Unit
				local distance = (goal - part.Position).Magnitude

				local adjusted_speed = math.pow(speed, 2)

				part.Position += (direction * adjusted_speed * deltaTime)
				if distance < threshold then
					if conn then
						conn:Disconnect()
					end

					spr.target(part, 1, 4, {
						Transparency = 1,
					})

					task.wait(0.3)

					part:Destroy()
				end
			end)
		end)
	end
end

return module
