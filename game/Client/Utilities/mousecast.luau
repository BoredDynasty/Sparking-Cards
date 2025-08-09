--!nonstrict

-- mousecast.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UserInputService = game:GetService("UserInputService")

local Packet = require(ReplicatedStorage.Packet)

local camera = workspace.CurrentCamera

return function(blacklist: { Instance })
	local mousePosition = UserInputService:GetMouseLocation()
	local mouseRay = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = blacklist

	local epsilon = 1000 -- or the distance.
	local ray = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * epsilon, params)
	if not ray then
		return nil
	end
	return ray
end
