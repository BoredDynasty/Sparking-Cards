--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local promise = require(ReplicatedStorage.Packages.promise)

-- speed-lines.luau

local self = {
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
local character = characterMarshaller.get(player)
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

function self:On(camera: Camera, lines: lines)
	camera = camera or workspace.CurrentCamera

	assert(lines, "Did you forget to input the lines model?")

	local function compute()
		if not character or not humanoid or humanoid.Health <= 0 then
			self:Off(lines)
		end

		local viewport_size = camera.ViewportSize
		local aspect_ratio = viewport_size.X / viewport_size.Y

		local fov = camera.FieldOfView
		local look_vector = camera.CFrame.LookVector
		local coordinate = camera.CFrame

		-- so you can see them on any other device
		if aspect_ratio > 1.5 then
			self.offset = 10
		else
			self.offset = 13
		end

		-- we should replace the 70 with the default FOV.
		-- 70 is the placeholder for now
		lines.CFrame = coordinate + look_vector * (self.offset / (fov / 70))
		lines.Attachment.ParticleEmitter.Rate = (humanoid.WalkSpeed / self.speed :: number)
			* self.rate :: number
	end

	lines.Name = "Speed_Lines"
	lines.Parent = camera
	lines.Attachment.ParticleEmitter.Enabled = true

	if self.is_bound:Get() == true then
		self:Off(camera:FindFirstChild("Speed_Lines")):catch(warn)
	end

	RunService:BindToRenderStep(self.tag, self.render_priority, compute)
	self.is_bound:Set(true)

	return lines
end

function self:Off(lines: lines?)
	RunService:UnbindFromRenderStep(self.tag)

	return promise.new(function(resolve: () -> ...unknown, reject: (string) -> ...unknown)
		if lines then
			lines:Destroy()
			resolve()
		else
			local camera = workspace.CurrentCamera

			if camera:FindFirstChild("Speed_Lines") :: lines? then
				(camera:FindFirstChild("Speed_Lines") :: lines):Destroy()
				resolve()
			else
				reject("failed to cleanup speed-lines. do it yourself")
			end
		end
	end)
end

return self
