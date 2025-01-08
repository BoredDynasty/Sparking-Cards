--!strict

-- Client.client.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- // Variables -- //

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local character = player.Character or player.CharacterAdded:Wait()

---------------------------------- Cards --------------------------------

local cardChoices = {
	Fire = Enum.KeyCode.One,
	Frost = Enum.KeyCode.Two,
}

local function getChoice(input, gameProcessed)
	if gameProcessed then
		return
	end
	for choice, keyCode in pairs(cardChoices) do
		if input.KeyCode == keyCode then
			print(`{player.DisplayName} chose: {choice}`)
			return choice
		end
	end
end

local function onInputBegan(input, gameProcessed)
	local choice = getChoice(input, gameProcessed)
	if choice then
		print("Player chose: ", choice)
		-- Send choice to server
		local sendCardChoice: RemoteEvent = ReplicatedStorage.RemoteEvents.SendCardChoice
		sendCardChoice:FireServer(choice)
	end
end

UserInputService.InputBegan:Connect(onInputBegan)

---------------------------------- Combat --------------------------------

-- Function to rotate the character based on mouse position
local function updateCharacterFacing(humanoidRootPart: BasePart)
	local mousePosition = mouse.Hit.p -- Get the mouse's world position
	local characterPosition = humanoidRootPart.Position

	-- Calculate the direction the character should face (Y-axis ignored)
	local direction = (Vector3.new(mousePosition.X, characterPosition.Y, mousePosition.Z) - characterPosition).unit
	print(`Got direction: {direction}`)
	-- Set the character's CFrame to face that direction
	humanoidRootPart.CFrame = CFrame.lookAt(characterPosition, characterPosition + direction)
	print("Set RootPart.CFrame: ", humanoidRootPart.CFrame)
end

local function getAnimations(folder: Folder)
	local animationTable = {}
	for _, animation: Animation in folder:GetChildren() do
		if animation:IsA("Animation") then
			table.insert(animationTable, animation)
		end
	end
end

local function playNextAnimation(folder: { Animation }, i: number)
	if i == 0 then
		print(`Couldn't find next anims: {folder}, {i}`)
		return false
	end
	i += 1 -- Increment
	if i >= #folder then
		print("Getting animation(s): ", folder, i)
	end
	-- Play the current animation
	local selectedAnimation = folder[i]
	selectedAnimation:Play()
end

local function onTarget(humanoidRootPart: BasePart)
	local WeaponClass = require(ReplicatedStorage.Classes.WeaponClass)
	local range =
		tonumber(humanoidRootPart.ExtentsCFrame * CFrame.new(3, humanoidRootPart.ExtentsCFrame.YVector, 3))
	if range then
		print("Got range: ", range)
		local otherPlayer = WeaponClass:Raycast(range)
		if otherPlayer and player then
			print("otherPlayer: ", otherPlayer)
			local DamageIndict = require(ReplicatedStorage.Classes.WeaponClass.DamageIndict)
			DamageIndict(otherPlayer, 15, true)
		end
	end
end

-- [TODO)
