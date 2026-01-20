--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local promise = require(ReplicatedStorage.Packages.promise)

-- take-a-hike.luau

-- quest

type quest = {
	name: string,
	description: string,
	inquirer_img: string | Instance, -- img id or a model
	progress: number,
	date_acquired: number, -- unix timestamp millis
	date_completed: number?,
	completed: boolean?,
	module: ModuleScript?,
}

local constants = {
	distance = 200,
}

return function(data: quest, player: Player)
	return promise
		.new(function(resolve: (quest?) -> ...unknown)
			local character = player.Character or player.CharacterAdded:Wait()
			local rootPart = character:FindFirstChild("HumanodiRootPart") :: BasePart
			if not rootPart then
				resolve(nil)
			end

			local currentDistance = math.clamp(data.progress / constants.distance, 0, 200)

			if currentDistance * 100 >= constants.distance then
				resolve({
					name = data.name,
					description = data.description,
					inquirer_img = data.inquirer_img,
					progress = currentDistance * 100,
					date_acquired = data.date_acquired,
					date_completed = DateTime.now().UnixTimestampMillis,
					completed = true,
					module = data.module or script,
				})
			end
		end)
		:expect()
end
