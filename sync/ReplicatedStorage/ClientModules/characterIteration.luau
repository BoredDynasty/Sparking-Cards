--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TextPlus = require(ReplicatedStorage.Utility.TextPlus)
local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local promise = require(ReplicatedStorage.Packages.promise)

-- characterIteration.luau
-- this module requires both sorting options to be enabled.
local characterIteration = {}

local function iterate(container: Frame, thread: (number, TextLabel | ImageLabel) -> ...any?)
	for i, child in ipairs(container:GetChildren()) do
		if child:IsA("Frame") or child:IsA("Folder") then
			for j, subchild in ipairs(child:GetChildren()) do
				if subchild:IsA("TextLabel") or subchild:IsA("ImageLabel") then
					thread(j, subchild)
				end
			end
		elseif child:IsA("TextLabel") or child:IsA("ImageLabel") then
			thread(i, child)
		end
	end
end

function characterIteration:shake(container: Frame)
	local function shake(_: number, character: TextLabel | ImageLabel)
		local prior = TweenPlus(character, { Position = character.Position + UDim2.fromOffset(10, 0) }, {
			Time = 0.1,
			EasingDirection = "In",
			EasingStyle = "Sine",
		})
		prior:Start()
		prior.Completed:Wait()
		TweenPlus(character, { Position = character.Position - UDim2.fromOffset(20, 0) }, {
			Time = 0.1,
			EasingDirection = "In",
			EasingStyle = "Sine",
		}):Start()
	end
	iterate(container, shake)
end

function characterIteration:count(container: Frame)
	local characterCount = 0
	iterate(container, function()
		characterCount += 1
	end)
	return characterCount
end

--[[
   Does a "jump" animation on each character.
]]
function characterIteration:jump(container: Frame)
	local function jumparoo(_: number, character: TextLabel | ImageLabel)
		local jumpPosition = UDim2.fromScale(character.Position.X.Scale, character.Position.Y.Scale * 1.5)
		local prior = TweenPlus(character, { Position = jumpPosition }, {
			Time = 0.8,
			EasingDirection = "Out",
			EasingStyle = "Sine",
		})
		prior:Start()
		prior.Completed:Wait()
		local position = UDim2.fromScale(
			character.Position.X.Scale,
			character.Position.Y.Scale // character.Position.Y.Scale
		)
		TweenPlus(character, { Position = position }, {
			Time = 0.8,
			EasingDirection = "Out",
			EasingStyle = "Sine",
		}):Start()
	end
	iterate(container, jumparoo)
end

--[[
	Does a "fade away" animation on each character.
]]
function characterIteration:fade(container: Frame)
	local function fadeAway(_: number, character: TextLabel | ImageLabel)
		TweenPlus(character, { TextTransparency = 1 }, {
			Time = 0.5,
			EasingDirection = "In",
			EasingStyle = "Sine",
		}):Start()
	end
	iterate(container, fadeAway)
end

--[[
	Does a "fade in" animation on each character.
]]
function characterIteration:fadeIn(container: Frame)
	local function fadeIn(_: number, character: TextLabel | ImageLabel)
		if typeof(character) == "TextLabel" then
			character.TextTransparency = 1
		end
		TweenPlus(character, { TextTransparency = 0 }, {
			Time = 0.5,
			EasingDirection = "In",
			EasingStyle = "Sine",
		}):Start()
	end
	iterate(container, fadeIn)
end

function characterIteration.getLine(folder: Folder | Frame, line: number)
	local value = nil

	value = promise
		.new(function()
			return folder[`{line}`]
		end)
		:expect()

	return value
end

function characterIteration.getAllLines(folder: Folder | Frame)
	local lines = {}
	for _, child in ipairs(folder:GetChildren()) do
		table.insert(lines, child)
	end
	return lines, #lines
end

function characterIteration:bolden(container: Frame)
	local function bolden(_: number, character: TextLabel | ImageLabel)
		if typeof(character) == "TextLabel" then
			task.delay(0.2, function()
				character.FontFace =
					Font.new(character.Font.Name, Enum.FontWeight.Bold, Enum.FontStyle.Normal)
			end)
		end
	end
	iterate(container, bolden)
end

function characterIteration:regularize(container: Frame)
	local function regularize(_: number, character: TextLabel | ImageLabel)
		if typeof(character) == "TextLabel" then
			task.delay(0.2, function()
				character.FontFace =
					Font.new(character.Font.Name, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
			end)
		end
	end
	iterate(container, regularize)
end

return characterIteration
