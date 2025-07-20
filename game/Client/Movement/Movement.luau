--!nonstrict

local Movement = {}
Movement.__index = Movement

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

-- local MovementStructure = require(ReplicatedStorage.Structures.MovementStructure)
local Stamina = require(Players.LocalPlayer.PlayerScripts.Movement.Stamina)
local TweenPlus = require(ReplicatedStorage.Utility.TweenPlus)
local animate = require(StarterPlayer.StarterPlayerScripts.Utilities.animate)
local audio = require(ReplicatedStorage.Modules.audio)
local dictionary = require(ReplicatedStorage.Utility.dictionary)
local gamecamera = require(StarterPlayer.StarterPlayerScripts.Modules.gamecamera)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local promise = require(ReplicatedStorage.Packages.promise)
local statemachine = require(ReplicatedStorage.Utility.statemachine)

local player = playerMarshaller.get()
local character = player.Character
local camera = workspace.CurrentCamera

type self = {
	character: typeof(character),
	springFOV: number,
	targetFOV: number,
	fovVelocity: number,
	stiffness: number,
	damping: number,
	mass: number,

	baseSpeed: number,
	maxSpeed: number,
	currentSpeed: number,
	accelerationRate: number,

	keybinds: { string: Enum.KeyCode },
	_animate: typeof(animate.new()),
	_audio: typeof(audio.new()),
	_debounces: {
		jump: {
			active: boolean,
			cooldown: number, -- Cooldown time in seconds
		},
		slide: {
			active: boolean,
			cooldown: number,
		},
		dash: {
			active: boolean,
			cooldown: number, -- Cooldown time in seconds
		},
	},
	_position_checks: {
		slide: RBXScriptConnection?, -- Renderstepped connection for slide position checks
	},
	_hip_height: {
		normal: number,
		slide: number,
	},
	_velocity: {
		forward: number, -- Speed loss when sliding forward
		upward: number, -- Speed loss when sliding upward
		downward: number, -- Speed loss when sliding downward
	},
	_push_velocity: {
		forward: number, -- Speed when pushing forward
		upward: number, -- Speed when pushing upward
		-- downward: number, -- Speed when pushing downward
	},

	_statemachine: statemachine.StateMachineType,
	_airborneStates: { [Enum.HumanoidStateType]: boolean },

	connections: { { name: string, connection: RBXScriptConnection, disconnect: () -> () } },

	new: () -> Movement,
	__overwrite: (self: self, src: { any }) -> (),
	__tostring: (self: self) -> string,
	isMoving: () -> boolean,
	sprint: (self: self) -> (),
	jump: (self: self) -> (),
	slide: (self: self) -> (),
	dash: (self: self) -> (),
	walk: (self: self) -> (),
}
export type Movement = { typeof(setmetatable({} :: self, Movement)) }

function Movement.new(): Movement
	Stamina:initialize()
	return setmetatable(
		{
			character = character,
			springFOV = 70, -- Default FOV
			targetFOV = 70,
			fovVelocity = 0,
			stiffness = 100, -- 200
			damping = 10,
			mass = 1,

			-- Speed parameters
			baseSpeed = 14,
			maxSpeed = 18,
			currentSpeed = 14,
			accelerationRate = 2, -- Speed increase per second
			staminaRate = 10, -- Stamina drain rate per second

			keybinds = {
				sprint = Enum.KeyCode.LeftShift,
				slide = Enum.KeyCode.C,
				cancel_slide = Enum.KeyCode.Space,
				dash = Enum.KeyCode.V,
			},
			_animate = animate.new(character),
			_audio = audio.new(),
			_debounces = {
				--[[
					These flags mean if you can use the action or not.
				]]
				sprint = {
					active = false,
					cooldown = 0.6,
				},
				jump = {
					active = false,
					cooldown = 0.8, -- Cooldown time in seconds
				},
				slide = {
					active = true,
					cooldown = 2,
				},
				dash = {
					active = false,
					cooldown = 3, -- Cooldown time in seconds
				},
			},
			_hip_height = {
				normal = 0,
				slide = -2,
			},
			_velocity = {
				-- for speed loss
				forward = 1,
				upward = 2,
				downward = 1,
			},
			_push_velocity = {
				forward = 50, -- Speed when pushing forward
				upward = 50, -- Speed when pushing upward
				--downward = 5, -- Speed when pushing downward
			},

			_statemachine = statemachine.new({
				running = {
					name = "running",
					transitions = {
						walking = "walking",
					},
				},
				walking = {
					name = "walking",
					transitions = {
						running = "running",
					},
				},
				sliding = {
					name = "sliding",
					transitions = {
						walking = "walking",
					},
				},
				dashing = {
					name = "dashing",
					transitions = {
						walking = "walking",
					},
				},
			}, "walking") :: statemachine.StateMachineType,
			_airborneStates = {
				[Enum.HumanoidStateType.Freefall] = true,
				[Enum.HumanoidStateType.Jumping] = true,
				[Enum.HumanoidStateType.Climbing] = true,
				[Enum.HumanoidStateType.Seated] = true,
				[Enum.HumanoidStateType.FallingDown] = true,
			},

			connections = {} :: { { name: string, connection: RBXScriptConnection, disconnect: () -> nil } },
			-- Store connections to avoid memory leaks
		} :: self,
		Movement
	)
