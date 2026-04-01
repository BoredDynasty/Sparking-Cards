--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local ripple = require(StarterPlayer.StarterPlayerScripts.Interface.ripple)
local spr = require(ReplicatedStorage.Modules.spr)

-- tab.luau
-- https://m3.material.io/components/tabs

local module = {}

local function createTab(): typeof(ReplicatedStorage.Interfaces.Tab)
	return ReplicatedStorage.Interfaces.Tab:Clone()
end

function module.new(holder: Frame)
	-- TODO: add icon support

	local self = setmetatable({}, { __index = module })
	self.holder = holder
	self.tabs = {}
	self.selected = nil
	self.debounce = ratelimit(1, 0.5)
	self.Changed = SignalPlus() :: SignalPlus.Signal<string>

	return self
end

function module:AddTab(name: string)
	local tab = createTab()
	tab.Name = name
	tab.TextLabel.Text = name
	tab.Parent = self.holder

	table.insert(self.tabs, tab)

	tab.Activated:Connect(function()
		self:SelectTab(name)
		ripple(tab)
	end)

	return tab
end

function module:SelectTab(name: string, force: boolean?)
	if not force and not self.debounce() then
		return
	end

	for i, tab in ipairs(self.tabs :: { typeof(ReplicatedStorage.Interfaces.Tab) }) do
		local active_indicator = tab.ActiveIndicator

		if tab.Name == name then
			spr.target(active_indicator, 0.8, 4, {
				ImageTransparency = 0,
				ImageColor3 = Color3.fromRGB(255, 181, 160),
			})

			spr.target(tab.TextLabel, 0.8, 4, {
				TextColor3 = Color3.fromRGB(255, 181, 160),
			})

			self.selected = name
			self.Changed:Fire(name)
		else
			spr.target(active_indicator, 0.8, 4, {
				ImageTransparency = 0.5,
				ImageColor3 = Color3.fromHex("#d8c2bc"),
			})
			spr.target(tab.TextLabel, 0.8, 4, {
				TextColor3 = Color3.fromHex("#d8c2bc"),
			})
		end
	end
end

function module:GetSelectedTab(): string?
	return self.selected
end

function module:RemoveTab(name: string)
	for i, tab in ipairs(self.tabs :: { typeof(ReplicatedStorage.Interfaces.Tab) }) do
		if tab.Name == name then
			tab:Destroy()
			table.remove(self.tabs, i)

			if self.selected == name then
				self.selected = nil
			end

			return
		end
	end
end

function module:Destroy()
	for i, tab in ipairs(self.tabs :: { typeof(ReplicatedStorage.Interfaces.Tab) }) do
		tab:Destroy()
	end

	self.tabs = {}
	self.selected = nil

	setmetatable(self, nil)
end

return module
