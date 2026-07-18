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

	create("TextLabel", {
		Name = "Signal",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.02, 0),
		Size = UDim2.fromScale(0.28, 1),
		Font = Constants.Fonts.Semibold,
		Text = "ooooo  " .. (options.Carrier or "ROBLOX"),
		TextColor3 = textColor,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 41,
		Parent = bar,
	})

	local clock = create("TextLabel", {
		Name = "Clock",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromScale(0.28, 1),
		Font = Constants.Fonts.Semibold,
		TextColor3 = textColor,
		TextScaled = true,
		ZIndex = 41,
		Parent = bar,
	})

	create("TextLabel", {
		Name = "Battery",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.98, 0),
		Size = UDim2.fromScale(0.24, 1),
		Font = Constants.Fonts.Semibold,
		Text = (options.Battery or "100%") .. " []",
		TextColor3 = textColor,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 41,
		Parent = bar,
	})

	local function updateTime()
		clock.Text = DateTime.now():FormatLocalTime("h:mm a", "en-us")
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