end

--[[
    Initialize the walk system
]]
function Movement:walk(self: self)
	-- Load walk animation
	self._animate:LoadAnimation("walk", {
		Id = "rbxassetid://94049151700764", -- Replace with actual walk animation ID
		Weight = 1,
		Speed = 1,
	})

	-- Set base walking speed
	self.character.Humanoid.WalkSpeed = self.baseSpeed
	TweenPlus(self.character.Humanoid, {
		WalkSpeed = self.baseSpeed,
	}, {
		duration = 0.75,
		easingStyle = Enum.EasingStyle.Quad,
		easingDirection = Enum.EasingDirection.Out,
	}):Start()

	-- Handle walking animation
	local connection = RunService.Heartbeat:Connect(function()
		if self.isMoving() and self._statemachine:getCurrentState() == "walking" then
			local track = self._animate:Play("walk", 0.25)

			if track then
				-- Adjust animation speed based on movement
				if self._airborneStates[self.character.Humanoid:GetState()] then
					track:AdjustSpeed(0.25)
				else
					track:AdjustSpeed(1)
				end
			end
		else
			self._animate:Stop("walk")
		end
	end)

	-- Store the connection
	table.insert(self.connections, {
		name = "walkHeartbeat",
		connection = connection,
		disconnect = function()
			if connection then
				connection:Disconnect()
				connection = nil
			end
		end,
	})
end

--[[
   Initialize the sprint system
]]
function Movement:sprint(self: self)
	-- load animations
	self._animate:LoadAnimation("run", {
		Id = "rbxassetid://14243308122",
		Weight = 1,
		Speed = 1,
	})

	local stop = function()
		if self._statemachine:getCurrentState() ~= "walking" then
			self._statemachine:transition("walking")
			self.character.Humanoid.WalkSpeed -= self.maxSpeed
			self._animate:Stop("run")
			self.character:SetAttribute("AntiRegenerate", nil) -- allow stamina regeneration again
			--gamecamera:disconnect("camera_trail")
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default -- reset mouse behavior
			local speedForce = self.character.HumanoidRootPart:FindFirstChild("SpeedForce")
			if speedForce then
				speedForce:Destroy() -- clean up the speed force effect
			end

			-- Disconnect the heartbeat connection
			for i, conn in pairs(self.connections) do
				if conn.name == "sprintHeartbeat" then
					conn.disconnect()
					table.remove(self.connections, i)
					break -- stop sprinting
				end
			end
		end
	end

	local start = function()
		local condition = self._statemachine:getCurrentState() ~= "running"
		local condition2 = self.character:GetAttribute("Stamina") :: number > 0
		if condition and condition2 then
			self._statemachine:transition("running")
			self.character.Humanoid.WalkSpeed += self.maxSpeed
			if not self.isMoving() then
				stop()
				return
			end
			self._statemachine:transition("running")
			local track = self._animate:Play("run", 0.25)
			local connection = nil

			local visualEffects = ReplicatedStorage.Assets.VisualEffects :: Folder
			local speedForce = visualEffects.SpeedForce:Clone() :: BasePart & { ParticleEmitter }
			speedForce.Parent = self.character.HumanoidRootPart
			speedForce.CFrame = self.character.HumanoidRootPart.CFrame

			--gamecamera:trail()

			connection = RunService.Heartbeat:Connect(function(deltaTime: number)
				if not self.isMoving() then
					stop()
				end
				assert(track, "Track is nil, did you load the animation?")
				if self._airborneStates[self.character.Humanoid:GetState()] then
					track:AdjustSpeed(0.25)
				else
					track:AdjustSpeed(1)
				end
				local currentStamina = self.character:GetAttribute("Stamina") :: number

				local velocity = self.character.HumanoidRootPart.AssemblyLinearVelocity
				local value = math.clamp(velocity.Magnitude / 100, 0, 5)

				local sequence = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(1, value),
				})

				local offset = CFrame.new(3 + value, 0, 0) * CFrame.Angles(90, 90, 0)
				speedForce.CFrame = self.character.HumanoidRootPart.CFrame * offset

				for _, particle in ipairs(speedForce:GetChildren()) do
					if particle:IsA("ParticleEmitter") then
						-- manipulate the attachment's position based on character's velocity
						particle.Size = sequence
					end
				end

				if currentStamina and currentStamina > 0 then
					local staminaDrain = self.staminaRate * deltaTime
					currentStamina = math.max(currentStamina - staminaDrain, 0)
					self.character:SetAttribute("AntiRegenerate", true) -- prevent stamina regeneration
					self.character:SetAttribute("Stamina", currentStamina)
				else
					stop() -- stop sprinting if no stamina left
				end
			end)
			table.insert(self.connections, {
				name = "sprintHeartbeat",
				connection = connection,
				disconnect = function()
					if connection then
						connection:Disconnect()
						connection = nil
					end
				end,
			})
		end
	end
	local keybind: Enum.KeyCode = self.keybinds.sprint

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		if not gameProcessedEvent and input.KeyCode == keybind then
			if not self._debounces.sprint.active then
				start()
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		if not gameProcessedEvent and input.KeyCode == keybind then
			stop()
		end
	end)
