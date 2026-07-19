local Constants = require(script.Parent.Parent.Constants)
local create = require(script.Parent.Parent.Utilities.Create)

local AppIcon = {}

local function rounded(parent: Instance, radius: number)
	create("UICorner", {
		CornerRadius = UDim.new(radius, 0),
		Parent = parent,
	})
end

local function addCircle(parent: Instance, name: string, position: UDim2, size: UDim2, color: Color3, zIndex: number)
	local circle = create("Frame", {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = color,
		Position = position,
		Size = size,
		ZIndex = zIndex,
		Parent = parent,
	})
	rounded(circle, 1)
	return circle
end

local function drawFallbackArt(tile: Instance, app: any)
	if app.Id == "messages" then
		local bubble = create("Frame", {
			Name = "Bubble",
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.fromScale(0.2, 0.24),
			Size = UDim2.fromScale(0.6, 0.42),
			ZIndex = 33,
			Parent = tile,
		})
		rounded(bubble, 0.4)
		create("Frame", {
			Name = "Tail",
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.fromScale(0.33, 0.56),
			Rotation = -24,
			Size = UDim2.fromScale(0.18, 0.16),
			ZIndex = 32,
			Parent = tile,
		})
	elseif app.Id == "camera" then
		create("Frame", {
			Name = "CameraBody",
			BackgroundColor3 = Color3.fromRGB(52, 52, 52),
			Position = UDim2.fromScale(0.18, 0.28),
			Size = UDim2.fromScale(0.64, 0.43),
			ZIndex = 33,
			Parent = tile,
		})
		addCircle(tile, "Lens", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.28, 0.28), Color3.fromRGB(25, 25, 25), 34)
		addCircle(
			tile,
			"Glass",
			UDim2.fromScale(0.5, 0.5),
			UDim2.fromScale(0.17, 0.17),
			Color3.fromRGB(112, 139, 155),
			35
		)
	elseif app.Id == "phone" then
		create("Frame", {
			Name = "Receiver",
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Position = UDim2.fromScale(0.33, 0.2),
			Rotation = -38,
			Size = UDim2.fromScale(0.28, 0.62),
			ZIndex = 33,
			Parent = tile,
		})
	elseif app.Id == "settings" then
		addCircle(
			tile,
			"GearOuter",
			UDim2.fromScale(0.5, 0.5),
			UDim2.fromScale(0.58, 0.58),
			Color3.fromRGB(115, 115, 115),
			33
		)
		addCircle(
			tile,
			"GearInner",
			UDim2.fromScale(0.5, 0.5),
			UDim2.fromScale(0.3, 0.3),
			Color3.fromRGB(210, 210, 210),
			34
		)
	elseif app.Id == "music" then
		local stem = create("Frame", {
			Name = "NoteStem",
			BackgroundColor3 = Color3.fromRGB(234, 56, 120),
			Position = UDim2.fromScale(0.56, 0.22),
			Size = UDim2.fromScale(0.08, 0.42),
			ZIndex = 33,
			Parent = tile,
		})
		rounded(stem, 0.2)
		addCircle(
			tile,
			"NoteHead",
			UDim2.fromScale(0.45, 0.68),
			UDim2.fromScale(0.25, 0.18),
			Color3.fromRGB(234, 56, 120),
			33
		)
	elseif app.Id == "gallery" then
		for index, color in ipairs({
			Color3.fromRGB(240, 75, 74),
			Color3.fromRGB(244, 166, 42),
			Color3.fromRGB(79, 176, 86),
			Color3.fromRGB(54, 151, 220),
			Color3.fromRGB(142, 85, 190),
		}) do
			addCircle(
				tile,
				"Petal" .. index,
				UDim2.fromScale(0.5 + math.cos(index * 1.26) * 0.16, 0.5 + math.sin(index * 1.26) * 0.16),
				UDim2.fromScale(0.22, 0.22),
				color,
				33
			)
		end
	elseif app.Id == "calendar" then
		create("TextLabel", {
			Name = "CalendarDay",
			BackgroundTransparency = 1,
			Font = Constants.Fonts.Regular,
			Text = "Tuesday",
			TextColor3 = Color3.fromRGB(235, 48, 54),
			TextScaled = true,
			Position = UDim2.fromScale(0.12, 0.13),
			Size = UDim2.fromScale(0.76, 0.2),
			ZIndex = 33,
			Parent = tile,
		})
		create("TextLabel", {
			Name = "CalendarDate",
			BackgroundTransparency = 1,
			Font = Constants.Fonts.Light,
			Text = "11",
			TextColor3 = Color3.fromRGB(50, 50, 50),
			TextScaled = true,
			Position = UDim2.fromScale(0.15, 0.28),
			Size = UDim2.fromScale(0.7, 0.52),
			ZIndex = 33,
			Parent = tile,
		})
	elseif app.Id == "clock" then
		addCircle(
			tile,
			"ClockFace",
			UDim2.fromScale(0.5, 0.5),
			UDim2.fromScale(0.64, 0.64),
			Color3.fromRGB(248, 248, 248),
			33
		)
		create("Frame", {
			Name = "HourHand",
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			Position = UDim2.fromScale(0.5, 0.5),
			Rotation = 34,
			Size = UDim2.fromScale(0.035, 0.2),
			ZIndex = 34,
			Parent = tile,
		})
		create("Frame", {
			Name = "MinuteHand",
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			Position = UDim2.fromScale(0.5, 0.5),
			Rotation = -88,
			Size = UDim2.fromScale(0.026, 0.28),
			ZIndex = 34,
			Parent = tile,
		})
	elseif app.Id == "contacts" then
		addCircle(
			tile,
			"Head",
			UDim2.fromScale(0.48, 0.39),
			UDim2.fromScale(0.27, 0.24),
			Color3.fromRGB(140, 140, 140),
			33
		)
		local body = create("Frame", {
			Name = "Shoulders",
			BackgroundColor3 = Color3.fromRGB(140, 140, 140),
			Position = UDim2.fromScale(0.28, 0.54),
			Size = UDim2.fromScale(0.4, 0.22),
			ZIndex = 33,
			Parent = tile,
		})
		rounded(body, 0.35)
		for index, color in ipairs({
			Color3.fromRGB(97, 180, 230),
			Color3.fromRGB(113, 201, 99),
			Color3.fromRGB(246, 197, 69),
		}) do
			create("Frame", {
				Name = "IndexTab" .. index,
				BackgroundColor3 = color,
				Position = UDim2.fromScale(0.78, 0.18 + index * 0.17),
				Size = UDim2.fromScale(0.12, 0.12),
				ZIndex = 33,
				Parent = tile,
			})
		end
	elseif app.Id == "bank" then
		create("Frame", {
			Name = "Card",
			BackgroundColor3 = Color3.fromRGB(245, 245, 255),
			Position = UDim2.fromScale(0.17, 0.3),
			Size = UDim2.fromScale(0.66, 0.42),
			ZIndex = 33,
			Parent = tile,
		})
		create("Frame", {
			Name = "Stripe",
			BackgroundColor3 = Color3.fromRGB(35, 117, 190),
			Position = UDim2.fromScale(0.17, 0.41),
			Size = UDim2.fromScale(0.66, 0.1),
			ZIndex = 34,
			Parent = tile,
		})
	end
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

	local tile = create("ImageLabel", {
		Name = "Tile",
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = app.Icon.Background,
		Position = UDim2.fromScale(0.5, 0),
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromScale(0.78, 0.62),
		Image = app.Icon.Image or "",
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

	if not app.Icon.Image then
		drawFallbackArt(tile, app)
	end

	create("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = app.Name,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		TextStrokeTransparency = 0.58,
		Position = UDim2.fromScale(-0.16, 0.65),
		Size = UDim2.fromScale(1.32, 0.15),
		ZIndex = 31,
		Parent = button,
	})

	button.Activated:Connect(activated)

	return button
end

return AppIcon
