local TweenService = game:GetService("TweenService")
local create = require(script.Parent.Parent:WaitForChild("Shared"):WaitForChild("Utilities"):WaitForChild("Create"))

local NotificationManager = {}
NotificationManager.__index = NotificationManager

local DEFAULT_APP_ICONS = {
	phone = { Name = "PHONE", Icon = "rbxassetid://71727318918905", Bg = Color3.fromRGB(52, 199, 89) },
	messages = { Name = "MESSAGES", Icon = "rbxassetid://108650574179237", Bg = Color3.fromRGB(52, 199, 89) },
	contacts = { Name = "CONTACTS", Icon = "rbxassetid://114778546922350", Bg = Color3.fromRGB(142, 142, 147) },
	bank = { Name = "BANK", Icon = "rbxassetid://126903961002759", Bg = Color3.fromRGB(18, 129, 91) },
	airdrop = { Name = "AIRDROP", Icon = "rbxassetid://108650574179237", Bg = Color3.fromRGB(0, 122, 255) },
	settings = { Name = "SETTINGS", Icon = "rbxassetid://71727318918905", Bg = Color3.fromRGB(142, 142, 147) },
}

local function resolveAppMeta(notification: any)
	local appId = string.lower(notification.AppId or notification.App or "")
	local title = notification.Title or ""

	if appId == "bank" or title:find("Bank") or title:find("Money") or title:find("Transfer") or title:find("Balance") or title:find("Uang") or title:find("Saldo") then
		return DEFAULT_APP_ICONS.bank
	elseif appId == "phone" or title:find("Phone") or title:find("Call") or title:find("Dial") or title:find("Panggilan") or title:find("Telepon") or title:find("📞") then
		return DEFAULT_APP_ICONS.phone
	elseif appId == "messages" or title:find("Messages") or title:find("Message") or title:find("SMS") or title:find("Pesan") or title:find("💬") then
		return DEFAULT_APP_ICONS.messages
	elseif appId == "contacts" or title:find("Contacts") or title:find("Contact") or title:find("AirDrop") or title:find("Kontak") or title:find("📡") then
		return DEFAULT_APP_ICONS.contacts
	end

	return {
		Name = string.upper(notification.AppName or notification.App or "NOTIFICATION"),
		Icon = notification.AppIcon or notification.Icon or "rbxassetid://71727318918905",
		Bg = notification.IconBg or Color3.fromRGB(18, 129, 91),
	}
end

function NotificationManager.new(screenRoot: Frame)
	return setmetatable({
		_screenRoot = screenRoot,
		_activeBanner = nil,
		_dismissTimer = nil,
	}, NotificationManager)
end

function NotificationManager:Send(
	notification: {
		AppId: string?,
		App: string?,
		AppName: string?,
		AppIcon: string?,
		Title: string?,
		Text: string?,
		Body: string?,
		Duration: number?,
	},
	onClicked: ((boolean) -> ())?,
	onDismissed: (() -> ())?
)
	if self._activeBanner then
		self._activeBanner:Destroy()
		self._activeBanner = nil
	end

	local meta = resolveAppMeta(notification)
	local duration = notification.Duration or 4.5
	local titleText = notification.Title or "Notification"
	local bodyText = notification.Body or notification.Text or ""

	-- iOS 7 White Banner Container
	local banner = create("TextButton", {
		Name = "NotificationBanner",
		AutoButtonColor = false,
		Text = "",
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.05,
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
		Color = Color3.fromRGB(215, 218, 228),
		Thickness = 1,
		Transparency = 0.2,
		Parent = banner,
	})

	-- App Icon Box
	local iconBox = create("Frame", {
		Name = "IconBox",
		BackgroundColor3 = meta.Bg,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 10, 0, 8),
		Size = UDim2.fromOffset(18, 18),
		ZIndex = 181,
		Parent = banner,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = iconBox })

	create("ImageLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		Image = meta.Icon,
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		ScaleType = Enum.ScaleType.Fit,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(12, 12),
		ZIndex = 182,
		Parent = iconBox,
	})

	-- Header Row: App Name & Timestamp
	create("TextLabel", {
		Name = "AppTag",
		BackgroundTransparency = 1,
		Font = Enum.Font.SourceSansBold,
		Text = meta.Name,
		TextColor3 = Color3.fromRGB(115, 120, 135),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 34, 0, 9),
		Size = UDim2.new(0.5, 0, 0, 14),
		ZIndex = 181,
		Parent = banner,
	})

	create("TextLabel", {
		Name = "TimeTag",
		BackgroundTransparency = 1,
		Font = Enum.Font.SourceSans,
		Text = "now",
		TextColor3 = Color3.fromRGB(142, 142, 147),
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(1, -70, 0, 9),
		Size = UDim2.new(0, 60, 0, 14),
		ZIndex = 181,
		Parent = banner,
	})

	-- Title Label
	create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Font = Enum.Font.SourceSansSemibold,
		Text = titleText,
		TextColor3 = Color3.fromRGB(24, 26, 32),
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0, 27),
		Size = UDim2.new(1, -20, 0, 14),
		ZIndex = 181,
		Parent = banner,
	})

	-- Body Label
	create("TextLabel", {
		Name = "Body",
		BackgroundTransparency = 1,
		Font = Enum.Font.SourceSans,
		Text = bodyText,
		TextColor3 = Color3.fromRGB(75, 80, 95),
		TextSize = 11,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0, 41),
		Size = UDim2.new(1, -20, 0, 13),
		ZIndex = 181,
		Parent = banner,
	})

	-- Slide In Animation
	banner.Position = UDim2.new(0.5, 0, 0, -80)
	TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 22),
	}):Play()

	local isDismissed = false
	local function dismissBanner(wasClicked: boolean)
		if isDismissed then return end
		isDismissed = true

		if banner and banner.Parent then
			local tween = TweenService:Create(banner, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, 0, 0, -80),
			})
			tween:Play()
			tween.Completed:Connect(function()
				if banner and banner.Parent then
					banner:Destroy()
				end
				if wasClicked and onClicked then
					onClicked(true)
				elseif not wasClicked and onDismissed then
					onDismissed()
				end
			end)
		end
	end

	banner.Activated:Connect(function()
		dismissBanner(true)
	end)

	task.delay(duration, function()
		if not isDismissed then
			dismissBanner(false)
		end
	end)
end

return NotificationManager