end

--[[
	Initialize the jump system
]]
function Movement:jump(self: self)
	local state = Enum.HumanoidStateType.Jumping
	local function onJumpRequest()
		if not self._debounces.jump.active then
			if self.character.Humanoid.FloorMaterial ~= Enum.Material.Air then
				-- prevent mid air jumps
				self.character.Humanoid:ChangeState(state)
				self._debounces.jump.active = true
				task.delay(self._debounces.jump.cooldown, function()
					self._debounces.jump.active = false
				end)
				-- take stamina
				local currentStamina = self.character:GetAttribute("Stamina") :: number
				if currentStamina and currentStamina > 0 then
					local staminaDrain: number = self.staminaRate * 0.5 -- Jumping drains less stamina
					currentStamina = math.max(currentStamina - staminaDrain, 0)
					self.character:SetAttribute("AntiRegenerate", true) -- prevent stamina regeneration

					task.wait(0.8) -- wait a bit to ensure the jump is registered

					if self.character and self.character:IsDescendantOf(game.Workspace) then
						self.character:SetAttribute("Stamina", currentStamina)
						task.wait(0.5) -- wait a bit before allowing stamina regeneration
						self.character:SetAttribute("AntiRegenerate", nil) -- allow stamina regeneration again
					end
				end
			else
				self.character.Humanoid:SetStateEnabled(state, false)
			end
		end
	end
	UserInputService.JumpRequest:Connect(onJumpRequest)
end

