--!strict

export type NotificationUI = ScreenGui & {
	CanvasGui: CanvasGui & {
		Frame: Frame & {
			Title: TextLabel,
			Message: TextLabel,
			ProgressBar: Frame & {
				Progress: Frame
			},
			Options: Frame & {
				Cancel: TextButton,
				OK: TextButton,
			},
			Input: TextBox,
			Submit: TextButton,
			GotIt: TextButton,
		}
	}
}

return {}
