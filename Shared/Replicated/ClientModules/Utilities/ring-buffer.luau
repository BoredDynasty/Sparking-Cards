--!strict

-- ring-buffer.luau

local module = {}
module.__index = module

type self = {
	data: { any },
	head: number,
	tail: number,
	count: number,
	capacity: number,
}

export type RingBuffer = typeof(setmetatable({} :: self, module))

function module.new(capacity: number)
	local self = setmetatable({}, module) :: RingBuffer

	self.data = table.create(capacity)
	self.head = 1
	self.tail = 1
	self.count = 0
	self.capacity = capacity

	return self
end

function module:Write(self: RingBuffer, value: any)
	self.data[self.tail] = value
	self.tail = (self.tail % self.capacity) + 1
	if self.count < self.capacity then
		self.count += 1
	else
		self.head = (self.head % self.capacity) + 1
	end
end

return module
