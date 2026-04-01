--!strict
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- typewriter.luau
-- RichText-safe typewriter controller with backwards compatibility.

type TextObject = TextLabel | TextButton | TextBox

export type Options = {
	cps: number?,
	punctuationPauses: { [string]: number }?,
	punctuation_pauses: { [string]: number }?,
	instantFinishKey: Enum.KeyCode?,
	instant_finish_key: Enum.KeyCode?,
	cursor: string?,
	cursorTween: boolean?,
	cursor_tween: boolean?,
	perCharSound: Sound?,
	per_char_sound: Sound?,
	respectNewlines: boolean?,
	respect_newlines: boolean?,
}

export type Token = {
	kind: "tag" | "text",
	raw: string,
	name: string?,
	closing: boolean?,
	self_closing: boolean?,
}

type NormalizedOptions = {
	cps: number,
	punctuation_pauses: { [string]: number },
	instant_finish_key: Enum.KeyCode?,
	cursor: string?,
	cursor_tween: boolean,
	per_char_sound: Sound?,
	respect_newlines: boolean,
}

local module = {}
module.__index = module

type TypewriterState = {
	_label: TextObject?,
	_default_options: Options?,
	_playing: boolean,
	_skip_requested: boolean,
	_session_id: number,
	_input_connection: RBXScriptConnection?,
	_destroyed: boolean,
}

export type Controller = setmetatable<TypewriterState, typeof(module)>

local ELLIPSIS = utf8.char(0x2026)
local DEFAULT_CPS = 30
local BLINK_SPEED = 1.8
local TAG_PATTERN = "<(/?)([%w:]+)(.-)(/?)>"

local DEFAULT_PUNCTUATION_PAUSES = {
	["."] = 0.25,
	[","] = 0.09,
	["!"] = 0.18,
	["?"] = 0.18,
	[":"] = 0.14,
	[";"] = 0.14,
	[ELLIPSIS] = 0.25,
} :: { [string]: number }

local function is_text_object(instance: any): boolean
	if typeof(instance) ~= "Instance" then
		return false
	end

	local object = instance :: Instance
	return object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")
end

local function pick_option<T>(new_value: T?, old_value: T?, default_value: T): T
	if new_value ~= nil then
		return new_value
	end

	if old_value ~= nil then
		return old_value
	end

	return default_value
end

local function read_alias<T>(options: Options?, snake_case_key: string, camel_case_key: string): T?
	if options == nil then
		return nil
	end

	local options_any = options :: any
	local snake_value = options_any[snake_case_key]
	if snake_value ~= nil then
		return snake_value :: T
	end

	local camel_value = options_any[camel_case_key]
	if camel_value ~= nil then
		return camel_value :: T
	end

	return nil
end

local function normalize_options(default_options: Options?, override_options: Options?): NormalizedOptions
	local cps = pick_option(
		override_options and override_options.cps,
		default_options and default_options.cps,
		DEFAULT_CPS
	)
	local punctuation_pauses = (
		read_alias(override_options, "punctuation_pauses", "punctuationPauses") :: { [string]: number }?
	)
		or read_alias(default_options, "punctuation_pauses", "punctuationPauses") :: { [string]: number }?
	local instant_finish_key = (
		read_alias(override_options, "instant_finish_key", "instantFinishKey") :: Enum.KeyCode?
	) or read_alias(default_options, "instant_finish_key", "instantFinishKey") :: Enum.KeyCode?
	local cursor = pick_option(
		override_options and override_options.cursor,
		default_options and default_options.cursor,
		nil :: any
	)
	local cursor_tween = (read_alias(override_options, "cursor_tween", "cursorTween") :: boolean?)
		or read_alias(default_options, "cursor_tween", "cursorTween") :: boolean?
	local per_char_sound = (read_alias(override_options, "per_char_sound", "perCharSound") :: Sound?)
		or read_alias(default_options, "per_char_sound", "perCharSound") :: Sound?
	local respect_newlines = (read_alias(override_options, "respect_newlines", "respectNewlines") :: boolean?)
		or read_alias(default_options, "respect_newlines", "respectNewlines") :: boolean?

	return {
		cps = math.max(cps, 1),
		punctuation_pauses = punctuation_pauses and table.clone(punctuation_pauses)
			or table.clone(DEFAULT_PUNCTUATION_PAUSES),
		instant_finish_key = instant_finish_key,
		cursor = cursor,
		cursor_tween = cursor_tween == true,
		per_char_sound = per_char_sound,
		respect_newlines = respect_newlines ~= false,
	}
end

local function utf8_length(input_text: string): number
	local length = utf8.len(input_text)
	if length then
		return length
	end

	return #input_text
