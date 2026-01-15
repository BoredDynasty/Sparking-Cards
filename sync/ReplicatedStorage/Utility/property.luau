--!nonstrict

-- property.luau

local property = {}

-- Get all available properties of an Instance
function property.getProperties(instance: Instance): { [string]: any }
	local properties = {}

	-- Get regular properties
	for _, member in ipairs(instance:GetDescendants()) do
		local success, value = pcall(function()
			return member.Name, member.Value
		end)

		if success then
			properties[member.Name] = value
		end
	end

	return properties
end

-- Get specific property value
function property.getProperty(instance: Instance, propertyName: string): any?
	local success, value = pcall(function()
		return instance[propertyName]
	end)

	return if success then value else nil
end

-- Get all attributes of an Instance
function property.getAttributes(instance: Instance): { [string]: any }
	local attributes = {}

	for _, attributeName in ipairs(instance:GetAttributes()) do
		attributes[attributeName] = instance:GetAttribute(attributeName)
	end

	return attributes
end

-- Get specific attribute value
function property.getAttribute(instance: Instance, attributeName: string): any?
	return instance:GetAttribute(attributeName)
end

-- Check if property exists
function property.hasProperty(instance: Instance, propertyName: string): boolean
	local success = pcall(function()
		return instance[propertyName]
	end)

	return success
end

return property
