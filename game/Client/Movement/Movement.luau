--!nonstrict

local Movement = {}
Movement.__index = Movement

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

-- local MovementStructure = require(ReplicatedStorage.Structures.MovementStructure)
local Keyboard = require(ReplicatedStorage.Utility.input.Keyboard)
local Stamina = require(Players.LocalPlayer.PlayerScripts.Movement.Stamina)
local animate = require(StarterPlayer.StarterPlayerScripts.Utilities.animate)
local audio = require(ReplicatedStorage.Modules.audio)
local characterUtility = require(ReplicatedStorage.Utility.character)
local dictionary = require(ReplicatedStorage.Utility.dictionary)
local promise = require(ReplicatedStorage.Packages.promise)
local statemachine = require(ReplicatedStorage.Utility.statemachine)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local character = characterUtility.get(player)

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
	_keyboard: typeof(Keyboard.new()),
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
			},
			_animate = animate.new(character),
			_keyboard = Keyboard.new(),
			_audio = audio.new(),
			_debounces = {
				jump = {
					active = false,
					cooldown = 0.8, -- Cooldown time in seconds
				},
				slide = {
					active = true,
					cooldown = 2,
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
   Initialize the sprint system
]]
function Movement:sprint(self: self)
	-- load animations
	self._animate:LoadAnimation("run", {
		Id = "rbxassetid://14608790956", -- Replace with actual animation ID
		Weight = 1,
		Speed = 1,
	})

	local stop = function()
		if self._statemachine:getCurrentState() ~= "walking" then
			self._statemachine:transition("walking")
			self.character.Humanoid.WalkSpeed -= self.maxSpeed
			self._animate:Stop("run")
			self.character:SetAttribute("AntiRegenerate", nil) -- allow stamina regeneration again
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
			end
			local track = self._animate:Play("run", 0.25)
			local connection = nil
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
			start()
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
					local staminaDrain = self.staminaRate * 0.5 -- Jumping drains less stamina
					currentStamina = math.max(currentStamina - staminaDrain, 0)
					self.character:SetAttribute("AntiRegenerate", true) -- prevent stamina regeneration
					-- once the player has landed, deduct stamina.
					-- we can use the quadratic formula to calculate the time it takes to land

					task.wait(0.2) -- wait a bit to ensure the jump is registered

					-- Quadratic formula to solve for time t in:
					-- y(t) = y0 + v0*t + 0.5*g*t^2  where final y = 0 (ground level assumed)

					local landingTime: number = 0

					local positionY: number = self.character.HumanoidRootPart.Position.Y
					local velocityY: number = self.character.HumanoidRootPart.Velocity.Y

					-- Coefficients for the quadratic equation: 0.5*g*t^2 + v0*t + y0 = 0
					local a = 0.5 * workspace.Gravity -- 196.2 studs/s² / 2 or * .5
					local b = velocityY
					local c = positionY

					local discriminant = b ^ 2 - 4 * a * c

					if discriminant < 0 then
						landingTime = 0 -- No real solution, possibly already on ground
					end

					local sqrtDisc = math.sqrt(discriminant)

					-- We want the *positive* root of the quadratic
					local t1 = (-b + sqrtDisc) / (2 * a)
					local t2 = (-b - sqrtDisc) / (2 * a)

					landingTime = math.max(t1, t2, 1 / 60) -- Fallback to a small value if no valid time found
					task.delay(landingTime, function()
						if self.character and self.character:IsDescendantOf(game.Workspace) then
							self.character:SetAttribute("Stamina", currentStamina)
							task.wait(0.5) -- wait a bit before allowing stamina regeneration
							self.character:SetAttribute("AntiRegenerate", nil) -- allow stamina regeneration again
						end
					end)
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
	local velocity: BodyVelocity? = nil
	local gyro: BodyGyro? = nil
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
		task.spawn(function()
			if velocity then
				velocity:Destroy() -- clean up the BodyVelocity instance
				velocity = nil
			end
			if gyro then
				gyro:Destroy() -- clean up the BodyGyro instance
				gyro = nil
			end
		end)
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

			velocity = Instance.new("BodyVelocity")
			velocity.Parent = self.character.HumanoidRootPart
			velocity.MaxForce = Vector3.new(40000, 0, 40000) -- Allow horizontal movement only
			velocity.Velocity = self.character.HumanoidRootPart.CFrame.LookVector * baseSpeed -- Double speed while sliding

			gyro = Instance.new("BodyGyro")
			gyro.Parent = self.character.HumanoidRootPart
			gyro.MaxTorque = Vector3.new(3e5, 3e5, 3e5) -- Allow rotation
			gyro.P = 10000

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

				local pushVelocity = Instance.new("BodyVelocity")
				pushVelocity.Parent = self.character.HumanoidRootPart
				pushVelocity.MaxForce = Vector3.new(40000, 40000, 40000) -- Allow horizontal movement only
				pushVelocity.Velocity = (
					self.character.HumanoidRootPart.CFrame.LookVector
					* (self._push_velocity.forward * cancelMultiplier)
				) + (self.character.HumanoidRootPart.CFrame.UpVector * self._push_velocity.upward)
				task.delay(0.1, function()
					-- could've just use debris but who cares
					if pushVelocity then
						pushVelocity:Destroy() -- clean up the BodyVelocity instance
						pushVelocity = nil
					end
				end)
				stop()
			end
		end
	end)
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
