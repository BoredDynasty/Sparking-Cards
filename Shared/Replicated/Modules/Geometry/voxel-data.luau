--!strict

-- voxel-data.luau
-- for converting voxel data into strings

local module = {}

local data_type_convert = {
	["Vector3"] = function(vec3: Vector3)
		return string.format(
			"Vector3.new(%0s, %1s, %2s)",
			tostring(vec3.X),
			tostring(vec3.Y),
			tostring(vec3.Z)
		)
	end,
	["EnumItem"] = function(enum)
		return enum.Name
	end,
	["number"] = function(int)
		return tostring(int)
	end,
}

local function convertTable(data: any)
	local tVal = "{\n"

	for i, v in ipairs(data) do
		local data_type = typeof(v)

		if data_type == "table" then
			tVal = tVal .. convertTable(v) .. ", " -- boom done
		elseif data_type_convert[data_type] then
			tVal = tVal .. data_type_convert[data_type](v) .. ", " -- boom done
		end
	end

	tVal = tVal .. "\n}"

	return tVal
end

function module.convert(t: { any })
	local stringT = ""

	for i, v in ipairs(Enum.Material:GetEnumItems()) do
		stringT = stringT .. string.format("local %s = %s\n", v.Name, tostring(v))
	end

	stringT = stringT .. "\nreturn {\n"

	for i, v in pairs(t) do
		local data_type = typeof(v)

		if data_type == "table" then
			stringT = stringT .. convertTable(v) .. ";\n"
		elseif data_type_convert[data_type] then
			stringT = stringT .. data_type_convert[data_type](v) .. ";\n" -- boom done
		end
	end

	stringT = stringT .. "\n}"

	return stringT
end

return module
