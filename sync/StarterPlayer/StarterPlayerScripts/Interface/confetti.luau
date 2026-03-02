--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local random = require(ReplicatedStorage.Utility.random)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local spr = require(ReplicatedStorage.Modules.spr)
local trove = require(ReplicatedStorage.Packages.trove)

-- confetti.luau

-- Util

local random_seed = random.create()
local _trove = trove.new()

return function(colors: { Color3 }?, container: Instance, add_shadow: boolean?)
	local default_colors = {
		Color3.new(1, 0, 0),
		Color3.new(0, 0.101961, 1),
		Color3.new(0, 1, 0.666667),
		Color3.new(1, 0.85098, 0),
	}

	colors = colors or default_colors
	if #colors == 0 then
		colors = default_colors
	end

	if not container:IsA("GuiObject") and not container:IsA("LayerCollector") then
		return
	end

	local confetti_holder = Instance.new("Folder")
	confetti_holder.Name = "ConfettiEffect"
	confetti_holder.Parent = container
	_trove:Add(confetti_holder)

	local piece_count = 22

	for _ = 1, piece_count do
		local piece = Instance.new("Frame")
		piece.Name = "ConfettiPiece"
		piece.AnchorPoint = Vector2.new(0.5, 0.5)
		piece.BorderSizePixel = 0
		piece.BackgroundColor3 = random_seed:value(colors) :: Color3
		piece.Position = UDim2.fromScale(random_seed:float(0.05, 0.95), random_seed:float(-0.15, 0))
		piece.Size = UDim2.fromOffset(random_seed:integer(5, 10), random_seed:integer(7, 14))
		piece.Rotation = random_seed:integer(0, 359)

		if container:IsA("GuiObject") then
			piece.ZIndex = container.ZIndex + 1
		end

		piece.Parent = confetti_holder

		if add_shadow then
			shadow(piece, Color3.new(), 0.45, 2)
		end

		local start_position = piece.Position
		local end_x = math.clamp(start_position.X.Scale + random_seed:float(-0.2, 0.2), -0.1, 1.1)
		local end_y = random_seed:float(0.85, 1.2)
		local lifetime = random_seed:float(0.55, 1.1)
		local end_rotation = piece.Rotation + random_seed:integer(180, 540)

		task.delay(random_seed:float(0, 0.12), function()
			if not piece.Parent then
				return
			end

			spr.target(piece, 0.95, 1 / lifetime, {
				Position = UDim2.fromScale(end_x, end_y),
				Rotation = end_rotation,
				BackgroundTransparency = 1,
			})

			spr.completed(piece, function()
				piece:Destroy()
			end)
		end)
	end

	task.delay(1.7, function()
		if confetti_holder.Parent then
			confetti_holder:Destroy()
		end
	end)
end
