--!nonstrict
--[=[
	CameraController
	@class CameraController

	Orchestrates camera effects by managing a collection of camera modules.
	It operates on a single RenderStep connection for performance and uses Trove for cleanup.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local promise = require(ReplicatedStorage.Packages.promise)
local trove = require(ReplicatedStorage.Packages.trove)

local CameraController = {}
CameraController.__index = CameraController

export type cameraEffect = {
	new: (self: cameraEffect) -> cameraEffect,
	Update: (self: cameraEffect, deltaTime: number, cframe: CFrame) -> CFrame,
	Destroy: (self: cameraEffect) -> (),
}

type self = {
	_trove: typeof(trove.new()),
	_effects: { cameraEffect },
	_camera: Camera,
	_other: { [string]: (any) -> ...any? },
	_update: SignalPlus.Signal<number>,
}

function CameraController.new(): setmetatable<self, typeof(CameraController)>
	local self = setmetatable({}, CameraController)

	self._trove = trove.new()
	self._effects = {}
	self._camera = workspace.CurrentCamera
	self._other = {} --@type { [string]: (any) -> ...any? }
	self._update = SignalPlus() :: SignalPlus.Signal<number>

	return self
end

function CameraController:Add<T>(effectName: string, effectModule: T & cameraEffect): T
	local effect = effectModule.new(self)

	if self._effects[effectName] then
		warn("Camera effect with name " .. effectName .. " already exists. Overwriting.")
		self._effects[effectName]:Destroy()
	end

	self._effects[effectName] = effect
	self._trove:Add(effect)

	return effect
end

function CameraController:Start()
	local conn = RunService.RenderStepped:Connect(function(deltaTime: number)
		debug.profilebegin("camera_update")
		local cframe = self._camera.CFrame

		for i, effect in pairs(self._effects :: { [string]: cameraEffect }) do
			if effect.Update then
				debug.profilebegin(i .. "_update")
				cframe = effect:Update(deltaTime, cframe)
			end
		end

		for i, effect in pairs(self._other :: { [string]: { update: () -> (), params: any } }) do
			if effect.update then
				effect.update(deltaTime, table.unpack({ effect.params }))
			end
		end

		self._camera.CFrame = cframe

		--self.update:Fire(deltaTime)
		debug.profileend()
	end)

	self._trove:Add(conn)
end

function CameraController:Bind(name: string, f: (any) -> ...any?, ...)
	self._other[name] = {
		update = f,
		params = ... or nil,
	}
end

function CameraController:UnBind(name: string)
	return promise.new(function()
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
