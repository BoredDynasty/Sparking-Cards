--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local fetchAsset = require(ReplicatedStorage.Combat.framework.utils.fetchAsset)
local random = require(ReplicatedStorage.Utility.random)
local trove = require(ReplicatedStorage.Packages.trove)

-- rocks.luau

local _trove = trove.new()

return function(position: CFrame, size_factor: number, amount: number)
	local castParams = RaycastParams.new()

	local coordinate = position * CFrame.new(0, -2.25, 0)

	local angle, pos_padding, size_padding = 0, -3, 2

	for i = 1, 5 do
		task.wait(0.2)
		-- hold the execution hostage for 0.2s
		pos_padding -= 3
		size_padding += 1

		for j = 1, amount do
			local rock = fetchAsset("Rock") :: BasePart
			rock.Size = Vector3.one * size_padding
			rock.CFrame = coordinate * CFrame.Angles(0, math.rad(angle), 0) * CFrame.new(0, 0, pos_padding)
			rock.Parent = Workspace

			local ray = Workspace:Raycast(rock.Position, rock.CFrame.UpVector * -6.2, castParams)
			if ray then
				rock.Color = ray.Instance.Color
				rock.Material = ray.Instance.Material

				local orientation = Vector3.one * random.float(-180, 180)
				rock.Orientation = orientation

				task.delay(1, function()
					TweenPlus(rock, {
						Transparency = 1,
						Size = Vector3.one * 0.1,
					}, {
						Time = 1,
					})
				end)
				task.delay(2.5, function()
					TweenPlus(rock, {
						Transparency = 1,
					}, {
						Time = 1,
					})
				end)

				angle += 24

				task.delay(5, rock.Destroy, rock)
			end
		end
	end
end
