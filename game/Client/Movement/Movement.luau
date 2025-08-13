--!nonstrict

-- This module is a singleton and should not be instantiated.
-- It handles all player movement logic.
local Movement = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local UserInputService = game:GetService("UserInputService")

-- local MovementStructure = require(ReplicatedStorage.Structures.MovementStructure)
local Stamina = require("./Stamina")
local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
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

-- State variables
local springFOV = 70 -- Default FOV
local targetFOV = 70
local fovVelocity = 0
local stiffness = 100 -- 200
local damping = 10
local mass = 1

-- Speed parameters
local baseSpeed = 14
local maxSpeed = 18
local currentSpeed = 14
local accelerationRate = 2 -- Speed increase per second
local staminaRate = 10 -- Stamina drain rate per second

local keybinds = {
	sprint = Enum.KeyCode.LeftShift,
	slide = Enum.KeyCode.C,
	cancel_slide = Enum.KeyCode.Space,
	dash = Enum.KeyCode.V,
}
local _animate = animate.new(character)
-- local _audio = audio.new()
local _debounces = {
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
}
local _hip_height = {
	normal = 0,
	slide = -2,
}
local _velocity = {
	-- for speed loss
	forward = 1,
	upward = 2,
	downward = 1,
}
local _push_velocity = {
	forward = 50, -- Speed when pushing forward
	upward = 50, -- Speed when pushing upward
}

local _statemachine = statemachine.new({
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
}, "walking") :: statemachine.StateMachineType
local _airborneStates = {
	[Enum.HumanoidStateType.Freefall] = true,
	[Enum.HumanoidStateType.Jumping] = true,
	[Enum.HumanoidStateType.Climbing] = true,
	[Enum.HumanoidStateType.Seated] = true,
	[Enum.HumanoidStateType.FallingDown] = true,
}

local connections = {} :: { { name: string, connection: RBXScriptConnection, disconnect: () -> nil } }

local function isMoving()
	if character and character.Humanoid then
		return character.Humanoid.MoveDirection.Magnitude > 0
	end
	return false
end

