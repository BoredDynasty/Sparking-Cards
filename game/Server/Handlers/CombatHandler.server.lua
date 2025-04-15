--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Raycast = require(ReplicatedStorage.Classes.Raycast)

-- // Requires

-- // Variables

print("Running combat handler server")

local assets = ReplicatedStorage:FindFirstChild("Assets") :: Folder
local visualEffects = assets:FindFirstChild("VisualEffects") :: Folder
local weapons = visualEffects:FindFirstChild("Weaponry") :: Folder

local function registerFrost(player: Player, combo: number, damage: number)
	local startTime = os.clock()
	local registeredAnimations = {
		Gauntlet_Combo_1 = 81021084939952,
		Gauntlet_Combo_2 = 107207958095996,
		Gauntlet_Combo_3 = 82258928842933,
		Gauntlet_Combo_4 = 109206938776854,
		Gauntlet_Combo_5 = 85269329835096,
		Gauntlet_Combo_6 = 85269329835096,
		Gauntlet_Combo_7 = 131781435014944,
	} :: { [string]: number }
	local gauntletTemplate = weapons:FindFirstChild("Gauntlet") :: Model
	local gauntlet = gauntletTemplate:Clone() :: Model

	local character = player.Character :: Model
	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
	local animator = humanoid:FindFirstChild("Animator") :: Animator
	if humanoid.Health > 0 and not character:FindFirstChild("Gauntlet") then
		-- The player is alive
		local handle = gauntlet:FindFirstChild("Handle") :: BasePart
		local cframeValue = gauntlet:FindFirstChild("Value") :: CFrameValue
		gauntlet.Parent = character

		local rightArm = character:FindFirstChild("Right Arm") :: BasePart

		-- Create Motor6D
		local motor6D = Instance.new("Motor6D")
		motor6D.Parent = handle
		motor6D.Part0 = rightArm
		motor6D.Part1 = handle
		motor6D.C1 = cframeValue.Value

		-- Put in our animation
		task.wait()
		local currentAnimation = registeredAnimations["Gauntlet_Combo_" .. tostring(combo)] :: number
		local animation = Instance.new("Animation")
		animation.Parent = character
		animation.AnimationId = tostring(currentAnimation)
		local animationTrack = animator:LoadAnimation(animation) :: AnimationTrack
		animationTrack:Play(0.6, 10)
		-- We can use magnitude for combat
		local _player: Player
		task.spawn(function()
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = { character, gauntlet }
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			local ray = Raycast.new(handle)
			ray.OnHit:Connect(function(hit, _humanoid: Humanoid)
				print(hit)
				_humanoid:TakeDamage(damage)
			end)
			ray:HitStart()
			task.wait()
			ray:HitStop()
		end)
	end
	print("finished frost move in: ", tostring(startTime - os.clock()))
end

-- // Registered Thingies

local registeredCards = {
	["Frost"] = function(player: Player, combo: number, damage: number)
		registerFrost(player, combo, damage)
	end,
} :: { [string]: (Player, number, number) -> () }

local function _requestHandler(player: Player, combat: string, combo: number, damage: number)
	registeredCards[combat](player, combo, damage)
end

-- ("CombatEvent")
-- ("CombatEvent", requestHandler)
