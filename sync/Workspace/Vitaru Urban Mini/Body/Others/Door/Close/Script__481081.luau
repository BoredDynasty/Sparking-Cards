function onClicked()
	script.Parent.Doorsclosing1:Play()
	wait(1)
	script.Parent.Door2:Play()
	wait(1.5)
	script.Parent.Doorsclosing1:Stop()
end
script.Parent.ClickDetector.MouseClick:connect(onClicked)