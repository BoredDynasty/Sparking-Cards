--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Cmdr Command

-- fly-command.luau

-- for flying around the map

return {
	Name = "Fly",
	Aliases = { "Flight", "Soar", "Fly", "Glide", "Hover" },
	Description = "Makes the player fly around the map",
	Group = "Movement",
	Args = {},
	ClientRun = function(context)
		local target = Players.LocalPlayer
		local character = target.Character or target.CharacterAdded:Wait()

		local camera = workspace.CurrentCamera

		if target:GetAttribute("Flying") then
			target:SetAttribute("Flying", false)

			if character then
				local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
				humanoid.PlatformStand = false
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end

			return "You have stopped flying, back to the ground!"
		end

		target:SetAttribute("Flying", true)

		if character then
			local humanoid = character:FindFirstChild("Humanoid") :: Humanoid
			humanoid.PlatformStand = true
			humanoid:ChangeState(Enum.HumanoidStateType.Flying)

			local rootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
			local current_position = rootPart.Position :: Vector3

			while target:GetAttribute("Flying") do
				local dt = RunService.Heartbeat:Wait()

				local add = Vector3.zero

				if UserInputService:IsKeyDown(Enum.KeyCode.W) then
					add += camera.CFrame.LookVector * dt
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then
					add -= camera.CFrame.LookVector * dt
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then
					add += camera.CFrame.RightVector * dt
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then
					add -= camera.CFrame.RightVector * dt
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.E) then
					add += camera.CFrame.UpVector * dt
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
					add -= camera.CFrame.UpVector * dt
				end

				rootPart.AssemblyAngularVelocity = Vector3.zero
				rootPart.AssemblyLinearVelocity = Vector3.zero

				current_position += add
				rootPart.CFrame =
					CFrame.lookAt(current_position, current_position + (camera.CFrame.LookVector * 1000))
			end
		else
			return "Couldn't get character"
		end

		return "You are now flying, enjoy the view!"
	end,
}
