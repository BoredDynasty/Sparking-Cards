--!strict
--[=[
	CameraController
	@class CameraController

	Orchestrates camera effects by managing a collection of camera modules.
	It operates on a single RenderStep connection for performance and uses Trove for cleanup.
]=]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.trove)

local CameraController = {}
CameraController.__index = CameraController

function CameraController.new()
	local self = setmetatable({}, CameraController)

	self._trove = Trove.new()
	self._effects = {}
	self._camera = workspace.CurrentCamera

	return self
end

function CameraController:Add(effectName: string, effectModule: any)
	local effect = effectModule.new(self)
	self._effects[effectName] = effect
	self._trove:Add(effect)
	return effect
end

function CameraController:Start()
	self._trove:Connect(RunService:BindToRenderStep("Camera", Enum.RenderPriority.Camera.Value, function(deltaTime: number)
		local cframe = self._camera.CFrame

		for _, effect in pairs(self._effects) do
			if effect.Update then
				cframe = effect:Update(deltaTime, cframe)
			end
		end

		self._camera.CFrame = cframe
	end))
end

function CameraController:Get(effectName: string)
	return self._effects[effectName]
end

function CameraController:Destroy()
	self._trove:Destroy()
	RunService:UnbindFromRenderStep("Camera")
end

return CameraController
