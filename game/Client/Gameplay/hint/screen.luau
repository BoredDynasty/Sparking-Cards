--!nonstrict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TextPlus = require(ReplicatedStorage.Utility.TextPlus)
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local trove = require(ReplicatedStorage.Packages.trove)

-- screen.luau

local screen_hint = {
	current_hint = observer.new() :: observer.Observer<BasePart?>,
	bindings = observer.new({}),
	_trove = trove.new(),
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

local mouse = player:GetMouse()

local playerGui = player.PlayerGui
local hintGui = playerGui:WaitForChild("Hint") :: hintInterface

function screen_hint._highlight(ancestor: Instance)
	local highlight = screen_hint._trove:Construct(Instance, "Highlight")

	highlight.Parent = ancestor
	highlight.Adornee = ancestor
	highlight.FillColor = Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 0.8
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.OutlineTransparency = 0.8

	highlight.Enabled = true

	return highlight :: Highlight
end

function screen_hint.bind(object: BasePart, text: string)
	screen_hint.bindings:Insert(nil, {
		object = object,
		text = text,
		highlight = screen_hint._highlight(object),
	})
end

function screen_hint.unbind(object: BasePart)
	local binding = screen_hint.bindings:Find(function(binding)
		return binding.object == object
	end)

	if binding then
		screen_hint.bindings:Remove(binding)
	end
end

function screen_hint.update()
	for _: number, binding: bindingData in ipairs(screen_hint.bindings:Get() :: { bindingData }) do
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

		-- mouse

		if mouse.Target ~= object then
			return
		end

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

		screen_hint.current_hint:Set(object)
	end
end

return screen_hint
