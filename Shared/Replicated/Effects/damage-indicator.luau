--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local hydration = require(ReplicatedStorage.Utility.hydration)
local markdown = require(ReplicatedStorage.ClientModules.markdown)
local random = require(ReplicatedStorage.Utility.random)

-- damage-indicator.luau

-- This module does a cool effect when a player is damaged.
type indicator = BasePart & {
	PhysicalTooltip: BillboardGui & {
		CanvasGroup: CanvasGroup & {
			Background: Frame & {
				TextLabel: TextLabel, -- Label to show damage amount
			},
		},
	},
}

local pseudorandom = random.create()

return function(damage: number, ancestor: BasePart)
	local indicator: indicator = fetchAsset("DamageIndict") :: indicator
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

	-- count up effect
	local counter = markdown.text_counter.new({
		to = damage,
		from = 1,
		duration = 0.8,
		label = label,
	})
	counter:Start()
	counter.completed:Once(function()
		task.defer(counter.Destroy, counter)
	end)

	-- transparency effect
	local transparency_tween = TweenPlus(label, {
		TextTransparency = 1,
	}, {
		Time = 0.6,
	})
	-- rotation effect
	local rotation_tween = TweenPlus(label, {
		Rotation = math.rad(15),
	}, {
		Time = 0.3,
		EasingDirection = "In",
		EasingStyle = "Sine",
	})

	transparency_tween:Start()
	rotation_tween:Start()

	task.delay(0.5, function()
		linearVelocity:Destroy()
		attachment:Destroy()
	end)
	task.delay(5, function()
		indicator:Destroy()
	end)

	return indicator
end
