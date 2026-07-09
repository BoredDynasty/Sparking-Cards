--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local damage = require(ReplicatedStorage.Combat.Strike.damage)
local grip = require(ReplicatedStorage.Combat.framework.utils.grip)
local hydration = require(ReplicatedStorage.Utility.hydration)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- sword.luau
-- Server-authoritative controller for sword weapons.

local module = {}
module.__index = module

local events = ReplicatedStorage.Events

export type BaseSword = Model & {
	Handle: BasePart,
	Blade: BasePart,
}

export type ActivateOptions = {
	trail_color: ColorSequence?,
	hit_window: number?,
}

export type Sword = typeof(setmetatable(
	{} :: {
		model: BaseSword,
		player: Player,
		grip_info: grip.GripInfo?,
		character: Model,
		_connections: { RBXScriptConnection },
		_hit_cache: { [Player]: number },
		_trail: Trail?,
		_can_hit: boolean,
	},
	module
))

function module:GetRegistered(): { string }
	return {
		"Katana",
	}
end

function module:GetAnimations(): { [number]: string }
	return {
		[1] = "rbxassetid://123950065803851",
		[2] = "rbxassetid://117366009412180",
		[3] = "rbxassetid://89377068894374",
	}
end

function module:GetMaxCombo(): number
	return 3
end

function module.new(player: Player, sword_name: string): Sword
	local weaponry = ReplicatedStorage.Assets:WaitForChild("Weaponry")
	local sword_model = weaponry:WaitForChild(sword_name, 10) :: BaseSword?
	assert(sword_model, "Couldn't fetch sword model: " .. sword_name)

	local self = setmetatable({}, module) :: Sword
	self.model = sword_model:Clone() :: BaseSword
	self.player = player
	self.character = player.Character or player.CharacterAdded:Wait()
	self._connections = {}
	self._hit_cache = {}
	self._trail = nil
	self._can_hit = false

	self.grip_info =
		grip.createGrip(self.character, self.model, "Right", CFrame.new(0, 0, -1.5), Vector3.new(-90, 180, 0))

	return self
end

function module:GetGripData(): grip.GripInfo?
	return self.grip_info
end

--- Starts the sword hit window and plays the current combo animation.
--- @param combat_data typemarshaller.PlayerData
--- @param options ActivateOptions?
--- @return number
function module:Activate(combat_data: typemarshaller.PlayerData, options: ActivateOptions?): number
	local combo_info = combat_data.combo_info
	local max_combo = math.max(self:GetMaxCombo(), 1)

	if (os.clock() - combo_info.LastHitTime) < 2 then
		combo_info.CurrentCombo += 1
	else
		combo_info.CurrentCombo = 1
	end

	if combo_info.CurrentCombo > max_combo then
		combo_info.CurrentCombo = 1
	end

	combo_info.LastHitTime = os.clock()
	combo_info.MaxCombo = math.max(combo_info.MaxCombo, combo_info.CurrentCombo)

	local animation = self:GetAnimations()[combo_info.CurrentCombo]
	if animation then
		events.PlayAnimation:FireClient(self.player, animation)
	end

	self._can_hit = true
	self:CreateTrail(options and options.trail_color or nil)

	task.delay(options and options.hit_window or 0.45, function()
		self._can_hit = false
		self:RemoveTrail()
	end)

	return combo_info.CurrentCombo
end

function module:Equip()
	if self.model and self.character then
		self.model.Parent = self.character
	end

	local blade = self.model:FindFirstChild("Blade") :: BasePart?
	if not blade or not blade:IsA("BasePart") then
		return
	end

	local conn = blade.Touched:Connect(function(base_part)
		self:OnTouched(base_part)
	end)

	table.insert(self._connections, conn)
end

function module:Unequip()
	for _, conn in ipairs(self._connections) do
		if conn.Connected then
			conn:Disconnect()
		end
	end

	table.clear(self._connections)
	self:RemoveTrail()

	if self.grip_info then
		grip.removeGrip(self.model)
		self.grip_info = nil
	end

	self.model.Parent = ReplicatedStorage.Assets.Weaponry
end

function module:OnTouched(hit: Instance)
	if not self._can_hit then
		return
	end

	local character_model = hit:FindFirstAncestorWhichIsA("Model")
	if not character_model then
		return
	end

	local target_player = Players:GetPlayerFromCharacter(character_model)
	if not target_player or target_player == self.player then
		return
	end

	local last_hit = self._hit_cache[target_player] or 0
	if os.clock() - last_hit < 0.5 then
		return
	end

	self._hit_cache[target_player] = os.clock()

	damage:apply({
		amount = 10,
		source = self.player,
		target = target_player,
	})
end

function module:CreateTrail(color: ColorSequence?)
	if self._trail then
		return
	end

	local handle = self.model:FindFirstChild("Handle") :: BasePart?
	local blade = self.model:FindFirstChild("Blade") :: BasePart?
	if not handle or not blade then
		return
	end

	local a0 = handle:FindFirstChild("_TrailAttach0") :: Attachment?
	if not a0 then
		a0 = Instance.new("Attachment")
		a0.Name = "_TrailAttach0"
		a0.Parent = handle
	end

	local a1 = blade:FindFirstChild("_TrailAttach1") :: Attachment?
	if not a1 then
		a1 = Instance.new("Attachment")
		a1.Name = "_TrailAttach1"
		a1.Parent = blade
	end

	local trail = Instance.new("Trail")
	hydration(trail) {
		Attachment0 = a0,
		Attachment1 = a1,
		Lifetime = 0.25,
		Transparency = NumberSequence.new(0, 1),
		Color = color
			or ColorSequence.new(Color3.new(0.658824, 0.658824, 0.658824), Color3.new(1, 1, 1)),
		Parent = self.model,
	}

	self._trail = trail
end

function module:RemoveTrail()
	if not self._trail then
		return
	end

	self._trail:Destroy()
	self._trail = nil
end

function module:Destroy()
	self:Unequip()
	table.clear(self._hit_cache)
	table.clear(self :: any)
	setmetatable(self, nil)
end

return module
