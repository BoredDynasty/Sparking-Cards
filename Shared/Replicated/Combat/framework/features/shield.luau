--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local damage = require(ReplicatedStorage.Combat.Strike.damage)
local damage_indicator = require(ReplicatedStorage.Effects["damage-indicator"])
local future = require(ReplicatedStorage.Packages.future)
local observer = require(ReplicatedStorage.Utility.observer)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- shield.luau

export type ShieldData = {
	initialized: number, -- the time it was created
	duration: number,
	health: number, -- how much damage it absorbs
	holder: typemarshaller.Character,
	active: observer.Observer<boolean>,
}

local module = {}

local assets = ReplicatedStorage.Assets

function module.new(player: Player, duration: number, health: number)
	local character = player.Character or player.CharacterAdded:Wait()
	character:SetAttribute("ShieldActive", true)

	return {
		initialized = os.time(),
		duration = duration,
		health = health,
		holder = player.Character or player.CharacterAdded:Wait(),
		active = observer.new(false),
	}
end

function module:Intercept(data: ShieldData)
	if not module:IsActive(data) then
		print("shield not active")
		return
	end

	local player = Players:GetPlayerFromCharacter(data.holder)
	if not player then
		return
	end

	local character = data.holder

	local incoming_data = damage:GetIncomingForPlayer(player)
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
		module:SetActive(data, false)
		return
	end

	-- negate shield health
	data.health -= incoming_data.amount

	incoming_data.amount = 0

	damage_indicator(incoming_data.amount, Color3.new(0.164706, 0.552941, 0.921569), character.PrimaryPart)

	-- TODO) add some sfx or some visuals
end

function module:Render(data: ShieldData): RBXScriptConnection?
	-- render the shield model

	local player = Players:GetPlayerFromCharacter(data.holder)

	if not player then
		return nil
	end

	local character = data.holder

	local model = assets["Shield-01"]:Clone()

	model.Parent = character
	model.CFrame = character.PrimaryPart.CFrame

	local emitters = {}
	for _, emitter in pairs(model:GetDescendants()) do
		if emitter:IsA("ParticleEmitter") then
			table.insert(emitters, emitter)
		end
	end

	local force_field = emitters[1]
	local outer_rings = emitters[2]
	force_field.Enabled = true
	outer_rings.Enabled = true

	local character_scale = character:GetExtentsSize().Magnitude / 3
	print(character_scale)

	force_field.Size = NumberSequence.new(character_scale)
	outer_rings.Size = NumberSequence.new(character_scale * 2)

	-- use runservice

	local conn

	conn = RunService.Heartbeat:Connect(function()
		if not data.active:Get() and conn then
			force_field.Enabled = false
			outer_rings.Enabled = false

			task.delay(2, model.Destroy, model)

			conn:Disconnect()
			conn = nil

			return
		end

		model.CFrame = character.PrimaryPart.CFrame

		local incoming_data = damage:GetIncomingForPlayer(player)
		if not incoming_data then
			return
		end

		if incoming_data.amount > data.health then
			-- yeah the player is cooked
			module:SetActive(data, false)

			local shield_break = assets["Shield-Break-01"]:Clone()
			shield_break.Parent = character
			shield_break.CFrame = character.PrimaryPart.CFrame
			for i, emitter in pairs(shield_break:GetDescendants()) do
				if emitter:IsA("ParticleEmitter") then
					emitter:Emit(10)
				end
			end
			return
		end
	end)

	return conn
end

function module:SetActive(data: ShieldData, active: boolean)
	future.Try(function(...)
		data.active:Set(active)
		data.holder:SetAttribute("ShieldActive", false)
	end)
end

function module:IsActive(data: ShieldData): boolean
	return data.active:Get()
end

function module:Clean(data: ShieldData)
	data.active:Destroy()
end

return module
