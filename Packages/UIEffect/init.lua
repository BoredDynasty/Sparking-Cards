--!nocheck

-- Da Dubious Dynasty

-- By the way, don't use this Module: https://devforum.roblox.com/t/uianimator-devlog-effects-ui-effect-manager-wip/3190172

--[=[
	@class UIEffect
		@tag A Module for all your UI Needs.
-]=]
local UIEffect = {}

-- // Services
local Lighting = game:GetService("Lighting")

-- // Requires
-- local Style = require(script:FindFirstChild("Style"))
local Color = require(script.Color)
local SoundManager = require(script.SoundManager)
local Maid = require(script.Maid)
local Curvy = require(script.Curvy)
local Text = require(script.Text)

-- local Camera = game.Workspace.CurrentCamera

Maid.new()

local Blur = Instance.new("BlurEffect")
Blur.Parent = Lighting
Blur.Enabled = false
Blur.Name = "UIBlur"

-- // Functions -- //

-- // UIEffect

--[=[
	@function getColor
		@within UIEffect
		@param color string
		@return Color3? | BrickColor?
--]=]
function UIEffect.getColor(color: string)
	return Color.getColor(color)
end

--[=[
	@function BlurEffect
		@within UIEffect
		@param value boolean
		@return boolean?
--]=]
function UIEffect.BlurEffect(value)
	if value == true then
		Curvy:Curve(Blur, TweenInfo.new(0.5), "Size", 10)
		task.delay(0.5, function()
			Blur.Enabled = true
		end)
	elseif value == false then
		Curvy:Curve(Blur, TweenInfo.new(0.5), "Size", 0)
		task.delay(0.5, function()
			Blur.Enabled = false
		end)
	end
	return value
end

--[=[
	@function TypewriterEffect
		@within UIEffect
		@param DisplayText table string
		@param textlabel TextLabel | TextButton
		@param speed number
--]=]
function UIEffect.TypewriterEffect(DisplayedText: string, textlabel, speed)
	return Text.TypewriterEffect(DisplayedText, textlabel, speed)
end

--[=[
	@function Sound
		@within UIEffect
		@param sound string | number
--]=]
function UIEffect.Sound(sound)
	SoundManager.Play(sound, script.UISounds)
end

--[=[
	@function changeColor
		@within UIEffect
		@param color string
		@param canvas Frame
--]=]
function UIEffect.changeColor(color: string | Color3, canvas: Frame | CanvasGroup)
	color = Color.getColor(color)
	if color then
		task.wait(1)
		if canvas:IsA("Frame") or canvas:IsA("CanvasGroup") then
			Curvy:Curve(canvas, TweenInfo.new(0.1), "BackgroundColor3", color)
		elseif canvas:IsA("ImageLabel") or canvas:IsA("ImageButton") then
			Curvy:Curve(canvas, TweenInfo.new(0.5), "ImageColor3", color)
		end
	end
end

--[=[
	@function markdownToRichText
		@within UIEffect
		@param input string
		@return string?
--]=]
function UIEffect:markdownToRichText(input): string?
	return Text:MD_ToRichText(input)
end

--[=[
	@function CustomAnimation
		@within UIEffect
		@param effect any
		@param object GuiObbject
		@param value boolean
--]=]
function UIEffect:CustomAnimation(effect, object: GuiObject, value)
	local objectSize = object.Size
	-- local objectPosition = object.Position

	if effect == "Hover" and value == true then
		local target = UDim2.new(
			object.Size.X.Scale * 0.9,
			object.Size.Y.Offset,
			object.Size.Y.Scale * 0.9,
			object.Size.Y.Offset
		)
		Curvy:Curve(object, Curvy.TweenInfo(0.5, "Back", "InOut", 0, false, 0), "Size", target)
	elseif value == false then
		local target =
			UDim2.new(objectSize.X.Scale, objectSize.X.Offset, objectSize.Y.Scale, objectSize.Y.Offset)
		Curvy:Curve(object, Curvy.TweenInfo(0.5, "Back", "InOut", 0, false, 0), "Size", target)
	elseif effect == "Click" then
		local target = UDim2.new(
			object.Size.X.Scale * 0.9,
			object.Size.Y.Offset,
			object.Size.Y.Scale * 0.9,
			object.Size.Y.Offset
		)
		Curvy:Curve(object, Curvy.TweenInfo(0.2, "Back", "InOut", 0, false, 0), "Size", target)
		task.wait(0.2)
		local newTarget =
			UDim2.new(object.Size.X.Scale, object.Size.X.Offset, object.Size.Y.Scale, object.Size.Y.Offset)
		Curvy:Create(object, Curvy.TweenInfo(0.2, "Back", "InOut", 0, false, 0), "Size", newTarget)
	elseif effect == "FadeIn" then
		Curvy:Curve(object, Curvy.TweenInfo(0.5, "Sine", "InOut", 0, false, 0), "GroupTransparency", 0)
	elseif effect == "FadeOut" then
		Curvy:Curve(object, Curvy.TweenInfo(0.5, "Sine", "InOut", 0, false, 0), "GroupTransparency", 1)
	end
end
--[=[
	@function changeVisibility
		@within UIEffect
		@param canvas CanvasGroup
		@param value boolean
		@param frame Frame?
--]=]
function UIEffect:changeVisibility(canvas: GuiObject, value)
	if value == true then
		Curvy:Curve(canvas, Curvy.TweenInfo(0.5, "Sine", "InOut", 0, false, 0), "GroupTransparency", 0)
		canvas.Visible = true
	else
		Curvy:Curve(canvas, Curvy.TweenInfo(0.5, "Sine", "InOut", 0, false, 0), "GroupTransparency", 1)
		canvas.Visible = false
	end
end

export type UIEffectmodule = "Color" | "SoundManager" | "Maid" | "Curvy" | "Text"

function UIEffect.getModule(module: UIEffectmodule): any
	return require(script[module])
end

return UIEffect
