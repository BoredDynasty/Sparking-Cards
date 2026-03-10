local indicatorClient = script:FindFirstChild("IndicatorsClient")
if indicatorClient then
	indicatorClient.Parent = game:GetService("StarterPlayer").StarterPlayerScripts
end
script:Destroy()