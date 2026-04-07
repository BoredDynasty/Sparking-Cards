--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local future = require(ReplicatedStorage.Packages.future)
local random = require(ReplicatedStorage.Utility.random)

-- scatter.luau

local module = {}

function module:Out(part: BasePart, r_limit: { number }?, v_limit: { number }?)
	if part:IsA("BasePart") then
		r_limit = r_limit or { -360, 360 }
		v_limit = v_limit or { -15, 15 }

		local tween =
			TweenService:Create(part, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				CFrame = part.CFrame * CFrame.Angles(
					math.rad(random.float(table.unpack(r_limit))),
					math.rad(random.float(table.unpack(v_limit))),
					math.rad(random.float(table.unpack(r_limit)))
				),
			})

		tween:Play()

		return tween
	else
		error("Expected a BasePart, got " .. part.ClassName)
	end
end

return module
