--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- damageIndict.luau

-- This module does a cool effect when a player is damaged.

local vfxFolder = ReplicatedStorage.Assets.VisualEffects

type damageIndictPart = BasePart & {
	PhysicalTooltip: BillboardGui & {
		CanvasGroup: CanvasGroup & {
			Background: Frame & {
				TextLabel: TextLabel, -- Label to show damage amount
			},
		},
	},
}

local random = Random.new()

return function(damage: number, parent: BasePart)
	local effectInstance: damageIndictPart = vfxFolder.DamageIndict:Clone()
	effectInstance.Parent = parent
	effectInstance.Position = parent.Position

	-- Set the size and transparency based on damage
	local sizeMultiplier = math.clamp(damage / 100, 0.1, 1) -- Adjust size based on damage
	effectInstance.Size = Vector3.new(sizeMultiplier, sizeMultiplier, sizeMultiplier)
	effectInstance.Transparency = 0.5 -- Semi-transparent effect

	local randomX = random:NextInteger(-5, 5)
	local randomZ = random:NextInteger(-5, 5)

	local attachment = effectInstance:FindFirstChildOfClass("Attachment") :: Attachment

	local maxForce = 250
	local y = random:NextInteger(45, 55)
	local vectorVelocity = Vector3.new(randomX, y, randomZ)

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Parent = effectInstance
	linearVelocity.MaxForce = maxForce
	linearVelocity.Attachment0 = attachment
	linearVelocity.VectorVelocity = vectorVelocity

	-- Set the tooltip text to show damage amount
	effectInstance.PhysicalTooltip.CanvasGroup.Background.TextLabel.Text = tostring(damage)

	task.delay(0.25, function()
		linearVelocity:Destroy()
		attachment:Destroy()
	end)
	task.delay(5, function()
		effectInstance:Destroy()
	end)

	return effectInstance
end
