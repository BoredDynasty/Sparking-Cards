--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TextPlus = require(ReplicatedStorage.Utility.TextPlus)
local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- world.luau

local world_hint = {
	current_hint = observer.new() :: observer.Observer<BasePart?>,
	bindings = observer.new({}),
	hint_position = observer.new(Vector3.zero),
}

export type hintInterface = ScreenGui & {
	Frame: Frame & {
		TextDisplay: Frame,
	},
}

export type bindingData = {
	object: BasePart,
	text: string,
}

local player = playerMarshaller.get()
local character = characterMarshaller.get(player)

local rootPart = character:FindFirstChild("HumanoidRootPart")
local playerGui = player.PlayerGui
local hintGui = playerGui:WaitForChild("Hint") :: hintInterface

local camera = workspace.CurrentCamera

function world_hint._move()
	if not world_hint.current_hint:Get() then
		world_hint.hint_position:Set(Vector3.new(0, 0, 0))
		return
	end

	local studs_offset = Vector3.new(0, 2, 0)
	local offset = (camera.CFrame.LookVector + studs_offset)

	local coordinates = world_hint.hint_position:Get() + offset

	TweenPlus(hintGui.Frame, {
		Time = 0.1,
		EasingStyle = Enum.EasingStyle.Quad,
		EasingDirection = Enum.EasingDirection.Out,
	}, {
		Position = UDim2.fromOffset(
			camera:WorldToViewportPoint(coordinates).X - hintGui.Frame.Size.X.Offset / 2,
			camera:WorldToViewportPoint(coordinates).Y - hintGui.Frame.Size.Y.Offset / 2
		),
	}):Start()
end

function world_hint.bind(object: BasePart, text: string)
	world_hint.bindings:Insert(nil, {
		object = object,
		text = text,
	})
end

function world_hint.unbind(object: BasePart)
	for i, binding in ipairs(world_hint.bindings:Get() :: { bindingData }) do
		if binding.object == object then
			world_hint.bindings:Remove(i)
			break
		end
	end
end

function world_hint.update()
	for _: number, binding: bindingData in ipairs(world_hint.bindings:Get() :: { bindingData }) do
		local object = binding.object
		local text = binding.text

		-- range

		local range = 14

		if not object or not rootPart or not object:IsDescendantOf(workspace) then
			return
		end
		if (rootPart.Position :: Vector3 - object.Position).Magnitude > range then
			return
		end
		if character.Humanoid.Health <= 0 then
			return
		end

		world_hint.hint_position:Set(object.Position)

		local studs_offset = Vector3.new(0, 2, 0)
		local offset = (camera.CFrame.LookVector + studs_offset)

		local coordinates = camera:WorldToViewportPoint(object.Position + offset)

		local pixel_offset = Vector2.new(0, 20)

		hintGui.Frame.Position =
			UDim2.fromOffset(coordinates.X + pixel_offset.X, coordinates.Y - 20 - pixel_offset.Y)

		TextPlus.Create(hintGui.Frame.TextDisplay, text, {
			Font = Font.new(
				"rbxasset://fonts/families/Montserrat.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Size = 14,
			Color = Color3.fromRGB(255, 219, 209),
			XAlignment = "Left",
			YAlignment = "Center",
			Dynamic = true,
			LineSorting = true,
			WordSorting = true,
		})

		world_hint.current_hint:Set(object)
	end
end
