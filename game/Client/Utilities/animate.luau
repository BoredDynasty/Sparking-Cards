--!nonstrict

-- animate.luau

--[[
    Animation utility module for playing animations on characters
    Provides a clean API for loading and playing animations
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local player = playerMarshaller.get()

type AnimationObject = {
	Animation: Animation,
	Track: AnimationTrack?,
	Weight: number?,
	Speed: number?,
	IsLoaded: boolean,
}

type AnimationData = {
	Id: string,
	Weight: number?,
	Speed: number?,
}

-- Store animations in a global table
local animations: { [string]: AnimationObject } = {}
local currentCharacter = nil
local currentAnimator = nil

local function initialize(character: Model)
	currentCharacter = character
	currentAnimator = character.Humanoid.Animator
	animations = {}
end

local function loadAnimation(name: string, data: AnimationData): AnimationObject
	if animations[name] then
		return animations[name]
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

	animations[name] = animObject
	return animObject
end

local function playAnimation(name: string, fadeTime: number?): AnimationTrack?
	if not currentAnimator then
		warn("Animator not initialized. Call initialize() first.")
		return nil
	end

	local animObject: AnimationObject = animations[name]
	if not animObject then
		warn(`No animation found with name: {name}`)
		return nil
	end

	if not animObject.IsLoaded then
		animObject.Track = currentAnimator:LoadAnimation(animObject.Animation)
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

local function stopAnimation(name: string)
	local animObject: AnimationObject = animations[name]
	if animObject and animObject.Track then
		animObject.Track:Stop()
	end
end

local function stopAllAnimations(fadeTime: number?)
	fadeTime = fadeTime or 0.25
	for _, animObject: AnimationObject in animations do
		if animObject.Track then
			animObject.Track:Stop(fadeTime)
		end
	end
end

local function cleanup()
	stopAllAnimations()
	table.clear(animations)
	animations = {}
	currentAnimator = nil
	currentCharacter = nil
end

return {
	initialize = initialize,
	loadAnimation = loadAnimation,
	play = playAnimation,
	stop = stopAnimation,
	stopAll = stopAllAnimations,
	cleanup = cleanup,
}
