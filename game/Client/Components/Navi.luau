--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SignalPlus = require(ReplicatedStorage.Dependencies.SignalPlus)
local TweenPlus = require(ReplicatedStorage.Modules.TweenPlus)
local audio = require(ReplicatedStorage.Modules.audio)
local lucide = require(ReplicatedStorage.Packages.lucide)
local observer = require(ReplicatedStorage.Utility.observer)
local promise = require(ReplicatedStorage.Packages.promise)
local spr = require(ReplicatedStorage.Modules.spr)

-- Navi.luau

-- all navigation rails must follow the same design principle.

local navi = {
	tracked = {} :: { data },
}

export type data = {
	rail: Frame,
	railDescriptor: string,
	buttons: {
		[string]: {
			state: observer.Observer<boolean>,
			button_data: button_data,
			callback: (unknown) -> unknown?,
			disabledCallback: (unknown) -> unknown?,
		},
	},
}

export type button_data = {
	name: string,
	icon: typeof(lucide.GetAsset("", 0)) | string,
}

function navi.new(
	rail: Frame,
	callback: (unknown) -> unknown?,
	disabledCallback: (unknown) -> unknown?,
	defaultBtn: button_data?,
	overrideState: boolean?
)
	defaultBtn = defaultBtn or {
		name = "Home",
		icon = "rbxassetid://10723407389",
	}

	local railDescriptor = rail:GetFullName()

	local state = observer.new(overrideState or false)

	local tbl = {
		rail = rail,
		railDescriptor = railDescriptor,
		buttons = {
			[defaultBtn.name] = {
				state = state,
				button_data = defaultBtn,
				callback = callback,
				disabledCallback = disabledCallback,
			},
		},
	}
	table.insert(navi.tracked, tbl)
end

function navi._render(ancestor: Instance?)
	local ButtonTemplate = Instance.new("TextButton")
	local UICorner = Instance.new("UICorner")
	local Icon = Instance.new("ImageLabel")
	local AspectRatio = Instance.new("UIAspectRatioConstraint")
	local AspectRatio_2 = Instance.new("UIAspectRatioConstraint")

	--Properties:

	ButtonTemplate.Name = "ButtonTemplate"
	ButtonTemplate.Parent = ancestor or ReplicatedStorage
	ButtonTemplate.AnchorPoint = Vector2.new(0.5, 0.5)
	ButtonTemplate.BackgroundColor3 = Color3.fromRGB(93, 64, 55)
	ButtonTemplate.BorderColor3 = Color3.fromRGB(0, 0, 0)
	ButtonTemplate.BorderSizePixel = 0
	ButtonTemplate.Position = UDim2.new(0, 25, 0, 25)
	ButtonTemplate.Size = UDim2.new(0.877192974, 0, 0.108225107, 0)
	ButtonTemplate.Font = Enum.Font.SourceSans
	ButtonTemplate.Text = ""
	ButtonTemplate.TextColor3 = Color3.fromRGB(0, 0, 0)
	ButtonTemplate.TextSize = 14.000

	UICorner.CornerRadius = UDim.new(1, 0)
	UICorner.Parent = ButtonTemplate

	Icon.Name = "Icon"
	Icon.Parent = ButtonTemplate
	Icon.AnchorPoint = Vector2.new(0.5, 0.5)
	Icon.BackgroundTransparency = 1.000
	Icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	Icon.Size = UDim2.new(0.400000006, 0, 0.400000006, 0)
	Icon.Image = "rbxassetid://10723407389"

	AspectRatio.Name = "AspectRatio"
	AspectRatio.Parent = Icon
	AspectRatio.DominantAxis = Enum.DominantAxis.Height

	AspectRatio_2.Name = "AspectRatio"
	AspectRatio_2.Parent = ButtonTemplate
	AspectRatio_2.AspectRatio = 1.000

	return ButtonTemplate
end

function navi:add(
	rail: Frame,
	name: string,
	icon: typeof(lucide.GetAsset("", 0)) | string,
	callback: (unknown) -> unknown?,
	disabledCallback: (unknown) -> unknown?,
	overrideState: boolean?
)
	local tbl = nil :: data?

	for i, data in ipairs(navi.tracked) do
		if data.railDescriptor == rail:GetFullName() then
			tbl = data
		else
			continue
		end
	end

	if not tbl then
		return
	end

	tbl.buttons[name] = {
		state = observer.new(overrideState or false),
		button_data = {
			name = name,
			icon = icon,
		},
		callback = callback,
		disabledCallback = disabledCallback,
	}
end

function navi:remove(rail: Frame, name: string)
	for i, data in ipairs(navi.tracked) do
		if data.railDescriptor == rail:GetFullName() then
			if data.buttons[name] then
				data.buttons[name].state:Destroy()
				data.buttons[name] = nil
			else
				return
			end
		else
			continue
		end
	end
end

function navi:render(rail: Frame)
	local tbl = nil :: data?

	for i, data in ipairs(navi.tracked) do
		if data.railDescriptor == rail:GetFullName() then
			tbl = data
		end
	end

	if not tbl then
		return
	end

	for i, data in tbl.buttons do
		local btn = navi._render(tbl.rail)

		promise
			.new(function()
				btn.Icon.Image = if typeof(data.button_data.icon) == "string"
					then data.button_data.icon
					else "rbxassetid://" .. data.button_data.icon.Id
			end)
			:catch(warn)
		if tbl.buttons[i].state:Get() == true then
			-- if overrid
			spr.target(btn, 0.8, 0.3, {
				Size = UDim2.fromScale(btn.Size.X.Scale * 1.2, btn.Size.Y.Scale * 1.2),
			})
			-- when already overrid, the callback should've already been in effect.
		end

		data.state:Watch(function(newValue: boolean, oldValue: boolean)
			if newValue then
				spr.target(btn, 0.8, 0.3, {
					Size = UDim2.fromScale(btn.Size.X.Scale * 1.2, btn.Size.Y.Scale * 1.2),
				})
				promise
					.new(function()
						data.callback()
					end)
					:catch(warn)
			elseif not newValue and oldValue then
				spr.target(btn, 0.8, 0.3, {
					Size = UDim2.fromScale(btn.Size.X.Scale / 1.2, btn.Size.Y.Scale / 1.2),
				})
				promise
					.new(function()
						data.disabledCallback()
					end)
					:catch(warn)
			end
		end)
	end
end

return navi
