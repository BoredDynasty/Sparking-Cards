--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local dictionary = require(ReplicatedStorage.Utility.dictionary)
local promise = require(ReplicatedStorage.Packages.promise)
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
	return promise.new(function(resolve, reject)
		if not element:IsA("GuiObject") then
			reject("Element must be a GuiObject")
			return
		end

		local opts = dictionary.copy(DEFAULT_OPTIONS, true)
		if options then
			--[[
			for k, v in options do
				if type(v) == "table" then
					opts[k] = table.clone(v)
				else
					opts[k] = v
				end
			end
         --]]
			options = dictionary.reconcile(DEFAULT_OPTIONS, options)
		end

		-- Create a promise array for multiple tweens if recursive
		local promises = {}

		local function fadeInstance(inst: GuiObject)
			return promise.new(function(tweenResolve)
				local tweenOptions = {
					Time = opts.duration,
					EasingStyle = "Quad",
					EasingDirection = "InOut",
				}
				local function createTweenForClass(): TweenPlus.Tween
					local ret_tween = nil
					if inst:IsA("Frame") or inst:IsA("TextLabel") then
						local tween = TweenPlus(inst, {
							BackgroundTransparency = opts.transparency.target,
						}, tweenOptions)
						tween = ret_tween
					elseif inst:IsA("ImageLabel") then
						local tween = TweenPlus(inst, {
							ImageTransparency = opts.transparency.target,
							BackgroundTransparency = opts.transparency.target,
						}, tweenOptions)
						tween = ret_tween
					elseif inst:IsA("ImageButton") then
						local tween = TweenPlus(inst, {
							ImageTransparency = opts.transparency.target,
							BackgroundTransparency = opts.transparency.target,
						}, tweenOptions)
						tween = ret_tween
					end
					return ret_tween
				end

				local tween = createTweenForClass()

				-- Set initial transparency
				inst.Transparency = opts.transparency.start

				-- Listen for completion
				tween.Completed:Once(function()
					tweenResolve(true)
				end)

				-- Start the tween
				tween:Start()
			end)
		end

		-- Add main element tween
		table.insert(promises, fadeInstance(element))

		-- Handle recursive fading if enabled
		if opts.recursive then
			for _, descendant in element:GetDescendants() do
				if descendant:IsA("GuiObject") then
					table.insert(promises, fadeInstance(descendant))
				end
			end
		end

		-- Resolve when all tweens complete
		promise
			.all(promises)
			:andThen(function()
				resolve(true)
			end)
			:catch(reject)
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
   ## Example Usage:
   ```luau
   local Fade = require(path.to.fade)

   -- Basic fade in
   Fade.fadeIn(myUIElement):andThen(function()
       print("Fade in complete!")
   end)

   -- Basic fade out
   Fade.fadeOut(myUIElement, 1.0) -- 1 second duration

   -- Custom fade with options
   Fade.fade(myUIElement, {
       duration = 0.75,
      transparency = {
           start = 0.5,
           target = 0
       },
       recursive = true
   }):andThen(function()
       print("Custom fade complete!")
   end):catch(function(err)
       warn("Fade failed:", err)
   end)
]]
return {
	fade = fadeElement,
	fadeIn = fadeIn,
	fadeOut = fadeOut,
}
