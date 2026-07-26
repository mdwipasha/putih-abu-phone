local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local root = script.Parent.Parent
local Constants = require(root:WaitForChild("Shared"):WaitForChild("Constants"))
local StatusBar = require(root:WaitForChild("Shared"):WaitForChild("Components"):WaitForChild("StatusBar"))
local create = require(root:WaitForChild("Shared"):WaitForChild("Utilities"):WaitForChild("Create"))
local EconomyAdapter = require(root:WaitForChild("Services"):WaitForChild("EconomyAdapter"))

local ICONS = {
	Phone = "rbxassetid://71727318918905",
	Message = "rbxassetid://108650574179237",
	History = "rbxassetid://134731973725035",
	Contacts = "rbxassetid://114778546922350",
	Keypad = "rbxassetid://139428637585494",
	AvatarFallback = "rbxassetid://114778546922350",
	Trash = "rbxassetid://83051479285340",
}

local COLORS = {
	Background = Color3.fromRGB(242, 242, 247),
	Card = Color3.fromRGB(255, 255, 255),
	CardStroke = Color3.fromRGB(225, 225, 232),
	TextDark = Color3.fromRGB(28, 28, 30),
	TextMuted = Color3.fromRGB(142, 142, 147),
	AccentGreen = Color3.fromRGB(52, 199, 89),
	AccentBlue = Color3.fromRGB(0, 122, 255),
	AccentGold = Color3.fromRGB(255, 149, 0),
	DestructiveRed = Color3.fromRGB(255, 59, 48),
	DarkCallBg = Color3.fromRGB(18, 22, 28),
}

local KEYPAD_KEYS = {
	{ num = "1", sub = "" },
	{ num = "2", sub = "" },
	{ num = "3", sub = "" },
	{ num = "4", sub = "" },
	{ num = "5", sub = "" },
	{ num = "6", sub = "" },
	{ num = "7", sub = "" },
	{ num = "8", sub = "" },
	{ num = "9", sub = "" },
	{ num = "*", sub = "" },
	{ num = "0", sub = "" },
	{ num = "#", sub = "" },
}

local function rounded(instance: Instance, radiusOffset: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radiusOffset)
	corner.Parent = instance
	return corner
end

local function padded(instance: Instance, left: number, right: number, top: number, bottom: number)
	create("UIPadding", {
		PaddingLeft = UDim.new(left or 0, 0),
		PaddingRight = UDim.new(right or left or 0, 0),
		PaddingTop = UDim.new(top or 0, 0),
		PaddingBottom = UDim.new(bottom or top or 0, 0),
		Parent = instance,
	})
end

local function stroke(instance: Instance, color: Color3?, thickness: number?, transparency: number?)
	return create("UIStroke", {
		Color = color or COLORS.CardStroke,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		Parent = instance,
	})
end

local function label(props: { [string]: any })
	local maxTextSize = props.MaxTextSize or 15
	local minTextSize = props.MinTextSize or 8
	props.MaxTextSize = nil
	props.MinTextSize = nil

	local defaults = {
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		TextColor3 = COLORS.TextDark,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}
	for k, v in pairs(props) do
		defaults[k] = v
	end
	local inst = create("TextLabel", defaults)
	if inst.TextScaled then
		create("UITextSizeConstraint", {
			MinTextSize = minTextSize,
			MaxTextSize = maxTextSize,
			Parent = inst,
		})
	end
	return inst
end

local function iconImage(props: { [string]: any })
	local defaults = {
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		ImageColor3 = Color3.fromRGB(255, 255, 255),
	}
	for k, v in pairs(props) do
		defaults[k] = v
	end
	return create("ImageLabel", defaults)
end

