local TweenService = game:GetService("TweenService")
local create = require(script.Parent.Parent:WaitForChild("Shared"):WaitForChild("Utilities"):WaitForChild("Create"))

local NotificationManager = {}
NotificationManager.__index = NotificationManager

function NotificationManager.new(screenRoot: Frame)
	return setmetatable({
		_screenRoot = screenRoot,
		_activeBanner = nil,
	}, NotificationManager)
end

function NotificationManager:Send(notification: {
	App: string?,
	Title: string?,
	Body: string?,
})
	if self._activeBanner then
		self._activeBanner:Destroy()
		self._activeBanner = nil
	end

	local banner = create("Frame", {
		Name = "NotificationBanner",
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0, -80),
		Size = UDim2.new(0.92, 0, 0, 58),
		ZIndex = 180,
		Parent = self._screenRoot,
	})
	self._activeBanner = banner

	create("UICorner", {
		CornerRadius = UDim.new(0, 14),
		Parent = banner,
	})

	create("UIStroke", {
		Color = Color3.fromRGB(225, 228, 235),
		Thickness = 1,
		Transparency = 0,
		Parent = banner,
	})

	-- Header Row: App Tag & Time
	local appText = notification.App or "NOTIFIKASI"
	create("TextLabel", {
		Name = "AppTag",
		BackgroundTransparency = 1,
		Font = Enum.Font.SourceSansSemibold,
		Text = string.upper(appText),
		TextColor3 = Color3.fromRGB(140, 145, 158),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 14, 0, 7),
		Size = UDim2.new(0, 120, 0, 12),
		ZIndex = 181,
		Parent = banner,
	})

	create("TextLabel", {
		Name = "TimeTag",
		BackgroundTransparency = 1,
		Font = Enum.Font.SourceSans,
		Text = "Sekarang",
		TextColor3 = Color3.fromRGB(160, 165, 175),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -74, 0, 7),
		Size = UDim2.new(0, 60, 0, 12),
		ZIndex = 181,
		Parent = banner,
	})

	-- Title Label (Left aligned at 14px)
	create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Font = Enum.Font.SourceSansSemibold,
		Text = notification.Title or "Notifikasi",
		TextColor3 = Color3.fromRGB(20, 26, 38),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 14, 0, 21),
		Size = UDim2.new(1, -28, 0, 16),
		ZIndex = 181,
		Parent = banner,
	})

	-- Body Label (Left aligned at 14px)
	create("TextLabel", {
		Name = "Body",
		BackgroundTransparency = 1,
		Font = Enum.Font.SourceSans,
		Text = notification.Body or "",
		TextColor3 = Color3.fromRGB(90, 98, 112),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 14, 0, 38),
		Size = UDim2.new(1, -28, 0, 14),
		ZIndex = 181,
		Parent = banner,
	})

	-- Smooth Slide In Animation
	banner.Position = UDim2.new(0.5, 0, 0, -80)
	TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 24),
	}):Play()

	-- Auto Dismiss after 4 seconds with smooth slide up
	task.delay(4, function()
		if banner and banner.Parent then
			local tween = TweenService:Create(banner, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, 0, 0, -80),
			})
			tween:Play()
			tween.Completed:Connect(function()
				if banner and banner.Parent then
					banner:Destroy()
				end
			end)
		end
	end)
end

return NotificationManager
