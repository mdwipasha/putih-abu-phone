local Constants = require(script.Parent.Parent.Constants)
local create = require(script.Parent.Parent.Utilities.Create)

local AppIcon = {}

local function rounded(parent: Instance, radius: number)
	create("UICorner", {
		CornerRadius = UDim.new(radius, 0),
		Parent = parent,
	})
end

function AppIcon.new(parent: Instance, app: any, activated: () -> ())
	local button = create("TextButton", {
		Name = app.Id .. "Icon",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 30,
		Parent = parent,
	})

	local tile = create("Frame", {
		Name = "Tile",
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = app.Icon.Background,
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromScale(0.82, 0.66),
		ZIndex = 31,
		Parent = button,
	})
	rounded(tile, 0.22)

	create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.45, app.Icon.Background),
			ColorSequenceKeypoint.new(1, app.Icon.Background:Lerp(Color3.fromRGB(0, 0, 0), 0.18)),
		}),
		Rotation = 90,
		Parent = tile,
	})

	create("TextLabel", {
		Name = "Glyph",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Light,
		Text = app.Icon.Glyph,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		Size = UDim2.fromScale(0.78, 0.78),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = 32,
		Parent = tile,
	})

	create("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = app.Name,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		TextStrokeTransparency = 0.58,
		Position = UDim2.fromScale(-0.1, 0.69),
		Size = UDim2.fromScale(1.2, 0.28),
		ZIndex = 31,
		Parent = button,
	})

	button.Activated:Connect(activated)

	return button
end

return AppIcon