function Movement:slide(self: self)
	-- // instances
	local velocity: LinearVelocity? = nil
	local align: AlignOrientation? = nil
	local isOnCooldown = false -- cooldown flag

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { self.character }
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local baseSpeed = 50
	local currentMultiplier = 1 -- Speed multiplier for sliding
	local maxMultiplier = 2 -- Maximum speed multiplier
	self._animate:LoadAnimation("slide", {
		Id = "rbxassetid://14608790956", -- Replace with actual animation ID
		Weight = 1,
		Speed = 1,
	})

	local stop = function()
		self._statemachine:transition("walking") -- stop sliding
		self.character.Humanoid.HipHeight = self._hip_height.normal -- reset hip height
		self._animate:Stop("slide")
		if velocity then
			velocity:Destroy() -- clean up the BodyVelocity instance
			velocity = nil
		end
		if align then
			align:Destroy() -- clean up the AlignOrientation instance
			align = nil
		end
		for i, conn in pairs(self.connections) do
			if conn.name == "slidePositionCheck" then
				conn.disconnect()
				table.remove(self.connections, i)
				break -- stop sliding
			end
		end

		task.delay(self._debounces.slide.cooldown, function()
			self._debounces.slide.active = true
		end)
	end

	local keybind = self.keybinds.slide
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		if not gameProcessedEvent and input.KeyCode == keybind then
			if isOnCooldown then
				return -- already on cooldown
			end
			isOnCooldown = true
			task.delay(self._debounces.slide.cooldown, function()
				isOnCooldown = false
			end)

			local direction = -self.character.HumanoidRootPart.CFrame.UpVector * 10
			local ray = workspace:Raycast(self.character.HumanoidRootPart.Position, direction, raycastParams)

			if
				self._statemachine:getCurrentState() == "sliding"
				or not self._debounces.slide.active
				or not ray
			then
				return -- already sliding or on cooldown
			end

			local attachment = Instance.new("Attachment")
			attachment.Parent = self.character.HumanoidRootPart

			velocity = Instance.new("LinearVelocity")
			velocity.Parent = self.character.HumanoidRootPart
			velocity.Attachment0 = attachment
			velocity.MaxForce = math.huge
			velocity.VectorVelocity = self.character.HumanoidRootPart.CFrame.LookVector * baseSpeed -- Double speed while sliding

			align = Instance.new("AlignOrientation")
			align.Attachment0 = attachment
			align.Parent = self.character.HumanoidRootPart
			align.MaxTorque = Vector3.new(3e5, 3e5, 3e5) -- Allow rotation
			align.Responsiveness = 200

			self._statemachine:transition("sliding")

			self.character.Humanoid.HipHeight = self._hip_height.slide -- Lower hip height for sliding
			self._animate:Play("slide", 0.25)

			local previousY = self.character.HumanoidRootPart.Position.Y
			currentMultiplier = 1 -- Reset multiplier when starting to slide

			local connection: RBXScriptConnection? = nil

			connection = RunService.RenderStepped:Connect(function(deltaTime: number)
				local currentY = self.character.HumanoidRootPart.Position.Y
				local verticalChange = (currentY - previousY)

				previousY = currentY

				-- align character to the slope
				if ray and gyro then
					local currentRightVector = self.character.HumanoidRootPart.CFrame.RightVector
					local upVector = ray.Normal
					local newFacialVector = currentRightVector:Cross(upVector)
					local translation = CFrame.fromMatrix(
						self.character.HumanoidRootPart.Position,
						currentRightVector,
						upVector,
						newFacialVector
					)
					gyro.CFrame = translation
				end

				if velocity then
					velocity.Velocity = self.character.HumanoidRootPart.CFrame.LookVector
						* (baseSpeed * currentMultiplier) -- Adjust velocity based on multiplier
				end

				if verticalChange < 0.1 and verticalChange > -0.1 then
					-- Slide forward (decrease speed until 0)
					if currentMultiplier > 1 then
						-- if too fast speed rate,
						--will multiply and speed will drop faster.
						currentMultiplier = math.clamp(
							currentMultiplier - self._velocity.forward * deltaTime,
							0,
							maxMultiplier
						)
					end
					currentMultiplier =
						math.clamp(currentMultiplier - (self._velocity.forward * deltaTime), 0, maxMultiplier)
				elseif verticalChange > 0 then
					-- slide up (decrease speed until 0)
					if currentMultiplier > 1 then
						-- if too fast, speed rate will multiply and
						-- drop faster!
						currentMultiplier = math.clamp(
							currentMultiplier - (self._velocity.upward * 2) * deltaTime,
							0,
							maxMultiplier
						)
					end
					currentMultiplier =
						math.clamp(currentMultiplier - self._velocity.upward * deltaTime, 0, maxMultiplier)
				else
					-- slide down (add up speed until max)
					currentMultiplier =
						math.clamp(currentMultiplier + self._velocity.downward * deltaTime, 0, maxMultiplier)
				end

				if currentMultiplier < 0.1 or not ray then
					stop() -- stop sliding if speed is too low or no raycast hit
				end
			end)
			table.insert(self.connections, {
				name = "slidePositionCheck",
				connection = connection,
				disconnect = function()
					if connection then
						connection:Disconnect()
						connection = nil
					end
				end,
			})
		elseif not gameProcessedEvent and input.KeyCode == self.keybinds.cancel_slide then
			if self._statemachine:getCurrentState() == "sliding" then
				stop() -- stop sliding if cancel key is pressed
				local cancelMultiplier = currentMultiplier
				-- [play slide cancel sound]
				-- push on cancel logic

				local pushVelocity = Instance.new("LinearVelocity")
				pushVelocity.Parent = self.character.HumanoidRootPart
				pushVelocity.Attachment0 = Instance.new("Attachment", self.character.HumanoidRootPart)
				pushVelocity.MaxForce = math.huge
				pushVelocity.VectorVelocity = (
					self.character.HumanoidRootPart.CFrame.LookVector
					* (self._push_velocity.forward * cancelMultiplier)
				) + (self.character.HumanoidRootPart.CFrame.UpVector * self._push_velocity.upward)
				task.delay(0.1, function()
					if pushVelocity then
						pushVelocity:Destroy()
					end
				end)
				stop()
			end
		end
	end)
end

