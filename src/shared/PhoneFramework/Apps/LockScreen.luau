local Constants = require(script.Parent.Parent.Shared.Constants)
local StatusBar = require(script.Parent.Parent.Shared.Components.StatusBar)
local Wallpaper = require(script.Parent.Parent.Shared.Components.Wallpaper)
local create = require(script.Parent.Parent.Shared.Utilities.Create)

local LockScreen = {
	Id = "lock",
	Name = "Lock",
	Icon = { Background = Color3.fromRGB(70, 70, 76), Glyph = "LOCK" },
	Order = -2,
	IsSystem = true,
}

function LockScreen.Create(context: any)
	local root = create("Frame", {
		Name = "LockScreen",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 20,
	})

	Wallpaper.new(root, "Lock")
	StatusBar.new(root, { Light = true, Carrier = "", Battery = "100%" })

	local timeText = create("TextLabel", {
		Name = "Time",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Light,
		Text = DateTime.now():FormatLocalTime("h:mm", "en-us"),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.105),
		Size = UDim2.fromScale(0.72, 0.13),
		ZIndex = 30,
		Parent = root,
	})

	create("TextLabel", {
		Name = "Date",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = DateTime.now():FormatLocalTime("dddd, MMMM D", "en-us"),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.23),
		Size = UDim2.fromScale(0.8, 0.042),
		ZIndex = 30,
		Parent = root,
	})

	local slider = create("TextButton", {
		Name = "SlideToUnlock",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.62,
		Font = Constants.Fonts.Light,
		Text = "slide to unlock",
		TextColor3 = Color3.fromRGB(225, 225, 225),
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.905),
		Size = UDim2.fromScale(0.72, 0.068),
		ZIndex = 35,
		Parent = root,
	})
	create("UICorner", {
		CornerRadius = UDim.new(0.12, 0),
		Parent = slider,
	})
	slider.Activated:Connect(context.Unlock)

	create("TextLabel", {
		Name = "Chevron",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = ">",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		Position = UDim2.fromScale(0.06, 0.11),
		Size = UDim2.fromScale(0.16, 0.76),
		ZIndex = 36,
		Parent = slider,
	})

	create("TextButton", {
		Name = "CameraShortcut",
		AnchorPoint = Vector2.new(1, 1),
		AutoButtonColor = true,
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "[]",
		TextColor3 = Color3.fromRGB(220, 220, 220),
		TextScaled = true,
		Position = UDim2.fromScale(0.96, 0.975),
		Size = UDim2.fromScale(0.11, 0.055),
		ZIndex = 35,
		Parent = root,
	}).Activated:Connect(function()
		context.Unlock()
		context.OpenApp("camera")
	end)

	task.spawn(function()
		while root.Parent do
			timeText.Text = DateTime.now():FormatLocalTime("h:mm", "en-us")
			task.wait(10)
		end
	end)

	return root
end

return LockScreen
