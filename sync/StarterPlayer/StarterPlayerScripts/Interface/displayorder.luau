--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local hydration = require(ReplicatedStorage.Utility.hydration)
local observer = require(ReplicatedStorage.Utility.observer)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local spr = require(ReplicatedStorage.Modules.spr)

-- displayorder.luau

local module = {}

type CanvasData = {
	canvas: CanvasGroup,
	state: observer.Observer<boolean>,
}

local tracked = {} :: { CanvasData }

local debounce = ratelimit(1, 2)

local function createScale(ancestor: Instance)
	local scale = Instance.new("UIScale")
	hydration(scale) {
		Scale = 1,
		Name = "ui_scale",
		Parent = ancestor,
	}

	return scale
end

local function getScale(ancestor: Instance)
	return ancestor:FindFirstChild("ui_scale", true) :: UIScale
end

local function indexCanvasData(canvas: CanvasGroup): CanvasData?
	-- find the canvas data

	for _, data in ipairs(tracked) do
		if data.canvas == canvas then
			return data
		end
	end

	return nil
end

local function openCanvas(canvas_data: CanvasData)
	local scale = getScale(canvas_data.canvas)

	if not scale then
		warn("couldn't find scale")

		return
	end

	spr.stop(scale)

	spr.target(scale, 0.8, 1.5, {
		Scale = 1,
	})

	canvas_data.canvas.Visible = true

	canvas_data.state:Set(true)
end

local function closeCanvas(canvas_data: CanvasData)
	local scale = getScale(canvas_data.canvas)

	if not scale then
		warn("couldn't find scale")

		return
	end

	spr.stop(scale)

	spr.target(scale, 0.9, 1, {
		Scale = 0,
	})

	spr.completed(scale, function()
		canvas_data.canvas.Visible = false
	end)

	canvas_data.state:Set(false)
end

function module.new(canvas: CanvasGroup)
	local data = {
		canvas = canvas,
		state = observer.new(false),
	} :: CanvasData

	canvas.Destroying:Connect(function()
		local i = table.find(tracked, data)

		if i then
			local new_data = table.remove(tracked, i)

			assert(new_data, "no return value from 'table.remove'?")

			new_data.state:Destroy()
		end
	end)

	createScale(data.canvas)

	table.insert(tracked, data)
end

function module:Toggle(canvas: CanvasGroup)
	-- open the new gui

	local data = indexCanvasData(canvas)
	if not data then
		warn("canvas not indexed")
		return
	end

	if data.state:Get() then
		task.spawn(closeCanvas, data)
	else
		task.spawn(openCanvas, data)
	end

	-- close every other gui
	for _, other_data in ipairs(tracked) do
		if other_data ~= data and other_data.state:Get() then
			task.spawn(closeCanvas, other_data)
		end
	end
end

function module:Open(canvas: CanvasGroup)
	local data = indexCanvasData(canvas)
	if not data then
		warn("canvas not indexed")
		return
	end

	if not data.state:Get() then
		openCanvas(data)

		-- close every other gui
		for _, other_data in ipairs(tracked) do
			if other_data ~= data and other_data.state:Get() then
				task.spawn(closeCanvas, other_data)
			end
		end
	end
end

function module:Close(canvas: CanvasGroup)
	local data = indexCanvasData(canvas)
	if not data then
		warn("canvas not indexed")
		return
	end

	if data.state:Get() then
		task.spawn(closeCanvas, data)
	end
end

function module:CloseAll()
	for _, data in ipairs(tracked) do
		if data.state:Get() then
			task.spawn(closeCanvas, data)
		end
	end
end

return module
