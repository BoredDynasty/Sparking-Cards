local Highlight = {}

local HighlightInstance = script:WaitForChild("ItemHighlight")

local TweenService = game:GetService("TweenService")

local Highlights = {} 


function Highlight.EnableHighlight(prompt)
	if prompt and not Highlights[prompt] then
		if prompt.Parent:IsA("BasePart") then
			local NewHighlight = HighlightInstance:Clone()

			local partToHighlight = prompt:FindFirstChild("PartToHighlight")
			if partToHighlight and partToHighlight:IsA("ObjectValue") and partToHighlight.Value and partToHighlight.Value:IsA("BasePart") then
				NewHighlight.Parent = partToHighlight.Value
				NewHighlight.Adornee = partToHighlight.Value
			else
				NewHighlight.Parent = prompt.Parent
				NewHighlight.Adornee = prompt.Parent
			end
			
			

			NewHighlight.Enabled = true
			NewHighlight.OutlineTransparency = 1
			TweenService:Create(NewHighlight, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {OutlineTransparency = 0}):Play()

			Highlights[prompt] = NewHighlight
		end
	end
end


function Highlight.DisableHighlight(prompt)
	if prompt and Highlights[prompt] then
		local highlight = Highlights[prompt]

		TweenService:Create(highlight, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {OutlineTransparency = 1}):Play()
		wait(0.2)

		if highlight then
			highlight:Destroy() 
			Highlights[prompt] = nil 
		end
	end
end

return Highlight