local function walk()
	-- Load walk animation
	_animate:LoadAnimation("walk", {
		-- TODO: Verify this animation ID. If animations are not working, this is a likely culprit.
		Id = "rbxassetid://94049151700764",
		Weight = 1,
		Speed = 1,
	})

	-- Set base walking speed
	character.Humanoid.WalkSpeed = baseSpeed
	TweenPlus(character.Humanoid, {
		WalkSpeed = baseSpeed,
	}, {
		duration = 0.75,
		easingStyle = Enum.EasingStyle.Quad,
		easingDirection = Enum.EasingDirection.Out,
	}):Start()

	-- Handle walking animation
	local connection = RunService.Heartbeat:Connect(function()
		if isMoving() and _statemachine:getCurrentState() == "walking" then
			local track = _animate:Play("walk", 0.25)

			if track then
				-- Adjust animation speed based on movement
				if _airborneStates[character.Humanoid:GetState()] then
					track:AdjustSpeed(0.25)
				else
					track:AdjustSpeed(1)
				end
			end
		else
			_animate:Stop("walk")
		end
	end)

	-- Store the connection
	table.insert(connections, {
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

local function sprint()
	-- load animations
	_animate:LoadAnimation("run", {
		-- TODO: Verify this animation ID. If animations are not working, this is a likely culprit.
		Id = "rbxassetid://14243308122",
		Weight = 1,
		Speed = 1,
	})

	local function stop()
		if _statemachine:getCurrentState() ~= "walking" then
			_statemachine:transition("walking")
			character.Humanoid.WalkSpeed -= maxSpeed
			_animate:Stop("run")
			character:SetAttribute("AntiRegenerate", nil) -- allow stamina regeneration again
			--gamecamera:disconnect("camera_trail")
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default -- reset mouse behavior
			local speedForce = character.HumanoidRootPart:FindFirstChild("SpeedForce")
			if speedForce then
				speedForce:Destroy() -- clean up the speed force effect
			end

			-- Disconnect the heartbeat connection
			for i = #connections, 1, -1 do
				local conn = connections[i]
				if conn.name == "sprintHeartbeat" then
					conn.disconnect()
					table.remove(connections, i)
					break -- stop sprinting
				end
			end
		end
	end

	local function start()
		local condition = _statemachine:getCurrentState() ~= "running"
		local condition2 = (character:GetAttribute("Stamina") or 100) > 0
		if condition and condition2 then
			_statemachine:transition("running")
			character.Humanoid.WalkSpeed += maxSpeed
			if not isMoving() then
				stop()
				return
			end
			_statemachine:transition("running")
			local track = _animate:Play("run", 0.25)
			local connection = nil

			local visualEffects = ReplicatedStorage.Assets.VisualEffects :: Folder
			local speedForce = visualEffects.SpeedForce:Clone() :: BasePart & { ParticleEmitter }
			speedForce.Parent = character.HumanoidRootPart
			speedForce.CFrame = character.HumanoidRootPart.CFrame

			--gamecamera:trail()

			connection = RunService.Heartbeat:Connect(function(deltaTime: number)
				if not isMoving() then
					stop()
				end
				assert(track, "Track is nil, did you load the animation?")
				if _airborneStates[character.Humanoid:GetState()] then
					track:AdjustSpeed(0.25)
				else
					track:AdjustSpeed(1)
				end
				local currentStamina = character:GetAttribute("Stamina") :: number

				local velocity = character.HumanoidRootPart.AssemblyLinearVelocity
				local value = math.clamp(velocity.Magnitude / 100, 0, 5)

				local sequence = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(1, value),
				})

				local offset = CFrame.new(3 + value, 0, 0) * CFrame.Angles(90, 90, 0)
				speedForce.CFrame = character.HumanoidRootPart.CFrame * offset

				for _, particle in ipairs(speedForce:GetChildren()) do
					if particle:IsA("ParticleEmitter") then
						-- manipulate the attachment's position based on character's velocity
						particle.Size = sequence
					end
				end

				if currentStamina and currentStamina > 0 then
					local staminaDrain = staminaRate * deltaTime
					currentStamina = math.max(currentStamina - staminaDrain, 0)
					character:SetAttribute("AntiRegenerate", true) -- prevent stamina regeneration
					character:SetAttribute("Stamina", currentStamina)
				else
					stop() -- stop sprinting if no stamina left
				end
			end)
			table.insert(connections, {
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
	local keybindValue: Enum.KeyCode = keybinds.sprint

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		if not gameProcessedEvent and input.KeyCode == keybindValue then
			if not _debounces.sprint.active then
				start()
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		if not gameProcessedEvent and input.KeyCode == keybindValue then
			stop()
		end
	end)
end

local function jump()
	local state = Enum.HumanoidStateType.Jumping
	local function onJumpRequest()
		if not _debounces.jump.active then
			if character.Humanoid.FloorMaterial ~= Enum.Material.Air then
				-- prevent mid air jumps
				character.Humanoid:ChangeState(state)
				_debounces.jump.active = true
				task.delay(_debounces.jump.cooldown, function()
					_debounces.jump.active = false
				end)
				-- take stamina
				local currentStamina = character:GetAttribute("Stamina") :: number
				if currentStamina and currentStamina > 0 then
					local staminaDrain: number = staminaRate * 0.5 -- Jumping drains less stamina
					currentStamina = math.max(currentStamina - staminaDrain, 0)
					character:SetAttribute("AntiRegenerate", true) -- prevent stamina regeneration

					task.wait(0.8) -- wait a bit to ensure the jump is registered

					if character and character:IsDescendantOf(game.Workspace) then
						character:SetAttribute("Stamina", currentStamina)
						task.wait(0.5) -- wait a bit before allowing stamina regeneration
						character:SetAttribute("AntiRegenerate", nil) -- allow stamina regeneration again
					end
				end
			else
				character.Humanoid:SetStateEnabled(state, false)
			end
		end
	end
	UserInputService.JumpRequest:Connect(onJumpRequest)
end

local function slide()
	-- // instances
	local velocity: LinearVelocity? = nil
	local align: AlignOrientation? = nil
	local isOnCooldown = false -- cooldown flag

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { character }
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local slideBaseSpeed = 50
	local currentMultiplier = 1 -- Speed multiplier for sliding
	local maxMultiplier = 2 -- Maximum speed multiplier
	_animate:LoadAnimation("slide", {
		-- TODO: Verify this animation ID. If animations are not working, this is a likely culprit.
		Id = "rbxassetid://14608790956",
		Weight = 1,
		Speed = 1,
	})

	local function stop()
		_statemachine:transition("walking") -- stop sliding
		character.Humanoid.HipHeight = _hip_height.normal -- reset hip height
		_animate:Stop("slide")
		if velocity then
			velocity:Destroy() -- clean up the BodyVelocity instance
			velocity = nil
		end
		if align then
			align:Destroy() -- clean up the AlignOrientation instance
			align = nil
		end
		for i = #connections, 1, -1 do
			local conn = connections[i]
			if conn.name == "slidePositionCheck" then
				conn.disconnect()
				table.remove(connections, i)
				break -- stop sliding
			end
		end

		task.delay(_debounces.slide.cooldown, function()
			_debounces.slide.active = true
		end)
	end

	local keybindValue = keybinds.slide
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		if not gameProcessedEvent and input.KeyCode == keybindValue then
			if isOnCooldown then
				return -- already on cooldown
			end
			isOnCooldown = true
			task.delay(_debounces.slide.cooldown, function()
				isOnCooldown = false
			end)

			local direction = -character.HumanoidRootPart.CFrame.UpVector * 10
			local ray = workspace:Raycast(character.HumanoidRootPart.Position, direction, raycastParams)

			if _statemachine:getCurrentState() == "sliding" or not _debounces.slide.active or not ray then
				return -- already sliding or on cooldown
			end

			local attachment = Instance.new("Attachment")
			attachment.Parent = character.HumanoidRootPart

			velocity = Instance.new("LinearVelocity")
			velocity.Parent = character.HumanoidRootPart
			velocity.Attachment0 = attachment
			velocity.MaxForce = math.huge
			velocity.VectorVelocity = character.HumanoidRootPart.CFrame.LookVector * slideBaseSpeed -- Double speed while sliding

			align = Instance.new("AlignOrientation")
			align.Attachment0 = attachment
			align.Parent = character.HumanoidRootPart
			align.MaxTorque = Vector3.new(3e5, 3e5, 3e5) -- Allow rotation
			align.Responsiveness = 200

			_statemachine:transition("sliding")

			character.Humanoid.HipHeight = _hip_height.slide -- Lower hip height for sliding
			_animate:Play("slide", 0.25)

			local previousY = character.HumanoidRootPart.Position.Y
			currentMultiplier = 1 -- Reset multiplier when starting to slide

			local connection: RBXScriptConnection? = nil

			connection = RunService.RenderStepped:Connect(function(deltaTime: number)
				local currentY = character.HumanoidRootPart.Position.Y
				local verticalChange = (currentY - previousY)

				previousY = currentY

				-- align character to the slope
				if ray and align then
					local currentRightVector = character.HumanoidRootPart.CFrame.RightVector
					local upVector = ray.Normal
					local newFacialVector = currentRightVector:Cross(upVector)
					local translation = CFrame.fromMatrix(
						character.HumanoidRootPart.Position,
						currentRightVector,
						upVector,
						newFacialVector
					)
					-- FIX: 'gyro' was not defined, it should be 'align'
					align.CFrame = translation
				end

				if velocity and character:FindFirstChildOfClass("LinearVelocity") then
					velocity.VectorVelocity = character.HumanoidRootPart.CFrame.LookVector
						* (slideBaseSpeed * currentMultiplier) -- Adjust velocity based on multiplier
				end

				if verticalChange < 0.1 and verticalChange > -0.1 then
					-- Slide forward (decrease speed until 0)
					if currentMultiplier > 1 then
						currentMultiplier =
							math.clamp(currentMultiplier - _velocity.forward * deltaTime, 0, maxMultiplier)
					end
					currentMultiplier =
						math.clamp(currentMultiplier - (_velocity.forward * deltaTime), 0, maxMultiplier)
				elseif verticalChange > 0 then
					-- slide up (decrease speed until 0)
					if currentMultiplier > 1 then
						currentMultiplier = math.clamp(
							currentMultiplier - (_velocity.upward * 2) * deltaTime,
							0,
							maxMultiplier
						)
					end
					currentMultiplier =
						math.clamp(currentMultiplier - _velocity.upward * deltaTime, 0, maxMultiplier)
				else
					-- slide down (add up speed until max)
					currentMultiplier =
						math.clamp(currentMultiplier + _velocity.downward * deltaTime, 0, maxMultiplier)
				end

				if currentMultiplier < 0.1 or not ray then
					stop() -- stop sliding if speed is too low or no raycast hit
				end
			end)
			table.insert(connections, {
				name = "slidePositionCheck",
				connection = connection,
				disconnect = function()
					if connection then
						connection:Disconnect()
						connection = nil
					end
				end,
			})
		elseif not gameProcessedEvent and input.KeyCode == keybinds.cancel_slide then
			if _statemachine:getCurrentState() == "sliding" then
				stop() -- stop sliding if cancel key is pressed
				local cancelMultiplier = currentMultiplier
				-- [play slide cancel sound]
				-- push on cancel logic

				local pushVelocity = Instance.new("LinearVelocity")
				pushVelocity.Parent = character.HumanoidRootPart
				pushVelocity.Attachment0 = Instance.new("Attachment", character.HumanoidRootPart)
				pushVelocity.MaxForce = math.huge
				pushVelocity.VectorVelocity = (
					character.HumanoidRootPart.CFrame.LookVector
					* (_push_velocity.forward * cancelMultiplier)
				) + (character.HumanoidRootPart.CFrame.UpVector * _push_velocity.upward)
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

local function dash()
	if _statemachine:getCurrentState() == "dashing" then
		return -- already dashing
	end
	_statemachine:transition("dashing")
	_animate:LoadAnimation("dash", {
		-- TODO: Verify this animation ID. If animations are not working, this is a likely culprit.
		Id = "rbxassetid://14608790956",
		Weight = 1,
		Speed = 1,
	})
	local keybindValue = keybinds.dash
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		if not gameProcessedEvent and input.KeyCode == keybindValue then
			if _debounces.dash.active then
				return -- already dashing or on cooldown
			end
			if character and character:IsDescendantOf(game.Workspace) then
				character:SetAttribute("AntiRegenerate", true) -- prevent stamina regeneration
			end
			_animate:Play("dash", 0.25) -- play dash animation
			_debounces.dash.active = true
			task.delay(_debounces.dash.cooldown, function()
				_debounces.dash.active = false
			end)

			-- FIX: Replaced deprecated BodyVelocity with LinearVelocity
			local velocity = Instance.new("LinearVelocity")
			velocity.Attachment0 = Instance.new("Attachment", character.HumanoidRootPart)
			velocity.MaxForce = 30000
			velocity.VectorVelocity = character.HumanoidRootPart.CFrame.LookVector * 100
			velocity.Parent = character.HumanoidRootPart

			-- now for some cool effects!!!11!

			local visualEffects = ReplicatedStorage.Assets.VisualEffects :: Folder
			local windForce = visualEffects.WindForce:Clone() :: BasePart & { Attachment | Beam }

			windForce.Parent = character.HumanoidRootPart

			local connection = nil
			connection = RunService.RenderStepped:Connect(function()
				if _statemachine:getCurrentState() ~= "dashing" then
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
				windForce.CFrame = character.HumanoidRootPart.CFrame
				local windForceOffset = Vector3.new(0, 2, 2) -- offset for the wind force
				windForce.Position = character.HumanoidRootPart.Position + windForceOffset
				local characterVelocity = character.HumanoidRootPart.AssemblyLinearVelocity
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
				if _statemachine:getCurrentState() ~= "dashing" or not velocity then
					break -- stop dashing if state changes
				end
				velocity.VectorVelocity *= 0.7
				print(velocity.VectorVelocity)
			end
			-- stop dashing
			if velocity then
				velocity:Destroy() -- clean up the BodyVelocity instance
			end
			_statemachine:transition("walking") -- transition back to walking state
			_animate:Stop("dash") -- stop dash animation
			if character and character:IsDescendantOf(game.Workspace) then
				character:SetAttribute("AntiRegenerate", nil) -- allow stamina regeneration again
			end
		end
	end)
end

function Movement.initialize()
	Stamina:initialize()
	dash()
	sprint()
	jump()
	slide()
	walk()
end

return Movement
