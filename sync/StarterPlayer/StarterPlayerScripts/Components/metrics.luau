--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)
local ring_buffer = require(StarterPlayer.StarterPlayerScripts.Utilities["ring-buffer"])

-- metrics.luau
-- wip

local module = {}

export type Metric =
	"frametime"
	| "fps"
	| "average_fps"
	| "low_1_percent_fps"
	| "low_01_percent_fps"
	| "CustomMetric"

export type CurrentMetrics = {
	frametime: number?,
	fps: number?,
	average_fps: number?,
	low_1_percent_fps: number?,
	low_01_percent_fps: number?,
	custom_metric: number?,
}

export type GraphConfig = {
	metric: Metric,
	max_value: number,
	history_size: number,
	line_thickness: number,
	line_color: Color3,
}

export type OptionalGraphConfig = {
	metric: Metric?,
	max_value: number?,
	history_size: number?,
	line_thickness: number?,
	line_color: Color3?,
}

export type LabelConfig = {
	metric: Metric,
	format: string,
}

export type OptionalLabelConfig = {
	metric: Metric?,
	format: string?,
}

export type Config = {
	frame_buffer_capacity: number,
	update_interval: number,
	screen_gui: ScreenGui,

	defaults: {
		graph: GraphConfig,
		label: LabelConfig,
	},

	graphs: { [string]: OptionalGraphConfig },
	labels: { [string]: OptionalLabelConfig },
}

export type ActiveElements = {
	graphs: {
		[string]: {
			history_buffer: ring_buffer.RingBuffer,
			ui_element: GuiObject,
			config: GraphConfig,
			segments: { Frame },
		},
	},
	labels: {
		[string]: {
			ui_element: TextLabel,
			config: LabelConfig,
		},
	},
}

local config = {
	frame_buffer_capacity = 240,
	update_interval = 0.2,
	screen_gui = nil,

	defaults = {
		graph = {
			metric = "CustomMetric",
			max_value = 100,
			history_size = 60,
			line_thickness = 2,
			line_color = Color3.fromRGB(255, 255, 255),
		},
		label = {
			metric = "CustomMetric",
			format = "%.0f",
		},
	},

	graphs = {
		FrametimeGraph = {
			metric = "Frametime",
			max_value = 30,
			history_size = 240,
			line_thickness = 1,
			line_color = Color3.fromRGB(228, 191, 192),
		},
	},

	labels = {
		-- to snake_case
		fps_value = { metric = "FPS" },
		average_fps_value = { metric = "AverageFPS" },
		low_1_percent_fps_value = { metric = "Low1PercentFPS" },
		low_01_percent_fps_value = { metric = "Low01PercentFPS" },
		frametime_value = {
			metric = "Frametime",
			format = "%.1f ms",
		},
	},
}

local frame_buffer = ring_buffer.new(config.frame_buffer_capacity)

local current_metrics = {} :: CurrentMetrics

local player = playerMarshaller.get()
local player_gui = player.PlayerGui

local total_delta_time = 0

local active_elements = {
	graphs = {},
	labels = {},
} :: ActiveElements

local conn = nil

local function drawLine(frame: Frame, x1: number, y1: number, x2: number, y2: number)
	local center = Vector2.new((x1 + x2) / 2, (y1 + y2) / 2)

	local direction = Vector2.new(x2 - x1, y2 - y1)
	local length = direction.Magnitude

	local arc_tanget = math.atan2(direction.Y, direction.X)
	local rotation_degrees = math.deg(arc_tanget)

	if rotation_degrees > 0 then
		rotation_degrees -= 180
	end

	frame.Size = UDim2.fromOffset(length, frame.Size.Y.Offset)
	frame.Position = UDim2.fromOffset(center.X, center.Y)
	frame.Rotation = rotation_degrees
end

local function updateGraph()
	for i, graph_data in pairs(active_elements.graphs) do
		local history_buffer = graph_data.history_buffer
		local ui_element = graph_data.ui_element
		local graph_config = graph_data.config
		local segments = graph_data.segments

		local history_size = graph_config.history_size
		local max_value = graph_config.max_value
		local metric = graph_config.metric

		history_buffer:Write(current_metrics[metric])

		local width_per_point = ui_element.AbsoluteSize.X / (history_size - 1)
		local container_height = ui_element.AbsoluteSize.Y

		local head = history_buffer.head
		local current_value = history_buffer.data[head]

		for j = 1, history_size - 1 do
			local current_segment = segments[j]

			head %= history_size + 1

			local next_value = history_buffer.data[head]

			if not next_value then
				break
			end

			local clipped_current_value = math.min(current_value, max_value)
			local clipped_next_value = math.min(next_value, max_value)

			current_value = next_value

			local x1 = math.round((j - 1) * width_per_point)
			local x2 = math.round(j * width_per_point)

			local y1 = math.round((1 - (clipped_current_value / max_value)) * container_height)
			local y2 = math.round((1 - (clipped_next_value / max_value)) * container_height)

			current_segment.Visible = true
			drawLine(current_segment, x1, y1, x2, y2)
		end
	end
end
