local Constants = {}

Constants.RemoteName = "PhoneFrameworkRemote"

Constants.Input = {
	ToggleKey = Enum.KeyCode.P,
	CloseKey = Enum.KeyCode.Backspace,
}

Constants.Device = {
	AspectRatio = 0.473,
	AnchorPoint = Vector2.new(1, 1),
	ClosedPosition = UDim2.fromScale(1.08, 1.18),
	OpenPosition = UDim2.fromScale(0.985, 0.955),
	Size = UDim2.fromScale(0.205, 0.78),
	MinHeight = 430,
	MaxHeight = 690,
	BodyColor = Color3.fromRGB(247, 247, 245),
	EdgeColor = Color3.fromRGB(198, 174, 128),
	ScreenRect = {
		Position = UDim2.fromScale(0.075, 0.138),
		Size = UDim2.fromScale(0.85, 0.735),
	},
}

Constants.Screen = {
	AspectRatio = 370 / 638,
	StatusBarHeight = 0.035,
	WallpaperTop = Color3.fromRGB(24, 22, 46),
	WallpaperMid = Color3.fromRGB(37, 80, 98),
	WallpaperBottom = Color3.fromRGB(10, 28, 45),
	DockHeight = 0.145,
	IconSize = 0.194,
	GridLeft = 0.044,
	GridTop = 0.066,
	GridXGap = 0.053,
	GridYGap = 0.056,
}

Constants.Animation = {
	OpenTime = 0.38,
	CloseTime = 0.24,
	ScreenWakeTime = 0.16,
	AppTime = 0.22,
	EasingStyle = Enum.EasingStyle.Quart,
	EasingDirection = Enum.EasingDirection.Out,
}

Constants.Fonts = {
	Regular = Enum.Font.SourceSans,
	Light = Enum.Font.SourceSansLight,
	Semibold = Enum.Font.SourceSansSemibold,
}

return Constants
