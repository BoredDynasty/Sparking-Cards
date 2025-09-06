--!nonstrict
--[=[
	CameraController
	@class CameraController

	Orchestrates camera effects by managing a collection of camera modules.
	It operates on a single RenderStep connection for performance and uses Trove for cleanup.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local promise = require(ReplicatedStorage.Packages.promise)
local trove = require(ReplicatedStorage.Packages.trove)
local url = require(ReplicatedStorage.Modules.Serialization.url)

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
	self._other = {} --@type { [string]: (any) -> ...any? }

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
			debug.profilebegin("camera_update")
			local cframe = self._camera.CFrame

			for _, effect: cameraEffect in pairs(self._effects) do
				if effect.Update then
					cframe = effect:Update(deltaTime, cframe)
				end
			end

			for _, effect in pairs(self._other) do
				if effect.update then
					effect.update(deltaTime, table.unpack({ effect.params }))
				end
			end

			self._camera.CFrame = cframe
			debug.profileend()
		end
	)
end

function CameraController:Bind(name: string, f: (any) -> ...any?, ...)
	self._other[name] = {
		update = f,
		params = ... or nil,
	}
end

function CameraController:UnBind(name: string)
	promise.new(function()
		self._other[name] = nil
	end)
end

function CameraController:Get<T>(effectName: string)
	return self._effects[effectName] :: T & cameraEffect & any
end

function CameraController:Destroy()
	self._trove:Clean()
	self._trove:Destroy()
end

return CameraController
