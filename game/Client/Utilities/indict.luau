--!nonstrict

--# selene: allow(incorrect_standard_library_use)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local DisplayOrder = require(script.Parent.Parent.Interface.displayorder).new()
local Pop = require(script.Parent.Parent.Interface.pop)
local SignalPlus = require(ReplicatedStorage.Utility.SignalPlus)
local promise = require(ReplicatedStorage.Packages.promise)

-- indict.luau
-- for indictating preloads

local templates = ReplicatedStorage:WaitForChild("Interfaces") :: Folder

return function(element: GuiObject, signal: typeof(SignalPlus()))
	local loaderTemplates = templates:FindFirstChild("Loaders") :: Folder
	local loader = loaderTemplates:WaitForChild("Basic"):Clone() :: ImageLabel

	loader.Visible = true
	loader.Parent = element
	loader.Position = DisplayOrder.canvasPositions.middle
	Pop(loader)

	local circle = 360

	local connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		loader.Rotation += circle * deltaTime
	end)
	local function cleanup()
		if connection then
			connection:Disconnect()
		end
		task.defer(function() -- at the end of the frame
			loader:Destroy()
		end)
	end
	signal:Once(cleanup)
	return {
		heartbeat_connection = connection,
		icon = loader,
	}
end
