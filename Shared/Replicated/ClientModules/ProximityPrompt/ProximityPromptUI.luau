export type ProximityPromptUI = ScreenGui & {
	CanvasGroup: CanvasGroup & {
		UIPadding: UIPadding;
		Primary: Frame & {
			UICorner: UICorner;
			UIPadding: UIPadding;
			UIStroke: UIStroke;
			Keybind: TextLabel & {
				UITextSizeConstraint: UITextSizeConstraint;
			};
		};
		Secondary: Frame & {
			UICorner: UICorner;
			UIPadding: UIPadding;
			UIStroke: UIStroke;
			Object: TextLabel & {
				UITextSizeConstraint: UITextSizeConstraint;
			};
		};
		Tertiary: Frame & {
			UICorner: UICorner;
			UIPadding: UIPadding;
			UIStroke: UIStroke;
			Action: TextLabel & {
				UITextSizeConstraint: UITextSizeConstraint;
			};
		};
		ProgressBar: Frame & {
			UICorner: UICorner;
			Progress: Frame & {
				UICorner: UICorner;
			};
		};
	};
};

return nil
