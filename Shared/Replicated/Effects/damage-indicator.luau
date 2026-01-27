--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local hydration = require(ReplicatedStorage.Utility.hydration)
local random = require(ReplicatedStorage.Utility.random)
local spr = require(ReplicatedStorage.Modules.spr)
local text_counter = require(ReplicatedStorage.ClientModules.markdown["text-counter"])

-- damage-indicator.luau

-- This module does a cool effect when a player is damaged.
type Indicator = BasePart & {
	PhysicalTooltip: BillboardGui & {
		CanvasGroup: CanvasGroup & {
			Background: Frame & {
				TextLabel: TextLabel, -- Label to show damage amount
			},
		},
	},
}

local pseudorandom = random.create()

return function(damage: number, text_color: Color3?, ancestor: BasePart)
	local indicator: any = fetchAsset("DamageIndict") :: Indicator
	hydration(indicator) {
		Anchored = false,
		Parent = ancestor,
		Position = ancestor.Position + Vector3.new(0, 4, 0),
		Size = Vector3.one,
		Transparency = 1,
	}

	local randomX = pseudorandom:float(-5, 5)
	local randomZ = pseudorandom:float(-5, 5)

	local attachment = indicator:FindFirstChildOfClass("Attachment") :: Attachment
	if not attachment then
		return
	end

	local maxForce = 250
	local y = pseudorandom:float(45, 55)
	local vectorVelocity = Vector3.new(randomX, y, randomZ)

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Parent = indicator
	linearVelocity.MaxForce = maxForce
	linearVelocity.Attachment0 = attachment
	linearVelocity.VectorVelocity = vectorVelocity

	-- Set the tooltip text to show damage amount
	local background = indicator.PhysicalTooltip.CanvasGroup.Background
	local label = background.TextLabel

	-- set text color
	if text_color then
		label.TextColor3 = text_color
	end

	-- count up effect

	local counter = text_counter.new(label, damage, 0.8)
	counter:Start(counter)

	spr.target(label, 1, 2, {
		TextTransparency = 1,
	})
	spr.target(label, 0.6, 6, {
		Rotation = math.rad(15),
	})
	spr.target(background, 0.7, 8, {
		Size = UDim2.new(),
	})

	task.delay(0.5, function()
		linearVelocity:Destroy()
		attachment:Destroy()
	end)
	task.delay(5, function()
		indicator:Destroy()
	end)

	return indicator
end
