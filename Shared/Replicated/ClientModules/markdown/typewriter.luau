--!strict

-- typewriter.luau
-- we used chatgpt for this one
-- however, I fixed some formatting mistakes tho.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local promise = require(ReplicatedStorage.Packages.promise)

export type Options = {
	cps: number?, -- characters per second (visible chars)
	punctuationPauses: { [string]: number }?, -- extra pause (seconds) after a char
	instantFinishKey: Enum.KeyCode?, -- press to instantly finish the line
	cursor: string?, -- e.g. "|" or "_" (added at end while typing)
	cursorTween: boolean?, -- subtle blink for cursor
	perCharSound: Sound?, -- optional Sound object to :Play() for each printed char
	respectNewlines: boolean?, -- if false, converts "\n" to "<br/>"
}

local DEFAULT_PAUSES = {
	["."] = 0.25,
	[","] = 0.09,
	["!"] = 0.18,
	["?"] = 0.18,
	[":"] = 0.14,
	[";"] = 0.14,
	["…"] = 0.25,
}

local Typewriter = {}
Typewriter.__index = Typewriter

-- UTF-8 helpers
local function utf8len(s: string): number
	local ok, count = pcall(function()
		local c = 0
		for _ in string.gmatch(s, "[%z\1-\127\194-\244][\128-\191]*") do
			c += 1
		end
		return c
	end)
	return ok and count or #s
end

local function utf8sub(s: string, i: number, j: number?): string
	j = j or i
	local t = {}
	local idx = 0
	for ch in string.gmatch(s, "[%z\1-\127\194-\244][\128-\191]*") do
		idx += 1
		if idx >= i and idx <= j then
			table.insert(t, ch)
		end
		if idx > j then
			break
		end
	end
	return table.concat(t)
end

-- RichText tokenizer: splits into tag tokens and text tokens
export type Token = {
	kind: "tag" | "text",
	raw: string,
	name: string?,
	closing: boolean?,
	selfClosing: boolean?,
}

local TAG_PATTERN = "<(/?)([%w:]+)(.-)(/?)>" -- captures /, name, attrs, trailing /

local function tokenize(input: string): { Token }
	local tokens: { Token } = {}
	local last = 1
	for s, e, slash1, name, attrs, slash2 in input:gmatch("()" .. TAG_PATTERN .. "()") do
		-- text chunk before the tag
		if s > last then
			local chunk = string.sub(input, last, s - 1)
			if chunk ~= "" then
				table.insert(tokens, { kind = "text", raw = chunk })
			end
		end
		local raw = string.sub(input, s, e - 1)
		local closing = (slash1 == "/")
		local selfClosing = (slash2 == "/") or string.find(raw, "/>%s*$") ~= nil
		table.insert(
			tokens,
			{ kind = "tag", raw = raw, name = name:lower(), closing = closing, selfClosing = selfClosing }
		)
		last = e
	end
	-- trailing text
	if last <= #input then
		local chunk = string.sub(input, last)
		if chunk ~= "" then
			table.insert(tokens, { kind = "text", raw = chunk })
		end
	end
	return tokens
end

-- Build visible string up to N visible characters, keeping tags balanced
local function buildVisible(
	tokens: { Token },
	visibleChars: number,
	respectNewlines: boolean,
	cursor: string?,
	cursorBlink: boolean,
	blinkPhase: number
): (string, number)
	local openStack = {} :: { Token }

	local remaining = visibleChars

	local out = table.create(#tokens * 2)

	local printed = 0

	local function pushOpen(tag: Token)
		table.insert(openStack, tag)
	end

	local function popOpen(name: string)
		for i = #openStack, 1, -1 do
			if openStack[i].name == name then
				table.remove(openStack, i)

				break
			end
		end
	end

	for _, t in ipairs(tokens) do
		if t.kind == "tag" then
			-- Normalize certain tags
			if respectNewlines == false and (t.name == "br" and t.selfClosing) then
				-- keep as is
			end

			table.insert(out, t.raw)

			if not t.selfClosing then
				if t.closing then
					popOpen(t.name)
				else
					pushOpen(t)
				end
			end
		elseif t.kind == "text" then
			local text = t.raw

			if respectNewlines == false then
				text = text:gsub("\n", "<br/>")
			end

			local tlen = utf8len(text)

			if tlen <= remaining then
				table.insert(out, text)
				remaining -= tlen
				printed += tlen
			else
				if remaining > 0 then
					local slice = utf8sub(text, 1, remaining)

					table.insert(out, slice)

					printed += remaining
					remaining = 0
				end
				break
			end
		end
	end
	-- Close any open tags to keep TextLabel parser happy :))
	for i = #openStack, 1, -1 do
		local name = openStack[i].name
		table.insert(out, string.format("</%s>", name))
	end

	-- Optional cursor
	if cursor and cursor ~= "" then
		local showCursor = true

		if cursorBlink then
			-- blinkPhase in [0,1), hide for half the cycle

			showCursor = blinkPhase < 0.5
		end
		if showCursor then
			table.insert(out, cursor)
		end
	end

	return table.concat(out), printed
end

