--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local audio = require(ReplicatedStorage.Modules.audio)
local random = require(ReplicatedStorage.Utility.random)
local spr = require(ReplicatedStorage.Modules.spr)
local text_counter = require(ReplicatedStorage.ClientModules.markdown["text-counter"])

-- damage-indicator.luau
-- this module does a cool effect when a player is damaged.

local pool = PoolerPlus:CreatePool("DamageIndicatorPool", function()
	return ReplicatedStorage.Assets.VisualEffects.DamageIndict:Clone()
end)
pool:Preload(20)

local pseudorandom = random.create()

local config = {
	colors = {
		[1] = Color3.fromRGB(255, 0, 0), -- Damage has been inflicted.
		[2] = Color3.fromRGB(150, 0, 255), -- Damage has been received.
		[3] = Color3.fromRGB(255, 200, 0), -- Damage inflicted was critical.
		[4] = Color3.fromRGB(0, 255, 0), -- HP was restored.
		[5] = Color3.fromRGB(255, 255, 255), --Neutral, the "numericType" parameter was not defined.
	},
	sizes = {
		normal = UDim2.new(0.12, 0, 0.016, 4),
		critical = UDim2.new(0.12, 0, 0.020, 6),
		critical2 = UDim2.new(0.12, 0, 0.024, 8),
	},
	sounds = {
		normal = 1, -- we dont have a sound id yet for this one. TODO)
		critical = 137392628136734,
		critical2 = 135698842254153,
	},
}

audio:AddSFX("critical-hit-1", config.sounds.critical)
audio:AddSFX("critical-hit-2", config.sounds.critical2)

--[[
	Numeric Types:

	1: Damage has been inflicted.

	2: Damage has been received.

	3: Damage inflicted was critical.

	4: HP was restored.

	5: Neutral, the "numericType" parameter was not defined.
]]
return function(damage: number, ancestor: BasePart, numericType: number?)
	local indicator = pool:Get()

	local randomX = pseudorandom:float(-5, 5)
	local randomZ = pseudorandom:float(-5, 5)

	local attachment = indicator.Attachment

	-- apply an impulse to the attachment to make it fly up
	local linear_velocity = Instance.new("LinearVelocity")
	linear_velocity.Attachment0 = attachment
	linear_velocity.MaxForce = math.huge
	linear_velocity.VectorVelocity = Vector3.new(randomX, 20, randomZ)
	linear_velocity.Parent = attachment

	-- Set the tooltip text to show damage amount
	local background = indicator.PhysicalTooltip.CanvasGroup.Background
	local label = background.TextLabel

	label.Text = "0"
	label.TextColor3 = config.colors[numericType or 5]
	-- Set the size of the tooltip based on whether it's a critical hit or not
	if numericType == 3 then
		background.Size = config.sizes.critical
		audio:PlayVariation("critical-hit", pseudorandom:integer(1, 2))
	elseif numericType == 4 then
		background.Size = config.sizes.critical2
	else
		background.Size = config.sizes.normal
	end

	-- count up effect

	indicator.Parent = workspace
	indicator.Position = ancestor.Position * Vector3.new(0, 3, 0)

	local counter = text_counter.new(label, if numericType == 4 then damage else -damage, 0.8)
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
		linear_velocity:Destroy()
		attachment:Destroy()
	end)
	task.delay(5, function()
		indicator:Destroy()
		if counter then
			counter:Destroy()
		end
	end)

	return indicator
end
