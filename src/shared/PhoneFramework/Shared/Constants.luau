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
		Position = UDim2.fromScale(0.07, 0.13),
		Size = UDim2.fromScale(0.86, 0.75),
	},
}

Constants.Screen = {
	AspectRatio = 320 / 568,
	StatusBarHeight = 0.036,
	WallpaperTop = Color3.fromRGB(24, 22, 46),
	WallpaperMid = Color3.fromRGB(37, 80, 98),
	WallpaperBottom = Color3.fromRGB(10, 28, 45),
	DockHeight = 0.175,
	IconSize = 0.2,
	GridLeft = 0.045,
	GridTop = 0.065,
	GridXGap = 0.035,
	GridYGap = 0.01,
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
