local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local root = script.Parent.Parent
local Constants = require(root:WaitForChild("Shared"):WaitForChild("Constants"))
local StatusBar = require(root:WaitForChild("Shared"):WaitForChild("Components"):WaitForChild("StatusBar"))
local create = require(root:WaitForChild("Shared"):WaitForChild("Utilities"):WaitForChild("Create"))

local SettingsApp = {
	Id = "settings",
	Name = "Settings",
	Icon = { 
		Background = Color3.fromRGB(115, 115, 122), 
		Image = "rbxassetid://129638627110007",
	},
	Order = 70,
}

local PRESET_WALLPAPERS = {
	{ name = "iOS 7 Nebula", asset = "rbxassetid://103030063690728" },
	{ name = "iOS 7 Ocean", asset = "rbxassetid://136578458499742" },
	{ name = "Naruto", asset = "rbxassetid://115291664497394" },
	{ name = "Gojo", asset = "rbxassetid://133470515272434" },
}

function SettingsApp.Create(context: any)
	local player = Players.LocalPlayer
	local saveService = context.Services.SaveService
	local photoService = context.Services.PhotoService

	local rootFrame = create("Frame", {
		Name = "SettingsApp",
		BackgroundColor3 = Color3.fromRGB(239, 239, 244),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
	})

	StatusBar.new(rootFrame, { Light = false, Carrier = "Putih-Abu", Battery = "100%", ZIndex = 100 })

	-- ─── TOP NAVIGATION BAR ───────────────────────────────────────
	local navBar = create("Frame", {
		Name = "NavigationBar",
		BackgroundColor3 = Color3.fromRGB(248, 248, 248),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 64),
		ZIndex = 52,
		Parent = rootFrame,
	})

	create("Frame", {
		Name = "Separator",
		BackgroundColor3 = Color3.fromRGB(200, 200, 205),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -1),
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 53,
		Parent = navBar,
	})

	local backBtn = create("TextButton", {
		Name = "BackButton",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "く",
		TextColor3 = Color3.fromRGB(0, 122, 255),
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0, 28),
		Size = UDim2.new(0, 60, 0, 26),
		ZIndex = 53,
		Parent = navBar,
	})

	backBtn.Activated:Connect(function()
		context.CloseCurrentApp()
	end)

	create("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Semibold,
		Text = "Settings",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 16,
		Position = UDim2.new(0.3, 0, 0, 28),
		Size = UDim2.new(0.4, 0, 0, 26),
		ZIndex = 53,
		Parent = navBar,
	})

	-- ─── SCROLLING SETTINGS CONTAINER ─────────────────────────────
	local scrollFrame = create("ScrollingFrame", {
		Name = "SettingsScroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 66),
		Size = UDim2.new(1, 0, 1, -66),
		ScrollBarThickness = 3,
		CanvasSize = UDim2.new(0, 0, 0, 680),
		Parent = rootFrame,
	})

	local listLayout = create("UIListLayout", {
		Padding = UDim.new(0, 12),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = scrollFrame,
	})

	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 24)
	end)

	-- Helper: Create Section Header Label
	local function createSectionHeader(titleText: string, order: number)
		local headerFrame = create("Frame", {
			Name = "SectionHeader_" .. titleText,
			BackgroundTransparency = 1,
			LayoutOrder = order,
			Size = UDim2.new(0.92, 0, 0, 18),
			Parent = scrollFrame,
		})
		create("TextLabel", {
			Name = "Text",
			BackgroundTransparency = 1,
			Font = Constants.Fonts.Semibold,
			Text = string.upper(titleText),
			TextColor3 = Color3.fromRGB(109, 109, 114),
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 4, 0, 0),
			Size = UDim2.new(1, 0, 1, 0),
			Parent = headerFrame,
		})
		return headerFrame
	end

	-- Helper: Create Group Card
	local function createGroupCard(name: string, height: number, order: number)
		local card = create("Frame", {
			Name = "GroupCard_" .. name,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			LayoutOrder = order,
			Size = UDim2.new(0.92, 0, 0, height),
			Parent = scrollFrame,
		})
		create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = card })
		create("UIStroke", { Color = Color3.fromRGB(215, 215, 220), Thickness = 1, Parent = card })
		return card
	end

	-- Helper: Create iOS 7 Toggle Switch
	local function createIOS7Switch(parent: Instance, initialValue: boolean, onToggle: (boolean) -> ())
		local switchTrack = create("TextButton", {
			Name = "SwitchTrack",
			AutoButtonColor = false,
			BackgroundColor3 = if initialValue then Color3.fromRGB(52, 199, 89) else Color3.fromRGB(229, 229, 234),
			BorderSizePixel = 0,
			Text = "",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.new(0, 46, 0, 26),
			ZIndex = 55,
			Parent = parent,
		})
		create("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = switchTrack })

		local switchKnob = create("Frame", {
			Name = "SwitchKnob",
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			Position = UDim2.new(if initialValue then 1 else 0, if initialValue then -24 else 2, 0, 2),
			Size = UDim2.new(0, 22, 0, 22),
			ZIndex = 56,
			Parent = switchTrack,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = switchKnob })

		local isToggled = initialValue
		switchTrack.Activated:Connect(function()
			isToggled = not isToggled
			onToggle(isToggled)

			local targetBg = if isToggled then Color3.fromRGB(52, 199, 89) else Color3.fromRGB(229, 229, 234)
			local targetPos = UDim2.new(if isToggled then 1 else 0, if isToggled then -24 else 2, 0, 2)

			TweenService:Create(switchTrack, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = targetBg
			}):Play()
			TweenService:Create(switchKnob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = targetPos
			}):Play()
		end)
	end

	-- ─── SECTION 1: SOUND & AUDIO ──────────────────────────────
	createSectionHeader("Sounds & Audio", 3)
	local soundCard = createGroupCard("Sound", 42, 4)

	local silentRow = create("Frame", {
		Name = "SilentRow",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 42),
		Parent = soundCard,
	})
	create("TextLabel", {
		Name = "Label",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "🔇 Silent Mode",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 12, 0, 0),
		Size = UDim2.new(0.6, 0, 1, 0),
		Parent = silentRow,
	})
	local initSilent = saveService:Get("SilentMode", false)
	createIOS7Switch(silentRow, initSilent, function(state)
		saveService:Set("SilentMode", state)
		context.SendNotification({
			Title = "Settings",
			Body = if state then "Silent Mode Enabled" else "Silent Mode Disabled",
			Duration = 2,
		})
	end)

	-- ─── SECTION 2: WALLPAPER CONFIGURATION ────────────────────
	createSectionHeader("Wallpaper", 5)
	local wallCard = createGroupCard("Wallpaper", 185, 6)

	create("TextLabel", {
		Name = "WallLabel",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Semibold,
		Text = "Presets",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 12, 0, 8),
		Size = UDim2.new(0.9, 0, 0, 16),
		Parent = wallCard,
	})

	-- Preset Grid
	local presetFrame = create("Frame", {
		Name = "PresetGrid",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 28),
		Size = UDim2.new(1, -24, 0, 60),
		Parent = wallCard,
	})

	local currentWall = saveService:Get("WallpaperImage", "rbxassetid://103030063690728")

	for i, preset in ipairs(PRESET_WALLPAPERS) do
		local btn = create("ImageButton", {
			Name = "Preset_" .. i,
			BackgroundColor3 = Color3.fromRGB(30, 30, 35),
			BorderSizePixel = 0,
			Image = preset.asset,
			ScaleType = Enum.ScaleType.Crop,
			Position = UDim2.new((i - 1) * 0.25, 2, 0, 0),
			Size = UDim2.new(0.23, -4, 1, 0),
			ZIndex = 53,
			Parent = presetFrame,
		})
		create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })
		create("UIStroke", { Color = Color3.fromRGB(0, 122, 255), Thickness = if currentWall == preset.asset then 2 else 0, Parent = btn })

		btn.Activated:Connect(function()
			saveService:Set("WallpaperImage", preset.asset)
			context.SendNotification({ Title = "Wallpaper", Body = preset.name .. " applied!", Duration = 2 })
			for _, child in ipairs(presetFrame:GetChildren()) do
				if child:IsA("ImageButton") then
					local stroke = child:FindFirstChildOfClass("UIStroke")
					if stroke then stroke.Thickness = 0 end
				end
			end
			local myStroke = btn:FindFirstChildOfClass("UIStroke")
			if myStroke then myStroke.Thickness = 2 end
		end)
	end

	-- Custom Asset ID Input
	create("TextLabel", {
		Name = "CustomLabel",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Semibold,
		Text = "Custom Asset ID",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 12, 0, 96),
		Size = UDim2.new(0.9, 0, 0, 16),
		Parent = wallCard,
	})

	local inputFrame = create("Frame", {
		Name = "InputFrame",
		BackgroundColor3 = Color3.fromRGB(242, 242, 247),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 12, 0, 116),
		Size = UDim2.new(1, -24, 0, 32),
		Parent = wallCard,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = inputFrame })

	local assetInput = create("TextBox", {
		Name = "AssetInput",
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		Font = Constants.Fonts.Regular,
		PlaceholderText = "Enter Roblox Asset ID",
		Text = currentWall,
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(0.7, 0, 1, 0),
		Parent = inputFrame,
	})

	local applyBtn = create("TextButton", {
		Name = "ApplyButton",
		BackgroundColor3 = Color3.fromRGB(0, 122, 255),
		BorderSizePixel = 0,
		Font = Constants.Fonts.Semibold,
		Text = "Set",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 11,
		Position = UDim2.new(0.72, 0, 0.1, 0),
		Size = UDim2.new(0.26, 0, 0.8, 0),
		Parent = inputFrame,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = applyBtn })

	local function applyCustomWallpaper()
		local text = string.gsub(assetInput.Text, "^%s*(.-)%s*$", "%1")
		if text ~= "" then
			saveService:Set("WallpaperImage", text)
			context.SendNotification({ Title = "Wallpaper", Body = "Custom Wallpaper applied!", Duration = 2 })
		end
	end

	applyBtn.Activated:Connect(applyCustomWallpaper)
	assetInput.FocusLost:Connect(function(enterPressed)
		if enterPressed then applyCustomWallpaper() end
	end)

	-- ─── SECTION 3: ABOUT PHONE ─────────────────────────────────
	createSectionHeader("About Device", 7)
	local aboutCard = createGroupCard("About", 126, 8)

	local myPhoneNum = "08" .. tostring(math.abs(player.UserId))

	local aboutRows = {
		{ label = "Device Name", val = "iPhone 5" },
		{ label = "Phone Number", val = myPhoneNum },
	}

	for i, item in ipairs(aboutRows) do
		local r = create("Frame", {
			Name = "AboutRow_" .. i,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, (i - 1) * 42),
			Size = UDim2.new(1, 0, 0, 41),
			Parent = aboutCard,
		})
		create("TextLabel", {
			Name = "Label",
			BackgroundTransparency = 1,
			Font = Constants.Fonts.Regular,
			Text = item.label,
			TextColor3 = Color3.fromRGB(0, 0, 0),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 12, 0, 0),
			Size = UDim2.new(0.45, 0, 1, 0),
			Parent = r,
		})
		create("TextLabel", {
			Name = "Val",
			BackgroundTransparency = 1,
			Font = Constants.Fonts.Regular,
			Text = item.val,
			TextColor3 = Color3.fromRGB(142, 142, 147),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.new(0.5, 0, 0, 0),
			Size = UDim2.new(0.45, 0, 1, 0),
			Parent = r,
		})

		if i < #aboutRows then
			create("Frame", {
				Name = "Sep",
				BackgroundColor3 = Color3.fromRGB(230, 230, 235),
				BorderSizePixel = 0,
				Position = UDim2.new(0, 12, 0, 41),
				Size = UDim2.new(1, -12, 0, 1),
				Parent = aboutCard,
			})
		end
	end

	-- ─── SECTION 4: RESET DATA ──────────────────────────────────
	createSectionHeader("System", 9)
	local resetCard = createGroupCard("Reset", 42, 10)

	local resetBtn = create("TextButton", {
		Name = "ResetLogsBtn",
		AutoButtonColor = true,
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "Clear Reset Settings",
		TextColor3 = Color3.fromRGB(255, 59, 48),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		Parent = resetCard,
	})

	resetBtn.Activated:Connect(function()
		saveService:Set("RecentsCalls", {})
		saveService:Set("AirplaneMode", false)
		saveService:Set("SilentMode", false)
		saveService:Set("WallpaperImage", "rbxassetid://103030063690728")
		context.SendNotification({ Title = "Settings", Body = "Recents & Settings reset to default.", Duration = 3 })
	end)

	return rootFrame
end

return SettingsApp
