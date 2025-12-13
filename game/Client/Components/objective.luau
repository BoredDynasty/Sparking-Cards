--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local future = require(ReplicatedStorage.Packages.future)
local hydration = require(ReplicatedStorage.Utility.hydration)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local quest = require(ReplicatedStorage.ClientModules.quest)
local spr = require(ReplicatedStorage.Modules.spr)
local timer = require(ReplicatedStorage.Modules.timer)

-- objective.luau

local player = playerMarshaller.get()
local playerGui = player.PlayerGui

export type objectiveGui = ScreenGui & {
	CanvasGroup: CanvasGroup & {
		Frame: Frame & {
			Completed: Frame & {
				Value: TextLabel,
				ImageLabel: ImageLabel,
			},
			Holder: Frame,
			Navigation: Frame,
			Uncompleted: Frame & {
				Value: TextLabel,
				ImageLabel: ImageLabel,
			},
		},
	},
}

export type card = Frame & {
	Viewport: ViewportFrame,
	Progress: Frame & {
		Bar: Frame,
	},
	ViewportImage: ImageLabel,
	Title: TextLabel,
	Details: TextLabel,
}

local objectiveGui = playerGui:WaitForChild("Objective") :: objectiveGui

local objective_module = {
	current_timer = timer.new(),
}

function objective_module._createCard(ancestor: Instance?): card
	-- Instances:

	local Frame = Instance.new("Frame")
	local UICorner = Instance.new("UICorner")
	local Title = Instance.new("TextLabel")
	local AspectRatio = Instance.new("UIAspectRatioConstraint")
	local Details = Instance.new("TextLabel")
	local AspectRatio_2 = Instance.new("UIAspectRatioConstraint")
	local Progress = Instance.new("Frame")
	local UICorner_2 = Instance.new("UICorner")
	local Bar = Instance.new("Frame")
	local UICorner_3 = Instance.new("UICorner")
	local AspectRatio_3 = Instance.new("UIAspectRatioConstraint")
	local UIPadding = Instance.new("UIPadding")
	local AspectRatio_4 = Instance.new("UIAspectRatioConstraint")
	local Viewport = Instance.new("ViewportFrame")
	local UICorner_4 = Instance.new("UICorner")
	local AspectRatio_5 = Instance.new("UIAspectRatioConstraint")
	local ViewportImage = Instance.new("ImageLabel")
	local UICorner_5 = Instance.new("UICorner")
	local AspectRatio_6 = Instance.new("UIAspectRatioConstraint")
	local AspectRatio_7 = Instance.new("UIAspectRatioConstraint")

	--Properties:

	Frame.Parent = ancestor or ReplicatedStorage
	Frame.AnchorPoint = Vector2.new(0.5, 0.5)
	Frame.BackgroundColor3 = Color3.fromRGB(26, 17, 15)
	Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Frame.BorderSizePixel = 0
	Frame.Position = UDim2.new(0.222985342, 0, 0.195440441, 0)
	Frame.Size = UDim2.new(0.445970684, 0, 0.390880883, 0)

	UICorner.CornerRadius = UDim.new(0.106347442, 0)
	UICorner.Parent = Frame

	Title.Name = "Title"
	Title.Parent = Frame
	Title.AnchorPoint = Vector2.new(0.5, 0.5)
	Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Title.BackgroundTransparency = 1.000
	Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Title.BorderSizePixel = 0
	Title.Position = UDim2.new(0.315246373, 0, 0.21419096, 0)
	Title.Size = UDim2.new(0.5, 0, 0.287305146, 0)
	Title.Font = Enum.Font.GothamMedium
	Title.Text = "Take a hike"
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextSize = 16.000
	Title.TextXAlignment = Enum.TextXAlignment.Left

	AspectRatio.Name = "AspectRatio"
	AspectRatio.Parent = Title
	AspectRatio.AspectRatio = 3.819

	Details.Name = "Details"
	Details.Parent = Frame
	Details.AnchorPoint = Vector2.new(0.5, 0.5)
	Details.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Details.BackgroundTransparency = 1.000
	Details.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Details.BorderSizePixel = 0
	Details.Position = UDim2.new(0.315246373, 0, 0.499999702, 0)
	Details.Size = UDim2.new(0.5, 0, 0.287305146, 0)
	Details.Font = Enum.Font.Gotham
	Details.Text = "Walk 200 meters"
	Details.TextColor3 = Color3.fromRGB(255, 255, 255)
	Details.TextSize = 16.000
	Details.TextTransparency = 0.300
	Details.TextXAlignment = Enum.TextXAlignment.Left

	AspectRatio_2.Name = "AspectRatio"
	AspectRatio_2.Parent = Details
	AspectRatio_2.AspectRatio = 3.819

	Progress.Name = "Progress"
	Progress.Parent = Frame
	Progress.AnchorPoint = Vector2.new(0.5, 0.5)
	Progress.BackgroundColor3 = Color3.fromRGB(26, 17, 15)
	Progress.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Progress.BorderSizePixel = 0
	Progress.Position = UDim2.new(0.504543126, 0, 0.815718651, 0)
	Progress.Size = UDim2.new(0.878593504, 0, 0.121137246, 0)

	UICorner_2.CornerRadius = UDim.new(1, 0)
	UICorner_2.Parent = Progress

	Bar.Name = "Bar"
	Bar.Parent = Progress
	Bar.AnchorPoint = Vector2.new(0.5, 0.5)
	Bar.BackgroundColor3 = Color3.fromRGB(93, 64, 55)
	Bar.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Bar.BorderSizePixel = 0
	Bar.Position = UDim2.new(0.49999994, 0, 0.500001431, 0)
	Bar.Size = UDim2.new(1.00800002, 0, 0.699999988, 0)

	UICorner_3.CornerRadius = UDim.new(1, 0)
	UICorner_3.Parent = Bar

	AspectRatio_3.Name = "AspectRatio"
	AspectRatio_3.Parent = Bar
	AspectRatio_3.AspectRatio = 22.130

	UIPadding.Parent = Progress
	UIPadding.PaddingLeft = UDim.new(0, 5)
	UIPadding.PaddingRight = UDim.new(0, 5)

	AspectRatio_4.Name = "AspectRatio"
	AspectRatio_4.Parent = Progress
	AspectRatio_4.AspectRatio = 15.917

	Viewport.AnchorPoint = Vector2.new(0.5, 0.5)
	Viewport.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Viewport.BorderSizePixel = 0
	Viewport.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Viewport.Name = "Viewport"
	Viewport.Parent = Frame
	Viewport.Position = UDim2.new(0.849835157, 0, 0.315718979, 0)
	Viewport.Visible = false

	UICorner_4.CornerRadius = UDim.new(0.213333338, 0)
	UICorner_4.Parent = Viewport

	AspectRatio_5.Name = "AspectRatio"
	AspectRatio_5.Parent = Viewport

	ViewportImage.Name = "ViewportImage"
	ViewportImage.Parent = Frame
	ViewportImage.AnchorPoint = Vector2.new(0.5, 0.5)
	ViewportImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ViewportImage.BackgroundTransparency = 1.000
	ViewportImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ViewportImage.BorderSizePixel = 0
	ViewportImage.Position = UDim2.new(0.849835157, 0, 0.315718979, 0)
	ViewportImage.Size = UDim2.new(0.227156103, 0, 0.498503625, 0)
	ViewportImage.Image = "rbxassetid://16147970"

	UICorner_5.CornerRadius = UDim.new(0.159999996, 0)
	UICorner_5.Parent = ViewportImage

	AspectRatio_6.Name = "AspectRatio"
	AspectRatio_6.Parent = ViewportImage

	AspectRatio_7.Name = "AspectRatio"
	AspectRatio_7.Parent = Frame
	AspectRatio_7.AspectRatio = 2.195

	return Frame
