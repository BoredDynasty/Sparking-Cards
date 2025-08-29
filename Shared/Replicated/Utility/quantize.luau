--!optimize 2
--!native
--!strict

-- Quantize.luau
-- A fully typed Luau module for MMCQ color quantization.
-- With added support for Color3s to be used instead of RGB arrays.
-- Based on quantize.js and Leptonica.

type Comparator = (A: VolumeBox, B: VolumeBox) -> boolean

type ColorMapPrototype = {
	-- ForceBW renamed to Greyscale
	Greyscale: ((self: ColorMap, CreateCopy: false?) -> ())
		& ((self: ColorMap, CreateCopy: true) -> ColorMap),
	Nearest: ((self: ColorMap, Pixel: Pixel) -> Pixel) & ((self: ColorMap, Color3: Color3) -> Pixel),
	Map: ((self: ColorMap, Pixel: Pixel) -> Pixel) & ((self: ColorMap, Color3: Color3) -> Pixel),
	Palette: (self: ColorMap) -> { Pixel },

	-- .size() method changed out to use the __len metamethod
	-- for consistency w lua
	__len: (self: ColorMap) -> number,
	__index: ColorMapPrototype,
}

type VolumeBoxPrototype = {
	Contains: ((self: VolumeBox, Pixel: Pixel) -> boolean) & ((self: VolumeBox, Color3: Color3) -> boolean),
	Volume: (self: VolumeBox, Force: boolean?) -> number,
	Average: (self: VolumeBox, Force: boolean?) -> Pixel,
	Count: (self: VolumeBox, Force: boolean?) -> number,
	Copy: (self: VolumeBox) -> VolumeBox,

	__len: (self: VolumeBox) -> number,
	__index: VolumeBoxPrototype,
}

export type VolumeBox = typeof(setmetatable(
	{} :: {
		Histo: { number },
		RedMin: number,
		RedMax: number,
		GreenMin: number,
		GreenMax: number,
		BlueMin: number,
		BlueMax: number,

		__average_pixel: Pixel?,
		__volume: number?,
		__count: number?,
	},
	{} :: VolumeBoxPrototype
))

export type ColorMap = typeof(setmetatable(
	{} :: {
		VolumeBoxes: { VolumeBox },
		__sorted: boolean,
	},
	{} :: ColorMapPrototype
))

export type Pixel = { number } | { ["1"]: number, ["2"]: number, ["3"]: number }

local InvalidPixelAtIndexFormat = "[Quantize] %s value in Pixel at index &d, is not in range 0..255"
local FractByPopulations = 0.75
local MaxIterations = 1000
local Sigbits = 5
local HistoSize = bit32.lshift(1, 3 * Sigbits)
local RShift = 8 - Sigbits
local VboxAvgMult = bit32.lshift(1, RShift)
local Mask = bit32.rshift(0xff, RShift)

local function GetOrCreatePixel(PixelOrColor3: Pixel | Color3): Pixel
	if typeof(PixelOrColor3) == "table" then
		return PixelOrColor3
	else
		local Pixel = table.create(3)
		Pixel[1] = math.clamp(math.ceil(PixelOrColor3.R * 255), 0, 255)
		Pixel[2] = math.clamp(math.ceil(PixelOrColor3.G * 255), 0, 255)
		Pixel[3] = math.clamp(math.ceil(PixelOrColor3.B * 255), 0, 255)
		return Pixel
	end
end

local function CheckPixel(Pixel: Pixel)
	if Pixel[1] > 255 or Pixel[1] < 0 then
		error("Red value in Pixel is not in range 0..255")
	elseif Pixel[2] > 255 or Pixel[2] < 0 then
		error("Green value in Pixel is not in range 0..255")
	elseif Pixel[3] > 255 or Pixel[3] < 0 then
		error(" Blue value in Pixel is not in range 0..255")
	end
	return Pixel
end

local function SortColorMap(ColorMap: ColorMap, Comparator: Comparator)
	if not ColorMap.__sorted then
		table.sort(ColorMap.VolumeBoxes, Comparator)
		ColorMap.__sorted = true
	end
end

