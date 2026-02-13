--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local audio = require(ReplicatedStorage.Modules.audio)
local badges = require(ReplicatedStorage.Structures.badges)
local hint = require(StarterPlayer.StarterPlayerScripts.Components.hint)
local pop = require(StarterPlayer.StarterPlayerScripts.Interface.pop)
local ratelimit = require(ReplicatedStorage.Utility.ratelimit)
local shadow = require(StarterPlayer.StarterPlayerScripts.Interface.shadow)
local text_counter = require(ReplicatedStorage.ClientModules.markdown["text-counter"])
local typemarshaller = require(ReplicatedStorage.Types.typemarshaller)

-- achievement.luau

local module = {}
module.limit = ratelimit(1, 0.5)

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local badgesGui = playerGui:WaitForChild("Badges")
local badgesCanvas = badgesGui.CanvasGroup
local shopFrame = badgesCanvas.Frame

local itemHolder = shopFrame.Holder
local total = shopFrame.Total

local function createTemplate(ancestor: Instance?)
	local Instances = {
		ItemTemplate = Instance.new("Frame"),
		UICorner = Instance.new("UICorner"),
		UIStroke = Instance.new("UIStroke"),
		Details = Instance.new("TextButton"),
		UICorner_2 = Instance.new("UICorner"),
		ImageLabel = Instance.new("ImageLabel"),
		AspectRatio = Instance.new("UIAspectRatioConstraint"),
		AspectRatio_2 = Instance.new("UIAspectRatioConstraint"),
		Share = Instance.new("TextButton"),
		UICorner_3 = Instance.new("UICorner"),
		ImageLabel_2 = Instance.new("ImageLabel"),
		AspectRatio_3 = Instance.new("UIAspectRatioConstraint"),
		AspectRatio_4 = Instance.new("UIAspectRatioConstraint"),
		Image_3 = Instance.new("ImageLabel"),
		AspectRatio_5 = Instance.new("UIAspectRatioConstraint"),
		Title = Instance.new("TextLabel"),
		AspectRatio_6 = Instance.new("UIAspectRatioConstraint"),
		AspectRatio_7 = Instance.new("UIAspectRatioConstraint"),
	}

	Instances.ItemTemplate.Name = "ItemTemplate"
	Instances.ItemTemplate.AnchorPoint = Vector2.new(0.5, 0.5)
	Instances.ItemTemplate.Size = UDim2.new(0.41, 0, 0.29, 0)
	Instances.ItemTemplate.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Instances.ItemTemplate.Position = UDim2.new(0.21, 0, 0.14, 0)
	Instances.ItemTemplate.BorderSizePixel = 0
	Instances.ItemTemplate.BackgroundColor3 = Color3.fromRGB(26, 17, 15)
	Instances.ItemTemplate.Parent = ancestor or ReplicatedStorage

	Instances.UICorner.Name = "UICorner"
	Instances.UICorner.CornerRadius = UDim.new(0.14, 0)
	Instances.UICorner.Parent = Instances.ItemTemplate

	Instances.UIStroke.Name = "UIStroke"
	Instances.UIStroke.Color = Color3.fromRGB(133, 115, 110)
	Instances.UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Instances.UIStroke.Transparency = 0.8
	Instances.UIStroke.Parent = Instances.ItemTemplate

	Instances.Details.Name = "Details"
	Instances.Details.AnchorPoint = Vector2.new(0.5, 0.5)
	Instances.Details.Size = UDim2.new(0.2, 0, 0.3, 0)
	Instances.Details.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Instances.Details.Position = UDim2.new(0.88, 0, 0.78, 0)
	Instances.Details.BorderSizePixel = 0
	Instances.Details.BackgroundColor3 = Color3.fromRGB(231, 189, 178)
	Instances.Details.FontFace =
		Font.new("rbxassetid://11702779517", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	Instances.Details.TextColor3 = Color3.fromRGB(255, 219, 209)
	Instances.Details.Text = ""
	Instances.Details.TextWrapped = true
	Instances.Details.Parent = Instances.ItemTemplate

	Instances.UICorner_2.Name = "UICorner"
	Instances.UICorner_2.CornerRadius = UDim.new(1, 0)
	Instances.UICorner_2.Parent = Instances.Details

	Instances.ImageLabel.Name = "ImageLabel"
	Instances.ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	Instances.ImageLabel.Size = UDim2.new(0.33, 0, 0.59, 0)
	Instances.ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Instances.ImageLabel.BackgroundTransparency = 1
	Instances.ImageLabel.Position = UDim2.new(0.49, 0, 0.53, 0)
	Instances.ImageLabel.BorderSizePixel = 0
	Instances.ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Instances.ImageLabel.ImageColor3 = Color3.fromRGB(68, 42, 34)
	Instances.ImageLabel.Image = "rbxassetid://10723365987"
	Instances.ImageLabel.Parent = Instances.Details

	Instances.AspectRatio.Name = "AspectRatio"
	Instances.AspectRatio.Parent = Instances.ImageLabel

	Instances.AspectRatio_2.Name = "AspectRatio"
	Instances.AspectRatio_2.AspectRatio = 1.79
	Instances.AspectRatio_2.Parent = Instances.Details

	Instances.Share.Name = "Share"
	Instances.Share.AnchorPoint = Vector2.new(0.5, 0.5)
	Instances.Share.ZIndex = 3
	Instances.Share.Size = UDim2.new(0.11, 0, 0.3, 0)
	Instances.Share.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Instances.Share.BackgroundTransparency = 1
	Instances.Share.Position = UDim2.new(0.69, 0, 0.78, 0)
	Instances.Share.BorderSizePixel = 0
	Instances.Share.BackgroundColor3 = Color3.fromRGB(68, 42, 34)
	Instances.Share.FontFace =
		Font.new("rbxassetid://11702779517", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	Instances.Share.TextColor3 = Color3.fromRGB(255, 255, 255)
	Instances.Share.Text = ""
	Instances.Share.Parent = Instances.ItemTemplate

	Instances.UICorner_3.Name = "UICorner"
	Instances.UICorner_3.CornerRadius = UDim.new(1, 0)
	Instances.UICorner_3.Parent = Instances.Share

	Instances.ImageLabel_2.Name = "ImageLabel"
	Instances.ImageLabel_2.AnchorPoint = Vector2.new(0.5, 0.5)
	Instances.ImageLabel_2.Size = UDim2.new(0.5, 0, 0.5, 0)
	Instances.ImageLabel_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Instances.ImageLabel_2.BackgroundTransparency = 1
	Instances.ImageLabel_2.Position = UDim2.new(0.5, 0, 0.5, 0)
	Instances.ImageLabel_2.BorderSizePixel = 0
	Instances.ImageLabel_2.BackgroundColor3 = Color3.fromRGB(114, 53, 35)
	Instances.ImageLabel_2.ImageColor3 = Color3.fromRGB(255, 219, 209)
	Instances.ImageLabel_2.Image = "rbxassetid://10734950553"
	Instances.ImageLabel_2.Parent = Instances.Share

	Instances.AspectRatio_3.Name = "AspectRatio"
	Instances.AspectRatio_3.AspectRatio = 0.98
	Instances.AspectRatio_3.Parent = Instances.ImageLabel_2

	Instances.AspectRatio_4.Name = "AspectRatio"
	Instances.AspectRatio_4.AspectRatio = 0.98
	Instances.AspectRatio_4.Parent = Instances.Share

	Instances.Image_3.Name = "Image"
	Instances.Image_3.AnchorPoint = Vector2.new(0.5, 0.5)
	Instances.Image_3.Size = UDim2.new(0.25, 0, 0.69, 0)
	Instances.Image_3.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Instances.Image_3.BackgroundTransparency = 1
	Instances.Image_3.Position = UDim2.new(0.21, 0, 0.5, 0)
	Instances.Image_3.BorderSizePixel = 0
	Instances.Image_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Instances.Image_3.Image = "rbxassetid://86354301652315"
	Instances.Image_3.Parent = Instances.ItemTemplate

	Instances.AspectRatio_5.Name = "AspectRatio"
	Instances.AspectRatio_5.AspectRatio = 0.99
	Instances.AspectRatio_5.Parent = Instances.Image_3

	Instances.Title.Name = "Title"
	Instances.Title.AnchorPoint = Vector2.new(0.5, 0.5)
	Instances.Title.Size = UDim2.new(0.6, 0, 0.23, 0)
	Instances.Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Instances.Title.BackgroundTransparency = 1
	Instances.Title.Position = UDim2.new(0.68, 0, 0.26, 0)
	Instances.Title.BorderSizePixel = 0
	Instances.Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Instances.Title.FontFace =
		Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	Instances.Title.RichText = true
	Instances.Title.TextColor3 = Color3.fromRGB(241, 223, 218)
	Instances.Title.Text = 'Item<br/><font weight="Regular"><font transparency="0.5">09/18/25</font></font>'
	Instances.Title.TextXAlignment = Enum.TextXAlignment.Left
	Instances.Title.Parent = Instances.ItemTemplate

	Instances.AspectRatio_6.Name = "AspectRatio"
	Instances.AspectRatio_6.AspectRatio = 7.1
	Instances.AspectRatio_6.Parent = Instances.Title

	Instances.AspectRatio_7.Name = "AspectRatio"
	Instances.AspectRatio_7.AspectRatio = 2.75
	Instances.AspectRatio_7.Parent = Instances.ItemTemplate

	return Instances.ItemTemplate :: any
end

function module:Unload()
	for _, item in ipairs(itemHolder:GetChildren()) do
		if item and item:IsA("Frame") then
			item:Destroy()

			if module.limit.count_map[item] then
				module.limit.count_map[item] = nil
			end

			RunService.Heartbeat:Wait()
		end
	end
end

function module:DisplayTotal(profile: typemarshaller.Profile)
	local total_label = total.Amount

	local total = tonumber(profile and #profile.Data.achievements)

	if total then
		local counter = text_counter.new(total_label, total, 3)

		counter:Start(counter)
	else
		total_label.Text = "?"
	end
end

function module:Load(profile: typemarshaller.Profile)
	if not profile then
		--print("no profile to load badges")

		hint.new():SetText("Error loading achievements. Please try again later."):SetCanClick(false)

		return
	end

	module:Unload()

	local items = profile.Data.achievements

	for i, item in ipairs(items :: { badges.badge }) do
		local template = createTemplate(itemHolder)

		shadow(template)

		local details_btn = template.Details :: TextButton
		local share_btn = template.Share :: TextButton

		-- load title
		local title = template.Title :: TextLabel

		local date_achieved = DateTime.fromUnixTimestampMillis(item.date_acquired)
		local universal_time = date_achieved:FormatUniversalTime("LL", "en-us")

		title.Text = item.name
			.. [[
      <br/><font weight="Regular"><font transparency="0.5">]]
			.. universal_time
			.. [[</font></font>
      ]]

		-- TODO) finish these mechanics

		details_btn.Activated:Connect(function()
			if not module.limit(details_btn) then
				return
			end

			audio:PlaySFX("click")

			pop(details_btn)
		end)

		share_btn.Activated:Connect(function()
			if not module.limit(share_btn) then
				return
			end

			audio:PlaySFX("click")

			pop(share_btn)
		end)
	end
end

return module
