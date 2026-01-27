local ts,ti = game.TweenService,TweenInfo.new(.5,Enum.EasingStyle.Quint)

local on1,on2,off1,off2 = ts:Create(script.Parent.Fill,ti,{ImageTransparency=0}), ts:Create(script.Parent.Knob,ti,{Position=UDim2.new(1,-39,.5,0)}),ts:Create(script.Parent.Fill,ti,{ImageTransparency=1}), ts:Create(script.Parent.Knob,ti,{Position=UDim2.new(0,-3,.5,0)})

local state = script.Parent:GetAttribute("state")

if state then
	on1:Play()
	on2:Play()
else
	off1:Play()
	off2:Play()
end

script.Parent.MouseButton1Click:Connect(function()
	state = script.Parent:GetAttribute("state")
	
	if state then
		script.Parent:SetAttribute("state",false)
		off1:Play()
		off2:Play()
	else
		script.Parent:SetAttribute("state",true)
		on1:Play()
		on2:Play()
	end
end)