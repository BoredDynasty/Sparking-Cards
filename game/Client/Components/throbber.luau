--!nonstrict

--# selene: allow(incorrect_standard_library_use)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local DisplayOrder = require(script.Parent.Parent.Interface.displayorder)
local Pop = require(script.Parent.Parent.Interface.pop)
local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local promise = require(ReplicatedStorage.Packages.promise)

-- throbber.luau
-- for indicating preloads

local templates = ReplicatedStorage:WaitForChild("Interfaces") :: Folder

return function(element: GuiObject, signal: SignalPlus.Signal<>)
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
	promise
		.new(function(resolve, reject)
			signal:Connect(function()
				resolve()
			end)
		end)
		:andThen(function()
			connection:Disconnect()
			loader:Destroy()
			signal:Destroy()
		end)
		:catch(function(err)
			warn("Error in throbber promise: ", err)
		end)
end
