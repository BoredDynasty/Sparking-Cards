--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local PoolerPlus = require(ReplicatedStorage.Dependencies.PoolerPlus)
local audio = require(ReplicatedStorage.Modules.audio)
local future = require(ReplicatedStorage.Packages.future)
local observer = require(ReplicatedStorage.Utility.observer)
local pop = require(StarterPlayer.StarterPlayerScripts.Interface.pop)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
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

	self.active_button:Watch(function(new)
		spr.target(new, 0.6, 4.3, {
			BackgroundTransparency = 1,
		})

		pop(new, 1.1)

		for i, data in ipairs(self.buttons) do
			if data.text_button == new then
				continue
			end

			local text_button = data.text_button

			spr.target(text_button, 0.6, 4.3, {
				BackgroundTransparency = 1,
			})
		end
	end)

	return self
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
			image_label.ImageContent = Content.fromAssetId(icon.Id)

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
		task.spawn(function()
			future.Try(function(...)
				button.Image.ImageContent = ...
			end, Content.fromAssetId(icon.Id))
		end)

		button.Parent = self.holder

		-- shadows aren't required.

		button.Activated:Connect(function()
			if not self.rate_limit(name) then
				return
			end

			self.active_button:Set(button)

			task.spawn(future.Try, fn)
		end)
	end
end

return module