-- Utility: clear a scrolling frame's dynamic content (preserving layout objects)
local function clearDynamicChildren(frame: Instance)
	for _, child in ipairs(frame:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") or child:IsA("ImageLabel") then
			child:Destroy()
		end
	end
end

local PhoneApp = {
	Id = "phone",
	Name = "Phone",
	Icon = {
		Background = Color3.fromRGB(35, 214, 63),
		Image = "rbxassetid://71727318918905",
	},
	Order = 100,
}

function PhoneApp.Create(context: any)
	local localPlayer = Players.LocalPlayer
	local saveService = context.Services.SaveService
	local remote = ReplicatedStorage:FindFirstChild(Constants.RemoteName)

	-- State Aplikasi Phone (3 tab: recents, keypad, contacts)
	local state = {
		ActiveTab = "keypad", -- "recents", "keypad", "contacts"
		DialedNumber = "",
		CallState = "idle", -- "idle", "ringing", "active", "incoming"
		CallPartner = nil,
		CallStartTime = 0,
	}

	-- Root Container
	local rootFrame = create("Frame", {
		Name = "PhoneRoot",
		BackgroundColor3 = COLORS.Background,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
	})

	StatusBar.new(rootFrame, { Light = false })

	local navHeight = 0.075
	local tabBarHeight = 0.08
	local contentTop = Constants.Screen.StatusBarHeight + navHeight
	local contentHeight = 1 - contentTop - tabBarHeight

	-- Navigation Bar Atas
	local navBar = create("Frame", {
		Name = "NavigationBar",
		BackgroundColor3 = COLORS.Card,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, Constants.Screen.StatusBarHeight),
		Size = UDim2.fromScale(1, navHeight),
		ZIndex = 60,
		Parent = rootFrame,
	})
	stroke(navBar, COLORS.CardStroke, 1)

	local backBtn = create("TextButton", {
		Name = "BackButton",
		AutoButtonColor = true,
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "く",
		TextColor3 = COLORS.AccentGreen,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(0, 75, 1, 0),
		ZIndex = 61,
		Parent = navBar,
	})
	backBtn.Activated:Connect(function()
		context.CloseCurrentApp()
	end)

	local titleLabel = label({
		Name = "Title",
		Parent = navBar,
		Font = Constants.Fonts.Semibold,
		Text = "Keypad",
		TextColor3 = COLORS.TextDark,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.5, 0.6),
		MaxTextSize = 16,
		MinTextSize = 11,
		ZIndex = 61,
	})

	-- Right header action button (clear history on recents, nothing otherwise)
	local headerActionBtn = create("TextButton", {
		Name = "HeaderActionBtn",
		AutoButtonColor = true,
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "",
		TextColor3 = COLORS.DestructiveRed,
		TextSize = 11,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -5, 0.5, 0),
		Size = UDim2.new(0, 70, 1, 0),
		Visible = false,
		ZIndex = 61,
		Parent = navBar,
	})

	-- Bottom Tab Bar (3 tabs: Recents | Keypad | Contacts)
	local tabBar = create("Frame", {
		Name = "TabBar",
		BackgroundColor3 = COLORS.Card,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, 1 - tabBarHeight),
		Size = UDim2.fromScale(1, tabBarHeight),
		ZIndex = 60,
		Parent = rootFrame,
	})
	stroke(tabBar, COLORS.CardStroke, 1)

	local tabs = {
		{ id = "recents",  name = "Recents",  icon = "",   pos = 0 },
		{ id = "keypad",   name = "Keypad",   icon = "",    pos = 1 },
		{ id = "contacts", name = "Kontak",   icon = "",  pos = 2 },
	}

	local tabButtons = {}
	local tabWidth = 1 / #tabs
	for _, tabInfo in ipairs(tabs) do
		local btn = create("TextButton", {
			Name = "Tab_" .. tabInfo.id,
			AutoButtonColor = true,
			BackgroundTransparency = 1,
			Text = "",
			Position = UDim2.new(tabInfo.pos * tabWidth, 0, 0, 0),
			Size = UDim2.new(tabWidth, 0, 1, 0),
			ZIndex = 61,
			Parent = tabBar,
		})

		local txt = label({
			Name = "Label",
			Parent = btn,
			Font = Constants.Fonts.Semibold,
			Text = tabInfo.name,
			TextColor3 = if tabInfo.id == "keypad" then COLORS.AccentGreen else COLORS.TextMuted,
			TextXAlignment = Enum.TextXAlignment.Center,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.9),
			Size = UDim2.fromScale(1, 0.4),
			MaxTextSize = 10,
			MinTextSize = 7,
			ZIndex = 62,
		})

		tabButtons[tabInfo.id] = { button = btn, text = txt }
	end

	-- Content Area
	local contentArea = create("Frame", {
		Name = "ContentArea",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0, contentTop),
		Size = UDim2.fromScale(1, contentHeight),
		ZIndex = 51,
		Parent = rootFrame,
	})

	-- Views
	local keypadView   = create("Frame",          { Name = "KeypadView",   BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 52, Parent = contentArea })
	local recentsView  = create("ScrollingFrame", { Name = "RecentsView",  BackgroundTransparency = 1, BorderSizePixel = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0), ScrollBarThickness = 3, ScrollBarImageColor3 = COLORS.TextMuted, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 52, Parent = contentArea })
	local contactsView = create("ScrollingFrame", { Name = "ContactsView", BackgroundTransparency = 1, BorderSizePixel = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0), ScrollBarThickness = 3, ScrollBarImageColor3 = COLORS.TextMuted, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 52, Parent = contentArea })

	padded(recentsView,  0.04, 0.04, 0.02, 0.04)
	padded(contactsView, 0.04, 0.04, 0.02, 0.04)
	create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = recentsView })
	create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = contactsView })

	-- Forward references
	local updateKeypadDisplay
	local startCall
	local renderRecents
	local renderContacts
	local openAddContactWithPhone

	-- ======================
	-- 1. KEYPAD VIEW
	-- ======================
	local numberDisplayBox = label({
		Name = "NumberDisplay",
		Parent = keypadView,
		Font = Constants.Fonts.Light,
		Text = "",
		TextColor3 = COLORS.TextDark,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.new(0.05, 0, 0.01, 0),
		Size = UDim2.new(0.9, 0, 0, 42),
		MaxTextSize = 26,
		MinTextSize = 14,
		ZIndex = 53,
	})

	local backspaceBtn = create("TextButton", {
		Name = "BackspaceBtn",
		AutoButtonColor = true,
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "⌫",
		TextColor3 = COLORS.TextMuted,
		TextSize = 18,
		Visible = false,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(0.95, 0, 0.07, 0),
		Size = UDim2.fromOffset(30, 30),
		ZIndex = 54,
		Parent = keypadView,
	})

	local keypadGrid = create("Frame", {
		Name = "KeypadGrid",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.15, 0),
		Size = UDim2.new(0.85, 0, 0.65, 0),
		ZIndex = 53,
		Parent = keypadView,
	})

	create("UIGridLayout", {
		CellPadding = UDim2.new(0.08, 0, 0.04, 0),
		CellSize = UDim2.new(0.28, 0, 0.22, 0),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = keypadGrid,
	})

	for idx, key in ipairs(KEYPAD_KEYS) do
		local circleKey = create("TextButton", {
			Name = "Key_" .. key.num,
			AutoButtonColor = true,
			BackgroundColor3 = Color3.fromRGB(246, 247, 250),
			BorderSizePixel = 0,
			Text = "",
			LayoutOrder = idx,
			ZIndex = 54,
			Parent = keypadGrid,
		})
		rounded(circleKey, 30)
		stroke(circleKey, Color3.fromRGB(215, 220, 230), 1)

		label({
			Name = "Num",
			Parent = circleKey,
			Font = Constants.Fonts.Regular,
			Text = key.num,
			TextColor3 = COLORS.TextDark,
			TextXAlignment = Enum.TextXAlignment.Center,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, if key.sub ~= "" then 0.38 else 0.5),
			Size = UDim2.fromScale(0.8, 0.55),
			MaxTextSize = 22,
			MinTextSize = 14,
			ZIndex = 55,
		})

		if key.sub ~= "" then
			label({
				Name = "Sub",
				Parent = circleKey,
				Font = Constants.Fonts.Semibold,
				Text = key.sub,
				TextColor3 = COLORS.TextMuted,
				TextXAlignment = Enum.TextXAlignment.Center,
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 0.88),
				Size = UDim2.fromScale(0.9, 0.3),
				MaxTextSize = 9,
				MinTextSize = 6,
				ZIndex = 55,
			})
		end

		circleKey.Activated:Connect(function()
			state.DialedNumber = state.DialedNumber .. key.num
			updateKeypadDisplay()
		end)
	end

	-- Call Button (Big Green Circular Button)
	local callKeypadBtn = create("TextButton", {
		Name = "CallKeypadBtn",
		AutoButtonColor = true,
		BackgroundColor3 = COLORS.AccentGreen,
		BorderSizePixel = 0,
		Text = "",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0.97, 0),
		Size = UDim2.fromOffset(50, 50),
		ZIndex = 54,
		Parent = keypadView,
	})
	rounded(callKeypadBtn, 26)
	iconImage({
		Name = "Icon",
		Image = ICONS.Phone,
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(26, 26),
		ZIndex = 55,
		Parent = callKeypadBtn,
	})

	updateKeypadDisplay = function()
		numberDisplayBox.Text = state.DialedNumber
		local hasNum = (state.DialedNumber ~= "")
		backspaceBtn.Visible = hasNum
	end

	backspaceBtn.Activated:Connect(function()
		if #state.DialedNumber > 0 then
			state.DialedNumber = string.sub(state.DialedNumber, 1, #state.DialedNumber - 1)
			updateKeypadDisplay()
		end
	end)

	callKeypadBtn.Activated:Connect(function()
		if state.DialedNumber ~= "" then
			startCall({ phone = state.DialedNumber })
		else
			local recents = saveService:Get("RecentsCalls", {})
			if #recents > 0 then
				state.DialedNumber = recents[1].Phone or ""
				updateKeypadDisplay()
			end
		end
	end)

	-- ======================
	-- 2. RECENTS VIEW
	-- ======================
	renderRecents = function()
		clearDynamicChildren(recentsView)

		local recents = saveService:Get("RecentsCalls", {})
		if #recents == 0 then
			label({
				Name = "EmptyLabel",
				Parent = recentsView,
				Font = Constants.Fonts.Regular,
				Text = "Belum ada riwayat panggilan.",
				TextColor3 = COLORS.TextMuted,
				TextXAlignment = Enum.TextXAlignment.Center,
				Size = UDim2.new(1, 0, 0, 80),
				MaxTextSize = 13,
				MinTextSize = 9,
				ZIndex = 53,
			})
			return
		end

		for idx, log in ipairs(recents) do
			local isMissed = log.Type == "missed"
			local textColor = if isMissed then COLORS.DestructiveRed else COLORS.TextDark

			local row = create("Frame", {
				Name = "Recent_" .. idx,
				BackgroundColor3 = COLORS.Card,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 52),
				LayoutOrder = idx,
				ZIndex = 53,
				Parent = recentsView,
			})
			rounded(row, 10)
			stroke(row, COLORS.CardStroke, 1)

			label({
				Name = "Name",
				Parent = row,
				Font = Constants.Fonts.Semibold,
				Text = log.Name or log.Phone or "Panggilan",
				TextColor3 = textColor,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Position = UDim2.new(0, 14, 0, 10),
				Size = UDim2.new(0.5, 0, 0, 16),
				MaxTextSize = 13,
				MinTextSize = 9,
				ZIndex = 54,
			})

			local timeText = if log.Timestamp then os.date("%H:%M", log.Timestamp) else "-"
			local logPhone = log.Phone or "-"
			label({
				Name = "Time",
				Parent = row,
				Text = logPhone .. " • " .. timeText,
				TextColor3 = COLORS.TextMuted,
				Position = UDim2.new(0, 14, 0, 28),
				Size = UDim2.new(0.5, 0, 0, 14),
				MaxTextSize = 10,
				MinTextSize = 7,
				ZIndex = 54,
			})

			-- Quick Call button
			local callIconBtn = create("TextButton", {
				Name = "QuickCall",
				AutoButtonColor = true,
				BackgroundColor3 = Color3.fromRGB(235, 247, 240),
				BorderSizePixel = 0,
				Text = "",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -48, 0.5, 0),
				Size = UDim2.fromOffset(28, 28),
				ZIndex = 54,
				Parent = row,
			})
			rounded(callIconBtn, 14)
			iconImage({
				Name = "Icon",
				Image = ICONS.Phone,
				ImageColor3 = COLORS.AccentGreen,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(14, 14),
				ZIndex = 55,
				Parent = callIconBtn,
			})
			callIconBtn.Activated:Connect(function()
				startCall({ name = log.Name, phone = log.Phone, userId = log.UserId })
			end)

			-- Delete single entry button
			local deleteBtn = create("TextButton", {
				Name = "DeleteBtn",
				AutoButtonColor = true,
				BackgroundColor3 = Color3.fromRGB(255, 235, 235),
				BorderSizePixel = 0,
				Font = Constants.Fonts.Regular,
				Text = "✕",
				TextColor3 = COLORS.DestructiveRed,
				TextSize = 12,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.fromOffset(28, 28),
				ZIndex = 54,
				Parent = row,
			})
			rounded(deleteBtn, 14)
			do
				local capturedIdx = idx
				deleteBtn.Activated:Connect(function()
					local fresh = saveService:Get("RecentsCalls", {})
					table.remove(fresh, capturedIdx)
					saveService:Set("RecentsCalls", fresh)
					renderRecents()
				end)
			end
		end
	end

	-- ======================
	-- 3. CONTACTS VIEW
	-- ======================
	renderContacts = function()
		clearDynamicChildren(contactsView)

		local contacts = saveService:Get("Contacts", {})
		if #contacts == 0 then
			label({
				Name = "EmptyLabel",
				Parent = contactsView,
				Font = Constants.Fonts.Regular,
				Text = "Belum ada kontak tersimpan.\nTambah kontak di aplikasi Contacts.",
				TextColor3 = COLORS.TextMuted,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextWrapped = true,
				Size = UDim2.new(1, 0, 0, 80),
				MaxTextSize = 13,
				MinTextSize = 9,
				ZIndex = 53,
			})
			return
		end

		for idx, contact in ipairs(contacts) do
			local card = create("Frame", {
				Name = "Contact_" .. idx,
				BackgroundColor3 = COLORS.Card,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 52),
				LayoutOrder = idx,
				ZIndex = 53,
				Parent = contactsView,
			})
			rounded(card, 10)
			stroke(card, COLORS.CardStroke, 1)

			local avatar = create("ImageLabel", {
				Name = "Avatar",
				BackgroundColor3 = Color3.fromRGB(230, 235, 245),
				Image = if contact.UserId then ("rbxthumb://type=AvatarBust&id=" .. contact.UserId .. "&w=150&h=150") else ICONS.AvatarFallback,
				Position = UDim2.new(0, 10, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.fromOffset(36, 36),
				ZIndex = 54,
				Parent = card,
			})
			rounded(avatar, 18)

			label({
				Name = "Name",
				Parent = card,
				Font = Constants.Fonts.Semibold,
				Text = contact.Name or "Kontak",
				TextColor3 = COLORS.TextDark,
				Position = UDim2.new(0, 56, 0, 10),
				Size = UDim2.new(0.52, 0, 0, 16),
				MaxTextSize = 13,
				MinTextSize = 9,
				ZIndex = 54,
			})

			label({
				Name = "Phone",
				Parent = card,
				Text = contact.Phone or "-",
				TextColor3 = COLORS.TextMuted,
				Position = UDim2.new(0, 56, 0, 28),
				Size = UDim2.new(0.52, 0, 0, 14),
				MaxTextSize = 10,
				MinTextSize = 7,
				ZIndex = 54,
			})

			local callIconBtn = create("TextButton", {
				Name = "QuickCall",
				AutoButtonColor = true,
				BackgroundColor3 = COLORS.AccentGreen,
				BorderSizePixel = 0,
				Text = "",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.fromOffset(28, 28),
				ZIndex = 54,
				Parent = card,
			})
			rounded(callIconBtn, 14)
			iconImage({
				Name = "Icon",
				Image = ICONS.Phone,
				ImageColor3 = Color3.fromRGB(255, 255, 255),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(14, 14),
				ZIndex = 55,
				Parent = callIconBtn,
			})
			callIconBtn.Activated:Connect(function()
				startCall(contact)
			end)
		end
	end

	-- ======================
	-- ACTIVE CALL SCREEN (iOS 7)
	-- ======================
	local activeCallOverlay = create("Frame", {
		Name = "ActiveCallOverlay",
		BackgroundColor3 = COLORS.DarkCallBg,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 100,
		Parent = rootFrame,
	})

	local callAvatar = create("ImageLabel", {
		Name = "CallAvatar",
		BackgroundColor3 = Color3.fromRGB(40, 48, 60),
		Image = ICONS.AvatarFallback,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.12, 0),
		Size = UDim2.fromOffset(80, 80),
		ZIndex = 101,
		Parent = activeCallOverlay,
	})
	rounded(callAvatar, 40)
	stroke(callAvatar, COLORS.AccentGreen, 2)

	local callPartnerName = label({
		Name = "PartnerName",
		Parent = activeCallOverlay,
		Font = Constants.Fonts.Semibold,
		Text = "Seseorang",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.new(0, 0, 0.32, 0),
		Size = UDim2.new(1, 0, 0, 24),
		MaxTextSize = 18,
		MinTextSize = 12,
		ZIndex = 101,
	})

	local callStatusLabel = label({
		Name = "CallStatus",
		Parent = activeCallOverlay,
		Font = Constants.Fonts.Regular,
		Text = "Memanggil...",
		TextColor3 = COLORS.AccentGreen,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.new(0, 0, 0.38, 0),
		Size = UDim2.new(1, 0, 0, 18),
		MaxTextSize = 13,
		MinTextSize = 9,
		ZIndex = 101,
	})

	local callControlsFrame = create("Frame", {
		Name = "CallControls",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.48, 0),
		Size = UDim2.new(0.8, 0, 0.3, 0),
		ZIndex = 101,
		Parent = activeCallOverlay,
	})
	create("UIGridLayout", {
		CellPadding = UDim2.new(0.12, 0, 0.1, 0),
		CellSize = UDim2.new(0.25, 0, 0.4, 0),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = callControlsFrame,
	})

	for idx, c in ipairs({
		{ name = "Mute",     icon = "🔇" },
		{ name = "Keypad",   icon = "🔢" },
		{ name = "Speaker",  icon = "🔊" },
		{ name = "AddCall",  icon = "➕" },
		{ name = "FaceTime", icon = "📹" },
		{ name = "Contacts", icon = "👤" },
	}) do
		local btn = create("TextButton", {
			Name = "Ctrl_" .. c.name,
			AutoButtonColor = true,
			BackgroundColor3 = Color3.fromRGB(40, 45, 55),
			BorderSizePixel = 0,
			Font = Constants.Fonts.Semibold,
			Text = c.icon,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			LayoutOrder = idx,
			ZIndex = 102,
			Parent = callControlsFrame,
		})
		rounded(btn, 22)
		stroke(btn, Color3.fromRGB(60, 68, 80), 1)
	end

	local endCallBtn = create("TextButton", {
		Name = "EndCallBtn",
		AutoButtonColor = true,
		BackgroundColor3 = COLORS.DestructiveRed,
		BorderSizePixel = 0,
		Text = "",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0.94, 0),
		Size = UDim2.fromOffset(56, 56),
		ZIndex = 101,
		Parent = activeCallOverlay,
	})
	rounded(endCallBtn, 28)
	iconImage({
		Name = "Icon",
		Image = ICONS.Phone,
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Rotation = 135,
		Size = UDim2.fromOffset(26, 26),
		ZIndex = 102,
		Parent = endCallBtn,
	})

	-- ======================
	-- INCOMING CALL MODAL
	-- ======================
	local incomingCallOverlay = create("Frame", {
		Name = "IncomingCallOverlay",
		BackgroundColor3 = COLORS.DarkCallBg,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 110,
		Parent = rootFrame,
	})

	local incAvatar = create("ImageLabel", {
		Name = "Avatar",
		BackgroundColor3 = Color3.fromRGB(40, 48, 60),
		Image = ICONS.AvatarFallback,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.15, 0),
		Size = UDim2.fromOffset(84, 84),
		ZIndex = 111,
		Parent = incomingCallOverlay,
	})
	rounded(incAvatar, 42)
	stroke(incAvatar, COLORS.AccentGreen, 2)

	local incName = label({
		Name = "IncName",
		Parent = incomingCallOverlay,
		Font = Constants.Fonts.Semibold,
		Text = "Panggilan Masuk",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.new(0, 0, 0.36, 0),
		Size = UDim2.new(1, 0, 0, 24),
		MaxTextSize = 18,
		MinTextSize = 12,
		ZIndex = 111,
	})

	local incSub = label({
		Name = "IncSub",
		Parent = incomingCallOverlay,
		Font = Constants.Fonts.Regular,
		Text = "Sedang memanggil...",
		TextColor3 = COLORS.AccentGreen,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.new(0, 0, 0.43, 0),
		Size = UDim2.new(1, 0, 0, 18),
		MaxTextSize = 13,
		MinTextSize = 9,
		ZIndex = 111,
	})

	local declineCallBtn = create("TextButton", {
		Name = "DeclineCallBtn",
		AutoButtonColor = true,
		BackgroundColor3 = COLORS.DestructiveRed,
		BorderSizePixel = 0,
		Text = "",
		Position = UDim2.new(0.18, 0, 0.78, 0),
		Size = UDim2.fromOffset(56, 56),
		ZIndex = 111,
		Parent = incomingCallOverlay,
	})
	rounded(declineCallBtn, 28)
	iconImage({
		Name = "Icon",
		Image = ICONS.Phone,
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Rotation = 135,
		Size = UDim2.fromOffset(26, 26),
		ZIndex = 112,
		Parent = declineCallBtn,
	})

	local answerCallBtn = create("TextButton", {
		Name = "AnswerCallBtn",
		AutoButtonColor = true,
		BackgroundColor3 = COLORS.AccentGreen,
		BorderSizePixel = 0,
		Text = "",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(0.82, 0, 0.78, 0),
		Size = UDim2.fromOffset(56, 56),
		ZIndex = 111,
		Parent = incomingCallOverlay,
	})
	rounded(answerCallBtn, 28)
	iconImage({
		Name = "Icon",
		Image = ICONS.Phone,
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(26, 26),
		ZIndex = 112,
		Parent = answerCallBtn,
	})

	-- ======================
	-- CALL LOGIC
	-- ======================
	-- startCall: do NOT open call screen yet; wait for server response:
	--   CallRinging  → show call screen (number exists, may be offline)
	--   CallFailed   → show notification (number not in DataStore at all)
	startCall = function(target: { name: string?, phone: string?, userId: number? })
		local targetPhone = target.phone or state.DialedNumber
		local targetName = target.name or targetPhone

		if targetPhone == "" then return end

		if state.CallState ~= "idle" then return end

		-- Fire to server first; server will validate phone via DataStore
		if remote and remote:IsA("RemoteEvent") then
			remote:FireServer("StartCall", {
				targetUserId = target.userId,
				targetPhone = targetPhone,
			})
		end

		-- Pre-set partner info (screen will open when server responds with CallRinging)
		state.CallState = "ringing"
		state.CallPartner = { name = targetName, phone = targetPhone, userId = target.userId }
	end

	endCallBtn.Activated:Connect(function()
		activeCallOverlay.Visible = false
		state.CallState = "idle"
		if remote and remote:IsA("RemoteEvent") and state.CallPartner and state.CallPartner.userId then
			remote:FireServer("EndCall", { partnerUserId = state.CallPartner.userId })
		end
		state.CallPartner = nil
	end)

	declineCallBtn.Activated:Connect(function()
		incomingCallOverlay.Visible = false
		state.CallState = "idle"
		if remote and remote:IsA("RemoteEvent") and state.CallPartner and state.CallPartner.userId then
			remote:FireServer("DeclineCall", { partnerUserId = state.CallPartner.userId })
		end
		state.CallPartner = nil
	end)

	answerCallBtn.Activated:Connect(function()
		incomingCallOverlay.Visible = false
		activeCallOverlay.Visible = true
		state.CallState = "active"
		state.CallStartTime = tick()
		callStatusLabel.Text = "00:00"
		if remote and remote:IsA("RemoteEvent") and state.CallPartner and state.CallPartner.userId then
			remote:FireServer("AnswerCall", { callerUserId = state.CallPartner.userId })
		end
	end)

	-- Timer Loop
	local callTimerConnection = RunService.Heartbeat:Connect(function()
		if state.CallState == "active" and activeCallOverlay.Visible then
			local elapsed = math.floor(tick() - state.CallStartTime)
			local mins = math.floor(elapsed / 60)
			local secs = elapsed % 60
			callStatusLabel.Text = string.format("%02d:%02d", mins, secs)
		end
	end)

	-- ======================
	-- SWITCH TAB
	-- ======================
	local function switchTab(tabId: string)
		state.ActiveTab = tabId
		for tid, tData in pairs(tabButtons) do
			local isActive = (tid == tabId)
			if tData.icon then
				tData.icon.ImageColor3 = if isActive then COLORS.AccentGreen else COLORS.TextMuted
			end
			if tData.text then
				tData.text.TextColor3 = if isActive then COLORS.AccentGreen else COLORS.TextMuted
			end
		end

		keypadView.Visible   = (tabId == "keypad")
		recentsView.Visible  = (tabId == "recents")
		contactsView.Visible = (tabId == "contacts")

		if tabId == "recents" then
			titleLabel.Text = "Recents"
			headerActionBtn.Text = "Hapus Semua"
			headerActionBtn.Visible = true
			renderRecents()
		elseif tabId == "contacts" then
			titleLabel.Text = "Kontak"
			headerActionBtn.Visible = false
			renderContacts()
		else
			titleLabel.Text = "Keypad"
			headerActionBtn.Visible = false
		end
	end

	-- "Hapus Semua Riwayat"
	headerActionBtn.Activated:Connect(function()
		saveService:Set("RecentsCalls", {})
		renderRecents()
	end)

	for tid, tData in pairs(tabButtons) do
		tData.button.Activated:Connect(function()
			switchTab(tid)
		end)
	end

	-- ======================
	-- REMOTE CLIENT LISTENER
	-- ======================
	local remoteConnection
	if remote and remote:IsA("RemoteEvent") then
		remoteConnection = remote.OnClientEvent:Connect(function(action: string, payload: any)
			if action == "CallRinging" and payload then
				-- Server confirmed target exists (may be offline): show call screen
				local tName = payload.targetName or (state.CallPartner and state.CallPartner.name) or (payload.targetPhone or "")
				local tPhone = payload.targetPhone or ""
				local tUserId = payload.targetUserId

				state.CallPartner = { name = tName, phone = tPhone, userId = tUserId }
				callPartnerName.Text = tName
				callStatusLabel.Text = "Memanggil..."
				if tUserId then
					callAvatar.Image = "rbxthumb://type=AvatarBust&id=" .. tUserId .. "&w=150&h=150"
				else
					callAvatar.Image = ICONS.AvatarFallback
				end
				activeCallOverlay.Visible = true

				-- Log to Recents
				local recents = saveService:Get("RecentsCalls", {})
				table.insert(recents, 1, {
					Name = tName,
					Phone = tPhone,
					UserId = tUserId,
					Type = "outgoing",
					Timestamp = os.time(),
				})
				saveService:Set("RecentsCalls", recents)

			elseif action == "IncomingCall" and payload then
				state.CallPartner = { userId = payload.callerUserId, name = payload.callerName, phone = payload.callerPhone }
				incName.Text = payload.callerName or "Seseorang"
				incSub.Text = payload.callerPhone or "Panggilan Masuk"
				if payload.callerUserId then
					incAvatar.Image = "rbxthumb://type=AvatarBust&id=" .. payload.callerUserId .. "&w=150&h=150"
				end
				incomingCallOverlay.Visible = true

				-- Log incoming
				local recents = saveService:Get("RecentsCalls", {})
				table.insert(recents, 1, {
					Name = payload.callerName,
					Phone = payload.callerPhone,
					UserId = payload.callerUserId,
					Type = "incoming",
					Timestamp = os.time(),
				})
				saveService:Set("RecentsCalls", recents)

			elseif action == "CallConnected" then
				activeCallOverlay.Visible = true
				incomingCallOverlay.Visible = false
				state.CallState = "active"
				state.CallStartTime = tick()
				callStatusLabel.Text = "00:00"

			elseif action == "CallEnded" then
				activeCallOverlay.Visible = false
				incomingCallOverlay.Visible = false
				state.CallState = "idle"
				state.CallPartner = nil

			elseif action == "CallFailed" then
				-- Number not in DataStore at all: cancel and notify immediately
				activeCallOverlay.Visible = false
				state.CallState = "idle"
				state.CallPartner = nil
				if payload and payload.reason then
					context.SendNotification({ Title = "📵 Nomor Tidak Terdaftar", Text = payload.reason, Duration = 4 })
				end
			end
		end)
	end

	rootFrame.Destroying:Connect(function()
		if remoteConnection then remoteConnection:Disconnect() end
		if callTimerConnection then callTimerConnection:Disconnect() end
	end)

	switchTab("keypad")

	return rootFrame
end

return PhoneApp
