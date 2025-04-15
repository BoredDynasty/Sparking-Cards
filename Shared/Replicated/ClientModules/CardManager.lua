--!strict

local CardManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // Util
local random = Random.new()

function CardManager:Drop(player: Player, amount: number)
	local assets = ReplicatedStorage:WaitForChild("Assets") :: Folder
	local object = assets:FindFirstChild("CardDrop") :: BasePart
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
	object = object:Clone()
	for _ = 1, amount do
		object.Parent = workspace
		object.CFrame = rootPart.CFrame

		local randomX = random:NextInteger(-5, 5)
		local randomZ = random:NextInteger(-5, 5)

		local attachment = object:FindFirstChild("Attachment") :: Attachment

		local maxForce = 250
		local vectorVelocity = Vector3.new(randomX, random:NextInteger(45, 55), randomZ)

		local linearVelocity = object:FindFirstChild("LinearVelocity") :: LinearVelocity
		linearVelocity.MaxForce = maxForce
		linearVelocity.Attachment0 = attachment
		linearVelocity.VectorVelocity = vectorVelocity
		task.delay(0.25, function()
			linearVelocity:Destroy()
			attachment:Destroy()
		end)
		task.delay(3, function()
			object:Destroy()
		end)
	end
end

return CardManager
