local Constants = require(script.Parent.Parent.Constants)
local StatusBar = require(script.Parent.StatusBar)
local create = require(script.Parent.Parent.Utilities.Create)

local SimpleAppView = {}

function SimpleAppView.new(context: any, title: string, color: Color3)
	local root = create("Frame", {
		Name = title .. "App",
		BackgroundColor3 = Color3.fromRGB(246, 246, 246),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
	})
	StatusBar.new(root, { Light = false, Battery = "100%" })

	local nav = create("Frame", {
		Name = "NavigationBar",
		BackgroundColor3 = Color3.fromRGB(248, 248, 248),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, Constants.Screen.StatusBarHeight),
		Size = UDim2.fromScale(1, 0.08),
		ZIndex = 51,
		Parent = root,
	})

	local back = create("TextButton", {
		Name = "BackButton",
		AutoButtonColor = true,
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "<",
		TextColor3 = Color3.fromRGB(0, 122, 255),
		TextScaled = true,
		Position = UDim2.fromScale(0.02, 0.15),
		Size = UDim2.fromScale(0.12, 0.7),
		ZIndex = 52,
		Parent = nav,
	})
	back.Activated:Connect(context.CloseCurrentApp)

	create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Semibold,
		Text = title,
		TextColor3 = Color3.fromRGB(20, 20, 20),
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.5, 0.55),
		ZIndex = 52,
		Parent = nav,
	})

	local icon = create("Frame", {
		Name = "AppMark",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = color,
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromScale(0.34, 0.19),
		ZIndex = 51,
		Parent = root,
	})
	create("UICorner", {
		CornerRadius = UDim.new(0.2, 0),
		Parent = icon,
	})

	create("TextLabel", {
		Name = "EmptyState",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = title,
		TextColor3 = Color3.fromRGB(80, 80, 80),
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.55),
		Size = UDim2.fromScale(0.6, 0.06),
		ZIndex = 51,
		Parent = root,
	})

	return root
end

return SimpleAppView
