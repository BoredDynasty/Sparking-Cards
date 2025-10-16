--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardLibrary = require(ReplicatedStorage.Combat.CardLibrary)
local Packet = require(ReplicatedStorage.Packet)
local boundingbox = require(ReplicatedStorage.Classes.boundingbox)
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local combo = require(ReplicatedStorage.Combat.framework.utils.combo)
local damage = require(ReplicatedStorage.Combat.Strike.damage)
local data = require(ReplicatedStorage.Combat.framework.utils.data)
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local grip = require(ReplicatedStorage.Combat.framework.utils.grip)
local nearest = require(ReplicatedStorage.Combat.framework.utils.nearest)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local promise = require(ReplicatedStorage.Packages.promise)
local space = require(ReplicatedStorage.Modules.Serialization.space)

-- Pyro.luau

local pyro = {
	moveset = {},
	lib = CardLibrary.PyroKatana,
}

local function comboToAnimationId(combo: number): string
	if combo == 1 then
		return "rbxassetid://123950065803851" -- M1_1
	elseif combo == 2 then
		return "rbxassetid://117366009412180" -- M1_2
	elseif combo == 3 then
		return "rbxassetid://89377068894374" -- M1_3
	else
		return "rbxassetid://123950065803851" -- Default to M1_1 if out of range
	end
end

function pyro.moveset.M1_1(player: playerMarshaller.player, ...: any?): any?
	print("Pyro M1_1 executed for player:", player.Name)
	-- Implement the actual attack logic here

	local character = characterMarshaller.get(player)

	local sword = character:FindFirstDescendant("Katana_Asset")
	if not sword then
		sword = fetchAsset("PyroKatana")
		sword.Parent = character
		sword:SetAttribute("Katana", character)

		local gripInfo = grip.createGrip(character, sword, "Right", CFrame.new(0, 0, 2))

		promise
			.new(function()
				data.arbitrary[player].gripInfo = gripInfo
			end)
			:catch(warn)

		return
	end
	if not sword:GetAttribute("Katana") then
		return
	end

	local combo_data = combo.incrementCombo(player)

	characterMarshaller.halt(character)

	Packet.ReplicateAnimation.sendTo({ identification = comboToAnimationId(combo_data.CurrentCombo) }, player)

	-- You can add hit detection and damage application logic here
	-- region checks!!!

	local primary = sword.PrimaryPart

	local range = vector.magnitude(pyro.lib.HitboxSize)
	print("range: ", range)

	local plr = nearest(primary, range)
	if plr then
		local params = {
			amount = 10 * pyro.lib.BaseDamageMultiplier,
			source = player,
			target = plr,
		}

		damage.__call(params)
	end

	task.delay(1, characterMarshaller.continue, character)

	return true
end

function pyro.moveset.BurningBlade_Skill(player: playerMarshaller.player, ...: any?): any?
	print("Pyro Skill executed for player:", player.Name)
	-- Implement the actual attack logic here
	return true
end

return pyro
