state = script.Parent.State

function act()
	state.Value = not state.Value
	if state.Value == true then
		script.Parent.a.CanCollide = true
		script.Parent.a.Transparency = 0
		script.Parent.b.CanCollide = true
		script.Parent.b.Transparency = 0
		else
		script.Parent.a.CanCollide = false
		script.Parent.a.Transparency = 0.75
		script.Parent.b.CanCollide = false
		script.Parent.b.Transparency = 0.75
	end
end

script.Parent.Show.Click.MouseClick:connect(act)
