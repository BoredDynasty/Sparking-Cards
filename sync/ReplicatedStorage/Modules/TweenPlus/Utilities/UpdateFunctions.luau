-- Value functions.
local valueFunctions = require(script.Parent.ValueFunctions)

local normalValueFunctions = valueFunctions.Normal
local advancedValueFunctions = valueFunctions.Advanced

-- Return update functions function.
return function(apiMap, instance, values)
	local updateFunctions, resetFunctions = {}, {}
	
	local classProperties = apiMap[instance.ClassName]
	if not classProperties then error("Could not identify class.", 3) end

	for valueName, valueDestination in values do
		if type(valueName) ~= "string" then error("Invalid value name of type '"..typeof(valueName).."' instead of string.", 3) end
		
		if valueName:sub(1, 1) == "@" then
			-- Attribute.
			local attributeName = valueName:sub(2)
			
			local original = instance:GetAttribute(attributeName)
			if original == nil then error("'"..attributeName.."' is not a valid attribute of '"..instance:GetFullName().."'.", 3) end
			
			local value = normalValueFunctions[typeof(valueDestination)]
			if not value then error("'"..typeof(valueDestination).."'' data type is not supported.", 3) end
			value = value(original, valueDestination)
			
			table.insert(updateFunctions, function(alpha)
				instance:SetAttribute(attributeName, value(alpha))
			end)
			table.insert(resetFunctions, function()
				instance:SetAttribute(attributeName, original)
			end)
		else
			-- Not attribute.
			local value = advancedValueFunctions[valueName]
			if value then
				-- Advanced type.
				if not instance:IsA(value.Target) then error("'"..instance:GetFullName().."'' doesn't support '"..valueName.."'.", 3) end
				
				local original = value.Get(instance)
				local set = value.Set()
				table.insert(updateFunctions, function(alpha)
					set(instance, original, valueDestination, alpha)
				end)
				table.insert(resetFunctions, function()
					set(instance, original, valueDestination, 0)
				end)
			else
				-- Property.
				local propertyType = classProperties[valueName].Type
				if not propertyType then error("'"..valueName.."' is not a valid property of '"..instance:GetFullName().."'.", 3) end
				
				local valueType = typeof(valueDestination)
				if valueType ~= propertyType then error("'"..valueName.."' is not of correct type '"..propertyType.."'.", 3) end
				
				value = normalValueFunctions[valueType]
				if not value then error("'"..typeof(valueDestination).."' data type is not supported.", 3) end
				
				local original = instance[valueName]
				value = value(original, valueDestination)
				
				table.insert(updateFunctions, function(alpha)
					instance[valueName] = value(alpha)
				end)
				table.insert(resetFunctions, function()
					instance[valueName] = original
				end)
			end
		end
	end
	
	-- Return update functions.
	return updateFunctions, resetFunctions
end