state = script.Parent.State
A=script.Parent.Aa
B=script.Parent.Ba
C=script.Parent.Ca
function collide(model,value)
	a=model:GetChildren()
	if value==false then t=.75 else t=0 end
	for i=1, #a do
		a[i].CanCollide=value
		a[i].Transparency=t
	end
	print(#a)
end
function act()
	if state.Value == 1 then
		collide(A, true)
		collide(B, false)
		collide(C, false)
	elseif state.Value==2 then
		collide(A, false)
		collide(B, true)
		collide(C, false)
	elseif state.Value==3 then
		collide(A, false)
		collide(B, false)
		collide(C, true)
	end
end
function next()
	if state.Value==1 then 
		state.Value=2
	elseif state.Value==2 then
		state.Value=3
	elseif state.Value==3 then
		state.Value=1
	end
	act()
end
act()

script.Parent.Show.Click.MouseClick:connect(next)
