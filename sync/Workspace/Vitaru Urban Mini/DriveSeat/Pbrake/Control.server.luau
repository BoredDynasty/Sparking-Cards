if script.Parent.Parent:IsA("VehicleSeat") then
	script.Parent.Parent.ChildAdded:connect(function(child)
		if child:IsA("Weld") and game.Players:GetPlayerFromCharacter(child.Part1.Parent)~=nil then
			local p=game.Players:GetPlayerFromCharacter(child.Part1.Parent)
			local g=script.G:Clone()
			g.Parent=p.PlayerGui
			g:WaitForChild("src")
			g.src.Value=script.Parent
			g.Horn.Disabled=false		
		end
	end)
end