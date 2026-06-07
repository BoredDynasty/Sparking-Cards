--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local playerMarshaller = require(ReplicatedStorage.Utility.playerMarshaller)

-- ui-scaler.luau

local module = {}

module._connections = {} :: { [string]: RBXScriptConnection }

local player = playerMarshaller.get()
local player_gui = player.PlayerGui

local camera = workspace.CurrentCamera

--[[
   It's prolly best to use this in a task.spawn

   @public
]]
function module:Outline()
	local tag = "Outline"

	local base_size = 1200

	for i, stroke in ipairs(player_gui:GetDescendants()) do
		if not stroke:IsA("UIStroke") then
			return
		end

		for j, conn_data in pairs(module._connections) do
			if j == "Outline" then
				conn_data:Disconnect()
			end
		end

		local initial_thickness = stroke.Thickness

		local function update()
			local viewport_size = camera.ViewportSize
			local x = viewport_size.X

			stroke.Thickness = initial_thickness * x / base_size
		end

		local signal = camera:GetPropertyChangedSignal("ViewportSize")
		local conn = signal:Connect(update)

		module._connections[tag] = conn
	end
end

--[[
	Applies equidistant layout scaling to position inner element with equal padding.
	
	@param background GuiObject -- The background/container element
	@param inner GuiObject -- The inner element to center with equidistant padding
	@param padding number -- Base padding value (unused in equidistant formula)
	
	@public
]]
function module:EquidistantLayout(background: GuiObject, inner: GuiObject, padding: number)
	local function update()
		local background_size = background.Size
		local inner_size = inner.Size

		local background_width = background_size.X.Offset
		local inner_width = inner_size.X.Offset

		-- Equidistant formula: (container_width - element_width) / 2
		local equidistant_padding = (background_width - inner_width) / 2

		inner.Position = UDim2.new(0, equidistant_padding, inner.Position.Y.Scale, inner.Position.Y.Offset)
	end

	update()

	local tag = "EquidistantLayout"
	if module._connections[tag] then
		module._connections[tag]:Disconnect()
	end

	local signal = camera:GetPropertyChangedSignal("ViewportSize")
	local conn = signal:Connect(update)

	module._connections[tag] = conn
end

return module
