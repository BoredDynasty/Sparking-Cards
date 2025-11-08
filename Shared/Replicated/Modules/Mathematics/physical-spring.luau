--!strict

local physical_spring = {}
physical_spring.__index = physical_spring

--[[
   Creates a new physical_spring simulation instance.
   @param frequency Controls how fast the physical_spring oscillates (Hz)
   @param damping Controls how much the physical_spring slows down (0 = infinite bounce, 1 = no overshoot)
   @param initialPosition The starting position

   @return A new physical_spring object

   ```luau
   local physical_spring = require(path.to.physical-spring) -- Adjust path
   local spring = physical_spring.new(1.5, 0.7, 0) -- Frequency 1.5 Hz, Damping 0.7 (slightly bouncy)

   -- Connect to the game loop
   RunService.Heartbeat:Connect(function(dt)
      spring:Update(dt)
    
       -- Use spring:GetPosition() for your object's position (e.g., a GUI element, camera, or Part)
       -- print("Current position:", spring.Position) 
   end)

   -- Example: change the target position after a few seconds
   task.wait(3)
   spring:SetTarget(10)

]]
function physical_spring.new(frequency: number, damping: number, initialPosition: number)
	local self = setmetatable({}, physical_spring)

	self.Frequency = frequency
	self.Damping = damping
	self.Target = initialPosition

	self.Position = initialPosition
	self.Velocity = 0

	return self
end

--- Updates the spring simulation by a given time step (dt).
-- This uses the Fourth-Order Runge-Kutta (RK4) method for high accuracy.
function physical_spring:Update(dt: number)
	-- Map frequency and damping to angular frequency (omega) and damping ratio (zeta)
	local omega = 2 * math.pi * self.Frequency :: number
	local zeta = self.Damping :: number
	-- Assuming mass = 1, the spring constant (k) is omega^2 and the damping coefficient (c) is 2 * zeta * omega

	local current_pos = self.Position
	local current_vel = self.Velocity
	local target = self.Target :: number

	-- Define the derivative function for the physical_spring system (F=ma => a = F/m)
	-- a = -k*displacement - c*velocity
	local function derivatives(pos: number, vel: number): (number, number)
		local acceleration = -omega ^ 2 * (pos - target) - 2 * zeta * omega * vel
		return vel, acceleration -- return (velocity, acceleration)
	end

	-- RK4 integration steps
	-- k1: derivatives at the beginning of the interval
	local k1_v, k1_a = derivatives(current_pos, current_vel)
	-- k2: derivatives at the midpoint using k1 estimate
	local k2_v, k2_a = derivatives(current_pos + k1_v * dt * 0.5, current_vel + k1_a * dt * 0.5)
	-- k3: derivatives at the midpoint using k2 estimate
	local k3_v, k3_a = derivatives(current_pos + k2_v * dt * 0.5, current_vel + k2_a * dt * 0.5)
	-- k4: derivatives at the end of the interval using k3 estimate
	local k4_v, k4_a = derivatives(current_pos + k3_v * dt, current_vel + k3_a * dt)

	-- Weighted average of the derivatives to get the final update
	self.Position += (k1_v + 2 * k2_v + 2 * k3_v + k4_v) * dt / 6.0
	self.Velocity += (k1_a + 2 * k2_a + 2 * k3_a + k4_a) * dt / 6.0
end

function physical_spring:GetPosition(): number
	return self.Position
end

function physical_spring:SetTarget(target: number)
	self.Target = target
end

return physical_spring
