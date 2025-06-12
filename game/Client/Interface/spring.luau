--!nonstrict

-- spring.luau

local Spring = {}
Spring.__index = Spring

export type self = {
	Position: Vector2,
	Velocity: Vector2,
	Target: Vector2,
	Stiffness: number,
	Damping: number,
	Mass: number,
	Update: (self: self, deltaTime: number) -> boolean,
}

export type Spring = typeof(setmetatable({} :: self, Spring))

--[[
   ```luau

   local Spring = require(path.to.spring)

   -- Create a new spring with custom parameters
   local mySpring = Spring.new(
       Vector2.new(0, 0), -- initial position
       100,               -- stiffness (higher = more rigid)
       10,                -- damping (higher = less bouncy)
       1                  -- mass (affects momentum)
   )
    ```
]]
function Spring.new(initialPosition: Vector2, stiffness: number?, damping: number?, mass: number?): self
	return setmetatable({
		Position = initialPosition,
		Velocity = Vector2.new(0, 0),
		Target = initialPosition,
		Stiffness = stiffness or 100,
		Damping = damping or 10,
		Mass = mass or 1,
	}, Spring)
end

--[[
   ```luau

   -- In your update loop:
   local function update(dt)
      -- Set new target position
      mySpring:SetTarget(mySpring, Vector2.new(100, 100))
    
      -- Update spring physics
      local isMoving = mySpring:Update(mySpring, dt)
    
      -- Apply spring position to UI element
      uiElement.Position = UDim2.fromOffset(
         mySpring.Position.X,
         mySpring.Position.Y
      )
   end
]]
function Spring:Update(self: self, deltaTime: number): boolean
	local force = self.Target - self.Position
	force = force * self.Stiffness

	-- Apply damping force
	local dampingForce = self.Velocity * -self.Damping
	force = force + dampingForce

	-- Calculate acceleration (F = ma)
	local acceleration = force / self.Mass

	-- Update velocity (v = v0 + at)
	self.Velocity = self.Velocity + acceleration * deltaTime

	-- Update position (p = p0 + vt)
	local previousPosition = self.Position
	self.Position = self.Position + self.Velocity * deltaTime

	-- Check if spring has settled
	local moveThreshold = 0.001
	local velocityThreshold = 0.001

	local hasSettled = (self.Position - previousPosition).Magnitude < moveThreshold
		and self.Velocity.Magnitude < velocityThreshold
		and (self.Position - self.Target).Magnitude < moveThreshold

	return not hasSettled
end

function Spring:SetTarget(self: self, target: Vector2)
	self.Target = target
end

function Spring:SetStiffness(self: self, stiffness: number)
	self.Stiffness = stiffness
end

function Spring:SetDamping(self: self, damping: number)
	self.Damping = damping
end

function Spring:Reset(self: self, position: Vector2?)
	self.Position = position or self.Target
	self.Velocity = Vector2.new(0, 0)
end

return Spring
