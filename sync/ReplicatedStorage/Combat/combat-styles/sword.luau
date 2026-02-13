--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.Packet)

local combo = require(ReplicatedStorage.Combat.framework.utils.combo)
local damage = require(ReplicatedStorage.Combat.Strike.damage)
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local future = require(ReplicatedStorage.Packages.future)
local grip = require(ReplicatedStorage.Combat.framework.utils.grip)
local hydration = require(ReplicatedStorage.Utility.hydration)
local tablekit = require(ReplicatedStorage.Packages.tablekit)

-- sword.luau
-- the main controller for the sword weapons.
-- supports basic trails and hit detection

local module = {}
module.__index = module

local events = ReplicatedStorage.Events

export type BaseSword = Model & {
	Handle: BasePart,
	Blade: BasePart,
} & any

function module:GetRegistered()
	return {
		"Katana",
	}
end

function module:GetAnimations()
	return {
		[1] = "rbxassetid://123950065803851", -- M1_1
		[2] = "rbxassetid://117366009412180", -- M1_2
		[3] = "rbxassetid://89377068894374", -- M1_3,
	}
end

function module:GetMaxCombo()
	return 3
end

export type Sword = setmetatable<{
	model: BaseSword,
	player: Player,

	grip_info: grip.GripInfo,
	character: Model,
	_connections: { RBXScriptConnection },
	_hit_cache: { [Player]: number },
	_trail: Trail?,
	_can_hit: boolean,
}, typeof(module)>

function module.new(player: Player, sword_name: string)
	local sword_model = fetchAsset(sword_name) :: BaseSword
	assert(sword_model, "Couldn't fetch sword model: " .. sword_name)

	local self = setmetatable({}, module)

	local player_data = events.Orion.GetPlayerData:Invoke(player)
	assert(player_data, "no player data???????")

	if player_data.element_active then
		error("element already active")
	end

	self.model = sword_model
	self.player = player

	local character = player.Character or player.CharacterAdded:Wait()

	local grip_info = grip.createGrip(character, self.model, "Right", CFrame.new(0, 0, 2))

	self.grip_info = grip_info
	self.character = character

	-- runtime state
	self._connections = {} :: { RBXScriptConnection }
	self._hit_cache = {} :: { [Player]: number }
	self._trail = nil :: Trail?
	self._can_hit = false

	return self
end

function module:GetGripData(): grip.GripInfo
	return self.grip_info
end

function module:Activate()
	-- swing the sword (client animation + server hit window)
	print(string.format("%s swings the sword!", tostring(self.player and self.player.Name)))

	local player_data = events.Orion.GetPlayerData:Invoke(self.player)
	assert(player_data, "no player data???????")

	local combo_info = player_data.combo_info

	-- combo:increment(combo_info, os.clock())

	events.Orion.IncrementCombo:Invoke(self.player, combo_info, os.clock())

	-- get the corresponding animation from this weapon's animation set
	local animations = self:GetAnimations()
	local animation = animations[combo_info.CurrentCombo]

	if animation then
		Packet.ReplicateAnimation.sendTo({ identification = animation }, self.player)
	end

	-- enable hit window and create trail for visual feedback
	self._can_hit = true
	self:CreateTrail()

	-- schedule disabling hit window and removing trail
	task.delay(0.45, function()
		self._can_hit = false
		self:RemoveTrail()
	end)
end

function module:Equip()
	if self.model and self.character then
		self.model.Parent = self.character
	end

	local blade = self.model:FindFirstChild("Blade") :: BasePart?
	if blade and blade:IsA("BasePart") then
		local conn = blade.Touched:Connect(function(base_part)
			self:OnTouched(base_part)
		end)

		table.insert(self._connections, conn)
	end
end

function module:Unequip()
	for i, conn in ipairs(self._connections :: { RBXScriptConnection }) do
		if conn and conn.Connected then
			conn:Disconnect()
		end
	end

	local model = self.model :: Model

	self._connections = {}

	future.new(grip.removeGrip, model):Await()

	-- store model back into ReplicatedStorage so it isn't lost
	model.Parent = ReplicatedStorage
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
	if not target_player then
		return
	end

	if target_player == self.player then
		return
	end

	local last_hit = self._hit_cache[target_player] or 0
	if os.clock() - last_hit < 0.5 then
		return
	end

	self._hit_cache[target_player] = os.clock()

	local params = {
		amount = 10,
		source = self.player :: Player?,
		target = target_player,
	}

	future.Try(damage.__call, params):After(function(ok, result)
		print("hit: ", ok, result)
	end)
end

function module:CreateTrail()
	if self._trail then
		return
	end

	local handle = self.model:FindFirstChild("Handle") :: BasePart?
	local blade = self.model:FindFirstChild("Blade") :: BasePart?
	if not handle or not blade then
		return
	end

	local a0 = handle:FindFirstChild("_TrailAttach0")
	if not a0 then
		a0 = Instance.new("Attachment")
		a0.Name = "_TrailAttach0"
		a0.Parent = handle
	end

	local a1 = blade:FindFirstChild("_TrailAttach1")
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
		Color = ColorSequence.new(Color3.new(0.658824, 0.658824, 0.658824), Color3.new(1, 1, 1)),
		Parent = self.model,
	}

	self._trail = trail
end

function module:RemoveTrail()
	if not self._trail then
		return
	end

	if self._trail.Parent then
		self._trail:Destroy()
	end
end

function module:Destroy()
	self:Unequip()
	self:RemoveTrail()

	table.clear(self._hit_cache)

	table.clear(self)

	setmetatable(self, nil)
end

return module
