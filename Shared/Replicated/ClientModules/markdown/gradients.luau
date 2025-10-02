--!strict

local configuration = require(script.Parent.configuration)

-- gradients.luau

return {

	Rainbow = function(object: any, text_position: number, text_length: number, dynamic: boolean): ()
		object:Add("font", {
			color = Color3.fromHSV(
				dynamic and ((tick() * configuration.speed) - (text_position / text_length)) % 1
					or text_position / text_length,
				1,
				1
			),
		})
	end,

	RainbowOutline = function(object: any, text_position: number, text_length: number, dynamic: boolean): ()
		object:Add("stroke", {
			color = Color3.fromHSV(
				dynamic and ((tick() * configuration.speed) - (text_position / text_length)) % 1
					or text_position / text_length,
				1,
				0.5
			),
			thickness = configuration.outline_thickness,
		})
	end,

	Ghost = function(object: any, text_position: number, text_length: number, dynamic: boolean): ()
		object:Add("font", {
			transparency = math.floor(
				(dynamic and 2.5 + math.sin((tick() * configuration.speed) * 5) or 2.5)
					* (text_position / text_length - 0.5) ^ 2
					* 100
			) / 100,
			color = Color3.new(0.4, 0.4, 0.4),
		})
	end,

	GhostOutline = function(object: any, text_position: number, text_length: number, dynamic: boolean): ()
		object:Add("stroke", {
			transparency = math.floor(
				(dynamic and 2.5 + math.sin((tick() * configuration.speed) * 5) or 2.5)
					* (text_position / text_length - 0.5) ^ 2
					* 100
			) / 100,
			thickness = configuration.outline_thickness,
		})
	end,

	Fire = function(object: any, text_position: number, text_length: number, dynamic: boolean): ()
		object:Add("font", {
			color = Color3.new(1, 0, 0):Lerp(
				Color3.new(1, 1, 0),
				dynamic and ((tick() * configuration.speed) - (text_position / text_length)) % 1
					or text_position / text_length
			),
		})
	end,

	FireOutline = function(object: any, text_position: number, text_length: number, dynamic: boolean): ()
		object:Add("stroke", {
			color = Color3.new(0.6, 0, 0):Lerp(
				Color3.new(0.6, 0.6, 0),
				dynamic and ((tick() * configuration.speed) - (text_position / text_length)) % 1
					or text_position / text_length
			),
			thickness = configuration.outline_thickness,
		})
	end,

	Sunset = function(object: any, text_position: number, text_length: number, dynamic: boolean): ()
		object:Add("font", {
			color = Color3.new(1, 0.5, 0):Lerp(
				Color3.new(0.5, 0, 1),
				dynamic and ((tick() * configuration.speed) - (text_position / text_length)) % 1
					or text_position / text_length
			),
		})
	end,

	SunsetOutline = function(object: any, text_position: number, text_length: number, dynamic: boolean): ()
		object:Add("stroke", {
			color = Color3.new(1, 0.3, 0):Lerp(
				Color3.new(0.3, 0, 1),
				dynamic and ((tick() * configuration.speed) - (text_position / text_length)) % 1
					or text_position / text_length
			),
			thickness = configuration.outline_thickness,
		})
	end,
} :: {
	[string]: (object: any, text_position: number?, text_length: number, dynamic: boolean) -> (),
}
