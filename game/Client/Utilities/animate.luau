--!nonstrict

-- animate.luau

--[[
    Animation utility module for playing animations on characters
    Provides a clean API for loading and playing animations
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local player = playerMarshaller.get()
local character = player.Character

type AnimationObject = {
	Animation: Animation,
	Track: AnimationTrack?,
	Weight: number?,
	Speed: number?,
	IsLoaded: boolean,
}

export type AnimationData = {
	Id: string,
	Weight: number?,
	Speed: number?,
}

local Animate = {}
Animate.__index = Animate

function Animate.new(char: typeof(character))
	local self = setmetatable({
		_character = char,
		_animator = char.Humanoid.Animator,
		_animations = {} :: { [string]: AnimationObject },
	}, Animate)

	return self
end

function Animate:LoadAnimation(name: string, data: AnimationData): AnimationObject
	if self._animations[name] then
		return self._animations[name]
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = data.Id

	local animObject: AnimationObject = {
		Animation = animation,
		Track = nil,
		Weight = data.Weight or 1,
		Speed = data.Speed or 1,
		IsLoaded = false,
	}

	self._animations[name] = animObject
	return animObject
end

function Animate:Play(name: string, fadeTime: number?): AnimationTrack?
	local animObject: AnimationObject = self._animations[name]
	if not animObject then
		warn(`No animation found with name: {name}`)
		return nil
	end

	if not animObject.IsLoaded then
		animObject.Track = self._animator:LoadAnimation(animObject.Animation)
		animObject.IsLoaded = true
	end
	fadeTime = fadeTime or 0.25

	if animObject.Track then
		animObject.Track:Play(fadeTime)
		animObject.Track:AdjustWeight(animObject.Weight or 1)
		animObject.Track:AdjustSpeed(animObject.Speed or 1)
		return animObject.Track
	end

	return nil
end

function Animate:Stop(name: string)
	local animObject: AnimationObject = self._animations[name]
	if animObject and animObject.Track then
		animObject.Track:Stop()
	end
end

function Animate:StopAll(fadeTime: number?)
	fadeTime = fadeTime or 0.25
	for _, animObject: AnimationObject in self._animations do
		if animObject.Track then
			animObject.Track:Stop(fadeTime)
		end
	end
end

function Animate:Destroy()
	self:StopAll()
	table.clear(self._animations)
	self._animations = nil :: any
	self._animator = nil :: any
	self._character = nil :: any
	setmetatable(self, nil)
end

return Animate
