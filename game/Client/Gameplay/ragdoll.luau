--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local animate = require(StarterPlayer.StarterPlayerScripts.Utilities.animate)
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- ragdoll.luau

local player = playerMarshaller.get()
local character = characterMarshaller.get(player)

local ragdoll = {}
ragdoll._states = {}

local function savePartState(part: BasePart)
	return {
		Anchored = part.Anchored,
		CanCollide = part.CanCollide,
		Massless = part.Massless,
	}
end

local function restorePartState(part: BasePart, state)
	if state then
		part.Anchored = state.Anchored
		part.CanCollide = state.CanCollide
		part.Massless = state.Massless
	end
end

function ragdoll:On()
	if not character or not character:IsA("Model") then
		return
	end
	if ragdoll._states[character] then
		return
	end -- already ragdolled

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local state = { parts = {}, humanoid = {} }

	-- save humanoid states
	state.humanoid.PlatformStand = humanoid.PlatformStand
	state.humanoid.AutoRotate = humanoid.AutoRotate

	-- awh, staaaawp~!
	animate.stopAll()

	-- save parts and apply ragdoll-friendly properties
	for _, desc in ipairs(character:GetDescendants()) do
		if desc:IsA("BasePart") then
			state.parts[desc] = savePartState(desc)
			-- make part fall and collide
			desc.Anchored = false
			desc.CanCollide = true
			desc.Massless = false
		end
	end

	-- set humanoid to physics/ragdoll state
	humanoid.PlatformStand = true
	humanoid.AutoRotate = false
	-- try to force physics simulation state
	pcall(function()
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end)

	ragdoll._states[character] = state

	-- If the character is removed, clean up stored state
	character.AncestryChanged:Connect(function(_, parent)
		if not parent then
			ragdoll._states[character] = nil
		end
	end)
end

function ragdoll:Off()
	local state = ragdoll._states[character]
	if not state then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	-- restore parts
	for part, partState in pairs(state.parts) do
		if part and part:IsA("BasePart") then
			restorePartState(part, partState)
		end
	end

	-- restore humanoid
	if humanoid then
		humanoid.PlatformStand = state.humanoid.PlatformStand or false
		humanoid.AutoRotate = state.humanoid.AutoRotate or true
		pcall(function()
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
	end

	ragdoll._states[character] = nil
end

function ragdoll.isRagdolled(character: Model)
	return ragdoll._states[character] ~= nil
end

return ragdoll
