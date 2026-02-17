--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local audio = require(ReplicatedStorage.Modules.audio)
local future = require(ReplicatedStorage.Packages.future)
local hud = require(StarterPlayer.StarterPlayerScripts.Components.hud)
local observer = require(ReplicatedStorage.Utility.observer)
local pop = require(StarterPlayer.StarterPlayerScripts.Interface.pop)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local spr = require(ReplicatedStorage.Modules.spr)
local tablekit = require(ReplicatedStorage.Packages.tablekit)
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- navigation-rail.luau
-- all rails must be pre-made

local module = {}
module.__index = module

local navigation_pool = PoolerPlus:CreatePool("NavigationPool", function()
	local templates = ReplicatedStorage.Interfaces

	return templates.NavigationRail:Clone()
end)

local button_pool = PoolerPlus:CreatePool("NavigationBtnPool", function()
	local templates = ReplicatedStorage.Interfaces

	return templates.NavigationButton:Clone()
end)

navigation_pool:AdaptivePreload()
button_pool:AdaptivePreload()

type Button = {
	name: string,
	icon: typemarshaller.LucideIcon,
	text_button: typeof(button_pool:Get()),
	fn: () -> (),
}

type NavigationRail = setmetatable<{
	rail_gui: typeof(navigation_pool:Get()),
	holder: typeof(navigation_pool:Get().Holder),

	action_button: typeof(navigation_pool:Get().ActionButton),
	expand_button: typeof(navigation_pool:Get().Expand),

	active_button: observer.Observer<typeof(button_pool:Get())>,
	buttons: { Button },

	rate_limit: ratelimit.Ratelimit<string>,
}, typeof(module)>

function module.new()
	local self = setmetatable({}, module)

	self.rail_gui = navigation_pool:Get()
	self.holder = self.rail_gui.Holder

	self.action_button = self.rail_gui.ActionButton
	self.expand_button = self.rail_gui.Expand

	self.active_button = observer.new(nil) :: observer.Observer<typeof(button_pool:Get())>
	self.buttons = {} :: { Button }

	self.rate_limit = ratelimit(1, 1.5)

	self.rail_gui.Position = UDim2.fromScale(-0.5, 0.5)

	self.active_button:Watch(function(new)
		if new then
			spr.target(new, 0.6, 4.3, {
				BackgroundTransparency = 0,
			})

			pop(new, 1.1)
		end

		for i, data in ipairs(self.buttons) do
			if data.text_button ~= new then
				local text_button = data.text_button

				spr.target(text_button, 0.6, 4.3, {
					BackgroundTransparency = 1,
				})
			end
		end
	end)

	self.action_button.AutoButtonColor = false
	self.expand_button.AutoButtonColor = false

	return self
end

--[[
	It is reccomended to place this directly under a **LayerCollector**.
]]
function module.SetAdornee(self: NavigationRail, parent: Instance)
	future.Try(function()
		self.rail_gui.Parent = parent
	end)
end

function module.Show(self: NavigationRail)
	local ancestor = self.rail_gui:FindFirstAncestorOfClass("ScreenGui")
	if ancestor then
		spr.stop(self.rail_gui)

		self.rail_gui.Visible = true

		if ancestor.ZIndexBehavior == Enum.ZIndexBehavior.Sibling then
			spr.target(self.rail_gui, 0.8, 3, {
				GroupTransparency = 0,
			})
		else
			spr.target(self.rail_gui, 1, 3, {
				Position = UDim2.fromScale(0.03, 0.5),
			})
		end
	end

	--hud:SetAlignment("right")
end

function module.Hide(self: NavigationRail)
	local ancestor = self.rail_gui:FindFirstAncestorOfClass("ScreenGui")
	if ancestor then
		spr.stop(self.rail_gui)

		if ancestor.ZIndexBehavior == Enum.ZIndexBehavior.Sibling then
			spr.target(self.rail_gui, 0.8, 3, {
				GroupTransparency = 1,
			})
		else
			spr.target(self.rail_gui, 0.8, 3, {
				Position = UDim2.fromScale(-0.5, 0.5),
			})
		end
	end

	spr.completed(self.rail_gui, function()
		self.rail_gui.Visible = false
	end)

	--hud:SetAlignment("left")
end

function module.Button(self: NavigationRail, name: string, icon: typemarshaller.LucideIcon, fn: () -> ())
	table.insert(self.buttons, {
		name = name,
		icon = icon,
		text_button = button_pool:Get(),
		fn = fn,
	})
end

function module.SetActionIcon(self: NavigationRail, icon: typemarshaller.LucideIcon)
	task.spawn(function()
		future.Try(function()
			local image_label = self.action_button.ImageLabel
			image_label.ImageContent = Content.fromUri(icon.Url)

			pop(image_label, 1.2)
		end)
	end)
end

function module.Render(self: NavigationRail)
	-- iterate the buttons

	for i, data in ipairs(self.buttons) do
		local button = data.text_button
		local fn = data.fn
		local name = data.name
		local icon = data.icon

		-- set the name & icon

		button.Name = name
		future.Try(function()
			task.spawn(function()
				local content = Content.fromUri(icon.Url)

				button.Image.ImageContent = content

				if content.Uri then
					button.Image.Image = content.Uri
				end

				button.TextLabel.Text = name
			end)
		end)

		button.AutoButtonColor = false

		-- shadows aren't required.

		button.Activated:Connect(function()
			if not self.rate_limit(name) then
				return
			end

			self.active_button:Set(button)

			audio:PlaySFX("click")

			future.Try(fn)
		end)

		button.Parent = self.holder
	end
end

return module
