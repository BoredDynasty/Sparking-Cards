--!strict
local configuration = require(script.configuration)
local escapeforms = require(script.escapeforms)
local gradients = require(script.gradients)
local text_counter = require(script["text-counter"])
local typeformatter = require(script.typeformatter)
local typewriter = require(script.typewriter)

-- markdown.luau

local markdown = {
	typewriter = typewriter,
	text_counter = text_counter,
}
markdown.__index = markdown

export type markdown = {
	__index: markdown,
	New: (Text: string) -> self,
	Gradient: (Text: string, GradientNames: { string }, Dynamic: boolean) -> string,
	Get: (self: self) -> string,
	ChangeText: (self: self, Text: string) -> self,
	HasTag: (self: self, Tag: string) -> boolean,
	HasProperty: (self: self, Tag: string, Property: string) -> boolean,
	Add: (self: self, Tag: string, Properties: { [string]: any }?) -> self,
	RemoveTags: (self: self, Tags: { string }) -> self,
	RemoveProperties: (self: self, Tag: string, Properties: { string }) -> self,
	Destroy: (self: self) -> (),
}

type self = {
	str: string,
	tags: {
		[string]: { [string]: any },
	},
}

type markdownObject = setmetatable<self, typeof(markdown)>

function markdown._filter_text(str: string)
	local pattern = ""
	for char in pairs(escapeforms) do
		pattern ..= char
	end

	return string.sub(str, 1, configuration.max_chars):gsub(`[{pattern}]`, escapeforms)
end

function markdown.new(str: string): markdownObject
	return setmetatable({
		str = markdown._filter_text(str),
		tags = {},
	}, markdown)
end

--[[
   ```luau

   local result = markdown:Gradient("baller", 
      {
         "Rainbow", 
         "RainbowOutline"
      }, 
      false
   )

   local RunService = game:GetService("RunService")
   local label = path.to.label :: TextLabel

   -- this can be very performance heavy though
   -- watch out lil bro
   RunService.Heartbeat:Connect(function()
   	label.Text = markdown:Gradient("TEXT", {"Rainbow"}, true)
   end)
   
   ```
]]
function markdown:Gradient(str: string, gradient_names: { string }, dynamic: boolean?)
	str = string.sub(str, configuration.max_chars)

	local result = ""
	local length = string.len(str)

	dynamic = dynamic or false

	for i = 1, length do
		local char = string.sub(str, i, i)

		local singleton = markdown.new(char)

		for j, gradient_name in ipairs(gradient_names) do
			gradients[gradient_name](singleton, i, length, dynamic)
		end

		result ..= singleton:Get(singleton)
		singleton:Destroy(singleton)
	end

	return result
end

function markdown:Get(self: markdownObject)
	local result = self.str

	for tag, properties in pairs(self.tags) do
		local prop_str = ""
		for property, value in properties do
			local type_of = typeformatter[typeof(value)]

			prop_str = `{prop_str} {property}="{type_of and type_of(value) or tostring(value)}"`

			result = string.sub(tag, -1) == "/" and `{result}<{tag}>` or `<{tag}{prop_str}>{result}</{tag}>`
			-- for the line break tag. (br/)
		end
	end

	return result
end

function markdown:ChangeText(self: markdownObject, str: string)
	self.str = markdown._filter_text(str)

	return self
end

function markdown:HasTag(self: markdownObject, tag: string)
	return self.tags[tag] ~= nil
end

function markdown:HasProperty(self: markdownObject, tag: string, prop: string): boolean
	return self.tags[tag] and self.tags[tag][prop] ~= nil
end

--[[
   ```luau

   markdown:Add("font", {color = "rgb(255, 0, 0)"}) -- The <br/> tag is also supported.

   --

   -- Auto-converts to rgb(255, 0, 0)
   markdown:Add("font", {color = Color3.new(1, 0, 0)})

   -- Supports BrickColor and Enum too
   markdown:Add("font", {color = BrickColor.Red()})
   markdown:Add("font", {face = Enum.Font.FredokaOne})
   markdown:Add("font", {weight = Enum.FontWeight.Heavy})
   markdown:Add("stroke", {joins = Enum.LineJoinMode.Miter})
   ```
]]
function markdown:Add(self: markdownObject, tag: string, props: { [string]: any }?)
	props = props or {}

	if not self.tags[tag] then
		self.tags[tag] = props
	else
		for prop, value in props do
			self.tags[tag][prop] = value
		end
	end

	return self
end

function markdown:RemoveTags(self: markdownObject, tags: { string })
	for i, tag in tags do
		if self.tags[tag] then
			self.tags[tag] = nil
		end
	end

	return self
end

function markdown:RemoveProperties(self: markdownObject, tag: string, properties: { string })
	if self.tags[tag] then
		for i, prop in properties do
			self.tags[tag][prop] = nil
		end
	end

	return self
end

function markdown:Destroy(self: markdownObject)
	table.clear(self)
	setmetatable(self, nil)
end

return markdown