end

local function utf8_slice(input_text: string, start_index: number, end_index: number): string
	if end_index < start_index then
		return ""
	end

	local start_offset = utf8.offset(input_text, start_index)
	if start_offset == nil then
		return string.sub(input_text, start_index, end_index)
	end

	local next_offset = utf8.offset(input_text, end_index + 1)
	local end_offset = next_offset and (next_offset - 1) or #input_text
	return string.sub(input_text, start_offset, end_offset)
end

local function text_to_characters(input_text: string): { string }
	local characters = {}
	if utf8.len(input_text) == nil then
		for index = 1, #input_text do
			table.insert(characters, string.sub(input_text, index, index))
		end

		return characters
	end

	for _, codepoint in utf8.codes(input_text) do
		table.insert(characters, utf8.char(codepoint))
	end

	return characters
end

local function tokenize(input_text: string): { Token }
	local tokens = {} :: { Token }
	local last_index = 1

	for raw_start, slash_1, tag_name, _attrs, slash_2, raw_end in
		string.gmatch(input_text, "()" .. TAG_PATTERN .. "()")
	do
		local tag_start = tonumber(raw_start) :: number
		local tag_end = tonumber(raw_end) :: number

		if tag_start > last_index then
			local text_chunk = string.sub(input_text, last_index, tag_start - 1)
			if text_chunk ~= "" then
				table.insert(tokens, { kind = "text", raw = text_chunk })
			end
		end

		local raw_tag = string.sub(input_text, tag_start, tag_end - 1)
		local self_closing = slash_2 == "/" or string.match(raw_tag, "/%s*>$") ~= nil

		table.insert(tokens, {
			kind = "tag",
			raw = raw_tag,
			name = string.lower(tag_name),
			closing = slash_1 == "/",
			self_closing = self_closing,
		})

		last_index = tag_end
	end

	if last_index <= #input_text then
		local trailing = string.sub(input_text, last_index)
		if trailing ~= "" then
			table.insert(tokens, { kind = "text", raw = trailing })
		end
	end

	return tokens
end

local function collect_visible_characters(tokens: { Token }): { string }
	local characters = {} :: { string }

	for _, token in ipairs(tokens) do
		if token.kind ~= "text" then
			continue
		end

		for _, character in ipairs(text_to_characters(token.raw)) do
			table.insert(characters, character)
		end
	end

	return characters
end

