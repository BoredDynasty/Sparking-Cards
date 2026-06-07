--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local future = require(ReplicatedStorage.Packages.future)
local property = require(ReplicatedStorage.Utility.property)
local tablekit = require(ReplicatedStorage.Packages.tablekit)

-- fade.luau

export type FadeOptions = {
	duration: number?,
	transparency: { start: number?, target: number? }?,
	recursive: boolean?,
}

local DEFAULT_OPTIONS: FadeOptions = {
	duration = 0.5,
	transparency = {
		start = 1,
		target = 0,
	},
	recursive = true,
}

local function fadeElement(element: GuiObject, options: FadeOptions)
	return future.Try(function()
		if not element:IsA("GuiObject") then
			error("element is not a GuiObject.")
		end

		local opts = tablekit.MergeDictionary(DEFAULT_OPTIONS :: any, options :: any) :: FadeOptions

		local function fadeInstance(inst: GuiObject)
			local T_info = TweenInfo.new(opts.duration, Enum.EasingStyle.Linear)

			local function createTweenForClass()
				-- use TweenService
				if inst:IsA("Frame") or inst:IsA("TextLabel") then
					return TweenService:Create(inst, T_info, {
						BackgroundTransparency = opts.transparency.target,
					})
				elseif inst:IsA("ImageLabel") then
					return TweenService:Create(inst, T_info, {
						ImageTransparency = opts.transparency.target,
						BackgroundTransparency = opts.transparency.target,
					})
				elseif inst:IsA("ImageButton") then
					return TweenService:Create(inst, T_info, {
						ImageTransparency = opts.transparency.target,
						BackgroundTransparency = opts.transparency.target,
					})
				elseif inst:IsA("TextButton") then
					return TweenService:Create(inst, T_info, {
						TextTransparency = opts.transparency.target,
						BackgroundTransparency = opts.transparency.target,
					})
				else
					-- For other GuiObject types, we can attempt to tween both properties if they exist
					local properties = {}

					if property.hasProperty(inst, "BackgroundTransparency") then
						properties.BackgroundTransparency = opts.transparency.target
					end
					if property.hasProperty(inst, "TextTransparency") then
						properties.TextTransparency = opts.transparency.target
					end
					if property.hasProperty(inst, "ImageTransparency") then
						properties.ImageTransparency = opts.transparency.target
					end

					return TweenService:Create(inst, T_info, properties)
				end
			end

			local tween = createTweenForClass()

			-- Set initial transparency
			inst.Transparency = opts.transparency.start

			-- Start the tween
			tween:Start()
		end

		-- Handle recursive fading if enabled
		if opts.recursive then
			for _, descendant in ipairs(element:GetDescendants()) do
				if descendant:IsA("GuiObject") then
					future.Try(fadeInstance, descendant)
				end
			end
		end
	end)
end

-- Convenience functions for common fade operations
local function fadeIn(element: GuiObject, duration: number?, recursive: boolean?)
	return fadeElement(element, {
		duration = duration,
		transparency = { start = 1, target = 0 },
		recursive = recursive,
	})
end

local function fadeOut(element: GuiObject, duration: number?, recursive: boolean?)
	return fadeElement(element, {
		duration = duration,
		transparency = { start = 0, target = 1 },
		recursive = recursive,
	})
end

--[[
   Usage example:
   ```luau
   local fadeModule = require(ReplicatedStorage.Modules.fade)
   local myFrame = script.Parent:WaitForChild("MyFrame")

   -- Fade in the frame over 1 second, including all descendants
   fadeModule.fadeIn(myFrame, 1, true)
   -- Fade out the frame over 1 second, including all descendants
   fadeModule.fadeOut(myFrame, 1, true)
   ```
]]
return {
	fade = fadeElement,
	fade_in = fadeIn,
	fade_out = fadeOut,
}
