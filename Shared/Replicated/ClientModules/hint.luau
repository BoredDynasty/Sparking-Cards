--!nonstrict

local LocalizationService = game:GetService("LocalizationService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local characterMarshaller = require(ReplicatedStorage.Utility.characterMarshaller)
local future = require(ReplicatedStorage.Packages.future)
local observer = require(ReplicatedStorage.Utility.observer)
local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local spr = require(ReplicatedStorage.Modules.spr)

-- hint.luau

type HintGui = ScreenGui & {
	CanvasGroup: CanvasGroup & {
		Frame: Frame & {
			TextLabel: TextLabel,
		},
	},
}

local player = playerMarshaller.get()
local playerGui = player.PlayerGui

local character = characterMarshaller.get(player)

local hint_gui = playerGui:WaitForChild("Dialog") :: HintGui

local module = {}

local disallowed_whitespace = { "\n", "\r", "\t", "\v", "\f" }

type Hint = setmetatable<{
	hint: TextButton,
	Clicked: SignalPlus.Signal<>,
	CanClick: observer.Observer<boolean>,
	expiry: number,
}, typeof(module.new())>

local function createHint(ancestor: Instance?)
	local Instances = {
		Hint = Instance.new("TextButton"),
		TextStroke = Instance.new("UIStroke"),
		BorderStroke = Instance.new("UIStroke"),
		HintCorner = Instance.new("UICorner"),
		TextPadding = Instance.new("UIPadding"),
	}

	Instances.Hint.Name = "Hint"
	Instances.Hint.Active = false
	Instances.Hint.AnchorPoint = Vector2.new(0.5, 0.5)
	Instances.Hint.AutomaticSize = Enum.AutomaticSize.X
	Instances.Hint.Size = UDim2.new(0, 0, 0, 30)
	Instances.Hint.BorderColor3 = Color3.fromRGB(27, 42, 53)
	Instances.Hint.Selectable = false
	Instances.Hint.BackgroundTransparency = 1
	Instances.Hint.Position = UDim2.new(0.5, 0, 1, -85)
	Instances.Hint.BorderSizePixel = 0
	Instances.Hint.BackgroundColor3 = Color3.fromRGB(25, 27, 29)
	Instances.Hint.FontFace =
		Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	Instances.Hint.TextTransparency = 1
	Instances.Hint.TextColor3 = Color3.fromRGB(255, 255, 255)
	Instances.Hint.Text = ""
	Instances.Hint.Parent = ancestor

	Instances.TextStroke.Name = "TextStroke"
	Instances.TextStroke.Thickness = 0
	Instances.TextStroke.Transparency = 1
	Instances.TextStroke.Parent = Instances.Hint

	Instances.BorderStroke.Name = "BorderStroke"
	Instances.BorderStroke.Thickness = 0
	Instances.BorderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Instances.BorderStroke.Transparency = 1
	Instances.BorderStroke.Parent = Instances.Hint

	Instances.HintCorner.Name = "HintCorner"
	Instances.HintCorner.CornerRadius = UDim.new(0.22, 0)
	Instances.HintCorner.Parent = Instances.Hint

	Instances.TextPadding.Name = "TextPadding"
	Instances.TextPadding.PaddingLeft = UDim.new(0, 11)
	Instances.TextPadding.PaddingRight = UDim.new(0, 11)
	Instances.TextPadding.Parent = Instances.Hint

	return Instances.Hint
end

--[[
	```luau

	-- usage

	local module = require(path.to.hint)

	local hint = module.new()
	hint:SetText("english or spanish?")
	hint:SetExpiry(5)
	hint:SetCanClick(false)

	-- it auto renders and cleans up by itself.
	-- pretty neat, huh?

	print("new hint!")

	```
]]
function module.new()
	local self = setmetatable({}, module)

	self.hint = createHint(hint_gui.CanvasGroup)
	self.Clicked = SignalPlus()
	self.CanClick = observer.new(false)
	self.expiry = 12

	self.CanClick:Watch(function(new)
		self.hint.Interactable = new
	end)

	self.hint.MouseButton1Click:Connect(function()
		self.Clicked:Fire()
	end)

	task.defer(module.Render, self, self)

	return self
end

function module:SetText(self: Hint, text: string, translate_text: boolean?)
	text = text or ""
	translate_text = translate_text or true

	for key, value in ipairs(disallowed_whitespace) do
		if string.find(text, value) then
			warn("whitespaces are not supported")
		end
	end

	if translate_text then
		local get_translator =
			future.Try(LocalizationService.GetTranslatorForPlayerAsync(LocalizationService, player))

		local translator = select(2, get_translator:Await()) :: Translator

		assert(translator, "Couldn't fetch translator from the cloud.")

		local translated = translator:Translate(self.hint, text)
		self.hint.Text = translated
	end

	self.hint.Text = text
end

function module:SetExpiry(self: Hint, expiry: number)
	self.expiry = expiry
end

function module:SetCanClick(self: Hint, enabled: boolean)
	self.CanClick:Set(enabled)
end

function module:Destroy(self: Hint)
	self.CanClick:Destroy()
	self.Clicked:Destroy()
	self.hint:Destroy()

	table.clear(self)
	setmetatable(self, nil)
end

function module:Render(self: Hint)
	-- auto-renders

	self.hint.Parent = hint_gui.CanvasGroup

	task.delay(self.expiry, function()
		spr.target(self.hint, 1, 0.9, {
			BackgroundTransparency = 1,
			TextTransparency = 1,
		})
		spr.completed(self.hint, function()
			self:Destroy(self)
		end)
	end)
end

return module
