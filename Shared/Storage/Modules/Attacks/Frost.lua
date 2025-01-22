local Frost = {}
Frost.__index = Frost

Frost.Attack = "Ice-Lances"
Frost.Burst = "Absolute-Zero"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local FastCast = require(ReplicatedStorage.Packages.FastCast)

type options = {
	animation: Animation,
	sound: Sound,
	isCutscene: boolean,
	cutsceneDirectory: Folder | Instance,
}

function Frost:Attack(player: Player, params: options) -- LMB
	local mouse = player:GetMouse()

	local asset: BasePart = ServerStorage.Assets.IceLances
	local target = mouse.Hit
	local character = player.Character
	local rootPosition = character.HumanoidRootPart.CFrame

	local direction = (target.Position - rootPosition.Position).unit
	local activeCast = FastCast.new(asset, rootPosition.Position, direction, 100, player)
	activeCast:SetPosition(rootPosition.Position + direction * 2)
	-- Sets the position of this cast at this point in time to position.
	activeCast:SetAcceleration(Vector3.new(0, 0, 0))
	-- Sets the acceleration of this cast at this point in time to acceleration.
	activeCast:Fire(rootPosition.Position, direction, 100)
	-- Fires the cast with the given position, direction, and speed.

	activeCast.RayHit:Connect(function(_, _, hit: Instance)
		if hit.Parent:FindFirstChild("Humanoid") then
			local targetPlayer = game.Players:GetPlayerFromCharacter(hit.Parent)
			if targetPlayer then
				-- If the player exists, then we can damage them.
				targetPlayer:TakeDamage(10)
			end
		end
	end)

	character.HumanoidRootPart.Anchored = true

	if params.animation then
		local animationTrack = player.Character.Humanoid:LoadAnimation(params.animation)
		animationTrack:Play()
	end
	if params.sound then
		params.sound:Play()
		params.sound.Ended:Wait()
		params.sound:Destroy()
		-- Cleanup
	end
	return params.isCutscene, params.cutsceneDirectory
end

function Frost:Burst(player: Player, params: options) -- RMB
	local mouse = player:GetMouse()

	local asset: BasePart = ServerStorage.Assets.AbsoluteZero
	local target = mouse.Hit
	local character = player.Character
	local rootPosition = character.HumanoidRootPart.CFrame

	local direction = (target.Position - rootPosition.Position).unit
	local activeCast = FastCast.new(asset, rootPosition.Position, direction, 100, player)
	activeCast:SetPosition(rootPosition.Position + direction * 2)
	-- Sets the position of this cast at this point in time to position.
	activeCast:SetAcceleration(Vector3.new(0, 0, 0))
	-- Sets the acceleration of this cast at this point in time to acceleration.
	activeCast:Fire(rootPosition.Position, direction, 100)
	-- Fires the cast with the given position, direction, and speed.

	activeCast.RayHit:Connect(function(_, _, hit: Instance)
		if hit.Parent:FindFirstChild("Humanoid") then
			local targetPlayer = game.Players:GetPlayerFromCharacter(hit.Parent)
			if targetPlayer then
				-- If the player exists, then we can damage them.
				targetPlayer:TakeDamage(60)
			end
		end
	end)

	character.HumanoidRootPart.Anchored = true

	if params.animation then
		local animationTrack = player.Character.Humanoid:LoadAnimation(params.animation)
		animationTrack:Play()
	end
	if params.sound then
		params.sound:Play()
		params.sound.Ended:Wait()
		params.sound:Destroy()
		-- Cleanup
	end
	return params.isCutscene, params.cutsceneDirectory
end

return Frost
