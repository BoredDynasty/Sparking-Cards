state = script.Parent.State

function act()
	state.Value = not state.Value
	if state.Value == true then
		script.Parent.One.CanCollide = true
		script.Parent.One.Transparency = 0	
		script.Parent.a.CanCollide = false
		script.Parent.a.Transparency = 0.75
		script.Parent.b.CanCollide = false
		script.Parent.b.Transparency = 0.75
		script.Parent.c.CanCollide = false
		script.Parent.c.Transparency = 0.75
		script.Parent.d.CanCollide = false
		script.Parent.d.Transparency = 0.75
		script.Parent.e.CanCollide = false
		script.Parent.e.Transparency = 0.75
		script.Parent.f.CanCollide = false
		script.Parent.f.Transparency = 0.75
		else
		script.Parent.One.CanCollide = false
		script.Parent.One.Transparency = 0.75
		script.Parent.a.CanCollide = true
		script.Parent.a.Transparency = 0
		script.Parent.b.CanCollide = true
		script.Parent.b.Transparency = 0
		script.Parent.c.CanCollide = true
		script.Parent.c.Transparency = 0
		script.Parent.d.CanCollide = true
		script.Parent.d.Transparency = 0
		script.Parent.e.CanCollide = true
		script.Parent.e.Transparency = 0
		script.Parent.f.CanCollide = true
		script.Parent.f.Transparency = 0
	end
end

script.Parent.Show.Click.MouseClick:connect(act)
