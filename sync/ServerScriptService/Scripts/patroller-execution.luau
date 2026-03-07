--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ai_backend = require(ReplicatedStorage.Modules["ai-backend"])
local random = require(ReplicatedStorage.Utility.random)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local trove = require(ReplicatedStorage.Packages.trove)

local _trove = trove.new()

local function createBindableExecution(): BindableEvent
	return _trove:Construct(Instance, "BindableEvent", script) :: BindableEvent
end

local debounce = false

local function bindableExecution()
	if script.Parent:IsA("Model") then
		local executor = ai_backend.new(script.Parent)

		task.synchronize()

		RunService.Heartbeat:ConnectParallel(function()
			if debounce then
				return
			end

			debounce = true

			executor:Patrol({ Vector3.new(-1837, 241, 36), Vector3.new(-1845, 241, 66) })

			debounce = false
		end)
	else
		warn("script is not parented under a valid NPC model.")
	end
end

local bindable = createBindableExecution()
bindable.Event:ConnectParallel(bindableExecution)
bindable:Fire()
