-- // Module by altforplasma [no credits needed]

local PromptPlus = {}

-- // Variables

local TweenService = game:GetService("TweenService")

local Highlight = require(script.Modules:WaitForChild("Highlight"))
local Styles = script:WaitForChild("Styles")
local Settings = script:WaitForChild("Settings")
local Sounds = script:WaitForChild("Sounds")

local Hover_Enter_Sound = Sounds:WaitForChild("Hover_Enter")
local Hover_Leave_Sound = Sounds:WaitForChild("Hover_Leave")
local Trigger_Sound = Sounds:WaitForChild("Trigger")


-- // Constants

local CurrentStyle = Settings:GetAttribute("Style")
local StyleEnabled = Settings:GetAttribute("StylesEnabled")
local CanHighlight = Settings:GetAttribute("CanHighlight")

local IsOnMobile = false

-- // Functions

function PromptPlus.isOnMobileDevice()
	if game:GetService("UserInputService").KeyboardEnabled then
		IsOnMobile = false
	else
		IsOnMobile = true
	end
end




local function applyStyleToPrompt(prompt)
	if IsOnMobile == true then return end

	local function createAndApplyStyle()
		local Style = Styles:WaitForChild(CurrentStyle):Clone()
		Style.Parent = prompt.Parent
		Style.Container.Key.Text = tostring(game:GetService("UserInputService"):GetStringForKeyCode(prompt.KeyboardKeyCode))
		Style.Container.ObjectText.Text = prompt.ObjectText
		Style.Container.ActionText.Text = prompt.ActionText
		
		if prompt.HoldDuration ~= 0 then
			Style.Container.HoldDurationDecor.Visible = true
			Style.Container.HoldDurationLine.Visible = true
			Style.Container.HoldDurationValue.Visible = true
			
			Style.Container.ActionText.Position = UDim2.new(0, 0,0.65, 0)
			Style.Container.ObjectText.Position = UDim2.new(0, 0,0.85, 0)
		else
			Style.Container.HoldDurationDecor.Visible = false
			Style.Container.HoldDurationLine.Visible = false
			Style.Container.HoldDurationValue.Visible = false
			
			Style.Container.ActionText.Position = UDim2.new(0, 0,0.5, 0)
			Style.Container.ObjectText.Position = UDim2.new(0, 0,0.68, 0)
		end

		
		Style.Enabled = false

		return Style
	end


	local Style = createAndApplyStyle()
	
	prompt.Triggered:Connect(function()
		if Style and Style:FindFirstChild("Container") then
			Style.Enabled = true
			Style.Container.Position = UDim2.new(0.5, 0,0.5, 0)
			TweenService:Create(Style.Container, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.9, 0,0.9, 0)}):Play()
			task.wait(0.18)
			if Style and Style:FindFirstChild("Container") then 
				TweenService:Create(Style.Container, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0,1, 0)}):Play()
			end
		end
		
		Sounds.Holding:Stop()
		
		Trigger_Sound:Play()

	end)
	
	prompt.PromptButtonHoldBegan:Connect(function()
		Sounds.Holding:Play()
		
		if Style and Style:FindFirstChild("Container") then
			Style.Container.HoldDurationValue.Size = UDim2.new(0, 0,0.08, 0)
			TweenService:Create(Style.Container, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.9, 0,0.9, 0)}):Play()
			TweenService:Create(Style.Container.HoldDurationValue, TweenInfo.new(tonumber(prompt.HoldDuration), Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.97, 0,0.08, 0)}):Play()
		end

		wait(tonumber(prompt.HoldDuration))
		
		if Style and Style:FindFirstChild("Container") then
			TweenService:Create(Style.Container, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0,1, 0)}):Play()
		end
	end)
	
	prompt.PromptButtonHoldEnded:Connect(function()
		
		if Style and Style:FindFirstChild("Container") then
			TweenService:Create(Style.Container, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0,1, 0)}):Play()
			TweenService:Create(Style.Container.HoldDurationValue, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 0,0.08, 0)}):Play()
		end
	
		Sounds.Holding:Stop()
	end)
	

	prompt.PromptShown:Connect(function()
		if Style and Style.Parent then
			Style:Destroy() 
		end
		Style = createAndApplyStyle() 
		Style.Enabled = true 
		Style.Container.Position = UDim2.new(0.5, 0,0.35, 0)
		TweenService:Create(Style.Container, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0,0.5, 0)}):Play()
		Hover_Enter_Sound:Play()

		if CanHighlight == true then
			Highlight.EnableHighlight(prompt)
		end
		
		
		Style.Enabled = true
		Style.Container.Position = UDim2.new(0.5, 0,0.5, 0)
	end)

	prompt.PromptHidden:Connect(function()
		if Style and Style:FindFirstChild("Container") then
			local tween = TweenService:Create(Style.Container, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0,0.05, 0), Size = UDim2.new(0.5, 0,0.05, 0)})
			tween:Play()
			Hover_Leave_Sound:Play()
			tween.Completed:Connect(function()
				
				if Style then
					if CanHighlight == true then
						Highlight.DisableHighlight(prompt)
					end

					Style:Destroy()
					Style = nil
				end
			end)
		else
		
			if CanHighlight == true and Style then
				Highlight.DisableHighlight(prompt)
				Style:Destroy()
				Style = nil
			end
		end
	end)

	prompt.Style = Enum.ProximityPromptStyle.Custom
end


local function handlePrompt(prompt)
	if StyleEnabled and prompt:IsA("ProximityPrompt") and prompt.Enabled then
		
		Settings:SetAttribute("StylesEnabled", not IsOnMobile) 
		
		prompt.Style = Enum.ProximityPromptStyle.Default
		if StyleEnabled == true then
			applyStyleToPrompt(prompt)
		else
			prompt.Style = Enum.ProximityPromptStyle.Default
		end
	end
end


function PromptPlus.InitializePrompts()
	local descendants = workspace:GetDescendants()
	for _, descendant in pairs(descendants) do
		
		
		handlePrompt(descendant)
	end
end


function PromptPlus.SetupPromptAddedListener()
	workspace.DescendantAdded:Connect(function(descendant)
		handlePrompt(descendant)
	end)
end


PromptPlus.isOnMobileDevice()
PromptPlus.InitializePrompts()
PromptPlus.SetupPromptAddedListener()

return PromptPlus
