local RunService = game:GetService("RunService")

local Constants = require(script.Parent.Parent.Constants)
local create = require(script.Parent.Parent.Utilities.Create)

local StatusBar = {}

function StatusBar.new(parent: Instance, options: { Light: boolean?, Carrier: string?, Battery: string? }?)
	options = options or {}
	local textColor = if options.Light == false then Color3.fromRGB(20, 20, 20) else Color3.fromRGB(255, 255, 255)

	local bar = create("Frame", {
		Name = "StatusBar",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, Constants.Screen.StatusBarHeight),
		ZIndex = 40,
		Parent = parent,
	})

	-- local signal = create("Frame", {
	-- 	Name = "SignalDots",
	-- 	BackgroundTransparency = 1,
	-- 	Position = UDim2.fromScale(0.02, 0),
	-- 	Size = UDim2.fromScale(0.14, 1),
	-- 	ZIndex = 41,
	-- 	Parent = bar,
	-- })
	-- for index = 1, 5 do
	-- 	local dot = create("Frame", {
	-- 		Name = "Dot" .. index,
	-- 		AnchorPoint = Vector2.new(0.5, 0.5),
	-- 		BackgroundColor3 = textColor,
	-- 		BackgroundTransparency = if index <= 4 then 0 else 0.58,
	-- 		Position = UDim2.fromScale(0.08 + (index - 1) * 0.15, 0.5),
	-- 		Size = UDim2.fromScale(0.105, 0.28),
	-- 		ZIndex = 42,
	-- 		Parent = signal,
	-- 	})
	-- 	create("UICorner", {
	-- 		CornerRadius = UDim.new(1, 0),
	-- 		Parent = dot,
	-- 	})
	-- end

	local carrier = create("TextLabel", {
		Name = "Carrier",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.02, 0),
		Size = UDim2.fromScale(0.22, 0.84),
		Font = Constants.Fonts.Semibold,
		-- Text = options.Carrier or "Putih-Abu",
		Text = "Putih-Abu",
		TextColor3 = textColor,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 41,
		Parent = bar,
	})
	create("UITextSizeConstraint", {
		MinTextSize = 6,
		MaxTextSize = 10,
		Parent = carrier,
	})

	local clock = create("TextLabel", {
		Name = "Clock",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.08),
		Size = UDim2.fromScale(0.22, 0.84),
		Font = Constants.Fonts.Semibold,
		TextColor3 = textColor,
		TextScaled = true,
		ZIndex = 41,
		Parent = bar,
	})
	create("UITextSizeConstraint", {
		MinTextSize = 6,
		MaxTextSize = 10,
		Parent = clock,
	})

	local batteryText = create("TextLabel", {
		Name = "Battery",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.87, 0.08),
		Size = UDim2.fromScale(0.15, 0.84),
		Font = Constants.Fonts.Semibold,
		Text = options.Battery or "100%",
		TextColor3 = textColor,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 41,
		Parent = bar,
	})
	create("UITextSizeConstraint", {
		MinTextSize = 6,
		MaxTextSize = 10,
		Parent = batteryText,
	})

	local battery = create("Frame", {
		Name = "BatteryIcon",
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.97, 0.55),
		Size = UDim2.fromScale(0.068, 0.48),
		ZIndex = 41,
		Parent = bar,
	})
	create("UIStroke", {
		Color = textColor,
		Thickness = 1,
		Transparency = 0.05,
		Parent = battery,
	})
	create("Frame", {
		Name = "Fill",
		BackgroundColor3 = textColor,
		BackgroundTransparency = 0.08,
		Position = UDim2.fromScale(0.1, 0.18),
		Size = UDim2.fromScale(0.76, 0.64),
		ZIndex = 42,
		Parent = battery,
	})
	create("Frame", {
		Name = "Cap",
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = textColor,
		Position = UDim2.fromScale(1.08, 0.51),
		Size = UDim2.fromScale(0.12, 0.36),
		ZIndex = 42,
		Parent = battery,
	})

	local function updateTime()
		clock.Text = DateTime.now():FormatLocalTime("HH:mm", "en-us")
	end

	updateTime()
	local connection = RunService.Heartbeat:Connect(function()
		local second = DateTime.now():ToLocalTime().Second
		if second == 0 then
			updateTime()
		end
	end)

	bar.Destroying:Connect(function()
		connection:Disconnect()
	end)

	return bar
end

return StatusBar
