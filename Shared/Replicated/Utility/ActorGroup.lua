--!nocheck

local ScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local IS_CLIENT = RunService:IsClient()
local player = game:GetService("Players").LocalPlayer

local templates = script.Templates

local client = templates.Client
local server = templates.Server

local groupContainer = Instance.new("Folder")
groupContainer.Name = "ACTOR_GROUPS"
groupContainer.Parent = IS_CLIENT and player.PlayerScripts or ScriptService

local actorTemplate = IS_CLIENT and client or server

local RANDOM = Random.new(tick())

local ActorGroup = {}

-- Queries a free worker to work with the given assignment.
-- Will call the callback function once completed.
function ActorGroup:WorkAsync(callback: (result: { any }) -> (), assignment: any)
	local taskId = HttpService:GenerateGUID(false):sub(1, 4)

	self._buffer[taskId] = {}
	self._callbacks[taskId] = { n = 1, fn = callback }

	local actor = self._actors[RANDOM:NextInteger(1, #self._actors)]

	task.defer(actor.SendMessage, actor, "Work", taskId, assignment)
end

-- Queries multiple free workers (if available) to work with the given assignments.
-- Will call the callback function once completed.
function ActorGroup:BulkWorkAsync(callback: (results: { any }) -> (), assignments: { any })
	local taskId = HttpService:GenerateGUID(false):sub(1, 4)

	if #assignments > #self._actors then
		error(`Number of assignments too large: {#assignments}`)
	end

	self._buffer[taskId] = {}
	self._callbacks[taskId] = { n = #assignments, fn = callback }

	for i = 1, #assignments do
		local actor = self._actors[i]
		task.defer(actor.SendMessage, actor, "Work", taskId, assignments[i])
	end
end

-- Queries a free wprker to work with the given assignment.
-- Waits until it finishes and returns the result.
function ActorGroup:AwaitWorkAsync(assignment: any): { any }?
	local running = coroutine.running()
	self:WorkAsync(function(result)
		task.defer(running, result)
	end, assignment)

	return coroutine.yield()
end

-- Queries multiple free workers (if available) to work with the given assignments.
-- Waits until it finishes and returns the result.
function ActorGroup:AwaitBulkWorkAsync(assignments: { any }): { any }?
	local running = coroutine.running()
	self:BulkWorkAsync(assignments, function(results)
		task.defer(running, results)
	end, assignments)

	return coroutine.yield()
end

-- Batches an assignment array into multiple nested assignments, for bulk assignment purposes.
function ActorGroup:BatchAssignments(assignments: { any }, batchSize: number?): { { any } }
	local numActors = #self._actors

	batchSize = batchSize or math.ceil(#assignments / numActors)

	local batches = {}

	for i = 1, #assignments, batchSize do
		local batchEnd = math.min(i + batchSize - 1, #assignments)

		local batch = {}

		for j = i, batchEnd do
			batch[#batch + 1] = assignments[j]
		end

		batches[#batches + 1] = batch
	end

	return batches
end

-- Clears this <code>ActorGroup</code> from memory.
function ActorGroup:Destroy()
	if self._group then
		self._group:Destroy()
	end

	table.clear(self._buffer)

	setmetatable(self, nil)
	table.clear(self)
end

-- Create a new <code>ActorGroup</code>.
local function ag_new(module: ModuleScript, count: number)
	assert(
		module ~= nil and (typeof(module) == "Instance" and module:IsA("ModuleScript")),
		"Bad module argument."
	)
	assert(count ~= nil and typeof(count) == "number", "Bad count argument.")

	local group = Instance.new("Model")
	group.Name = "ActorGroup"
	group.Parent = groupContainer

	local actorFolder = Instance.new("Folder")
	actorFolder.Name = "Actors"
	actorFolder.Parent = group

	local result = Instance.new("BindableEvent")
	result.Name = "Result"
	result.Parent = group

	local actors = {}

	for i = 1, count do
		local actor = actorTemplate:Clone()
		actor.Name = tostring(i)
		actor.Module.Value = module
		actor.Result.Value = result

		actor.Parent = actorFolder

		actors[i] = actor
	end

	local actorGroup = setmetatable({
		_buffer = {},
		_callbacks = {},
		_actors = actors,
		_group = group,
		_result = result,
	}, {
		__index = ActorGroup,
	})

	group.Destroying:Once(function()
		actorGroup:Destroy()
	end)

	result.Event:Connect(function(taskId, ...)
		local buf = actorGroup._buffer[taskId]
		local callback = actorGroup._callbacks[taskId]
		local len = #buf

		local numargs = select("#", ...)
		buf[len + 1] = numargs == 1 and ... or { ... }

		if (len + 1) < callback.n then
			return
		end

		-- selene: allow(shadowing)
		local result = actorGroup._buffer[taskId]
		actorGroup._buffer[taskId] = nil
		actorGroup._callbacks[taskId] = nil

		callback.fn(result)
	end)

	return actorGroup
end

return {
	new = ag_new,
}
