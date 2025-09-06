--!nonstrict

-- yoink.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local promise = require(ReplicatedStorage.Packages.promise)

export type response<T> = {
	success: boolean,
	value: T?,
	error: string?,
}

local yoink = {}

-- Creates a new remote function in ReplicatedStorage if it doesn't exist
function yoink.setup(): RemoteFunction
	local existingRemote = ReplicatedStorage:FindFirstChild("YoinkWrapper")
	if existingRemote then
		return existingRemote
	end

	local remoteFunction = Instance.new("RemoteFunction")
	remoteFunction.Name = "YoinkWrapper"
	remoteFunction.Parent = ReplicatedStorage

	return remoteFunction
end

-- Gets a value from the server using the provided key
function yoink.getValue<T>(key: string): response<T>
	local remote = yoink.setup()
	-- Use a promise to handle the remote call
	local resultPromise = promise.new(function(resolve, reject)
		local success, result = pcall(function()
			return remote:InvokeServer(key)
		end)
		if success then
			resolve(result)
		else
			reject("Failed to communicate with server: " .. tostring(result))
		end
	end)

	local result = resultPromise:expect()

	if not result then
		return {
			success = false,
			value = nil,
			error = "Failed to communicate with server: " .. tostring(result),
		}
	end

	return {
		success = true,
		value = result,
		error = nil,
	}
end

--[[

   Async version of getValue that returns the value

   ```luau
   local yoink = require("path/to/yoink")
   
   -- Synchronous usage
   local response = Yoink.getValue("gameConfig")
   if response.success then
       print("Game config:", response.value)
   else
       warn("Error:", response.error)
   end

   -- Async usage
   Yoink.getValueAsync("playerStats"):andThen(function(response)
       if response.success then
           print("Player stats:", response.value)
          else
           warn("Error:", response.error)
       end
   end)
   ```
   On the server:
   ```luau
   local ReplicatedStorage = game:GetService("ReplicatedStorage")

   -- Your server-side data store or cache
   local ServerData = {
    playerStats = {},
         gameConfig = {
         maxPlayers = 10,
         roundTime = 300
       }
   }

   local function handleYoinkRequest(player: Player, key: string)
       -- Add your authentication/validation here
       return ServerData[key]
   end

   local yoinkFunction = ReplicatedStorage:WaitForChild("YoinkFunction")
   yoinkFunction.OnServerInvoke = handleYoinkRequest
   ```
   ]]
function yoink.getAsync<T>(key: string)
	return promise.new(function(resolve, reject)
		resolve(yoink.getValue(key))
	end)
end

return yoink
