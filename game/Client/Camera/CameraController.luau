--!nonstrict
--[=[
	CameraController
	@class CameraController

	Orchestrates camera effects by managing a collection of camera modules.
	It operates on a single RenderStep connection for performance and uses Trove for cleanup.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local trove = require(ReplicatedStorage.Packages.trove)

local CameraController = {}
CameraController.__index = CameraController

export type cameraEffect = {
	new: (self: cameraEffect) -> cameraEffect,
	Update: (self: cameraEffect, deltaTime: number, cframe: CFrame) -> CFrame,
	Destroy: (self: cameraEffect) -> (),
}

function CameraController.new()
	local self = setmetatable({}, CameraController)

	self._trove = trove.new()
	self._effects = {}
	self._camera = workspace.CurrentCamera

	return self
end

function CameraController:Add<T>(effectName: string, effectModule: T): T
	local effect = effectModule.new(self)
	self._effects[effectName] = effect
	self._trove:Add(effect)
	return effect
end

function CameraController:Start()
	(self._trove :: typeof(trove.new())):BindToRenderStep(
		"Camera",
		Enum.RenderPriority.Camera.Value,
		function(deltaTime: number)
			local cframe = self._camera.CFrame

			for _, effect: cameraEffect in pairs(self._effects) do
				if effect.Update then
					cframe = effect:Update(deltaTime, cframe)
				end
			end

			self._camera.CFrame = cframe
		end
	)
end

function CameraController:Get<T>(effectName: string)
	return self._effects[effectName] :: T & cameraEffect & any
end

function CameraController:Destroy()
	self._trove:Clean()
	self._trove:Destroy()
end

return CameraController
