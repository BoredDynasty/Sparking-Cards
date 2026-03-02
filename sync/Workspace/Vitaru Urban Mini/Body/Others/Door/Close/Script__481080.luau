DoorA = script.Parent.Parent.DoorA
DoorB = script.Parent.Parent.DoorB
function onClick()
wait(3.5)
DoorA.Visible.Value = true
DoorB.Visible.Value = false
end
script.Parent.ClickDetector.MouseClick:connect(onClick)