function Movement:dash(self: self)
	if self._statemachine:getCurrentState() == "dashing" then
		return -- already dashing
	end
	self._statemachine:transition("dashing")
	self._animate:LoadAnimation("dash", {
		Id = "rbxassetid://14608790956", -- Replace with actual animation ID
		Weight = 1,
		Speed = 1,
	})
	local keybind = self.keybinds.dash
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		if not gameProcessedEvent and input.KeyCode == keybind then
			if self._debounces.dash.active then
				return -- already dashing or on cooldown
			end
			if self.character and self.character:IsDescendantOf(game.Workspace) then
				self.character:SetAttribute("AntiRegenerate", true) -- prevent stamina regeneration
			end
			self._animate:Play("dash", 0.25) -- play dash animation
			self._debounces.dash.active = true
			task.delay(self._debounces.dash.cooldown, function()
				self._debounces.dash.active = false
			end)

			local velocity = Instance.new("BodyVelocity") -- TODO) use linear velocity
			velocity.MaxForce = Vector3.new(1, 0, 1) * 30000
			velocity.Velocity = self.character.HumanoidRootPart.CFrame.LookVector * 100
			velocity.Parent = self.character.HumanoidRootPart

			-- now for some cool effects!!!11!

			local visualEffects = ReplicatedStorage.Assets.VisualEffects :: Folder
			local windForce = visualEffects.WindForce:Clone() :: BasePart & { Attachment | Beam }

			windForce.Parent = self.character.HumanoidRootPart

			local connection = nil
			connection = RunService.RenderStepped:Connect(function()
				if self._statemachine:getCurrentState() ~= "dashing" then
					if connection then
						connection:Disconnect() -- stop the connection if not dashing
						connection = nil
					end
					if windForce then
						task.wait(0.1) -- wait a bit before cleaning up
						windForce:Destroy() -- clean up the wind force effect
					end
					return
				end
				-- orient the wind force to the character's direction
				windForce.CFrame = self.character.HumanoidRootPart.CFrame
				local windForceOffset = Vector3.new(0, 2, 2) -- offset for the wind force
				windForce.Position = self.character.HumanoidRootPart.Position + windForceOffset
				local characterVelocity = self.character.HumanoidRootPart.AssemblyLinearVelocity
				-- these will run at the same time
				-- manipulate the beams and attachments based on character's velocity
				task.spawn(function()
					for _, beam in ipairs(windForce:GetChildren()) do
						if beam:IsA("Beam") then
							-- manipulate the beams transparency for a cool effect
							local value = math.clamp(characterVelocity.Magnitude / 100, 0, 1)
							local floats = NumberSequence.new({ -- set the default ones first
								NumberSequenceKeypoint.new(0.249, 1),
								NumberSequenceKeypoint.new(0.5, 0.254),
								NumberSequenceKeypoint.new(0.672, 0.27),
								NumberSequenceKeypoint.new(0.834, 0.989),
								-- set the dynamic ones
								NumberSequenceKeypoint.new(1, 1 - value), -- dynamic transparency based on speed
							})
							-- set the transparency of the beam
							beam.Transparency = floats
						end
					end
				end)
				task.spawn(function()
					for _, attachment in ipairs(windForce:GetChildren()) do
						if attachment:IsA("Attachment") and not string.find(attachment.Name, "base") then
							-- manipulate the attachment's position based on character's velocity
							attachment.CFrame.Position = windForceOffset + (characterVelocity * 0.1)
						end
					end
				end)
			end)

			-- run the cycle
			for i = 1, 8 do
				task.wait(0.1)
				if self._statemachine:getCurrentState() ~= "dashing" then
					break -- stop dashing if state changes
				end
				velocity.Velocity *= 0.7
				print(velocity.Velocity)
			end
			-- stop dashing
			velocity:Destroy() -- clean up the BodyVelocity instance
			self._statemachine:transition("walking") -- transition back to walking state
			self._animate:Stop("dash") -- stop dash animation
			if self.character and self.character:IsDescendantOf(game.Workspace) then
				self.character:SetAttribute("AntiRegenerate", nil) -- allow stamina regeneration again
			end
		end
	end)
end

function Movement:initialize(self: self)
	self:dash(self)
	self:sprint(self)
	self:jump(self)
	self:slide(self)
	self:walk(self)
end

function Movement.isMoving()
	if character and character.Humanoid then
		return character.Humanoid.MoveDirection.Magnitude > 0
	end
	return false
end

Movement.__overwrite = function(self: self, src: { any })
	-- reconcile self
	return dictionary.reconcile(self, src)
end

Movement.__tostring = function(self: self): string
	return "Movement: " .. self._statemachine:getCurrentState()
end

return Movement
