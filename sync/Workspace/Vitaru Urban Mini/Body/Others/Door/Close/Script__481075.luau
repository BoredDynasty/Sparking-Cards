function onClicked()
	script.Parent.Doorsclosing:Play()
	wait(1)
	script.Parent.Door:Play()
	wait(1.5)
	script.Parent.Doorsclosing:Stop()
end
script.Parent.ClickDetector.MouseClick:connect(onClicked)