--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CardLibrary = require(ReplicatedStorage.Combat.CardLibrary)
local damage = require(ReplicatedStorage.Combat.Strike.damage)
local nearest = require(ReplicatedStorage.Combat.hitbox.nearest)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)
local visuals = require(ReplicatedStorage.Combat.framework.visuals.pyro)

local pyro = {
	moveset = {},
	lib = CardLibrary.PyroKatana,
}

local events = ReplicatedStorage.Events

local function getAnimationId(attackType: typemarshaller.AttackType): string?
	if not pyro.lib.AnimationIds then
		return nil
	end

	local animation = pyro.lib.AnimationIds[attackType]
	if animation then
		return animation
	end

	if attackType == "M1" and type(pyro.lib.AnimationIds.M1) == "table" then
		return pyro.lib.AnimationIds.M1[1]
	end

	return nil
end

local function playAnimation(player: Player, animationId: string?)
	if not animationId then
		return
	end

	if type(animationId) == "number" then
		animationId = `rbxassetid://{animationId}`
	end

	events.PlayAnimation:FireClient(player, animationId)
end

local function getDamageValue(attackType: typemarshaller.AttackType): number
	if pyro.lib.DefaultDamageValues and pyro.lib.DefaultDamageValues[attackType] then
		return pyro.lib.DefaultDamageValues[attackType]
	end

	return 10
end

function pyro.moveset.M1(player: Player, ...)
	local character = player.Character or player.CharacterAdded:Wait()

	events.EnableShiftlock:FireClient(player)

	local combat_data = events.GetPlayerCombatData:Invoke(player) :: typemarshaller.PlayerData

	if not combat_data then
		warn("Pyro M1 could not fetch combat data for", player)
		return false
	end

	print("pyro m1 combo index:", combat_data.combo_info.CurrentCombo)

	local combo_index = events.CallStyleFunction:Invoke(player, "Activate") :: number
	visuals.m1_slash(character, combo_index or 1)

	return true
end

function pyro.moveset.Skill(player: Player, ...)
	local character = player.Character
	if not character then
		return false
	end

	events.EnableShiftlock:FireClient(player)

	playAnimation(player, getAnimationId("Skill"))
	visuals.skill_slash(character, 10)

	local root = character.PrimaryPart
	if root then
		local targets = nearest(root, 10)
		for _, other_player in ipairs(targets) do
			damage:apply({
				amount = getDamageValue("Skill"),
				source = player,
				target = other_player,
				element = pyro.lib.Element,
				position = root.Position,
			})
		end
	end

	return true
end

function pyro.moveset.Ultimate(player: Player, ...)
	local character = player.Character
	if not character then
		return false
	end

	events.EnableShiftlock:FireClient(player)

	playAnimation(player, getAnimationId("Ultimate"))

	local root = character.PrimaryPart
	if not root then
		return false
	end

	local position = root.Position + root.CFrame.LookVector * 12
	visuals.ultimate(position)

	local targets = nearest(root, 12)
	for _, other_player in ipairs(targets) do
		damage:apply({
			amount = getDamageValue("Ultimate"),
			source = player,
			target = other_player,
			element = pyro.lib.Element,
			position = position,
		})
	end

	return true
end

function pyro.moveset.Support(player: Player, ...)
	local character = player.Character
	if not character then
		return false
	end

	events.EnableShiftlock:FireClient(player)

	playAnimation(player, getAnimationId("Support"))

	local duration = 8
	player:SetAttribute("HeatAuraActive", true)
	character:SetAttribute("HeatAuraActive", true)
	visuals.heat_aura(player, duration)

	task.delay(duration, function()
		if player and player.Parent then
			player:SetAttribute("HeatAuraActive", false)
		end
		if character and character.Parent then
			character:SetAttribute("HeatAuraActive", false)
		end
	end)

	return true
end

function pyro.GetMaxCombo()
	return pyro.lib.MaxCombo or 3
end

return pyro
