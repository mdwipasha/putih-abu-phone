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
	OpenPosition = UDim2.fromScale(0.985, 0.965),
	Size = UDim2.fromScale(0.245, 0.78),
	MinHeight = 560,
	MaxHeight = 760,
	BodyColor = Color3.fromRGB(244, 244, 241),
	EdgeColor = Color3.fromRGB(188, 188, 184),
	ScreenRect = {
		Position = UDim2.fromScale(0.0835, 0.142),
		Size = UDim2.fromScale(0.833, 0.747),
	},
}

Constants.Screen = {
	AspectRatio = 320 / 568,
	StatusBarHeight = 0.035,
	WallpaperTop = Color3.fromRGB(24, 22, 46),
	WallpaperMid = Color3.fromRGB(37, 80, 98),
	WallpaperBottom = Color3.fromRGB(10, 28, 45),
	DockHeight = 0.16,
	IconSize = 0.165,
	GridLeft = 0.055,
	GridTop = 0.082,
	GridXGap = 0.061,
	GridYGap = 0.067,
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
