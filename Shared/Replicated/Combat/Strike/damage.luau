--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local damage_indicator = require(ReplicatedStorage.Effects["damage-indicator"])

export type Damage = {
	amount: number,
	source: Player?,
	target: Player,
	element: string?,
	position: Vector3?,
}

local module = {}
module.incoming = {} :: { Damage }
module.cancel = SignalPlus() :: SignalPlus.Signal<Player>

local HIT_DELAY = 2 / 16

local function remove_record(record: Damage)
	local index = table.find(module.incoming, record)
	if index then
		table.remove(module.incoming, index)
	end
end

local function get_reaction_multiplier(target: Player, target_character: Model): number
	if target:GetAttribute("Reaction_Melt") == true or target_character:GetAttribute("Reaction_Melt") == true then
		return 1.5
	end

	return 1
end

local function get_heat_aura_multiplier(target: Player, target_character: Model): number
	if target:GetAttribute("HeatAuraActive") == true or target_character:GetAttribute("HeatAuraActive") == true then
		return 0.75
	end

	return 1
end

--- Applies delayed, cancellable damage and stores the pending strike for interceptors.
--- @param parameters Damage
--- @return boolean
function module:apply(parameters: Damage): boolean
	if not parameters.amount or not parameters.target then
		warn("Invalid damage parameters")
		return false
	end

	local target_character = parameters.target.Character
	if not target_character then
		return false
	end

	local target_humanoid = target_character:FindFirstChild("Humanoid") :: Humanoid?
	if not target_humanoid then
		warn("No humanoid found on target")
		return false
	end

	local final_amount = math.max(0, parameters.amount)
	final_amount *= get_reaction_multiplier(parameters.target, target_character)
	final_amount *= get_heat_aura_multiplier(parameters.target, target_character)

	local record: Damage = {
		amount = final_amount,
		source = parameters.source,
		target = parameters.target,
		element = parameters.element,
		position = parameters.position,
	}

	-- Visual effect
	local target_root = target_character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if target_root then
		damage_indicator(final_amount, Color3.fromHex("#ffffff"), target_root)
	end

	-- Store damage record
	table.insert(module.incoming, record)

	-- Apply damage with delay
	local cancelled = false
	local thread = task.delay(2 / 16, function()
		if not cancelled then
			target_humanoid:TakeDamage(record.amount)
		end

		remove_record(record)
	end)

	-- Handle cancellation
	local connection: SignalPlus.Connection?
	connection = module.cancel:Connect(function(player)
		if player == parameters.target then
			cancelled = true
			task.cancel(thread)
			remove_record(record)

			if connection then
				connection:Disconnect()
				connection = nil
			end
		end
	end)

	task.delay(HIT_DELAY + 0.1, function()
		if connection then
			connection:Disconnect()
			connection = nil
		end
	end)

	return true
end

function module:GetIncomingForPlayer(player: Player): Damage?
	for _, data in ipairs(module.incoming) do
		if data.target == player then
			return data
		end
	end
	return nil
end

return module
