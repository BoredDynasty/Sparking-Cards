--!strict

-- animate.luau

--[[
    Animation utility module for playing animations on characters
    Provides a clean API for loading and playing animations
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local trove = require(ReplicatedStorage.Packages.trove)

export type AnimationObject = {
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

-- Store animations in a global table
local animations: { [string]: AnimationObject } = {}

local player = playerMarshaller.get()
local character = characterMarshaller.get(player)

local humanoid = character.Humanoid
local animator = humanoid:WaitForChild("Animator") :: Animator

humanoid.Died:Connect(function()
	task.defer(function()
		character = characterMarshaller.get(player)
	end)
end)

local _trove = trove.new()

local function loadAnimation(name: string, data: AnimationData): AnimationObject
	if animations[name] then
		return animations[name]
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = data.Id
	animation.Parent = character

	_trove:Add(animation)

	local track = animator:LoadAnimation(animation)

	local animObject: AnimationObject = {
		Animation = animation,
		Track = track,
		Weight = data.Weight or 1,
		Speed = data.Speed or 1,
		IsLoaded = true,
	}

	animations[name] = animObject

	animation.Destroying:Connect(function()
		pcall(_trove.Remove, _trove, animation)
		animations[name] = nil
	end)

	return animObject
end

local function playAnimation(name: string, fadeTime: number?): AnimationTrack?
	--assert(animator, "Animator not initialized. Call initialize() first.")

	local animObject: AnimationObject = animations[name]
	if not animObject then
		warn(`No animation found with name: {name}`)
		return nil
	end

	fadeTime = fadeTime or 0.25

	local track = animObject.Track
	if track == nil then
		warn("no anim-track")
		return nil
	end

	track:Play()
	track:AdjustWeight(animObject.Weight or 1)
	track:AdjustSpeed(animObject.Speed or 1)

	return nil
end

local function stopAnimation(name: string, fadeTime: number?)
	local animObject: AnimationObject = animations[name]

	fadeTime = fadeTime or 0.25

	if animObject and animObject.Track then
		animObject.Track:Stop(fadeTime)
		animObject.Track.TimePosition = 0
	end
end

local function stopAllAnimations(fadeTime: number?)
	fadeTime = fadeTime or 0.25

	for _, animObject in pairs(animations) do
		if animObject.Track then
			animObject.Track:Stop(fadeTime)
			animObject.Track.TimePosition = 0
		end
	end
end

local function getTrack(name: string): AnimationTrack?
	local animObject: AnimationObject = animations[name]
	if animObject and animObject.Track then
		return animObject.Track
	end

	return nil
end

local function cleanup()
	stopAllAnimations(0.25)
	-- the animation instances are still there however.
	-- lets presume the character is detroyed.
	table.clear(animations)
	_trove:Clean()
end

return {
	loadAnimation = loadAnimation,
	play = playAnimation,
	stop = stopAnimation,
	stopAll = stopAllAnimations,
	cleanup = cleanup,
	getTrack = getTrack,
}