end

--[[
   Creates a new Card in the objective container
   with the quest information and tracking.

   ```luau
   local objective_module = require(path.to.module)

   objective_module.new({...})
   ```
]]
function objective_module.new(data: quest.quest)
	local card = objective_module._createCard()
	card.Parent = objectiveGui.CanvasGroup.Frame.Holder

	-- load all quest data
	objective_module.current_timer:Reset()
	task.defer(objective_module.current_timer.Start, objective_module.current_timer)

	local completed: observer.Observer<number>, uncompleted: observer.Observer<number> = observer.scope(0, 0)

	local load_futures = {
		[1] = future.new(function()
			-- load title and details
			card.Title = data.name
			card.Details = data.description

			return "title & details"
		end),
		[2] = future.new(function()
			-- load viewports
			if type(data.inquirer_img) == "number" then
				-- it is a content
				local img_content = Content.fromAssetId(data.inquirer_img)
				card.ViewportImage.ImageContent = img_content

				card.Viewport.Visible = false
			else
				-- viewport
				card.Viewport.Visible = true
				card.ViewportImage.Visible = false

				local model = data.inquirer_img:Clone() :: Model & PVInstance
				local primaryPart = model.PrimaryPart
				local model_coordinate = if primaryPart then primaryPart.CFrame else model:GetPivot()

				local viewport_camera = Instance.new("Camera")
				card.Viewport.CurrentCamera = viewport_camera
				viewport_camera.Parent = card.Viewport

				local relative_position = CFrame.new(
					model_coordinate.Position + Vector3.new(0, 0, 1) * 10,
					model_coordinate.Position
				)

				viewport_camera.CFrame = relative_position

				model.Parent = card.Viewport

				-- todo) find a way to sway the camera and rotate the model
			end

			return "viewports"
		end),
		[3] = future.new(function()
			-- load progress
			local bar = card.Progress.Bar

			local y_factor = 0.008 -- dont you love floats?

			-- lets hope data.progress is (> 1)
			bar.Size = UDim2.new(data.progress / 100 + y_factor, 0, 0.7)

			-- pulsate the outline
			objective_module.current_timer:interval(1, function()
				spr.target(card.Progress.UIStroke, 1, 0.8, {
					Transparency = 0.7,
				})
				task.delay(1.2, spr.target, 1, 0.8, {
					Transparency = 0.9,
				})
			end)

			return "progress"
		end),
		[4] = future.new(function()
			-- completed and uncompleted
			if data.completed or data.date_completed > 0 then
				completed:Map(function(current: number)
					return current + 1
				end)
			else
				uncompleted:Map(function(current: number)
					return current + 1
				end)
			end

			local completedFrame = objectiveGui.CanvasGroup.Frame.Completed
			local uncompletedFrame = objectiveGui.CanvasGroup.Frame.Uncompleted

			completedFrame.Value.Text = tostring(completed) or completed:Get()
			uncompletedFrame.Value.Text = tostring(uncompleted) or uncompleted:Get()
			hydration(completedFrame.Value) {
				Text = completed,
			}
			hydration(uncompletedFrame.Value) {
				Text = uncompleted,
			}

			return "completed & uncompleted status's"
		end),
	}

	for i, fut in ipairs(load_futures) do
		fut:Await()

		local unwrapped = fut:UnwrapOr("couldn't do task, go debug")

		print(unwrapped)
	end

	local function onDestroying()
		return future.new(function()
			objective_module.current_timer.cancel_interval:Fire()
			objective_module.current_timer:Reset()
		end)
	end

	card.Destroying:Once(onDestroying)

	return completed, uncompleted
end

return objective_module
