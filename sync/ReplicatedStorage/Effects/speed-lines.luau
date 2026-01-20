--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local future = require(ReplicatedStorage.Packages.future)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- speed-lines.luau

local module = {
	-- variables
	speed = 20,
	rate = 1500,
	offset = 10,
	render_priority = Enum.RenderPriority.Camera.Value,
	is_bound = observer.new(false),
	tag = "speed-lines",
}

export type lines = BasePart & {
	Attachment: Attachment & {
		ParticleEmitter: ParticleEmitter,
	},
}

local player = playerMarshaller.get()
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:FindFirstChild("Humanoid") :: Humanoid

function module:On(camera: Camera, lines: lines)
	camera = camera or workspace.CurrentCamera

	assert(lines, "Did you forget to input the lines model?")

	local function compute()
		if not character or not humanoid or humanoid.Health <= 0 then
			module:Off(lines)
		end

		local viewport_size = camera.ViewportSize
		local aspect_ratio = viewport_size.X / viewport_size.Y

		local fov = camera.FieldOfView
		local look_vector = camera.CFrame.LookVector
		local coordinate = camera.CFrame

		-- so you can see them on any other device
		if aspect_ratio > 1.5 then
			module.offset = 10
		else
			module.offset = 13
		end

		-- we should replace the 70 with the default FOV.
		-- 70 is the placeholder for now
		lines.CFrame = coordinate + look_vector * (module.offset / (fov / 70))
		lines.Attachment.ParticleEmitter.Rate = (humanoid.WalkSpeed / module.speed :: number)
			* module.rate :: number
	end

	lines.Name = "Speed_Lines"
	lines.Parent = camera
	lines.Attachment.ParticleEmitter.Enabled = true

	if module.is_bound:Get() == true then
		module:Off(camera:FindFirstChild("Speed_Lines") :: any)
	end

	RunService:BindToRenderStep(module.tag, module.render_priority, compute)
	module.is_bound:Set(true)

	return lines
end

function module:Off(lines: lines?)
	RunService:UnbindFromRenderStep(module.tag)

	return future.new(function()
		if lines then
			lines:Destroy()
		else
			local camera = workspace.CurrentCamera

			lines = camera:FindFirstChild("Speed_Lines") :: lines?

			if lines then
				lines:Destroy()
			end

			-- if lines not found, assume we already cleaned up
		end
	end)
end

return module
