--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local trove = require(ReplicatedStorage.Packages.trove)
local url = require(ReplicatedStorage.Modules.Serialization.url)

-- star.luau

local star_module = {
	-- constants
	north = vector.create(0, 0, -1),
	east = vector.create(1, 0, 0),
	normal_down = vector.create(0, -1, 0),

	_trove = trove.new(),
}

function star_module._computeGMST(j: number)
	-- calculate JDUO (previous midnight UT1
	local jd0 = math.floor(j - 0.5) + 0.5

	-- hours since JD0
	local H = (j - jd0) * 24

	-- days since J2000.0 for JD0 and JDUT
	local DUT = jd0 - 2451545.0
	local DTT = j - 2451545.0

	-- centuries since J2000.0
	local T = DTT / 36525
	local T2 = T * T

	-- compute GMST in hours modulo 24
	local GMST_hours = (6.697375 + 0.065709824279 * DUT + 1.0027379 * H + 0.0000258 * T2) % 24

	-- convert decimal hours to hours, minutes, seconds
	local hours = math.floor(GMST_hours)
	local remainder = (GMST_hours - hours) * 60
	local minutes = math.floor(remainder)
	local seconds = (remainder - minutes) * 60

	return hours, minutes, seconds
end

--[[
   Calculates LST from Julian Date Number and Longitude
   Outputs: LST as hours decimal (float)
]]
function star_module._calculate_LST(j: number, longitude: number)
	-- takes in UTC
	local h, m, s = star_module._computeGMST(j)

	local gmst_hours = h + m / 60 + s / 3600

	local lst_hours = gmst_hours + longitude / 15

	return lst_hours
end

function star_module._spectralClassToColor(spectral: string)
	local main_class = string.match(spectral, "^([OBAFGKM])") or "G"
	local sub_class = tonumber(string.match(spectral, "%d+")) or 0

	local max = 9

	sub_class = math.clamp(sub_class, 0, max)

	local color_bands = {
		O = { Color3.fromRGB(155, 176, 255), Color3.fromRGB(167, 193, 255) },
		B = { Color3.fromRGB(167, 193, 255), Color3.fromRGB(202, 215, 255) },
		A = { Color3.fromRGB(202, 215, 255), Color3.fromRGB(248, 247, 255) },
		F = { Color3.fromRGB(248, 247, 255), Color3.fromRGB(255, 245, 236) },
		G = { Color3.fromRGB(255, 245, 236), Color3.fromRGB(255, 210, 161) },
		K = { Color3.fromRGB(255, 210, 161), Color3.fromRGB(255, 164, 111) },
		M = { Color3.fromRGB(255, 164, 111), Color3.fromRGB(255, 123, 70) },
	}

	local band = color_bands[main_class] or color_bands.G :: { [number]: Color3 }
	local start_color: Color3, end_color = band[1], band[2] :: Color3

	local t = sub_class / max

	return Color3.new(
		start_color.R + (end_color.R - start_color.R) * t,
		start_color.G + (end_color.G - start_color.G) * t,
		start_color.B + (end_color.B - start_color.B) * t
	)
end

function star_module._createInterface(): BillboardGui & {
	ImageLabel: ImageLabel,
}
	-- Instances:

	local BillboardGui = Instance.new("BillboardGui")
	local ImageLabel = Instance.new("ImageLabel")

	--Properties:

	BillboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	BillboardGui.Active = true
	BillboardGui.Size = UDim2.new(0, 25, 0, 25)

	ImageLabel.Parent = BillboardGui
	ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ImageLabel.BackgroundTransparency = 1.000
	ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ImageLabel.BorderSizePixel = 0
	ImageLabel.Size = UDim2.new(1, 0, 1, 0)
	ImageLabel.Image = "rbxassetid://114270892537134"

	return BillboardGui
end

--[[
   Create Stars given RA in deg, deg, apparent magnitude, spectral class and parent

   @param radii: `number`
   @param degrees: `number`
   @param magnitude: `number`
   @param spectal: `string`
   @param ancestor: `Instance`
]]
function star_module.createStar(
	radii: number,
	degrees: number,
	magnitude: number,
	spectral: string,
	ancestor: Instance
)
	local init = star_module.east * math.cos(math.rad(radii))
		+ star_module.normal_down * math.sin(math.rad(radii))

	init *= math.cos(math.rad(degrees)) + star_module.north * math.sin(math.rad(degrees))

	local attachment = star_module._trove:Construct(Instance, "Attachment", ancestor) :: Attachment

	local layer_collector = star_module._createInterface()

	layer_collector.Size = UDim2.fromScale(
		12 * math.clamp(4.58 - magnitude, 0.1, math.huge),
		12 * math.clamp(4.58 - magnitude, 0.1, math.huge)
	)

	layer_collector.Parent = ancestor
	layer_collector.ImageLabel.ImageColor3 = star_module._spectralClassToColor(spectral)

	attachment.WorldPosition = Vector3.zero + init * 2000
	attachment.Name = url.generateShortUniqueId() .. "_star_attachment"
end

--[[
   Turns HH:MM:SS into degrees.

   @return number
]]
function star_module._HMS_to_degrees<N>(h: number, m: number, s: number): N
	local sign = 1
	if 1 / h ~= 1 / math.abs(h) then
		sign = -1
	end

	return sign * 360 * (math.abs(h) + m / 60 + s / 3600) / 24
end

--[[
   Turns Degree Arcmin Arcsec into degrees.
   @return number
]]
function star_module._DAADEG(d: number, am: number, as: number)
	local sign = 1

	if 1 / d ~= 1 / math.abs(d) then
		sign = -1
	end

	return (math.abs(d) + am / 60 + as / 3600) * sign
end

function star_module._formatHMSS(str: string)
	return tonumber(string.split(string.gsub(str, "(%a+)", " "), " ")[1]),
		tonumber(string.split(string.gsub(str, "(%a+)", " "), " ")[2]),
		tonumber(string.match(str, "%d+%p%d+"))
end
function star_module._formatDAA(str: string)
	return tonumber(string.split(string.gsub(str, "(%a+)", " "), " ")[1]),
		tonumber(string.split(string.gsub(str, "(%a+)", " "), " ")[2]),
		tonumber(string.match(str, "%d+%p%d+"))
end

--[[
   Load rotation from latitude, rotation degree onto object
]]
function star_module._load_rotation(latitude, degrees, object: BasePart)
	local position = object.Position

	local pole = star_module.normal_down * math.cos(math.rad(latitude))
		- star_module.normal_down * math.sin(math.rad(latitude))
	local latitude_rotation = CFrame.fromAxisAngle(star_module.east, math.rad(latitude))
	local degrees_rotation = CFrame.fromAxisAngle(pole, -math.rad(degrees))

	local targetCoordinate = CFrame.new(position) * degrees_rotation * latitude_rotation

	object:PivotTo(targetCoordinate)
end

--[[
   Loads a database array into stars
]]

function star_module.load_array(array: {}, ancestor)
	for i, value in ipairs(array) do
		local h: number, m: number, s: number? = star_module._formatHMSS(value.RA)

		local radii = star_module._HMS_to_degrees(h, m, s)
		local deg = star_module._DAADEG(star_module._formatDAA(value.DEC))
		local magnitude = value.APPMAG
		local spec = value.SPEC

		star_module.createStar(radii, deg, magnitude, spec, ancestor)
	end
end

return star_module
