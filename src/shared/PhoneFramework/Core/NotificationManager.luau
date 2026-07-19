local create = require(script.Parent.Parent:WaitForChild("Shared"):WaitForChild("Utilities"):WaitForChild("Create"))

local NotificationManager = {}
NotificationManager.__index = NotificationManager

function NotificationManager.new(screenRoot: Frame)
	return setmetatable({
		_screenRoot = screenRoot,
		_queue = {},
	}, NotificationManager)
end

function NotificationManager:Send(notification: { Title: string?, Body: string? })
	local banner = create("Frame", {
		Name = "NotificationBanner",
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(246, 246, 246),
		BackgroundTransparency = 0.08,
		Position = UDim2.fromScale(0.5, 0.055),
		Size = UDim2.fromScale(0.92, 0.105),
		ZIndex = 180,
		Parent = self._screenRoot,
	})
	create("UICorner", {
		CornerRadius = UDim.new(0.12, 0),
		Parent = banner,
	})
	create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Font = Enum.Font.SourceSansSemibold,
		Text = notification.Title or "Notification",
		TextColor3 = Color3.fromRGB(20, 20, 20),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.05, 0.12),
		Size = UDim2.fromScale(0.9, 0.35),
		ZIndex = 181,
		Parent = banner,
	})
	create("TextLabel", {
		Name = "Body",
		BackgroundTransparency = 1,
		Font = Enum.Font.SourceSans,
		Text = notification.Body or "",
		TextColor3 = Color3.fromRGB(45, 45, 45),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.05, 0.5),
		Size = UDim2.fromScale(0.9, 0.32),
		ZIndex = 181,
		Parent = banner,
	})

	task.delay(3, function()
		if banner.Parent then
			banner:Destroy()
		end
	end)
end

return NotificationManager
