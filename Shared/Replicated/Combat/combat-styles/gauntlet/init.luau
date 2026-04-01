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

-- gauntlet.luau
-- the main controller for the gauntlet weapons.
-- supports hit detection and combo system

local module = {}
module.__index = module

local events = ReplicatedStorage.Events

export type BaseGauntlet = Model & {
	Handle: BasePart,
} & any

function module:GetRegistered()
	return {
		"CryoGauntlet",
	}
end

function module:GetAnimations()
	return {
		[1] = "rbxassetid://81021084939952", -- M1_1
		[2] = "rbxassetid://107207958095996", -- M1_2
		[3] = "rbxassetid://82258928842933", -- M1_3
		[4] = "rbxassetid://109206938776854", -- M1_4
		[5] = "rbxassetid://85269329835096", -- M1_5
		[6] = "rbxassetid://137172673904833", -- M1_6
		[7] = "rbxassetid://131781435014944", -- M1_7
	}
end

function module:GetMaxCombo()
	return 7
end

export type Gauntlet = setmetatable<{
	model: BaseGauntlet,
	player: Player,

	grip_info: grip.GripInfo,
	character: Model,
	_connections: { RBXScriptConnection },
	_hit_cache: { [Player]: number },
	_can_hit: boolean,
	_hand: string,
}, typeof(module)>

function module.new(player: Player, gauntlet_name: string, hand: string?)
	local gauntlet_model = fetchAsset(gauntlet_name) :: BaseGauntlet
	assert(gauntlet_model, "Couldn't fetch gauntlet model: " .. gauntlet_name)

	local self = setmetatable({}, module)

	self.model = gauntlet_model
	self.player = player
	self._hand = hand or "Left"

	local character = player.Character or player.CharacterAdded:Wait()

	local grip_info = grip.createGrip(character, self.model, self._hand, CFrame.new(0, 0, 0))

	self.grip_info = grip_info
	self.character = character

	-- runtime state
	self._connections = {} :: { RBXScriptConnection }
	self._hit_cache = {} :: { [Player]: number }
	self._can_hit = false

	return self
end

function module:GetGripData(): grip.GripInfo
	return self.grip_info
end

function module:Activate()
	local orion = require(ReplicatedStorage.Combat.orion)

	-- punch with the gauntlet (client animation + server hit window)
	print(string.format("%s punches with gauntlet!", tostring(self.player and self.player.Name)))

	local player_data = orion.get_player_data()
	assert(player_data, "no player data???????")

	combo:increment(player_data.combo_info, os.clock())

	-- get the corresponding animation from this weapon's animation set
	local animations = self:GetAnimations()
	local animation = animations[player_data.combo_info.CurrentCombo]

	if animation then
		events.PlayAnimation:FireClient(self.player, animation)
	end

	-- enable hit window for punch detection
	self._can_hit = true

	-- schedule disabling hit window
	task.delay(0.45, function()
		self._can_hit = false
	end)
end

function module:Equip()
	if self.model and self.character then
		self.model.Parent = self.character
	end

	local handle = self.model:FindFirstChild("Handle") :: BasePart?
	if handle and handle:IsA("BasePart") then
		local conn = handle.Touched:Connect(function(base_part)
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

	future.new(grip.removeGrip, model)

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

	damage:apply(params)
end

function module:Destroy()
	self:Unequip()

	table.clear(self._hit_cache)

	table.clear(self)

	setmetatable(self, nil)
end

return module
