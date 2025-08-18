--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packet = require(ReplicatedStorage.Packet)
local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local boundingbox = require(ReplicatedStorage.Combat.Strike.boundingbox)
local debounce = require(ReplicatedStorage.Combat.framework.utils.debounce).new({
	M1 = 0.1,
	Skill = 8,
	Ultimate = 15,
	Support = 18,
})
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local trove = require(ReplicatedStorage.Packages.trove)

-- Hydro.luau

local hydro = {
	moveset = {},
	_trove = trove.new(),
}

function hydro.moveset.Ultimate(player: playerMarshaller.player, position: Vector3)
	-- we're gonna have a literal kamehameha lmao

	local charged = SignalPlus()

	local character = player.Character
	local humanoid = character.Humanoid
	local rootPart = character.HumanoidRootPart

	local rightArm = character:WaitForChild("RightArm") :: BasePart

	local function charge()
		-- we'll charge first
		rootPart.Anchored = true
		local armPart = fetchAsset("ArmModel") :: BasePart
		armPart.Parent = rightArm
		armPart.CFrame = rightArm.CFrame
		armPart.Name = "Arm"
		local weld = hydro._trove:Construct(Instance, "Weld") :: Weld
		weld.Part0 = armPart
		weld.Part1 = rightArm
		weld.C0 = armPart.CFrame:Inverse() * rightArm.CFrame
		weld.Parent = armPart

		-- if floating
		Packet.StopAllAnimations.sendTo({ nil }, player)
		if humanoid.FloorMaterial == Enum.Material.Air then
			-- make the player go higher
			task.wait()
			local offset = Vector3.new(5, 10, 0)
			local tween = TweenPlus(rootPart, {
				Position = rootPart.Position + offset,
			}, {
				Time = 1,
				EasingStyle = "Sine",
				EasingDirection = "InOut",
			})

			tween:Start()
		end
		charged:Fire()
	end
	local function execute()
		local armPart = rightArm:WaitForChild("Arm", 5) :: BasePart & { Attachment: Attachment }
		for _, effect in armPart.Attachment:GetChildren() do
			if effect:IsA("ParticleEmitter") then
				effect.Enabled = false
			end
		end
		task.delay(3, function()
			armPart:Destroy()
		end)
		-- we've already stopped all the animations
		-- lets go ahead and do the effects
		-- ughhhhhh
		task.wait(0.25)
		-- we also needa play a sound here
		local model = fetchAsset("HydroBlastModel") :: Model & any
		model.Parent = workspace
		model.PrimaryPart.CFrame = rootPart.CFrame
		for _, beam: Beam in model:GetDescendants() do
			if beam:IsA("Beam") then
				beam.Width0 = 0
				beam.Width1 = 0
				if beam.Name == "Beam1" then
					TweenPlus(beam, {
						Width0 = 9.5,
						Width1 = 9.5,
					}, {
						Time = 0.4,
					}):Start()
				elseif beam.Name == "Beam2" then
					TweenPlus(beam, {
						Width0 = 16,
						Width1 = 16,
					}, {
						Time = 0.4,
					}):Start()
				elseif beam.Name == "Beam3" then
					TweenPlus(beam, {
						Width0 = 11,
						Width1 = 11,
					}, {
						Time = 0.4,
					}):Start()
				end
			end
		end
		local endPart = model:FindFirstChild("End", true) :: BasePart
		local tween = TweenPlus(endPart, {
			Position = position,
		}, {
			Time = 0.5,
		})
		task.delay(3, function()
			rootPart.Anchored = false
		end)
		endPart.Touched:Connect(function(otherPart: BasePart)
			if otherPart:IsA("BasePart") then
				endPart:Destroy()
			end
		end)
		local box = boundingbox.new(rootPart.CFrame * CFrame.new(0, 0, -25), Vector3.new(7, 7, 70))
		box.OnEnter:Connect(function(vec3)
			-- Find the player whose character's HumanoidRootPart is inside/touching vec3
			for _, plr in ipairs(playerMarshaller.all()) do
				local char = plr.Character
				if char and char:FindFirstChild("HumanoidRootPart") then
					local hrp = char.HumanoidRootPart
					if (hrp.Position - vec3).Magnitude < 4 then -- adjust threshold as needed
						-- This player is inside/touching vec3
						print("Player inside box:", plr.Name)
					end
				end
			end
		end)
	end
end
