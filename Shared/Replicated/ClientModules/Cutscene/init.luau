--!strict

local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

-- cutscene.luau
-- a runtime Moon Animator 2 cutscene playback module
-- we've been needing this lmao
-- read this for more information:
-- https://devforum.roblox.com/t/camera-animations-for-cutscenes-and-gameplay/1181691

local module = {}

function module:Cinematic(folder: Folder | Instance)
	local camera = workspace.CurrentCamera

	local frame_time = 0

	local conn = nil

	camera.CameraType = Enum.CameraType.Scriptable

	local frames = folder:FindFirstChild("Frames") :: Folder
	assert(frames, "Could not find 'Frames' folder in cutscene folder.")

	conn = RunService.PreRender:Connect(function(delta_time)
		frame_time += (delta_time * 60)

		local i = tostring(math.ceil(frame_time))

		local frame = frames:FindFirstChild(i) :: CFrameValue

		if frame then
			camera.CFrame = frame.Value
		else
			if conn then
				conn:Disconnect()
			end

			print("Cutscene has completed.")
		end
	end)
end

function module:GameplayCinematic(folder: Folder | Instance, root_part: BasePart)
	local camera = workspace.CurrentCamera

	local frame_time = 0

	local conn = nil

	camera.CameraType = Enum.CameraType.Scriptable

	local frames = folder:FindFirstChild("Frames") :: Folder
	assert(frames, "Could not find 'Frames' folder in cutscene folder.")

	conn = RunService.PreRender:Connect(function(delta_time)
		frame_time += (delta_time * 60)

		local i = tostring(math.ceil(frame_time))

		local frame = frames:FindFirstChild(i) :: CFrameValue

		if frame then
			camera.CFrame = root_part.CFrame * frame.Value
		else
			if conn then
				conn:Disconnect()
			end

			print("Cutscene has completed.")
		end
	end)
end

return module
