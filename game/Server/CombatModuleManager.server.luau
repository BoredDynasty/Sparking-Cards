--!strict
--[[
	CombatModuleManager.server.luau
	Manages loading, registration, and execution of combat modules (active abilities)
	and passive modules.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local orion = require(ReplicatedStorage.Combat.orion)
local CardLibrary = require(ReplicatedStorage.Combat.CardLibrary)
local Maid = require(ReplicatedStorage.Utility.Maid)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller) -- Required for player events

-- Define types for clarity
type Player = PlayerMarshaller.player
type AttackData = orion.AttackData
type Card = CardLibrary.Card
type MovesetFunction = (player: Player, attackData: AttackData, targetInfo: { targetPosition: Vector3?, targetInstanceId: number? }?) -> ()
type PassiveModule = {
	OnEquip: ((player: Player, cardName: string) -> ())?,
	OnUnequip: ((player: Player, cardName: string) -> ())?,
	OnPlayerDamaged: ((player: Player, source: Player?, damage: number, attackData: AttackData?) -> ())?,
	OnPlayerDealtDamage: ((player: Player, target: Player, damage: number, attackData: AttackData?) -> ())?,
	OnInterval: ((player: Player, deltaTime: number) -> ())?,
	-- Add other passive hooks as needed
}
type CombatModule = {
	moveset: { [string]: MovesetFunction }?,
	-- Other module-specific properties or functions if any
}

local CombatModuleManager = {}
CombatModuleManager._maid = Maid.new()
CombatModuleManager._loadedCombatModules = {} --- type: { [string]: CombatModule } -- Keyed by module name (e.g., "Frost")
CombatModuleManager._loadedPassiveModules = {} --- type: { [string]: PassiveModule } -- Keyed by passive module name (e.g., "FrostArmor")
CombatModuleManager._activePlayerPassives = {} --- type: { [number]: { cardName: string, passiveModule: PassiveModule, maid: Maid.Maid } } -- Key: Player.UserId

local COMBAT_MODULES_PATH = script.Parent.CombatModules
local PASSIVES_PATH = script.Parent.Passives -- Assuming a "Passives" folder parallel to "CombatModules"

function CombatModuleManager:Init()
	self:_loadAllCombatModules()
	self:_loadAllPassiveModules()
	self:_registerAttacksFromCardLibrary()
	self:_connectPlayerEvents()
	print("CombatModuleManager Initialized.")
end

function CombatModuleManager:_loadModule(moduleScript: ModuleScript): any?
	local success, moduleTable = pcall(require, moduleScript)
	if not success or typeof(moduleTable) ~= "table" then
		warn("Failed to load or invalid module type for:", moduleScript:GetFullName(), "| Error:", moduleTable)
		return nil
	end
	return moduleTable
end

function CombatModuleManager:_loadAllCombatModules()
	if not COMBAT_MODULES_PATH:IsA("Folder") then
		warn("CombatModules folder not found at:", COMBAT_MODULES_PATH:GetFullName())
		return
	end
	for _, moduleScript in ipairs(COMBAT_MODULES_PATH:GetChildren()) do
		if moduleScript:IsA("ModuleScript") then
			local moduleName = moduleScript.Name
			local combatModule = self:_loadModule(moduleScript)
			if combatModule and combatModule.moveset then
				self._loadedCombatModules[moduleName] = combatModule
				print("Loaded Combat Module:", moduleName)
			else
				warn("Combat Module", moduleName, "is missing a 'moveset' table or failed to load.")
			end
		end
	end
end

function CombatModuleManager:_loadAllPassiveModules()
	if not PASSIVES_PATH:IsA("Folder") then
		warn("Passives folder not found at:", PASSIVES_PATH:GetFullName())
		return
	end
	for _, moduleScript in ipairs(PASSIVES_PATH:GetChildren()) do
		if moduleScript:IsA("ModuleScript") then
			local moduleName = moduleScript.Name
			local passiveModule = self:_loadModule(moduleScript)
			if passiveModule then -- Basic check, specific functions like OnEquip are optional
				self._loadedPassiveModules[moduleName] = passiveModule
				print("Loaded Passive Module:", moduleName)
			else
				warn("Passive Module", moduleName, "failed to load or is not a table.")
			end
		end
	end
end

function CombatModuleManager:_registerAttacksFromCardLibrary()
	for cardName, cardData in pairs(CardLibrary) do
		if not cardData.Moveset then
			-- warn("Card", cardName, "has no Moveset defined in CardLibrary.")
			continue
		end

		-- Determine the combat module name.
		-- Convention: Card name (e.g., "FrostGauntlet") maps to module name "FrostGauntlet" or "Frost".
		-- This needs a robust way to map card names to their implementing module names.
		-- For now, let's assume the card name itself is the module name or can be derived.
		-- Example derivation: "FrostGauntlet" -> "Frost"
		local combatModuleName = cardName:gsub("Gauntlet", ""):gsub("Sword", ""):gsub("Polearm", ""):gsub("Claymore", "") -- Simple name derivation
		if combatModuleName == "Stone" then combatModuleName = "Earth" end -- Manual override example for "StoneClaymore" -> "Earth" module

		local combatModule = self._loadedCombatModules[combatModuleName]
		if not combatModule then
			-- warn("No loaded combat module found for derived name:", combatModuleName, "(from card:", cardName .. ")")
			continue
		end

		for actionType, orionAttackName in pairs(cardData.Moveset) do
			if typeof(orionAttackName) == "string" then
				local movesetFunction = combatModule.moveset and combatModule.moveset[actionType]

				if typeof(movesetFunction) == "function" then
					-- Default AttackData values (can be overridden by CardLibrary or module itself later)
					local attackData: AttackData = {
						Name = orionAttackName,
						Type = actionType, -- "M1", "Skill", "Ultimate", "Support"
						Damage = cardData.BaseDamageMultiplier and cardData.BaseDamageMultiplier * 10 or 10, -- Example damage
						Cooldown = 2, -- Example cooldown
						Range = 10, -- Example range
						MaxCombo = cardData.MaxCombo,
						NextComboAttack = nil, -- Will be set if this is part of a combo chain
						OnExecuteServer = function(player: Player, registeredAttackData: AttackData, targetInfo: { targetPosition: Vector3?, targetInstanceId: number? }?)
							-- Call the actual moveset function from the combat module
							(movesetFunction :: MovesetFunction)(player, registeredAttackData, targetInfo)
						end,
						-- Other fields like AnimationId, SoundId, HitboxProvider would ideally come from CardLibrary or be configured here
					}

					-- If it's an M1, check if there's a next combo attack defined in CardLibrary (e.g. FrostGauntlet_M1_2)
					if actionType:match("M1") and cardData.MaxCombo and cardData.MaxCombo > 1 then
						local currentComboNum = tonumber(actionType:match("M1_?(%d*)") or "1")
						if not currentComboNum then currentComboNum = 1 end -- if M1 is just "M1"

						if currentComboNum < cardData.MaxCombo then
							local nextComboAttackName = cardData.Moveset["M1_" .. tostring(currentComboNum + 1)]
								or cardName .. "_M1_" .. tostring(currentComboNum + 1) -- Fallback convention for next attack name

							-- A more robust way would be to have CardLibrary explicitly define combo chains.
							-- For now, we check if the next conventionally named attack is registered.
							-- This part is tricky as the next attack might not be in cardData.Moveset directly if it's not an input-triggered one.
							-- For this example, we assume NextComboAttack is defined in orion.RegisterAttack if needed.
							-- Let's assume CardLibrary.Moveset.M1 points to the *first* attack in the chain.
							-- Orion's M1 combo logic itself will handle finding NextComboAttack from the AttackData.
							-- We might need a way to register all combo pieces here if they are not directly in Moveset.
							-- For now, this example focuses on registering the primary actions.
							-- The `NextComboAttack` field in `AttackData` for orion.RegisterAttack would be set up here if known.
						end
					end

					orion.RegisterAttack(orionAttackName, attackData)
				else
					warn("Moveset function for", actionType, "not found in combat module", combatModuleName, "for attack", orionAttackName)
				end
			end
		end
	end
end

function CombatModuleManager:_handlePlayerProfileUpdate(player: Player, profile: any)
	-- This function would be called when a player's profile (especially EquippedCard) updates.
	-- For simplicity, we'll connect to PlayerAdded and a hypothetical ProfileUpdated event.

	local userId = player.UserId
	local oldPassiveData = self._activePlayerPassives[userId]

	if oldPassiveData and oldPassiveData.passiveModule.OnUnequip then
		pcall(oldPassiveData.passiveModule.OnUnequip, player, oldPassiveData.cardName)
		oldPassiveData.maid:Destroy()
	end
	self._activePlayerPassives[userId] = nil

	local equippedCardName = profile and profile.EquippedCard
	if not equippedCardName then return end

	local cardData = CardLibrary[equippedCardName]
	if not cardData or not cardData.PassiveModuleName then return end

	local passiveModule = self._loadedPassiveModules[cardData.PassiveModuleName]
	if not passiveModule then return end

	local newMaid = Maid.new()
	self._activePlayerPassives[userId] = {
		cardName = equippedCardName,
		passiveModule = passiveModule,
		maid = newMaid,
	}

	if passiveModule.OnEquip then
		pcall(passiveModule.OnEquip, player, equippedCardName)
	end

	-- Example: Hook for OnInterval if the passive module has it
	if passiveModule.OnInterval then
		newMaid:GiveTask(game:GetService("RunService").Heartbeat:Connect(function(dt)
			if self._activePlayerPassives[userId] and self._activePlayerPassives[userId].passiveModule == passiveModule then
				pcall(passiveModule.OnInterval, player, dt)
			end
		end))
	end
end

function CombatModuleManager:_connectPlayerEvents()
	-- When a player joins, check their profile for equipped passives
	self._maid:GiveTask(game:GetService("Players").PlayerAdded:Connect(function(playerInstance: Player)
		local player = playerMarshaller.get(playerInstance) -- Ensure we use the marshalled player object
		-- TODO: Need a reliable way to get the player's profile and listen for updates.
		-- This might involve a ProfileService that fires an event or provides a callback.
		-- For now, placeholder for profile retrieval:
		-- local profile = SomeProfileService:GetProfile(player)
		-- if profile then self:_handlePlayerProfileUpdate(player, profile) end
		-- SomeProfileService.ProfileUpdated:Connect(function(updatedPlayer, updatedProfile)
		--    if updatedPlayer == player then self:_handlePlayerProfileUpdate(player, updatedProfile) end
		-- end)
	end))

	self._maid:GiveTask(game:GetService("Players").PlayerRemoving:Connect(function(playerInstance: Player)
		local userId = playerInstance.UserId
		local passiveData = self._activePlayerPassives[userId]
		if passiveData and passiveData.passiveModule.OnUnequip then
			pcall(passiveData.passiveModule.OnUnequip, playerMarshaller.get(playerInstance), passiveData.cardName)
			passiveData.maid:Destroy()
		end
		self._activePlayerPassives[userId] = nil
	end))

	-- TODO: Connect to Orion's damage events or create signals within Orion to trigger passive hooks
	-- For example, orion might have a signal: orion.PlayerDamagedSignal:Connect(function(target, source, damage, attackData) ... )
	-- Inside that connection, we would call:
	-- self:TriggerPassive_OnPlayerDamaged(target, source, damage, attackData)
	-- self:TriggerPassive_OnPlayerDealtDamage(source, target, damage, attackData)
end

-- Functions to be called by other systems (e.g., Orion when damage occurs)
function CombatModuleManager:TriggerPassive_OnPlayerDamaged(player: Player, source: Player?, damage: number, attackData: AttackData?)
	local passiveData = self._activePlayerPassives[player.UserId]
	if passiveData and passiveData.passiveModule.OnPlayerDamaged then
		pcall(passiveData.passiveModule.OnPlayerDamaged, player, source, damage, attackData)
	end
end

function CombatModuleManager:TriggerPassive_OnPlayerDealtDamage(player: Player, target: Player, damage: number, attackData: AttackData?)
	local passiveData = self._activePlayerPassives[player.UserId]
	if passiveData and passiveData.passiveModule.OnPlayerDealtDamage then
		pcall(passiveData.passiveModule.OnPlayerDealtDamage, player, target, damage, attackData)
	end
end


function CombatModuleManager:Destroy()
	for userId, passiveData in pairs(self._activePlayerPassives) do
		if passiveData.passiveModule.OnUnequip then
			local player = playerMarshaller.getByUserId(userId)
			if player then
				pcall(passiveData.passiveModule.OnUnequip, player, passiveData.cardName)
			end
		end
		passiveData.maid:Destroy()
	end
	table.clear(self._activePlayerPassives)
	table.clear(self._loadedCombatModules)
	table.clear(self._loadedPassiveModules)
	self._maid:Destroy()
	print("CombatModuleManager Destroyed.")
end

-- Auto-initialize if this script is directly run by the game (e.g. in ServerScriptService)
-- Otherwise, another script (like a main server handler) would require and call :Init()
CombatModuleManager:Init()

return CombatModuleManager
