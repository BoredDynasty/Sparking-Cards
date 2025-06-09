--!strict

--[[ 
    sequence.luau

    for wrapping interface effects.
]]

local Sequence = {}
Sequence.__index = Sequence

type self = {
	_tagged: { [string]: { [string]: any } },
}
export type Sequence = typeof(setmetatable({} :: self, Sequence))

function Sequence.new(): Sequence
	local self = setmetatable({}, Sequence)

	self._tagged = {}

	return self
end

function Sequence:tag(objects: { GuiObject }, thread: (...any) -> any?, event: RBXScriptSignal<...any>): ()
	for _, object in objects do
		assert(typeof(object) == "Instance" and object:IsA("GuiObject"), "Object must be a GuiObject")

		-- Create a new thread for the event
		local threadId = tostring(object:GetFullName()) .. "_" .. tostring(event)
		self._tagged[threadId] = { object = object, thread = thread, event = event }

		-- Connect the event to the thread
		event:Connect(function(...)
			if self._tagged[threadId] then
				self._tagged[threadId].thread(...)
			end
		end)
	end
end

return Sequence