-- Public API
export type Controller = {
	Play: (
		self: Controller,
		label: TextLabel | TextBox | TextButton,
		fullText: string,
		options: Options?
	) -> nil,
	Skip: (self: Controller) -> nil,
	IsPlaying: (self: Controller) -> boolean,
}

--[[
   ```luau

   local Typewriter = require(script.Parent.Typewriter)
   local controller = Typewriter.new()

   local label: TextLabel = script.Parent:WaitForChild("Dialogue")
   label.RichText = true
   label.TextWrapped = true
   label.Text = "" -- start empty

   local fancy = [[
   Hello, <b>traveler</b>!\n
   <i>Welcome</i> to the <font color="#ffd166">Golden City</font>.
   Behold the <u>wonders</u> of the <stroke thickness="2" color="#000000">Old World</stroke>…
   <font size="28">Ready?</font>]]
--[[

controller:Play(label, fancy, {
   cps = 45,
   instantFinishKey = Enum.KeyCode.Space,
   cursor = "|",
   cursorTween = true,
   perCharSound = script:FindFirstChild("Tick") :: Sound?,
	respectNewlines = false, -- converts \n to <br/>
   punctuationPauses = {
	[","] = 0.06, ["."] = 0.25, ["?"] = 0.18, ["!"] = 0.18,
	}
})

-- To skip mid-type from code: controller:Skip()

]]
function Typewriter.new(): Controller
	local self = setmetatable({}, Typewriter) :: any

	self._playing = false
	self._skipRequested = false

	return self
end

function Typewriter:IsPlaying()
	return self._playing
end

function Typewriter:Skip()
	self._skipRequested = true
end

--[[
   ```luau

      controller:Play(label, fancy, {
      cps = 45,
      instantFinishKey = Enum.KeyCode.Space,
      cursor = "|",
      cursorTween = true,
      perCharSound = script:FindFirstChild("Tick") :: Sound?,
	   respectNewlines = false, -- converts \n to <br/>
      punctuationPauses = {
	   [","] = 0.06, ["."] = 0.25, ["?"] = 0.18, ["!"] = 0.18,
	   }
   })
]]
function Typewriter:Play(label: TextLabel | TextBox | TextButton, fullText: string, options: Options?)
	assert(
		label and label:IsA("TextLabel") or label:IsA("TextBox") or label:IsA("TextButton"),
		"Typewriter: label must be a UI text object"
	)

	label.RichText = true

	local cps = (options and options.cps) or 30
	local pauses = (options and options.punctuationPauses) or DEFAULT_PAUSES
	local instantKey = options and options.instantFinishKey
	local cursor = options and options.cursor
	local cursorTween = options and options.cursorTween or false
	local perCharSound = options and options.perCharSound
	local respectNewlines = options and options.respectNewlines

	local tokens = tokenize(fullText)
	local totalVisible = 0
	for _, t in ipairs(tokens) do
		if t.kind == "text" then
			totalVisible += utf8len(t.raw)
		end
	end

	self._playing = true
	self._skipRequested = false

	local conn: RBXScriptConnection? = nil
	if instantKey then
		conn = UserInputService.InputBegan:Connect(function(input, processed)
			if processed then
				return
			end
			if input.KeyCode == instantKey then
				self._skipRequested = true
			end
		end)
	end

	local printed = 0
	local startTime = os.clock()
	local blinkPhase = 0
	local lastEmit = 0

	label.Text = "" -- clear first

	while printed < totalVisible and self._playing do
		if self._skipRequested then
			printed = totalVisible

			break
		end

		-- compute target visible given cps and elapsed time
		local elapsed = os.clock() - startTime

		local target = math.clamp(math.floor(elapsed * cps), 0, totalVisible)

		if target > printed then
			local step = target - printed
			printed += step

			-- render frame

			blinkPhase = (blinkPhase + RunService.Heartbeat:Wait()) % 1
			local out

			out, _ = buildVisible(tokens, printed, respectNewlines ~= false, cursor, cursorTween, blinkPhase)
			label.Text = out

			-- per-char side effects for the last actually printed rune
			if perCharSound then
				promise.new(function()
					perCharSound.TimePosition = 0
					perCharSound:Play()
				end)
			end

			-- optional punctuation micro-pauses
			-- find last visible char
			local lastTextChar

			for i = #label.Text, 1, -1 do
				local c = string.sub(label.Text, i, i)

				if c ~= ">" and c ~= "/" then
					lastTextChar = c

					break
				end
			end

			local pause = lastTextChar and pauses[lastTextChar] or 0
			if pause and pause > 0 then
				task.wait(pause)
			end
		else
			-- idle; still update blink if a cursor is shown
			blinkPhase = (blinkPhase + RunService.Heartbeat:Wait()) % 1

			if cursor then
				local out
				out, _ =
					buildVisible(tokens, printed, respectNewlines ~= false, cursor, cursorTween, blinkPhase)

				label.Text = out
			end
		end
	end

	-- finalize with full text (no cursor)
	label.Text = buildVisible(tokens, totalVisible, respectNewlines ~= false, nil, false, 0)
	if typeof(label.Text) == "table" then
		label.Text = label.Text :: any
	end

	self._playing = false
	self._skipRequested = false

	if conn then
		conn:Disconnect()
	end
end

return Typewriter
