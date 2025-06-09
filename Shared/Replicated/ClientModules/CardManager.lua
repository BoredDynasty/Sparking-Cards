--!strict

local CardManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // Util
local random = Random.new()

function CardManager:Drop(player: Player, amount: number)
	local assets = ReplicatedStorage.Assets
	local object = assets:FindFirstChild("CardDrop") :: BasePart
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
	object = object:Clone()
	for _ = 1, amount do
		object.Transparency = 0
		object.Parent = workspace
		object.CFrame = rootPart.CFrame

		local randomX = random:NextInteger(-5, 5)
		local randomZ = random:NextInteger(-5, 5)

		local attachment = object:FindFirstChildOfClass("Attachment") :: Attachment

		local maxForce = 250
		local y = random:NextInteger(45, 55)
		local vectorVelocity = Vector3.new(randomX, y, randomZ)

		local linearVelocity = Instance.new("LinearVelocity")
		linearVelocity.Parent = object
		linearVelocity.MaxForce = maxForce
		linearVelocity.Attachment0 = attachment
		linearVelocity.VectorVelocity = vectorVelocity
		task.delay(0.25, function()
			linearVelocity:Destroy()
			attachment:Destroy()
		end)
		task.delay(5, function()
			object:Destroy()
		end)
	end
end

return CardManager
