--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local damage_indicator = require(ReplicatedStorage.Effects["damage-indicator"])

export type Damage = {
	amount: number,
	source: Player?,
	target: Player,
}

local module = {}
module.incoming = {} :: { Damage }
module.cancel = SignalPlus() :: SignalPlus.Signal<Player>

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

	-- Visual effect
	local target_root = target_character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if target_root then
		damage_indicator(parameters.amount, Color3.fromHex("#ffffff"), target_root)
	end

	-- Store damage record
	table.insert(module.incoming, parameters)

	-- Apply damage with delay
	local thread = task.delay(2 / 16, function()
		target_humanoid:TakeDamage(parameters.amount)
	end)

	-- Handle cancellation
	module.cancel:Connect(function(player)
		if player == parameters.target then
			task.cancel(thread)
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
