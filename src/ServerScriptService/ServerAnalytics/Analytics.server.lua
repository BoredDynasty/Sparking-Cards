local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local HTTPService = game:GetService("HttpService")

local CollectionService = game:GetService("CollectionService")

local FunnelSessionID = HTTPService:GenerateGUID(false)

print("Funnel Analytics are enabled.")


Players.PlayerAdded:Connect(function(player)
	AnalyticsService:LogOnboardingFunnelStepEvent(
		player,
		1, -- Step number
		"Player Joined" -- Step name
	)
	-- Tags
	for i, DriveSeat in pairs(CollectionService:GetTagged("CanDrive")) do
		DriveSeat.Touched:Connect(function()
			AnalyticsService:LogOnboardingFunnelStepEvent(
				player,
				2, -- Step number
				"Baby Steps" -- Step name
			)
		end)
	end
end)