local function build_visible(
	tokens: { Token },
	visible_chars: number,
	cursor: string?,
	cursor_blink: boolean,
	blink_phase: number
): string
	local open_tags = {} :: { string }
	local output = table.create(#tokens * 2)
	local remaining = visible_chars

	local function push_open(tag_name: string)
		table.insert(open_tags, tag_name)
	end

	local function pop_open(tag_name: string)
		for index = #open_tags, 1, -1 do
			if open_tags[index] == tag_name then
				table.remove(open_tags, index)
				break
			end
		end
	end

	for _, token in ipairs(tokens) do
		if token.kind == "tag" then
			table.insert(output, token.raw)

			local tag_name = token.name
			if tag_name == nil or token.self_closing then
				continue
			end

			if token.closing then
				pop_open(tag_name)
			else
				push_open(tag_name)
			end

			continue
		end

		if remaining <= 0 then
			break
		end

		local text_length = utf8_length(token.raw)
		if text_length <= remaining then
			table.insert(output, token.raw)
			remaining -= text_length
			continue
		end

		table.insert(output, utf8_slice(token.raw, 1, remaining))
		remaining = 0
		break
	end

	for index = #open_tags, 1, -1 do
		table.insert(output, string.format("</%s>", open_tags[index]))
	end

	if cursor and cursor ~= "" then
		local show_cursor = not cursor_blink or blink_phase < 0.5
		if show_cursor then
			table.insert(output, cursor)
		end
	end

	return table.concat(output)
end

local function disconnect_input(self: Controller)
	local connection = self._input_connection
	if connection == nil then
		return
	end

	connection:Disconnect()
	self._input_connection = nil
end

local function prepare_text(full_text: string, respect_newlines: boolean): (string, number?)
	if respect_newlines then
		return full_text, nil
	end

	return string.gsub(full_text, "\n", "<br/>")
end

--[[
	```luau
	local typewriter = require(path.to.typewriter)

	local controller = typewriter.new(label, {
		cps = 45,
		cursor = "|",
		cursor_tween = true,
	})

	controller:Start("Hello, <b>traveler</b>!")
	```
]]
function module.new(label: TextObject?, default_options: Options?): Controller
	if label ~= nil then
		assert(is_text_object(label), "Typewriter.new: label must be a TextLabel, TextButton, or TextBox")
	end

	local self = setmetatable({
		_label = label,
		_default_options = default_options,
		_playing = false,
		_skip_requested = false,
		_session_id = 0,
		_input_connection = nil,
		_destroyed = false,
	}, module) :: any

	return self
end

function module.Bind(self: Controller, label: TextObject): Controller
	assert(is_text_object(label), "Typewriter: label must be a TextLabel, TextButton, or TextBox")
	self._label = label
	return self
end

function module.SetDefaults(self: Controller, default_options: Options?): Controller
	self._default_options = default_options
	return self
end

function module.IsPlaying(self: Controller): boolean
	return self._playing
end

function module.Skip(self: Controller)
	self._skip_requested = true
end

--[[
	```luau
	controller:Start("Hello world", { cps = 36 })
	```
]]
function module.Start(self: Controller, full_text: string, options: Options?): thread?
	assert(not self._destroyed, "Typewriter: this controller was destroyed")

	local label = self._label
	assert(label ~= nil, "Typewriter: no label bound. Use typewriter.new(label) or controller:Bind(label)")
	assert(is_text_object(label), "Typewriter: label must be a TextLabel, TextButton, or TextBox")

	self._session_id += 1
	local session_id = self._session_id
	self._playing = true
	self._skip_requested = false

	disconnect_input(self)

	local resolved = normalize_options(self._default_options, options)
	local prepared_text = prepare_text(full_text, resolved.respect_newlines)
	local tokens = tokenize(prepared_text)
	local visible_characters = collect_visible_characters(tokens)
	local total_visible = #visible_characters

	local instant_finish_key = resolved.instant_finish_key
	if instant_finish_key then
		self._input_connection = UserInputService.InputBegan:Connect(
			function(input_object: InputObject, processed: boolean)
				if processed or self._session_id ~= session_id then
					return
				end

				if input_object.KeyCode == instant_finish_key then
					self._skip_requested = true
				end
			end
		)
	end

	label.RichText = true
	label.Text = ""

	return task.spawn(function()
		local printed_chars = 0
		local blink_phase = 0
		local previous_tick = os.clock()
		local next_emit_at = previous_tick
		local step_duration = 1 / resolved.cps
		local has_cursor = resolved.cursor ~= nil and resolved.cursor ~= ""

		while self._playing and self._session_id == session_id and printed_chars < total_visible do
			if self._skip_requested then
				printed_chars = total_visible
				break
			end

			if label.Parent == nil then
				break
			end

			local now = os.clock()
			local delta_time = now - previous_tick
			previous_tick = now
			blink_phase = (blink_phase + (delta_time * BLINK_SPEED)) % 1

			local should_emit = printed_chars < total_visible and now >= next_emit_at
			if should_emit then
				printed_chars += 1
				label.Text =
					build_visible(tokens, printed_chars, resolved.cursor, resolved.cursor_tween, blink_phase)

				local per_char_sound = resolved.per_char_sound
				if per_char_sound then
					per_char_sound.TimePosition = 0
					per_char_sound:Play()
				end

				local current_character = visible_characters[printed_chars]
				local punctuation_pause = current_character and resolved.punctuation_pauses[current_character]
					or 0
				next_emit_at = now + step_duration + punctuation_pause
			elseif has_cursor then
				label.Text =
					build_visible(tokens, printed_chars, resolved.cursor, resolved.cursor_tween, blink_phase)
			end

			RunService.Heartbeat:Wait()
		end

		if self._session_id ~= session_id then
			return
		end

		if label.Parent ~= nil then
			label.Text = build_visible(tokens, total_visible, nil, false, 0)
		end

		self._playing = false
		self._skip_requested = false
		disconnect_input(self)
	end)
end

--[[
	Backwards-compatible call signature:
	controller:Play(label, text, options)
]]
function module.Play(self: Controller, label: TextObject, full_text: string, options: Options?): thread?
	self:Bind(label)
	return self:Start(full_text, options)
end

--[[
	One-shot helper:
	```luau
	typewriter.play(label, "Hello there!", { cps = 40 })
	```
]]
function module.play(label: TextObject, full_text: string, options: Options?): Controller
	local controller = module.new(label)
	controller:Start(full_text, options)
	return controller
end

function module.Destroy(self: Controller)
	if self._destroyed then
		return
	end

	self._destroyed = true
	self._skip_requested = true
	self._playing = false
	self._session_id += 1

	disconnect_input(self)
	self._label = nil
	self._default_options = nil

	setmetatable(self, nil)
end

return module
