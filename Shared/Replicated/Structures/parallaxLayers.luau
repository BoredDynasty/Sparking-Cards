--!strict

-- parallaxLayers.luau

export type layer = {
	depthFactor: number,
	image: number,
}

export type self = {
	[string]: { layer },
}

return {
	Desert = {
		{
			depthFactor = 0.1,
			image = 85771976849760,
		},
		{
			depthFactor = 0.1,
			image = 86638818057918,
		},
		{
			depthFactor = 0.2,
			image = 78239140076204,
		},
		{
			depthFactor = 0.1,
			image = 101920658030720,
		},
		{
			depthFactor = 0.3,
			image = 95824378535326,
		},
		{
			depthFactor = 0.5,
			image = 96472199892347,
		},
		{
			depthFactor = 0.6,
			image = 107187586621751,
		},
		{
			depthFactor = 0.7,
			image = 102459277311926,
		},
		{
			depthFactor = 0.9,
			image = 107961319305129,
		},
	},
}
