--!strict

-- card-fanning.luau
-- a module to recreate a fanning effect
-- https://x.com/jaaay64/status/1986873547831320677

-- we're going to use a cool algorithm to do this.
-- we need to use a bit of trigonometry;
-- to create an arc, you place each card along a specific point
-- along the circumference of an invisible circle.

-- we distribute the cards across a total "arc angle" maybe like 60 degrees.
-- the radius determines how curved the hand looks.
-- a larger radius makes the arc flatter; a smaller radius make it more circular.
-- for position, we use sine for the x axis and cosine for y axis.

--[[
   ### usage example

   ```luau
   local cardFanning = require(path.to.card-fanning)
   local container = script.Parent.CardContainer
   local arc_angle = 60 -- degrees
   local radius = 100 -- pixels
   cardFanning.layout(container, arc_angle, radius)
   ```

   @param container - The GuiObject container holding the card UI elements.
   @param arc_angle_degrees - The total angle in degrees over which to fan the cards.
   @param radius - The radius of the imaginary circle used for positioning the cards.
   @param cards? - Optional list of GuiObjects to fan. If not provided, all children of the container are used.

   you can set arc_angle_degrees to 30-45 for a tighter fan,
   or 60-90 for a wider fan.

   radius can be set to 80-150 for a more pronounced curve,
   or 200+ for a flatter curve. (if the cards are too bunched up, increase radius)

   TODO) Animate the layout changes for a smoother effect.
]]
local function layout(container: GuiObject, arc_angle_degrees: number, radius: number, cards: { GuiObject }?)
	cards = cards or container:GetChildren() :: { GuiObject }
	-- if we have to filter it, we already add the variable.
	-- if not, save time and use :GetChildren()

	local count = #cards
	if count <= 0 then
		-- wtaf
		return
	end

	local angle_angle_rad = math.rad(arc_angle_degrees)

	for i, card in ipairs(cards) do
		-- step one:
		-- calculate the 't' value (0 - 1) for distribution.
		-- if there is only 1 card, we center it. (0.5)

		local t = (count > 1) and ((i - 1) / (count - 1)) or 0.5

		-- step two:
		-- map 't' to the angle range (centered at 0)
		local angle = (t - 0.5) * angle_angle_rad

		-- step three:
		-- calculate position
		-- use sine for x and cosine for y to create an upward arc.

		local x_offset = math.sin(angle) * radius
		local y_offset = -math.cos(angle) * radius
		-- negative cosine because we need it to go downwards.

		-- step 4:
		-- apply it to the ui
		-- anchor at the bottom center (0.5, 1) for natural fanning.
		card.AnchorPoint = (Vector2.one / 2) -- (0.5, 0.5)
		card.Position = UDim2.new(0.5, x_offset, 1, y_offset + radius)
		card.Rotation = math.deg(angle)
		card.ZIndex = i -- set the ZIndex to center cards overlap outer cards.
	end
end

return {
	layout = layout,
}
