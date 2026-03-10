local Players = game:GetService("Players")
local player = Players.LocalPlayer

local white = BrickColor.White()

local function isPlayerOnTeam(team)
	if (team == white) or (player.TeamColor == team) then
		return true
	end
	
	return false
end


local function updateIndicatorUI(attachment, indicatorUI)
	local image = attachment:GetAttribute("Image") or ""
	local enabled = attachment:GetAttribute("Enabled") or false
	local team = attachment:GetAttribute("Team")
	local color = attachment:GetAttribute("Color")
	
	if (not enabled) or (not color) or (image == "") or (not team) or (not isPlayerOnTeam(team)) then
		indicatorUI.Visible = false
		return
	else
		indicatorUI.Visible = true
	end
	
	indicatorUI.BackgroundColor3 = color
	indicatorUI.ArrowFrame.ArrowImage.ImageColor3 = color
	
	indicatorUI.IconImage.Image = image
end

return updateIndicatorUI