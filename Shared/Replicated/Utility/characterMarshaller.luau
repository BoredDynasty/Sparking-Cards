--!strict

--[[
	character.luau
	
    Better typechecking for character objects!
    from Luauberries
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- maps players w their characters appearance loaded to their character
local CHARACTER_APPEARANCE_LOADED = {} :: { [Player]: typemarshaller.Character? }

local function GET_APPEARANCE_LOADED(player: Player): typemarshaller.Character?
	return CHARACTER_APPEARANCE_LOADED[player]
end

local character = {}

-- this function exists so u dont have to do
-- local character = (player.Character :: any) :: character.Character?
local function getCharacter(player: Player): typemarshaller.Character
	local char = player.Character

	character.added(player, function(c)
		char = c
	end)

	return char :: any
end

function character.removing_once(player: Player, f: (character: typemarshaller.Character) -> ()): () -> ()
	local removing_conn = player.CharacterRemoving:Once(f :: any)

	return function()
		if removing_conn.Connected then
			removing_conn:Disconnect()
		end
	end
end

function character.removing(player: Player, f: (character: typemarshaller.Character) -> ()): () -> ()
	local removing_conn = player.CharacterRemoving:Connect(f :: any)

	return function()
		removing_conn:Disconnect()
	end
end

function character.added(
	player: Player,
	f: (character: typemarshaller.Character) -> (),
	dont_run_for_existing_character: boolean?
): () -> ()
	local characterModel = getCharacter(player)
	local removing_conn: RBXScriptConnection? = nil
	local thread: thread

	if characterModel and not dont_run_for_existing_character then
		thread = task.defer(f, characterModel)

		removing_conn = player.CharacterRemoving:Once(function()
			coroutine.close(thread)
		end)
	end

	local added_conn = player.CharacterAdded:Connect(f :: any)

	return function()
		if removing_conn then
			removing_conn:Disconnect()
		end

		if added_conn then
			added_conn:Disconnect()
		end

		coroutine.close(thread)
	end
end

function character.all()
	local players = Players:GetPlayers()

	local list = table.create(#players)

	for _, player in ipairs(players) do
		local character = character.get(player)

		if character then
			table.insert(list, character)
		end
	end

	return list
end

function character.getRoot(player: Player): BasePart?
	local char = character.get(player)
	if not char then
		return nil
	end

	return char:FindFirstChild("HumanoidRootPart") :: any
end

function character.isRoot(inst: Instance): (boolean?, BasePart?)
	if not inst.Parent then
		return false, nil
	end
	if Players:FindFirstChild(inst.Parent.Name) then
		return true, inst :: BasePart
	end

	return false, nil
end

function character.getLimb(char: typemarshaller.Character, limbName: string): BasePart?
	local limb = char:FindFirstChild(limbName)

	if limb and limb:IsA("BasePart") then
		return limb
	end
	return nil
end

function character.halt(char: typemarshaller.Character)
	local humanoid = char:FindFirstChild("Humanoid") :: Humanoid
	if humanoid then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
	end
end

function character.continue(char: typemarshaller.Character)
	local humanoid = char:FindFirstChild("Humanoid") :: Humanoid
	if humanoid then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
	end
end

function character.added_once(
	player: Player,
	f: (character: typemarshaller.Character) -> (),
	dont_run_for_existing_character: boolean?
): () -> ()
	local characterModel = getCharacter(player)

	if characterModel and not dont_run_for_existing_character then
		local thread = task.defer(f, characterModel)

		local conn = player.CharacterRemoving:Once(function()
			coroutine.close(thread)
		end)

		return function()
			if conn.Connected then
				conn:Disconnect()
			end
			coroutine.close(thread)
		end
	else
		local conn = player.CharacterAdded:Once(f :: any)

		return function()
			if conn.Connected then
				conn:Disconnect()
			end
		end
	end
end

function character.appearance_loaded(
	player: Player,
	f: (character: typemarshaller.Character) -> (),
	dont_run_for_existing_character: boolean?
): () -> ()
	local characterModel = GET_APPEARANCE_LOADED(player)
	local removing_conn: RBXScriptConnection?
	local thread: thread

	if characterModel and not dont_run_for_existing_character then
		thread = task.defer(f, characterModel)

		removing_conn = player.CharacterRemoving:Once(function()
			coroutine.close(thread)
		end)
	end

	local added_conn = player.CharacterAppearanceLoaded:Connect(f :: any)

	return function()
		if removing_conn then
			removing_conn:Disconnect()
		end

		if added_conn then
			added_conn:Disconnect()
		end

		coroutine.close(thread)
	end
end

function character.appearance_loaded_once(
	player: Player,
	f: (character: typemarshaller.Character) -> (),
	dont_run_for_existing_character: boolean?
): () -> ()
	local characterModel = GET_APPEARANCE_LOADED(player)

	if characterModel and not dont_run_for_existing_character then
		local thread = task.defer(f, characterModel)

		local conn = player.CharacterRemoving:Once(function()
			coroutine.close(thread)
		end)

		return function()
			if conn.Connected then
				conn:Disconnect()
			end
			coroutine.close(thread)
		end
	else
		local conn = player.CharacterAppearanceLoaded:Once(f :: any)

		return function()
			if conn.Connected then
				conn:Disconnect()
			end
		end
	end
end

character.get_appearance_loaded = GET_APPEARANCE_LOADED
character.get = getCharacter

do
	local function on_player_added(player: Player)
		player.CharacterAppearanceLoaded:Connect(function(characterModel: any)
			CHARACTER_APPEARANCE_LOADED[player] = characterModel
		end)
		player.CharacterRemoving:Connect(function()
			CHARACTER_APPEARANCE_LOADED[player] = nil
		end)
	end

	Players.PlayerRemoving:Connect(function(player)
		CHARACTER_APPEARANCE_LOADED[player] = nil
	end)

	for _, player in Players:GetPlayers() do
		task.spawn(on_player_added, player)
	end
	Players.PlayerAdded:Connect(on_player_added)
end

return character
