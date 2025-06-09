--!nonstrict

local quest = {}
export type dataType = {
	[string]: {
		Name: string,
		Provider: string,
		Description: string,
		--
		MinimumRank: string,
		WorldQuest: boolean,
		--
		routine: ((any) -> any) | thread,
		completed: number | boolean,
	},
}

quest.registered = {
	Take_a_hike = {
		Name = "Take a Hike",
		Provider = "Game",
		Description = "Walk 200m in-game.",

		MinimumRank = "Bronze",
		WorldQuest = false,

		routine = function(player: Player, copy: { completed: number | boolean })
			local character = player.Character :: Model
			local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart
			local startPosition = rootPart.Position:Ceil()
			task.spawn(function()
				if type(copy.completed) == "boolean" then
					return
				end
				while copy.completed ~= 200 or (copy.completed < 200) do
					task.wait()
					local currentPosition = rootPart.Position:Ceil()

					local magnitude = (startPosition - currentPosition).Magnitude
					if magnitude ~= 200 or (magnitude < 200) then
						copy.completed = math.ceil(magnitude)
					elseif (magnitude == 200) or magnitude > 200 then
						copy.completed = true
					end
				end
			end)
			return copy
		end,
		completed = 0, -- 0 percent
	},
} :: dataType

return quest
