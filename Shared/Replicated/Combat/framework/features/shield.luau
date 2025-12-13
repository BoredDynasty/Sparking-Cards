--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local damage = require(ReplicatedStorage.Combat.Strike.damage)
local damage_indicator = require(ReplicatedStorage.Effects["damage-indicator"])
local future = require(ReplicatedStorage.Packages.future)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- shield.luau

export type ShieldData = {
	initialized: number, -- the time it was created
	duration: number,
	health: number, -- how much damage it absorbs
	holder: typemarshaller.Character,
	active: observer.Observer<boolean>,
}

export type ShieldModel = BasePart & {
	Main: Attachment & {
		ForceField: ParticleEmitter,
		OuterRings: ParticleEmitter,
	},
}

local module = {}

function module.new(player: Player, duration: number, health: number)
	return {
		initialized = os.time(),
		duration = duration,
		health = health,
		holder = characterMarshaller.get(player),
		active = observer.new(false),
	} :: ShieldData
end

function module:Intercept(data: ShieldData)
	local player = future.new(playerMarshaller.getFromCharacter, data.holder):Unwrap()

	if not player then
		return
	end

	local character = data.holder

	local incoming_data = damage:GetIcomingForPlayer(player)

	if not incoming_data then
		return
	end

	-- make the shield absorb the damage

	if (os.time() - data.initialized) > data.duration then
		-- our window ran out; womp womp
		module:SetActive(data, false)

		return
	end

	local shield_health = data.health

	if incoming_data.amount > shield_health then
		-- yeah the player is cooked
		return
	end

	-- negate shield health
	data.health -= incoming_data.amount

	damage_indicator(incoming_data.amount, Color3.new(0.164706, 0.552941, 0.921569), character.PrimaryPart)

	-- TODO) add some sfx or some visuals
end

function module:Render(data: ShieldData, model: ShieldModel): thread?
	-- render the shield model

	local player = future.new(playerMarshaller.getFromCharacter, data.holder):Unwrap()

	if not player then
		return nil
	end

	local character = data.holder

	model.Parent = character
	model.CFrame = character.PrimaryPart.CFrame

	local main_attachment = model:WaitForChild("Main") :: Attachment
	local force_field = main_attachment:WaitForChild("ForceField") :: ParticleEmitter
	local outer_rings = main_attachment:WaitForChild("OuterRings") :: ParticleEmitter

	force_field.Enabled = true
	outer_rings.Enabled = true

	local character_scale = character:GetExtentsSize().Magnitude / 3

	force_field.Size = NumberSequence.new(character_scale)
	outer_rings.Size = NumberSequence.new(character_scale * 2)

	return task.spawn(function()
		while data.active:Get() do
			debug.profilebegin("shield render loop")

			model.CFrame = character.PrimaryPart.CFrame

			RunService.Heartbeat:Wait()

			debug.profileend()
		end

		force_field.Enabled = false
		outer_rings.Enabled = false

		task.delay(2, model.Destroy, model)
	end)
end

function module:SetActive(data: ShieldData, active: boolean)
	return future.new(data.active.Set, data.active, active)
end

function module:IsActive(data: ShieldData): boolean
	return data.active:Get()
end

function module:Clean(data: ShieldData)
	data.active:Destroy()

	table.clear(data)
end

return module
