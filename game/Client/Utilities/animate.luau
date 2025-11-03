--!nonstrict

-- animate.luau

--[[
    Animation utility module for playing animations on characters
    Provides a clean API for loading and playing animations
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local promise = require(ReplicatedStorage.Packages.promise)
local trove = require(ReplicatedStorage.Packages.trove)

local player = playerMarshaller.get()

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
local currentCharacter = nil :: characterMarshaller.Character?
local currentAnimator = nil :: Animator?

local _trove = trove.new()

local function initialize()
	local character = characterMarshaller.get(player)

	currentCharacter = character

	local humanoid = character.Humanoid
	local animator = humanoid:WaitForChild("Animator", 10)

	assert(animator, "Animator not found in character")

	currentAnimator = animator

	table.clear(animations)
	animations = {}
end

local function loadAnimation(name: string, data: AnimationData): AnimationObject
	if animations[name] then
		return animations[name]
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = data.Id
	animation.Parent = currentCharacter

	_trove:Add(animation)

	local ok = false
	promise
		.new(function(resolve, reject)
			if currentAnimator then
				currentAnimator:LoadAnimation(animation)

				resolve("Loaded animation")
			else
				reject("No animator")
			end
		end)
		:andThen(function(result: string)
			print(result)

			ok = true
		end)
		:catch(function(result: string)
			ok = false

			print(result)
		end)

	local animObject: AnimationObject = {
		Animation = animation,
		Track = nil,
		Weight = data.Weight or 1,
		Speed = data.Speed or 1,
		IsLoaded = ok,
	}

	animations[name] = animObject

	animation.Destroying:Connect(function()
		pcall(_trove.Remove, _trove, animation)
		animations[name] = nil
	end)

	return animObject
end

local function playAnimation(name: string, fadeTime: number?): AnimationTrack?
	--assert(currentAnimator, "Animator not initialized. Call initialize() first.")

	local animObject: AnimationObject = animations[name]
	if not animObject then
		warn(`No animation found with name: {name}`)
		return nil
	end

	print("found animation: ", unpack(animObject))

	if not animObject.Track or not animObject.IsLoaded and currentAnimator ~= nil then
		animObject.Track = currentAnimator:LoadAnimation(animObject.Animation)
		animObject.IsLoaded = true
	end

	fadeTime = fadeTime or 0.25

	if animObject.Track then
		animObject.Track:Play(fadeTime)
		animObject.Track:AdjustWeight(animObject.Weight or 1)
		animObject.Track:AdjustSpeed(animObject.Speed or 1)

		return animObject.Track
	else
		warn("no animation-track?: ", unpack(animObject))
	end

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
	animations = {}
	currentAnimator = nil
	currentCharacter = nil
	_trove:Clean()
end

return {
	initialize = initialize,
	loadAnimation = loadAnimation,
	play = playAnimation,
	stop = stopAnimation,
	stopAll = stopAllAnimations,
	cleanup = cleanup,
	getTrack = getTrack,
}