local function GetColorIndex(R: number, G: number, B: number)
	return bit32.lshift(R, 2 * Sigbits) + bit32.lshift(G, Sigbits) + B
end

local function OccupancySizeSort(A: VolumeBox, B: VolumeBox)
	return A:Count() * A:Volume() > B:Count() * B:Volume()
end

local function CountSort(A: VolumeBox, B: VolumeBox)
	return A:Count() > B:Count()
end

local function ReverseTable<T>(Tbl: { T })
	for Index = 1, #Tbl // 2 do
		local SwapIndex = (#Tbl - Index) + 1
		local Original = Tbl[Index]
		Tbl[Index] = Tbl[SwapIndex]
		Tbl[SwapIndex] = Original
	end
	return Tbl
end

-- Modified from:
-- https://github.com/Roblox/luau-polyfill/blob/main/modules/collections/src/Array/reduce.lua
local function GetArraySum(Tbl: { number })
	if #Tbl == 0 then
		return 0
	end
	local Sum = 0

	for _, Value in Tbl do
		Sum += Value
	end
	return Sum
end

local function To32Bit(N: number)
	return bit32.band(N, 0xFFFFFFFF)
end

--[[
	Basic Javascript port of the MMCQ (modified median cut quantization)
	algorithm from the Leptonica library (http://www.leptonica.com/).
	Returns a color map you can use to map original pixels to the reduced
	palette. Still a work in progress.

	@author Nick Rabinowitz
	@example
 
	array of pixels as {R,G,B} arrays
	local myPixels = {{190,197,190}, {202,204,200}, {207,214,210}, {211,214,211}, {205,207,207}}
	local maxColors = 4
 
	local ColorMap = Quantize(myPixels, maxColors)
	local Palette = ColorMap.Palette()
	local NewPixels = Array.map(myPixels, function(p)
		return ColorMap.Map(p)
	end)
--]]

-- 3d color space box

local VolumeBoxPrototype = {}
VolumeBoxPrototype.__index = VolumeBoxPrototype

function VolumeBoxPrototype.Contains(self: VolumeBox, PixelOrColor3: Pixel | Color3)
	local Pixel = CheckPixel(GetOrCreatePixel(PixelOrColor3))
	local RedValue = bit32.rshift(Pixel[1], RShift)
	local GreenValue = bit32.rshift(Pixel[2], RShift)
	local BlueValue = bit32.rshift(Pixel[3], RShift)

	return RedValue >= self.RedMin
		and RedValue <= self.RedMax
		and GreenValue >= self.GreenMin
		and GreenValue <= self.GreenMax
		and BlueValue >= self.BlueMin
		and BlueValue <= self.BlueMax
end

function VolumeBoxPrototype.Volume(self: VolumeBox, Force: boolean?)
	if Force or not self.__volume then
		self.__volume = ((self.RedMax - self.RedMin) + 1)
			* ((self.GreenMax - self.GreenMin) + 1)
			* ((self.BlueMax - self.BlueMin) + 1)
	end
	return self.__volume
end

function VolumeBoxPrototype.Count(self: VolumeBox, Force: boolean?)
	if Force or not self.__count then
		local PixelCount = 0

		for R = self.RedMin, self.RedMax do
			for G = self.GreenMin, self.GreenMax do
				for B = self.BlueMin, self.BlueMax do
					PixelCount += self.Histo[GetColorIndex(R, G, B)] or 0
				end
			end
		end

		self.__count = PixelCount
		return PixelCount
	else
		return self.__count
	end
end

function VolumeBoxPrototype.Average(self: VolumeBox, Force: boolean?)
	if Force or not self.__average_pixel then
		local GreenSum = 0
		local BlueSum = 0
		local RedSum = 0
		local NTOT = 0

		for R = self.RedMin, self.RedMax do
			for G = self.GreenMin, self.GreenMax do
				for B = self.BlueMin, self.BlueMax do
					local Hue = self.Histo[GetColorIndex(R, G, B)] or 0
					GreenSum += (Hue * (G + 0.5)) * VboxAvgMult
					BlueSum += (Hue * (B + 0.5)) * VboxAvgMult
					RedSum += (Hue * (R + 0.5)) * VboxAvgMult
					NTOT += Hue
				end
			end
		end

		local AveragePixel = table.create(3)

		if NTOT > 0 then
			AveragePixel[1] = To32Bit(RedSum / NTOT)
			AveragePixel[2] = To32Bit(GreenSum / NTOT)
			AveragePixel[3] = To32Bit(BlueSum / NTOT)
		else
			-- print("empty box")
			AveragePixel[1] = To32Bit((VboxAvgMult * (self.RedMin + self.RedMax + 1)) / 2)
			AveragePixel[2] = To32Bit((VboxAvgMult * (self.GreenMin + self.GreenMax + 1)) / 2)
			AveragePixel[3] = To32Bit((VboxAvgMult * (self.BlueMin + self.BlueMax + 1)) / 2)
		end

		self.__average_pixel = AveragePixel
		return AveragePixel
	else
		return self.__average_pixel
	end
end

function VolumeBoxPrototype.__len(self: VolumeBox)
	return self:Count()
end

function VolumeBoxPrototype.Copy(self: VolumeBox)
	return (
		setmetatable({
			GreenMin = self.GreenMin,
			GreenMax = self.GreenMax,
			BlueMin = self.BlueMin,
			BlueMax = self.BlueMax,
			RedMin = self.RedMin,
			RedMax = self.RedMax,
			Histo = self.Histo,

			__average_pixel = self.__average_pixel,
			__volume = self.__volume,
			__count = self.__count,
		}, VolumeBoxPrototype) :: any
	) :: VolumeBox
end

-- Color map
local ColorMapPrototype = {}
ColorMapPrototype.__index = ColorMapPrototype

function ColorMapPrototype.Nearest(self: ColorMap, PixelOrColor3: Pixel | Color3)
	local Pixel = CheckPixel(GetOrCreatePixel(PixelOrColor3))
	local D1 = math.huge
	local NearestPixel

	for _, VolumeBox in self.VolumeBoxes do
		local D2 = math.sqrt(
			math.pow(Pixel[1] - VolumeBox:Average()[1], 2)
				+ math.pow(Pixel[2] - VolumeBox:Average()[2], 2)
				+ math.pow(Pixel[3] - VolumeBox:Average()[3], 2)
		)

		if D2 < D1 then
			NearestPixel = VolumeBox:Average()
			D1 = D2
		end
	end
	return NearestPixel
end

function ColorMapPrototype.Map(self: ColorMap, PixelOrColor3: Pixel | Color3)
	local Pixel = CheckPixel(GetOrCreatePixel(PixelOrColor3))

	for _, VolumeBox in self.VolumeBoxes do
		if
			VolumeBox:Average()[1] == Pixel[1]
			and VolumeBox:Average()[2] == Pixel[2]
			and VolumeBox:Average()[3] == Pixel[3]
		then
			return VolumeBox:Average()
		end
	end
	return self:Nearest(Pixel)
end

function ColorMapPrototype.Greyscale(self: ColorMap, CreateCopy: boolean?)
	local ColorMap = if not CreateCopy
		then self
		else setmetatable({
			VolumeBoxes = self.VolumeBoxes,
			__sorted = self.__sorted,
		}, ColorMapPrototype)

	-- XXX: won't  work yet
	table.sort(ColorMap.VolumeBoxes, function(A, B)
		return GetArraySum(A:Average()) > GetArraySum(B:Average())
	end)

	-- force darkest color to black if everything < 5
	local Lowest = ColorMap.VolumeBoxes[1]
	local LowestPixel = Lowest:Average()

	if LowestPixel[1] < 5 and LowestPixel[2] < 5 and LowestPixel[3] < 5 then
		Lowest.__average_pixel = table.create(3, 0)
	end

	-- force lightest color to white if everything > 251
	-- deviation: switched #VolumeBoxes - 1 to just #VolumeBoxes
	local Highest = ColorMap.VolumeBoxes[#ColorMap.VolumeBoxes]
	local HighestPixel = Highest:Average()

	if HighestPixel[1] > 251 and HighestPixel[2] > 251 and HighestPixel[3] > 251 then
		Highest.__average_pixel = table.create(3, 255)
	end
	return if CreateCopy then ColorMap else nil
end

function ColorMapPrototype.Palette(self: ColorMap)
	local Pixels = table.create(#self.VolumeBoxes)

	for Index, VolumeBox in self.VolumeBoxes do
		Pixels[Index] = table.clone(VolumeBox:Average())
	end
	return Pixels
end

function ColorMapPrototype.__len(self: ColorMap)
	return #self.VolumeBoxes
end

local function VolumeBoxFromPixels(Pixels: { Pixel }, Histo: { number })
	local GreenMin = 1000000
	local GreenMax = 0
	local BlueMin = 1000000
	local BlueMax = 0
	local RedMin = 1000000
	local RedMax = 0

	for _, Pixel in Pixels do
		local GreenValue = bit32.rshift(Pixel[2], RShift)
		local BlueValue = bit32.rshift(Pixel[3], RShift)
		local RedValue = bit32.rshift(Pixel[1], RShift)

		if RedValue < RedMin then
			RedMin = RedValue
		elseif RedValue > RedMax then
			RedMax = RedValue
		end

		if GreenValue < GreenMin then
			GreenMin = GreenValue
		elseif GreenValue > GreenMax then
			GreenMax = GreenValue
		end

		if BlueValue < BlueMin then
			BlueMin = BlueValue
		elseif BlueValue > BlueMax then
			BlueMax = BlueValue
		end
	end

	return (
		setmetatable({
			RedMin = RedMin,
			RedMax = RedMax,
			GreenMin = GreenMin,
			GreenMax = GreenMax,
			BlueMin = BlueMin,
			BlueMax = BlueMax,
			Histo = Histo,
		}, VolumeBoxPrototype) :: any
	) :: VolumeBox
end

local function DoCut(
	MaxString: string,
	MinString: string,
	MaxNumber: number,
	MinNumber: number,
	VolumeBox: VolumeBox,
	PartialSum: { number },
	LookAheadSum: { number },
	Total: number
): { VolumeBox }?
	for Index = MinNumber, MaxNumber do
		if PartialSum[Index] > Total / 2 then
			local VolumeBox1 = VolumeBox:Copy()
			local VolumeBox2 = VolumeBox:Copy()
			local Left = Index - MinNumber
			local Right = MaxNumber - 1

			local D2 = if Left <= Right
				then math.min(MaxNumber - 1, To32Bit((Index + Right) / 2))
				else math.max(MinNumber, To32Bit((Index - 1) - (Left / 2)))

			-- avoid 0-count boxes
			while PartialSum[D2] == 0 or not PartialSum[D2] do
				D2 += 1
			end

			local Count2 = LookAheadSum[D2]

			while not Count2 and PartialSum[D2 - 1] do
				D2 -= 1
				Count2 = LookAheadSum[D2]
			end

			-- set dimensions
			VolumeBox1[MaxString] = D2
			VolumeBox2[MinString] = D2 + 1

			local VolumeBoxes = table.create(2)
			VolumeBoxes[1] = VolumeBox1
			VolumeBoxes[2] = VolumeBox2
			return VolumeBoxes
		end
	end

	return nil
end

local function MedianCutApply(Histo: { number }, VolumeBox: VolumeBox): { VolumeBox }?
	if #VolumeBox == 1 then
		-- only one pixel, no split
		return table.create(1, VolumeBox:Copy())
	elseif #VolumeBox == 0 then
		return nil
	end

	local GW = (VolumeBox.GreenMax - VolumeBox.GreenMin) + 1
	local BW = (VolumeBox.BlueMax - VolumeBox.BlueMin) + 1
	local RW = (VolumeBox.RedMax - VolumeBox.RedMin) + 1
	local MaxW = math.max(RW, GW, BW)

	-- Find the partial sum arrays along the selected axis.
	local PartialSum = {}
	local Total = 0

	if MaxW == RW then
		for R = VolumeBox.RedMin, VolumeBox.RedMax do
			local Sum = 0

			for G = VolumeBox.GreenMin, VolumeBox.GreenMax do
				for B = VolumeBox.BlueMin, VolumeBox.BlueMax do
					Sum += Histo[GetColorIndex(R, G, B)] or 0
				end
			end

			Total += Sum
			PartialSum[R] = Total
		end
	elseif MaxW == GW then
		for G = VolumeBox.GreenMin, VolumeBox.GreenMax do
			local Sum = 0

			for R = VolumeBox.RedMin, VolumeBox.RedMax do
				for B = VolumeBox.BlueMin, VolumeBox.BlueMax do
					Sum += Histo[GetColorIndex(R, G, B)] or 0
				end
			end

			Total += Sum
			PartialSum[G] = Total
		end
	else
		for B = VolumeBox.BlueMin, VolumeBox.BlueMax do
			local Sum = 0

			for R = VolumeBox.RedMin, VolumeBox.RedMax do
				for G = VolumeBox.GreenMin, VolumeBox.GreenMax do
					Sum += Histo[GetColorIndex(R, G, B)] or 0
				end
			end

			Total += Sum
			PartialSum[B] = Total
		end
	end
	local LookAheadSum = table.create(#PartialSum)

	for Index, Value in PartialSum do
		LookAheadSum[Index] = Total - Value
	end

	-- Determine the cut planes
	if MaxW == GW then
		return DoCut(
			"GreenMax",
			"GreenMin",
			VolumeBox.GreenMax,
			VolumeBox.GreenMin,
			VolumeBox,
			PartialSum,
			LookAheadSum,
			Total
		)
	elseif MaxW == BW then
		return DoCut(
			"BlueMax",
			"BlueMin",
			VolumeBox.BlueMax,
			VolumeBox.BlueMin,
			VolumeBox,
			PartialSum,
			LookAheadSum,
			Total
		)
	else
		return DoCut(
			"RedMax",
			"RedMin",
			VolumeBox.RedMax,
			VolumeBox.RedMin,
			VolumeBox,
			PartialSum,
			LookAheadSum,
			Total
		)
	end
end

-- inner function to do the iteration
local function Iterate(Target: number, ColorMap: ColorMap, Histo: { number }, Comparator: Comparator)
	local PixelCount = #ColorMap.VolumeBoxes
	local Niters = 0

	while Niters < MaxIterations do
		-- Doing the checks at the top like this PR:
		-- https://github.com/olivierlesnicki/quantize/pull/6
		if PixelCount >= Target or Niters > MaxIterations then
			return
		end
		--[[
			if Niters > MaxIterations then
				warn("[Quantize] infinite loop; perhaps too few pixels!")
				return
			end
		--]]

		SortColorMap(ColorMap, Comparator)
		local VolumeBox = table.remove(ColorMap.VolumeBoxes) :: VolumeBox

		-- just put it back
		if #VolumeBox == 0 then
			table.insert(ColorMap.VolumeBoxes, VolumeBox)
			Niters += 1
			continue
		end
		ColorMap.__sorted = false

		-- do the cut
		local VolumeBoxes = MedianCutApply(Histo, VolumeBox)

		if not VolumeBoxes then
			warn("[Quantize] MedianCutApply failed!")
			return
		elseif not VolumeBoxes[1] then
			warn("[Quantize] VolumeBox1 not defined; shouldn't happen!")
			return
		end
		table.insert(ColorMap.VolumeBoxes, VolumeBoxes[1])

		if VolumeBoxes[2] then
			table.insert(ColorMap.VolumeBoxes, VolumeBoxes[2])
			PixelCount += 1
		end

		Niters += 1
	end
end

local function Quantize(Pixels: {}, MaxColors: number, Outdepth: number?)
	-- short-circuit
	if #Pixels == 0 then
		error("[Quantize] Pixel array must have atleast 1 index")
	elseif MaxColors < 2 or MaxColors > 256 then
		error("[Quantize] MaxColors has to be in range 2..256")
	elseif Outdepth then
		if Outdepth ~= 1 or Outdepth ~= 2 or Outdepth ~= 4 or Outdepth ~= 8 then
			error("[Quantize] Outdepth does not equal 1, 2, 4, or 8")
		elseif MaxColors > 2 ^ Outdepth then
			error("[Quantize] MaxColors is greater than 2 ^ Outdepth")
		end
	end
	local NewPixels: { Pixel } = if typeof(Pixels[1]) == "table" then Pixels else table.clone(Pixels)

	-- array clone detection, as a clone wont be equal to the original
	if Pixels ~= NewPixels then
		for Index, Value in NewPixels do
			local NewPixel = GetOrCreatePixel(Value)

			if NewPixel[1] > 255 or NewPixel[1] < 0 then
				error(string.format(InvalidPixelAtIndexFormat, "Red", Index), 2)
			elseif NewPixel[2] > 255 or NewPixel[2] < 0 then
				error(string.format(InvalidPixelAtIndexFormat, "Green", Index), 2)
			elseif NewPixel[3] > 255 or NewPixel[3] < 0 then
				error(string.format(InvalidPixelAtIndexFormat, "Blue", Index), 2)
			end
			NewPixels[Index] = NewPixel
		end
	end

	-- XXX: check color content and convert to grayscale if insufficient
	-- histo (1-d array, giving the number of pixels in
	-- each quantized region of color space), or nil on error
	local Histo = table.create(HistoSize)

	for _, Pixel in NewPixels do
		local Index = GetColorIndex(
			bit32.rshift(Pixel[1], RShift),
			bit32.rshift(Pixel[2], RShift),
			bit32.rshift(Pixel[3], RShift)
		)
		Histo[Index] = (Histo[Index] or 0) + 1
	end

	-- XXX: generate the new colors from the histo and return
	if #Histo <= MaxColors then
		--[[
        -- Ported mostly from:
        -- https://github.com/DanBloomberg/leptonica/blob/e09c1f283aa5a896facc297b617775373519d450/src/colorquant2.c#L391
        local ColorAmount = 0

        for Index = 1, HistoSize do
            if Histo[Index] then
                ColorAmount += 1
            end
        end

        local Outdepth = Outdepth or if ColorAmount <= 2 then
		1
            elseif ColorAmount <= 4 then
                2
            elseif ColorAmount <= 16
                4
            else
                8
        local PixelsSize = bit32.lshift(1, Outdepth)
        local ColorMapPixels = table.create(PixelsSize)        

        for Index = 1, HistoSize do
            if Histo[Index] then
                local RedValue = bit32.lshift(bit32.rshift(Index, (2 * Sigbits)), RShift)
                local GreenValue = bit32.lshift(bit32.band(bit32.rshift(Index, Sigbits), Mask), RShift)
                local BlueValue = bit32.lshift(bit32.band(Index, Mask), RShift)
                
                if #ColorMapPixels + 1 > PixelsSize then
                    break
                else
                    local Pixel = table.create(3)
                    Pixel[1] = RedValue
                    Pixel[2] = GreenValue
                    Pixel[3] = BlueValue
                    ColorMapPixels[#ColorMapPixels + 1] = Pixel
                end

                Histo[Index] = Index + 1
            end
        end
        --]]
	end

	-- get the beginning vbox from the colors
	local VolumeBox = VolumeBoxFromPixels(NewPixels, Histo)
	local VolumeBoxes = table.create(1, VolumeBox)
	local ColorMap: ColorMap = setmetatable({
		VolumeBoxes = VolumeBoxes,
		__sorted = false,
	}, ColorMapPrototype) :: any

	-- first set of colors, sorted by population
	Iterate(FractByPopulations * MaxColors, ColorMap, Histo, CountSort)

	-- Re-sort by the product of pixel occupancy times the size in color space.
	-- deviation: rather than creating a whole new queue to basically
	-- reverse the queue, we just reverse the queue
	SortColorMap(ColorMap, CountSort)
	ReverseTable(VolumeBoxes)

	-- next set - generate the median cuts using the (npix * vol) sorting.
	Iterate(MaxColors, ColorMap, Histo, OccupancySizeSort)

	-- calculate the actual colors
	-- deviation: reversing again
	--[[ jsver:
	    var cmap = new CMap();
        while (pq2.size()) {
            cmap.push(pq2.pop());
        }
	--]]
	SortColorMap(ColorMap, OccupancySizeSort)
	ReverseTable(VolumeBoxes)
	return ColorMap
end

return Quantize :: ((Pixels: { Pixel }, MaxColors: number) -> ColorMap) & ((Color3s: { Color3 }, MaxColors: number) -> ColorMap)
