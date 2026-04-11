state = script.Parent.State

function act()
	state.Value = not state.Value
	if state.Value == true then
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
		script.Parent.g.CanCollide = true
		script.Parent.g.Transparency = 0
		script.Parent.h.CanCollide = true
		script.Parent.h.Transparency = 0
		script.Parent.i.CanCollide = true
		script.Parent.i.Transparency = 0
		script.Parent.j.CanCollide = true
		script.Parent.j.Transparency = 0
		script.Parent.k.CanCollide = true
		script.Parent.k.Transparency = 0
		else
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
		script.Parent.g.CanCollide = false
		script.Parent.g.Transparency = 0.75
		script.Parent.h.CanCollide = false
		script.Parent.h.Transparency = 0.75
		script.Parent.i.CanCollide = false
		script.Parent.i.Transparency = 0.75
		script.Parent.j.CanCollide = false
		script.Parent.j.Transparency = 0.75
		script.Parent.k.CanCollide = false
		script.Parent.k.Transparency = 0.75
	end
end

script.Parent.Show.Click.MouseClick:connect(act)
