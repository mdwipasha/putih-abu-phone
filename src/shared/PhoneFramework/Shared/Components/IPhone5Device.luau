local Constants = require(script.Parent.Parent.Constants)
local create = require(script.Parent.Parent.Utilities.Create)

local IPhone5Device = {}

local function rounded(parent: Instance, radiusScale: number)
	create("UICorner", {
		CornerRadius = UDim.new(radiusScale, 0),
		Parent = parent,
	})
end

local function stroke(parent: Instance, color: Color3, thickness: number, transparency: number?)
	create("UIStroke", {
		Color = color,
		Thickness = thickness,
		Transparency = transparency or 0,
		Parent = parent,
	})
end

function IPhone5Device.new(parent: Instance)
	local root = create("Frame", {
		Name = "PhoneRoot",
		AnchorPoint = Constants.Device.AnchorPoint,
		BackgroundTransparency = 1,
		Position = Constants.Device.ClosedPosition,
		Rotation = -5,
		Size = Constants.Device.Size,
		Visible = false,
		Parent = parent,
	})

	create("UIAspectRatioConstraint", {
		AspectRatio = Constants.Device.AspectRatio,
		DominantAxis = Enum.DominantAxis.Height,
		Parent = root,
	})
	create("UISizeConstraint", {
		MinSize = Vector2.new(0, Constants.Device.MinHeight),
		MaxSize = Vector2.new(10000, Constants.Device.MaxHeight),
		Parent = root,
	})

	local shadow = create("Frame", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.72,
		Position = UDim2.fromScale(0.515, 0.525),
		Size = UDim2.fromScale(0.99, 0.985),
		ZIndex = 1,
		Parent = root,
	})
	rounded(shadow, 0.115)

	local body = create("Frame", {
		Name = "Body",
		BackgroundColor3 = Constants.Device.BodyColor,
		ClipsDescendants = false,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
		Parent = root,
	})
	rounded(body, 0.115)
	stroke(body, Constants.Device.EdgeColor, 2)
	create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.43, Constants.Device.BodyColor),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(224, 224, 220)),
		}),
		Rotation = 90,
		Parent = body,
	})

	local glassInset = create("Frame", {
		Name = "GlassInset",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.22,
		Position = UDim2.fromScale(0.014, 0.008),
		Size = UDim2.fromScale(0.974, 0.982),
		ZIndex = 3,
		Parent = body,
	})
	rounded(glassInset, 0.105)
	stroke(glassInset, Color3.fromRGB(215, 215, 212), 1, 0.5)

	local innerRim = create("Frame", {
		Name = "InnerMetalRim",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.027, 0.018),
		Size = UDim2.fromScale(0.946, 0.964),
		ZIndex = 4,
		Parent = body,
	})
	rounded(innerRim, 0.098)
	stroke(innerRim, Color3.fromRGB(236, 222, 186), 1, 0.22)

	local screen = create("Frame", {
		Name = "Screen",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		ClipsDescendants = true,
		Position = Constants.Device.ScreenRect.Position,
		Size = Constants.Device.ScreenRect.Size,
		ZIndex = 10,
		Parent = body,
	})
	rounded(screen, 0.012)
	stroke(screen, Color3.fromRGB(24, 24, 26), 2, 0.05)
	create("UIAspectRatioConstraint", {
		AspectRatio = Constants.Screen.AspectRatio,
		DominantAxis = Enum.DominantAxis.Width,
		Parent = screen,
	})

	local screenContent = create("Frame", {
		Name = "ScreenContent",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		ClipsDescendants = true,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 11,
		Parent = screen,
	})
	rounded(screenContent, 0.012)

	local screenDimmer = create("Frame", {
		Name = "ScreenDimmer",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 200,
		Parent = screen,
	})

	local camera = create("Frame", {
		Name = "FrontCamera",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(15, 17, 22),
		Position = UDim2.fromScale(0.5, 0.048),
		Size = UDim2.fromScale(0.035, 0.016),
		ZIndex = 5,
		Parent = body,
	})
	rounded(camera, 1)
	stroke(camera, Color3.fromRGB(80, 97, 116), 1, 0.3)

	local sensor = create("Frame", {
		Name = "ProximitySensor",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(31, 32, 36),
		Position = UDim2.fromScale(0.334, 0.086),
		Size = UDim2.fromScale(0.026, 0.012),
		ZIndex = 5,
		Parent = body,
	})
	rounded(sensor, 1)

	local speaker = create("Frame", {
		Name = "Speaker",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(26, 27, 30),
		Position = UDim2.fromScale(0.5, 0.086),
		Size = UDim2.fromScale(0.205, 0.012),
		ZIndex = 5,
		Parent = body,
	})
	rounded(speaker, 1)
	stroke(speaker, Color3.fromRGB(165, 165, 160), 1, 0.2)

	local homeOuter = create("Frame", {
		Name = "HomeButtonRing",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(235, 235, 232),
		Position = UDim2.fromScale(0.5, 0.920),
		Size = UDim2.fromScale(0.205, 0.097),
		ZIndex = 5,
		Parent = body,
	})
	rounded(homeOuter, 1)
	stroke(homeOuter, Color3.fromRGB(236, 222, 186), 1, 0.1)

	local homeInner = create("Frame", {
		Name = "HomeButton",
		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(248, 248, 245),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.78, 0.78),
		ZIndex = 6,
		Parent = homeOuter,
	})
	rounded(homeInner, 1)

	local leftSwitch = create("Frame", {
		Name = "RingSilentSwitch",
		BackgroundColor3 = Color3.fromRGB(205, 205, 202),
		Position = UDim2.fromScale(-0.016, 0.16),
		Size = UDim2.fromScale(0.018, 0.055),
		ZIndex = 1,
		Parent = root,
	})
	rounded(leftSwitch, 0.2)

	for index, y in ipairs({ 0.275, 0.36 }) do
		local volumeButton = create("Frame", {
			Name = "VolumeButton" .. index,
			BackgroundColor3 = Color3.fromRGB(205, 205, 202),
			Position = UDim2.fromScale(-0.018, y),
			Size = UDim2.fromScale(0.02, 0.075),
			ZIndex = 1,
			Parent = root,
		})
		rounded(volumeButton, 0.2)
	end

	return {
		Root = root,
		Body = body,
		Screen = screen,
		ScreenContent = screenContent,
		Dimmer = screenDimmer,
		HomeButton = homeInner,
	}
end

return IPhone5Device
