--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- animate.luau

--[=[
    @within animate
    @function play
    @param character Model -- The character model to play the animation on
    @param animationId string -- The asset id of the animation
    @return AnimationTrack? -- The AnimationTrack if loaded and played, otherwise nil
    Plays the animation on the given character.
]=]

--[=[
    @within animate
    @function stop
    @param character Model -- The character model to stop the animation on
    @param animationId string -- The asset id of the animation
    Stops the animation on the given character.
]=]

--[=[
    @within animate
    @function load
    @param character Model -- The character model to load the animation on
    @param animationId string -- The asset id of the animation
    @return AnimationTrack? -- The AnimationTrack if loaded, otherwise nil
    Loads the animation on the given character.
]=]

--[=[
    @within animate
    @function getTrack
    @param character Model -- The character model to get the animation track from
    @param animationId string -- The asset id of the animation
    @return AnimationTrack? -- The AnimationTrack if found, otherwise nil
    Gets the AnimationTrack for the given animationId on the character.
]=]

local module = {}

local player = playerMarshaller.get()
local character = player.Character or player.CharacterAdded:Wait()

local function getAnimator(): Animator?
	-- Try to get the Animator from the Humanoid
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			return animator
		end
	end

	return nil
end

function module.load(animationId: string): AnimationTrack?
	local animator = getAnimator(character)
	if not animator then
		return nil
	end

	-- Check if already loaded
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		if track.Animation and track.Animation.AnimationId == animationId then
			return track
		end
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	local track = animator:LoadAnimation(animation)
	return track
end

function module.play(animationId: string, ...: any): AnimationTrack?
	local animator = getAnimator(character)
	if not animator then
		return nil
	end

	local track = module.load(animationId)
	if not track then
		return nil
	end

	-- Optionally pass arguments to Play (fadeTime, weight, speed)
	track:Play(...)
	return track
end

function module.stop(animationId: string): ()
	local animator = getAnimator(character)
	if not animator then
		return
	end

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		if track.Animation and track.Animation.AnimationId == animationId then
			track:Stop()
		end
	end
end

function module.stop_all()
	local animator = getAnimator(character)

	if not animator then
		return
	end

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		track:Stop()
	end
end

function module.getTrack(animationId: string): AnimationTrack?
	local animator = getAnimator(character)
	if not animator then
		return nil
	end

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		if track.Animation and track.Animation.AnimationId == animationId then
			return track
		end
	end
	return nil
end

return module
