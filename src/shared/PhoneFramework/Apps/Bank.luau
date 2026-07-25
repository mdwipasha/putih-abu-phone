local TweenService = game:GetService("TweenService")

local rootModule = script.Parent.Parent
local Constants = require(rootModule.Shared.Constants)
local StatusBar = require(rootModule.Shared.Components.StatusBar)
local create = require(rootModule.Shared.Utilities.Create)
local EconomyAdapter = require(rootModule.Services.EconomyAdapter)

local Bank = {
	Id = "bank",
	Name = "Bank",
	Icon = {
		Background = Color3.fromRGB(18, 129, 91),
		Glyph = "BANK",
	},
	Order = 50,
}

local COLORS = {
	Background = Color3.fromRGB(244, 245, 248),
	Card = Color3.fromRGB(255, 255, 255),
	CardStroke = Color3.fromRGB(228, 232, 240),

	TextDark = Color3.fromRGB(20, 26, 38),
	TextMuted = Color3.fromRGB(115, 125, 142),

	EmeraldDark = Color3.fromRGB(14, 76, 52),
	EmeraldMain = Color3.fromRGB(20, 140, 95),
	EmeraldLight = Color3.fromRGB(235, 247, 242),

	Blue = Color3.fromRGB(15, 110, 240),
	BlueLight = Color3.fromRGB(238, 244, 255),

	Red = Color3.fromRGB(225, 50, 50),
	RedLight = Color3.fromRGB(254, 240, 240),

	Green = Color3.fromRGB(18, 150, 85),
	GreenLight = Color3.fromRGB(235, 247, 240),

	Gold = Color3.fromRGB(215, 155, 40),
	GoldLight = Color3.fromRGB(255, 248, 235),
}

local ICONS = {
	Refresh = "rbxassetid://139428637585494",
	Chip = "rbxassetid://126903961002759",
	Contactless = "rbxassetid://127578521635782",
	Eye = "rbxassetid://83719759786505",
	Transfer = "rbxassetid://83051479285340",
	History = "rbxassetid://134731973725035",
	Incoming = "rbxassetid://85213797952853",
	Outgoing = "rbxassetid://99690898821926",
	Phone = "rbxassetid://107759348634097",
	Check = "rbxassetid://82537775608740",
	Note = "rbxassetid://74027576278793",
}

local PAGE_SIZE = 12

local function money(value)
	local amount = math.floor((tonumber(value) or 0) + 0.5)
	local text = tostring(amount)
	local result = ""
	while #text > 3 do
		result = "." .. string.sub(text, -3) .. result
		text = string.sub(text, 1, #text - 3)
	end
	return "Rp " .. text .. result
end

local function shortDate(timestamp)
	if not timestamp or timestamp <= 0 then
		return "-"
	end

	local date = os.date("*t", timestamp)
	return string.format("%02d/%02d %02d:%02d", date.month, date.day, date.hour, date.min)
end

local function transactionTitle(transaction)
	local direction = transaction.Direction or "NEUTRAL"
	local transactionType = transaction.Type or "TRANSFER"
	if direction == "INCOMING" then
		return "Incoming " .. transactionType
	elseif direction == "OUTGOING" then
		return "Outgoing " .. transactionType
	end
	return transactionType
end

local function signedAmount(transaction)
	local amount = math.abs(tonumber(transaction.Amount) or 0)
	if transaction.Direction == "OUTGOING" then
		return "-" .. money(amount), COLORS.Red
	elseif transaction.Direction == "INCOMING" then
		return "+" .. money(amount), COLORS.Green
	end
	return money(amount), COLORS.Gold
end

local function rounded(instance, radiusScaleOrOffset)
	local corner = Instance.new("UICorner")
	if typeof(radiusScaleOrOffset) == "number" then
		if radiusScaleOrOffset <= 1 then
			corner.CornerRadius = UDim.new(radiusScaleOrOffset, 0)
		else
			corner.CornerRadius = UDim.new(0, radiusScaleOrOffset)
		end
	else
		corner.CornerRadius = radiusScaleOrOffset
	end
	corner.Parent = instance
	return corner
end

local function padded(instance, left, right, top, bottom)
	create("UIPadding", {
		PaddingLeft = UDim.new(left or 0, 0),
		PaddingRight = UDim.new(right or left or 0, 0),
		PaddingTop = UDim.new(top or 0, 0),
		PaddingBottom = UDim.new(bottom or top or 0, 0),
		Parent = instance,
	})
end

local function stroke(instance, color, thickness, transparency)
	create("UIStroke", {
		Color = color or COLORS.CardStroke,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		Parent = instance,
	})
end

local function label(props)
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
	for key, value in pairs(props) do
		defaults[key] = value
	end
	local instance = create("TextLabel", defaults)
	if instance.TextScaled then
		create("UITextSizeConstraint", {
			MinTextSize = minTextSize,
			MaxTextSize = maxTextSize,
			Parent = instance,
		})
	end
	return instance
end

local function iconImage(props)
	local defaults = {
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		ImageColor3 = Color3.fromRGB(255, 255, 255),
	}
	for key, value in pairs(props) do
		defaults[key] = value
	end
	return create("ImageLabel", defaults)
end

local function button(props)
	local maxTextSize = props.MaxTextSize or 14
	local minTextSize = props.MinTextSize or 8
	props.MaxTextSize = nil
	props.MinTextSize = nil

	local defaults = {
		AutoButtonColor = true,
		BackgroundColor3 = COLORS.EmeraldMain,
		BorderSizePixel = 0,
		Font = Constants.Fonts.Semibold,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		Selectable = true,
	}
	for key, value in pairs(props) do
		defaults[key] = value
	end
	local instance = create("TextButton", defaults)
	if instance.TextScaled then
		create("UITextSizeConstraint", {
			MinTextSize = minTextSize,
			MaxTextSize = maxTextSize,
			Parent = instance,
		})
	end
	rounded(instance, 8)
	return instance
end

local function input(props)
	local maxTextSize = props.MaxTextSize or 14
	local minTextSize = props.MinTextSize or 9
	props.MaxTextSize = nil
	props.MinTextSize = nil

	local defaults = {
		BackgroundColor3 = Color3.fromRGB(246, 247, 250),
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Font = Constants.Fonts.Regular,
		PlaceholderColor3 = COLORS.TextMuted,
		Text = "",
		TextColor3 = COLORS.TextDark,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Selectable = true,
	}
	for key, value in pairs(props) do
		defaults[key] = value
	end
	local instance = create("TextBox", defaults)
	if instance.TextScaled then
		create("UITextSizeConstraint", {
			MinTextSize = minTextSize,
			MaxTextSize = maxTextSize,
			Parent = instance,
		})
	end
	rounded(instance, 8)
	stroke(instance, COLORS.CardStroke, 1)
	return instance
end

local function clear(container)
	for _, child in ipairs(container:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") and not child:IsA("UICorner") and not child:IsA("UIStroke") then
			child:Destroy()
		end
	end
end

local function makeTransactionRow(parent, transaction, onOpen, zIndex)
	local row = create("TextButton", {
		Name = "TransactionRow",
		AutoButtonColor = true,
		BackgroundColor3 = COLORS.Card,
		BorderSizePixel = 0,
		Text = "",
		Size = UDim2.new(1, 0, 0, 52),
		ZIndex = zIndex,
		Parent = parent,
	})

	local iconBg = COLORS.GoldLight
	local iconTint = COLORS.Gold
	local iconAsset = ICONS.Chip

	if transaction.Direction == "INCOMING" then
		iconBg = COLORS.GreenLight
		iconTint = COLORS.Green
		iconAsset = ICONS.Incoming
	elseif transaction.Direction == "OUTGOING" then
		iconBg = COLORS.RedLight
		iconTint = COLORS.Red
		iconAsset = ICONS.Outgoing
	end

	local iconFrame = create("Frame", {
		Name = "TypeIcon",
		BackgroundColor3 = iconBg,
		Position = UDim2.new(0, 10, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.fromOffset(32, 32),
		ZIndex = zIndex + 1,
		Parent = row,
	})
	rounded(iconFrame, 16)

	iconImage({
		Name = "Glyph",
		Parent = iconFrame,
		Image = iconAsset,
		ImageColor3 = iconTint,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.55, 0.55),
		ZIndex = zIndex + 2,
	})

	label({
		Name = "Title",
		Parent = row,
		Font = Constants.Fonts.Semibold,
		Text = transactionTitle(transaction),
		TextColor3 = COLORS.TextDark,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.new(0, 50, 0, 9),
		Size = UDim2.new(0.44, 0, 0, 16),
		MaxTextSize = 11,
		MinTextSize = 8,
		ZIndex = zIndex + 1,
	})

	label({
		Name = "Subtitle",
		Parent = row,
		Text = transaction.Description or "-",
		TextColor3 = COLORS.TextMuted,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.new(0, 50, 0, 26),
		Size = UDim2.new(0.44, 0, 0, 14),
		MaxTextSize = 10,
		MinTextSize = 7,
		ZIndex = zIndex + 1,
	})

	local amountText, amountColor = signedAmount(transaction)
	label({
		Name = "Amount",
		Parent = row,
		Font = Constants.Fonts.Semibold,
		Text = amountText,
		TextColor3 = amountColor,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 9),
		Size = UDim2.new(0.46, 0, 0, 16),
		MaxTextSize = 12,
		MinTextSize = 8,
		ZIndex = zIndex + 1,
	})

	label({
		Name = "Time",
		Parent = row,
		Text = shortDate(transaction.Timestamp),
		TextColor3 = COLORS.TextMuted,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 26),
		Size = UDim2.new(0.46, 0, 0, 14),
		MaxTextSize = 10,
		MinTextSize = 7,
		ZIndex = zIndex + 1,
	})

	create("Frame", {
		Name = "Separator",
		BackgroundColor3 = COLORS.CardStroke,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 50, 1, -1),
		Size = UDim2.new(1, -50, 0, 1),
		ZIndex = zIndex + 1,
		Parent = row,
	})

	row.Activated:Connect(function()
		onOpen(transaction)
	end)

	return row
end

function Bank.Create(context)
	local state = {
		Balance = 0,
		PhoneNumber = "-",
		PlayerName = "Cardholder",
		Transactions = {},
		Loaded = false,
		Loading = false,
		Error = nil,
		Page = "home",
		VisibleHistory = PAGE_SIZE,
		SelectedTransaction = nil,
		HideBalance = false,
	}

	local refs = {}
	local connections = {}
	local destroyed = false

	local root = create("Frame", {
		Name = "BankApp",
		BackgroundColor3 = COLORS.Background,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
	})

	StatusBar.new(root, { Light = false, Battery = "100%" })

	local navHeight = 0.075
	local nav = create("Frame", {
		Name = "NavigationBar",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, Constants.Screen.StatusBarHeight),
		Size = UDim2.fromScale(1, navHeight),
		ZIndex = 80,
		Parent = root,
	})
	stroke(nav, COLORS.CardStroke, 1)

	local back = create("TextButton", {
		Name = "BackButton",
		AutoButtonColor = true,
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "く",
		TextColor3 = Color3.fromRGB(0, 122, 255),
		TextSize =20,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 8, 0, 8),
		Size = UDim2.new(0, 100, 0, 10),
		ZIndex = 81,
		Parent = nav,
	})

	refs.Title = label({
		Name = "Title",
		Parent = nav,
		Font = Constants.Fonts.Semibold,
		Text = "Bank",
		TextColor3 = COLORS.TextDark,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.5, 0.6),
		MaxTextSize = 15,
		MinTextSize = 10,
		ZIndex = 81,
	})

	refs.RefreshButton = create("TextButton", {
		Name = "RefreshButton",
		AutoButtonColor = true,
		BackgroundTransparency = 1,
		Text = "",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.new(0, 17, 0, 17),
		ZIndex = 81,
		Parent = nav,
	})
	local refreshIcon = iconImage({
		Name = "RefreshIcon",
		Image = ICONS.Refresh,
		ImageColor3 = COLORS.TextDark,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(20, 20),
		ZIndex = 82,
		Parent = refs.RefreshButton,
	})
	create("UIAspectRatioConstraint", {
		AspectRatio = 1,
		DominantAxis = Enum.DominantAxis.Width,
		Parent = refreshIcon,
	})

	local contentTop = Constants.Screen.StatusBarHeight + navHeight
	local pages = create("Frame", {
		Name = "Pages",
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = UDim2.fromScale(0, contentTop),
		Size = UDim2.fromScale(1, 1 - contentTop),
		ZIndex = 51,
		Parent = root,
	})

	-- HOME PAGE
	local home = create("Frame", {
		Name = "HomePage",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 51,
		Parent = pages,
	})

	-- inner padded container (4% each side)
	local homePad = create("Frame", {
		Name = "HomePad",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.04, 0.015),
		Size = UDim2.fromScale(0.92, 0.97),
		ZIndex = 51,
		Parent = home,
	})

	-- BALANCE CARD (Debit Card style) — 30% height of content area
	local balanceCard = create("Frame", {
		Name = "BalanceCard",
		BackgroundColor3 = COLORS.EmeraldDark,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(1, 0.30),
		ZIndex = 52,
		Parent = homePad,
	})
	rounded(balanceCard, 12)
	create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, COLORS.EmeraldDark),
			ColorSequenceKeypoint.new(1, COLORS.EmeraldMain),
		}),
		Rotation = 35,
		Parent = balanceCard,
	})

	-- Card Chip & Decorative icons
	local chip = create("Frame", {
		Name = "Chip",
		BackgroundColor3 = Color3.fromRGB(240, 200, 90),
		Position = UDim2.fromScale(0.06, 0.10),
		Size = UDim2.fromScale(0.10, 0.20),
		ZIndex = 53,
		Parent = balanceCard,
	})
	rounded(chip, 3)
	create("UIAspectRatioConstraint", { AspectRatio = 1.5, Parent = chip })

	iconImage({
		Name = "Contactless",
		Image = ICONS.Contactless,
		ImageColor3 = Color3.fromRGB(220, 245, 235),
		ImageTransparency = 0.2,
		Position = UDim2.fromScale(0.19, 0.10),
		Size = UDim2.fromScale(0.07, 0.18),
		ZIndex = 53,
		Parent = balanceCard,
	})

	label({
		Name = "BankBrand",
		Parent = balanceCard,
		Font = Constants.Fonts.Semibold,
		Text = "PUTIH-ABU BANK",
		TextColor3 = Color3.fromRGB(210, 245, 230),
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromScale(0.38, 0.09),
		Size = UDim2.fromScale(0.56, 0.15),
		MaxTextSize = 10,
		MinTextSize = 7,
		ZIndex = 53,
	})

	label({
		Name = "BalanceLabel",
		Parent = balanceCard,
		Text = "AVAILABLE BALANCE",
		TextColor3 = Color3.fromRGB(180, 235, 210),
		Position = UDim2.fromScale(0.06, 0.34),
		Size = UDim2.fromScale(0.65, 0.12),
		MaxTextSize = 9,
		MinTextSize = 7,
		ZIndex = 53,
	})

	local eyeBtn = create("TextButton", {
		Name = "EyeToggle",
		AutoButtonColor = true,
		BackgroundTransparency = 1,
		Text = "",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(0.95, 0.40),
		Size = UDim2.fromScale(0.09, 0.15),
		ZIndex = 54,
		Parent = balanceCard,
	})

	local eyeIcon = iconImage({
		Name = "EyeIcon",
		Image = ICONS.Eye,
		ImageColor3 = Color3.fromRGB(200, 240, 225),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 55,
		Parent = eyeBtn,
	})

	refs.BalanceText = label({
		Name = "Balance",
		Parent = balanceCard,
		Font = Constants.Fonts.Semibold,
		Text = money(0),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.fromScale(0.06, 0.47),
		Size = UDim2.fromScale(0.88, 0.26),
		MaxTextSize = 22,
		MinTextSize = 12,
		ZIndex = 53,
	})

	refs.PlayerNameText = label({
		Name = "PlayerName",
		Parent = balanceCard,
		Text = "Cardholder",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.fromScale(0.06, 0.80),
		Size = UDim2.fromScale(0.44, 0.14),
		MaxTextSize = 10,
		MinTextSize = 7,
		ZIndex = 53,
	})

	refs.PhoneText = label({
		Name = "PhoneNumber",
		Parent = balanceCard,
		Text = "Phone: -",
		TextColor3 = Color3.fromRGB(190, 240, 225),
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromScale(0.48, 0.80),
		Size = UDim2.fromScale(0.46, 0.14),
		MaxTextSize = 10,
		MinTextSize = 7,
		ZIndex = 53,
	})

	-- QUICK ACTIONS SECTION — starts at 32%
	label({
		Name = "QuickActionsTitle",
		Parent = homePad,
		Font = Constants.Fonts.Semibold,
		Text = "QUICK ACTIONS",
		TextColor3 = COLORS.TextMuted,
		Position = UDim2.fromScale(0, 0.322),
		Size = UDim2.fromScale(1, 0.05),
		MaxTextSize = 11,
		MinTextSize = 8,
		ZIndex = 52,
	})

	local actionsContainer = create("Frame", {
		Name = "QuickActionsContainer",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0, 0.375),
		Size = UDim2.fromScale(1, 0.115),
		ZIndex = 52,
		Parent = homePad,
	})

	local function makeQuickActionCard(name, titleText, iconAsset, iconTint, xPos, width)
		local actionCard = create("TextButton", {
			Name = name,
			AutoButtonColor = true,
			BackgroundColor3 = COLORS.Card,
			BorderSizePixel = 0,
			Text = "",
			Position = UDim2.fromScale(xPos, 0),
			Size = UDim2.fromScale(width, 1),
			ZIndex = 53,
			Parent = actionsContainer,
		})
		rounded(actionCard, 10)
		stroke(actionCard, COLORS.CardStroke, 1)

		local actionIcon = iconImage({
			Name = "Icon",
			Image = iconAsset,
			ImageColor3 = iconTint,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.36),
			Size = UDim2.fromScale(0.32, 0.55),
			ZIndex = 54,
			Parent = actionCard,
		})
		create("UIAspectRatioConstraint", {
			AspectRatio = 1,
			DominantAxis = Enum.DominantAxis.Width,
			Parent = actionIcon,
		})

		label({
			Name = "ActionText",
			Parent = actionCard,
			Font = Constants.Fonts.Semibold,
			Text = titleText,
			TextColor3 = COLORS.TextDark,
			TextXAlignment = Enum.TextXAlignment.Center,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.66),
			Size = UDim2.fromScale(0.9, 0.28),
			MaxTextSize = 12,
			MinTextSize = 9,
			ZIndex = 54,
		})

		return actionCard
	end

	refs.TransferQuick = makeQuickActionCard("TransferQuick", "Transfer", ICONS.Transfer, COLORS.Blue, 0, 0.485)
	refs.HistoryQuick = makeQuickActionCard("HistoryQuick", "History", ICONS.History, COLORS.EmeraldMain, 0.515, 0.485)

	-- RECENT TRANSACTIONS SECTION — starts at ~50.5%
	label({
		Name = "RecentTitle",
		Parent = homePad,
		Font = Constants.Fonts.Semibold,
		Text = "LAST TRANSACTIONS",
		TextColor3 = COLORS.TextMuted,
		Position = UDim2.fromScale(0, 0.507),
		Size = UDim2.fromScale(0.65, 0.05),
		MaxTextSize = 11,
		MinTextSize = 8,
		ZIndex = 52,
	})

	local seeAllBtn = create("TextButton", {
		Name = "SeeAllBtn",
		AutoButtonColor = true,
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Semibold,
		Text = "See All",
		TextColor3 = COLORS.EmeraldMain,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromScale(0.65, 0.507),
		Size = UDim2.fromScale(0.35, 0.05),
		ZIndex = 52,
		Parent = homePad,
	})
	create("UITextSizeConstraint", { MinTextSize = 8, MaxTextSize = 11, Parent = seeAllBtn })

	refs.RecentList = create("Frame", {
		Name = "RecentList",
		BackgroundColor3 = COLORS.Card,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = UDim2.fromScale(0, 0.56),
		Size = UDim2.fromScale(1, 0.44),
		ZIndex = 52,
		Parent = homePad,
	})
	rounded(refs.RecentList, 10)
	stroke(refs.RecentList, COLORS.CardStroke, 1)
	create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = refs.RecentList,
	})

	-- TRANSFER PAGE
	local transfer = create("ScrollingFrame", {
		Name = "TransferPage",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = COLORS.TextMuted,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 51,
		Parent = pages,
	})
	padded(transfer, 0.04, 0.04, 0.02, 0.04)
	create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		Parent = transfer,
	})

	local form = create("Frame", {
		Name = "TransferForm",
		BackgroundColor3 = COLORS.Card,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 235),
		LayoutOrder = 1,
		ZIndex = 52,
		Parent = transfer,
	})
	rounded(form, 12)
	stroke(form, COLORS.CardStroke, 1)
	padded(form, 0.04, 0.04, 0.03, 0.03)

	-- Recipient Phone Field
	label({
		Parent = form,
		Font = Constants.Fonts.Semibold,
		Text = "RECIPIENT PHONE NUMBER",
		TextColor3 = COLORS.TextMuted,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 14),
		MaxTextSize = 10,
		MinTextSize = 8,
		ZIndex = 53,
	})

	local phoneBoxFrame = create("Frame", {
		Name = "PhoneBoxFrame",
		BackgroundColor3 = Color3.fromRGB(246, 247, 250),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 18),
		Size = UDim2.new(1, 0, 0, 36),
		ZIndex = 53,
		Parent = form,
	})
	rounded(phoneBoxFrame, 8)
	stroke(phoneBoxFrame, COLORS.CardStroke, 1)

	iconImage({
		Name = "PhoneIcon",
		Image = ICONS.Phone,
		ImageColor3 = COLORS.TextMuted,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.new(0, 18, 0, 18),
		ZIndex = 54,
		Parent = phoneBoxFrame,
	})

	refs.PhoneInput = input({
		Name = "PhoneInput",
		Parent = phoneBoxFrame,
		PlaceholderText = "Enter phone number",
		Position = UDim2.new(0, 36, 0, 0),
		Size = UDim2.new(1, -44, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		MaxTextSize = 13,
		MinTextSize = 9,
		ZIndex = 54,
	})

	-- Amount Field
	label({
		Parent = form,
		Font = Constants.Fonts.Semibold,
		Text = "NOMINAL TRANSFER (Rp)",
		TextColor3 = COLORS.TextMuted,
		Position = UDim2.new(0, 0, 0, 60),
		Size = UDim2.new(1, 0, 0, 14),
		MaxTextSize = 10,
		MinTextSize = 8,
		ZIndex = 53,
	})

	local amountBoxFrame = create("Frame", {
		Name = "AmountBoxFrame",
		BackgroundColor3 = Color3.fromRGB(246, 247, 250),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 78),
		Size = UDim2.new(1, 0, 0, 36),
		ZIndex = 53,
		Parent = form,
	})
	rounded(amountBoxFrame, 8)
	stroke(amountBoxFrame, COLORS.CardStroke, 1)

	label({
		Parent = amountBoxFrame,
		Font = Constants.Fonts.Semibold,
		Text = "Rp",
		TextColor3 = COLORS.EmeraldMain,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(0, 24, 1, 0),
		MaxTextSize = 14,
		MinTextSize = 10,
		ZIndex = 54,
	})

	refs.AmountInput = input({
		Name = "AmountInput",
		Parent = amountBoxFrame,
		PlaceholderText = "0",
		Position = UDim2.new(0, 36, 0, 0),
		Size = UDim2.new(1, -44, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		MaxTextSize = 14,
		MinTextSize = 9,
		ZIndex = 54,
	})

	-- Quick Chips Preset
	local chipsFrame = create("Frame", {
		Name = "ChipsFrame",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 120),
		Size = UDim2.new(1, 0, 0, 26),
		ZIndex = 53,
		Parent = form,
	})

	local presets = {
		{ Label = "+10rb", Value = 10000 },
		{ Label = "+50rb", Value = 50000 },
		{ Label = "+100rb", Value = 100000 },
		{ Label = "+500rb", Value = 500000 },
	}
	for idx, preset in ipairs(presets) do
		local xPos = (idx - 1) * 0.255
		local chipBtn = button({
			Name = "Chip" .. preset.Value,
			Parent = chipsFrame,
			Text = preset.Label,
			BackgroundColor3 = COLORS.EmeraldLight,
			TextColor3 = COLORS.EmeraldMain,
			Position = UDim2.fromScale(xPos, 0),
			Size = UDim2.fromScale(0.235, 1),
			MaxTextSize = 11,
			MinTextSize = 8,
			ZIndex = 54,
		})
		stroke(chipBtn, COLORS.EmeraldMain, 1, 0.7)
		chipBtn.Activated:Connect(function()
			local current = tonumber(refs.AmountInput.Text) or 0
			refs.AmountInput.Text = tostring(current + preset.Value)
		end)
	end

	-- Description Field
	label({
		Parent = form,
		Font = Constants.Fonts.Semibold,
		Text = "NOTE / DESCRIPTION (OPTIONAL)",
		TextColor3 = COLORS.TextMuted,
		Position = UDim2.new(0, 0, 0, 154),
		Size = UDim2.new(1, 0, 0, 14),
		MaxTextSize = 10,
		MinTextSize = 8,
		ZIndex = 53,
	})

	local descBoxFrame = create("Frame", {
		Name = "DescBoxFrame",
		BackgroundColor3 = Color3.fromRGB(246, 247, 250),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 172),
		Size = UDim2.new(1, 0, 0, 36),
		ZIndex = 53,
		Parent = form,
	})
	rounded(descBoxFrame, 8)
	stroke(descBoxFrame, COLORS.CardStroke, 1)

	iconImage({
		Name = "NoteIcon",
		Image = ICONS.Note,
		ImageColor3 = COLORS.TextMuted,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.new(0, 18, 0, 18),
		ZIndex = 54,
		Parent = descBoxFrame,
	})

	refs.DescriptionInput = input({
		Name = "DescriptionInput",
		Parent = descBoxFrame,
		PlaceholderText = "e.g. Lunch reimbursement",
		Position = UDim2.new(0, 36, 0, 0),
		Size = UDim2.new(1, -44, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		MaxTextSize = 13,
		MinTextSize = 9,
		ZIndex = 54,
	})

	-- Primary Transfer Action Button
	refs.TransferButton = button({
		Name = "TransferButton",
		Parent = transfer,
		Text = "Send Money Now",
		BackgroundColor3 = COLORS.EmeraldMain,
		Size = UDim2.new(1, 0, 0, 42),
		LayoutOrder = 2,
		MaxTextSize = 14,
		MinTextSize = 10,
		ZIndex = 52,
	})

	refs.TransferHint = label({
		Name = "TransferHint",
		Parent = transfer,
		Text = "Bank service unavailable. You can still browse while data loads.",
		TextColor3 = COLORS.Red,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, 20),
		LayoutOrder = 3,
		MaxTextSize = 10,
		MinTextSize = 8,
		ZIndex = 52,
	})

	-- HISTORY PAGE
	local history = create("Frame", {
		Name = "HistoryPage",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 51,
		Parent = pages,
	})
	padded(history, 0.04, 0.04, 0.02, 0.04)

	refs.HistoryList = create("ScrollingFrame", {
		Name = "HistoryList",
		BackgroundColor3 = COLORS.Card,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		Position = UDim2.fromScale(0, 0.01),
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = COLORS.TextMuted,
		Size = UDim2.fromScale(1, 0.96),
		ZIndex = 52,
		Parent = history,
	})
	rounded(refs.HistoryList, 10)
	stroke(refs.HistoryList, COLORS.CardStroke, 1)
	create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = refs.HistoryList,
	})

	-- DETAILS / RECEIPT PAGE — scale-based, no scroll needed
	local details = create("Frame", {
		Name = "DetailsPage",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 51,
		Parent = pages,
	})

	-- inner padded container
	local detailsPad = create("Frame", {
		Name = "DetailsPad",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.04, 0.015),
		Size = UDim2.fromScale(0.92, 0.97),
		ZIndex = 51,
		Parent = details,
	})

	refs.DetailsCard = create("Frame", {
		Name = "DetailsCard",
		BackgroundColor3 = COLORS.Card,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 52,
		Parent = detailsPad,
	})
	rounded(refs.DetailsCard, 12)
	stroke(refs.DetailsCard, COLORS.CardStroke, 1)

	-- LOADING OVERLAY
	refs.LoadingOverlay = create("Frame", {
		Name = "LoadingOverlay",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 120,
		Parent = root,
	})

	local spinnerBox = create("Frame", {
		Name = "SpinnerBox",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromOffset(80, 80),
		ZIndex = 121,
		Parent = refs.LoadingOverlay,
	})
	rounded(spinnerBox, 12)

	local spinner = iconImage({
		Name = "SpinnerIcon",
		Image = ICONS.Refresh,
		ImageColor3 = COLORS.EmeraldMain,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.38),
		Size = UDim2.fromOffset(32, 32),
		ZIndex = 122,
		Parent = spinnerBox,
	})

	label({
		Name = "LoadingText",
		Parent = spinnerBox,
		Text = "Processing...",
		TextColor3 = COLORS.TextDark,
		Font = Constants.Fonts.Semibold,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.7),
		Size = UDim2.fromScale(0.9, 0.22),
		MaxTextSize = 11,
		MinTextSize = 8,
		ZIndex = 122,
	})

	-- DIALOG LAYER
	refs.DialogLayer = create("Frame", {
		Name = "DialogLayer",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 130,
		Parent = root,
	})

	-- LOGIC & HANDLERS
	local function setPage(page)
		state.Page = page
		home.Visible = page == "home"
		transfer.Visible = page == "transfer"
		history.Visible = page == "history"
		details.Visible = page == "details"
		refs.Title.Text = if page == "transfer" then "Transfer" elseif page == "history" then "History" elseif page == "details" then "Receipt" else "Bank"
	end

	local function setLoading(loading)
		state.Loading = loading
		refs.LoadingOverlay.Visible = loading
	end

	local function showDialog(title, body, actions)
		clear(refs.DialogLayer)
		refs.DialogLayer.Visible = true

		local card = create("Frame", {
			Name = "Dialog",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.84, 0.34),
			ZIndex = 131,
			Parent = refs.DialogLayer,
		})
		rounded(card, 12)
		stroke(card, COLORS.CardStroke, 1)
		padded(card, 0.06, 0.06, 0.06, 0.06)

		label({
			Parent = card,
			Font = Constants.Fonts.Semibold,
			Text = title,
			TextColor3 = COLORS.TextDark,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromScale(0, 0.05),
			Size = UDim2.fromScale(1, 0.18),
			MaxTextSize = 15,
			MinTextSize = 10,
			ZIndex = 132,
		})

		label({
			Parent = card,
			Text = body,
			TextColor3 = COLORS.TextMuted,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextWrapped = true,
			Position = UDim2.fromScale(0, 0.28),
			Size = UDim2.fromScale(1, 0.38),
			MaxTextSize = 12,
			MinTextSize = 9,
			ZIndex = 132,
		})

		for index, action in ipairs(actions) do
			local width = if #actions == 1 then 1 else 0.47
			local x = if #actions == 1 then 0 else (index - 1) * 0.53
			local actionButton = button({
				Parent = card,
				Text = action.Text,
				BackgroundColor3 = action.Color or COLORS.EmeraldMain,
				TextColor3 = action.TextColor or Color3.fromRGB(255, 255, 255),
				Position = UDim2.fromScale(x, 0.74),
				Size = UDim2.fromScale(width, 0.24),
				MaxTextSize = 13,
				MinTextSize = 9,
				ZIndex = 132,
			})
			actionButton.Activated:Connect(function()
				refs.DialogLayer.Visible = false
				if action.Callback then
					action.Callback()
				end
			end)
		end

		card.Size = UDim2.fromScale(0.76, 0.28)
		TweenService:Create(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(0.84, 0.34),
		}):Play()
	end

	local function showError(message)
		showDialog("Unable to Continue", message or "Unknown error.", {
			{ Text = "OK", Callback = function() end },
		})
	end

	local function openTransactionDetails(transaction)
		state.SelectedTransaction = transaction
		setPage("details")
		clear(refs.DetailsCard)

		-- Top checkmark icon & header
		local statusIconCircle = create("Frame", {
			Name = "StatusIconCircle",
			BackgroundColor3 = COLORS.GreenLight,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.03),
			Size = UDim2.fromOffset(40, 40),
			ZIndex = 53,
			Parent = refs.DetailsCard,
		})
		rounded(statusIconCircle, 20)

		iconImage({
			Name = "CheckIcon",
			Image = ICONS.Check,
			ImageColor3 = COLORS.Green,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.6, 0.6),
			ZIndex = 54,
			Parent = statusIconCircle,
		})

		label({
			Parent = refs.DetailsCard,
			Font = Constants.Fonts.Semibold,
			Text = "TRANSACTION RECEIPT",
			TextColor3 = COLORS.TextMuted,
			TextXAlignment = Enum.TextXAlignment.Center,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.145),
			Size = UDim2.fromScale(0.9, 0.04),
			MaxTextSize = 10,
			MinTextSize = 8,
			ZIndex = 53,
		})

		local amtText, amtColor = signedAmount(transaction)
		label({
			Parent = refs.DetailsCard,
			Font = Constants.Fonts.Semibold,
			Text = amtText,
			TextColor3 = amtColor,
			TextXAlignment = Enum.TextXAlignment.Center,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.19),
			Size = UDim2.fromScale(0.9, 0.07),
			MaxTextSize = 22,
			MinTextSize = 14,
			ZIndex = 53,
		})

		-- Perforated divider line
		create("Frame", {
			Name = "Divider",
			BackgroundColor3 = COLORS.CardStroke,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.06, 0.285),
			Size = UDim2.fromScale(0.88, 0.004),
			ZIndex = 53,
			Parent = refs.DetailsCard,
		})

		local fields = {
			{ "Transaction ID", transaction.Id },
			{ "Type", transaction.Type },
			{ "Sender", transaction.Sender },
			{ "Receiver", transaction.Receiver },
			{ "Description", transaction.Description },
			{ "Date & Time", shortDate(transaction.Timestamp) },
			{ "Status", transaction.Status },
		}

		for fieldIndex, field in ipairs(fields) do
			local y = 0.315 + (fieldIndex - 1) * 0.075
			label({
				Parent = refs.DetailsCard,
				Text = field[1],
				TextColor3 = COLORS.TextMuted,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.fromScale(0.06, y),
				Size = UDim2.fromScale(0.38, 0.05),
				MaxTextSize = 11,
				MinTextSize = 8,
				ZIndex = 53,
			})
			label({
				Parent = refs.DetailsCard,
				Font = Constants.Fonts.Semibold,
				Text = tostring(field[2] or "-"),
				TextColor3 = COLORS.TextDark,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Position = UDim2.fromScale(0.46, y),
				Size = UDim2.fromScale(0.48, 0.05),
				MaxTextSize = 11,
				MinTextSize = 8,
				ZIndex = 53,
			})
		end

		local doneBtn = button({
			Parent = refs.DetailsCard,
			Text = "Back to Home",
			BackgroundColor3 = COLORS.EmeraldMain,
			Position = UDim2.fromScale(0.06, 0.865),
			Size = UDim2.fromScale(0.88, 0.095),
			MaxTextSize = 13,
			MinTextSize = 9,
			ZIndex = 53,
		})
		doneBtn.Activated:Connect(function()
			setPage("home")
		end)
	end

	local function renderRecent()
		clear(refs.RecentList)
		if #state.Transactions == 0 then
			label({
				Parent = refs.RecentList,
				Text = "No transactions yet.",
				TextColor3 = COLORS.TextMuted,
				TextXAlignment = Enum.TextXAlignment.Center,
				Size = UDim2.new(1, 0, 0, 56),
				MaxTextSize = 12,
				MinTextSize = 9,
				ZIndex = 53,
			})
			return
		end

		for index = 1, math.min(3, #state.Transactions) do
			makeTransactionRow(refs.RecentList, state.Transactions[index], function(transaction)
				openTransactionDetails(transaction)
			end, 53).LayoutOrder = index
		end
	end

	local function renderHistory()
		clear(refs.HistoryList)
		local visibleCount = math.min(state.VisibleHistory, #state.Transactions)
		refs.HistoryList.CanvasSize = UDim2.fromOffset(0, math.max(visibleCount * 56, refs.HistoryList.AbsoluteSize.Y + 1))

		if #state.Transactions == 0 then
			label({
				Parent = refs.HistoryList,
				Text = if state.Loading then "Loading transactions..." else "No transactions yet.",
				TextColor3 = COLORS.TextMuted,
				TextXAlignment = Enum.TextXAlignment.Center,
				Size = UDim2.new(1, 0, 0, 70),
				MaxTextSize = 12,
				MinTextSize = 9,
				ZIndex = 53,
			})
			return
		end

		for index = 1, visibleCount do
			makeTransactionRow(refs.HistoryList, state.Transactions[index], function(transaction)
				openTransactionDetails(transaction)
			end, 53).LayoutOrder = index
		end
	end

	local function render()
		if state.HideBalance then
			refs.BalanceText.Text = "Rp • • • • •"
		else
			refs.BalanceText.Text = money(state.Balance)
		end

		refs.PhoneText.Text = "Phone: " .. (state.PhoneNumber or "-")
		refs.PlayerNameText.Text = state.PlayerName or "Cardholder"

		refs.TransferButton.Active = state.Loaded and not state.Loading
		refs.TransferButton.AutoButtonColor = state.Loaded and not state.Loading
		refs.TransferButton.BackgroundColor3 = if state.Loaded then COLORS.EmeraldMain else Color3.fromRGB(170, 170, 176)
		refs.TransferHint.Visible = not state.Loaded
		renderRecent()
		renderHistory()
	end

	eyeBtn.Activated:Connect(function()
		state.HideBalance = not state.HideBalance
		eyeIcon.ImageTransparency = if state.HideBalance then 0.6 else 0
		render()
	end)

	seeAllBtn.Activated:Connect(function()
		state.VisibleHistory = PAGE_SIZE
		setPage("history")
		renderHistory()
	end)

	local function sendTransactionNotification(transaction)
		if not transaction then
			return
		end

		local amountText = money(transaction.Amount)
		local description = transaction.Description or "-"
		local title = "Transaksi Bank"
		local body = amountText .. " - " .. description
		local iconAsset = ICONS.Chip
		local iconColor = COLORS.Gold
		local iconBg = COLORS.GoldLight

		if transaction.Direction == "INCOMING" then
			title = "Uang Masuk"
			local sender = if transaction.Sender and transaction.Sender ~= "Unknown" and transaction.Sender ~= "-" then transaction.Sender else "Pengirim"
			body = "+" .. amountText .. " dari " .. sender
			iconAsset = ICONS.Incoming
			iconColor = COLORS.Green
			iconBg = COLORS.GreenLight
		elseif transaction.Direction == "OUTGOING" then
			title = "Transfer Berhasil"
			local receiver = if transaction.Receiver and transaction.Receiver ~= "Unknown" and transaction.Receiver ~= "-" then transaction.Receiver else "Penerima"
			body = "-" .. amountText .. " ke " .. receiver
			iconAsset = ICONS.Outgoing
			iconColor = COLORS.Red
			iconBg = COLORS.RedLight
		end

		if description ~= "-" and description ~= "" then
			body = body .. " • \"" .. description .. "\""
		end

		if context.SendNotification then
			context.SendNotification({
				App = "BANK",
				Title = title,
				Body = body,
				Icon = iconAsset,
				IconColor = iconColor,
				IconBg = iconBg,
			})
		end
	end

	local function refreshAll(showOverlay)
		if destroyed then
			return
		end

		if showOverlay then
			setLoading(true)
			TweenService:Create(refreshIcon, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Rotation = refreshIcon.Rotation + 360,
			}):Play()
		end

		task.spawn(function()
			local success, data = pcall(function()
				return EconomyAdapter.GetPlayerData()
			end)
			local hSuccess, history = pcall(function()
				return EconomyAdapter.GetTransactionHistory()
			end)

			if success and typeof(data) == "table" then
				state.Balance = data.Balance or state.Balance or 0
				if data.PhoneNumber and data.PhoneNumber ~= "-" then
					state.PhoneNumber = data.PhoneNumber
				end
				if data.PlayerName and data.PlayerName ~= "Unknown" then
					state.PlayerName = data.PlayerName
				end
			end
			if hSuccess and typeof(history) == "table" then
				state.Transactions = history
			end

			state.Loaded = true -- Always keep state.Loaded = true once loaded so UI buttons are never permanently locked
			state.Error = nil

			if showOverlay then
				setLoading(false)
			end
			render()
		end)
	end

	local function bindEconomyEvents()
		task.spawn(function()
			for _attempt = 1, 10 do
				if destroyed then
					return
				end

				local balanceConnection = EconomyAdapter.OnBalanceChanged(function(balance)
					state.Balance = balance
					refreshAll(false)
				end)
				local transactionConnection = EconomyAdapter.OnTransactionCreated(function(transaction)
					sendTransactionNotification(transaction)
					refreshAll(false)
				end)
				local dataConnection = EconomyAdapter.OnPlayerDataLoaded(function()
					refreshAll(false)
				end)

				if balanceConnection or transactionConnection or dataConnection then
					table.insert(connections, balanceConnection)
					table.insert(connections, transactionConnection)
					table.insert(connections, dataConnection)
					return
				end

				task.wait(3)
			end
		end)
	end

	refs.PhoneInput:GetPropertyChangedSignal("Text"):Connect(function()
		local cleaned = refs.PhoneInput.Text:gsub("%D", "")
		if cleaned ~= refs.PhoneInput.Text then
			refs.PhoneInput.Text = cleaned
		end
	end)

	refs.AmountInput:GetPropertyChangedSignal("Text"):Connect(function()
		local cleaned = refs.AmountInput.Text:gsub("[^%d%.]", "")
		if cleaned ~= refs.AmountInput.Text then
			refs.AmountInput.Text = cleaned
		end
	end)

	refs.TransferQuick.Activated:Connect(function()
		setPage("transfer")
	end)

	refs.HistoryQuick.Activated:Connect(function()
		state.VisibleHistory = PAGE_SIZE
		setPage("history")
		renderHistory()
	end)

	refs.RefreshButton.Activated:Connect(function()
		refreshAll(true)
	end)

	back.Activated:Connect(function()
		if state.Page == "home" then
			context.CloseCurrentApp()
		else
			setPage("home")
		end
	end)

	refs.HistoryList:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		local remaining = refs.HistoryList.CanvasSize.Y.Offset - refs.HistoryList.AbsoluteSize.Y - refs.HistoryList.CanvasPosition.Y
		if remaining < 80 and state.VisibleHistory < #state.Transactions then
			state.VisibleHistory += PAGE_SIZE
			renderHistory()
		end
	end)

	refs.TransferButton.Activated:Connect(function()
		if not state.Loaded then
			showError("Bank service is still loading. Please try again shortly.")
			return
		end

		local phone = refs.PhoneInput.Text:gsub("%D", "")
		local amount = tonumber(refs.AmountInput.Text)
		local description = refs.DescriptionInput.Text
		if phone == "" then
			showError("Invalid phone number.")
			return
		end
		if not amount or amount <= 0 then
			showError("Invalid transfer amount.")
			return
		end
		if description == "" then
			description = "-"
		end

		showDialog("Confirm Transfer", "Send " .. money(amount) .. " to " .. phone .. "?\n" .. description, {
			{
				Text = "Cancel",
				Color = Color3.fromRGB(230, 230, 235),
				TextColor = COLORS.Blue,
			},
			{
				Text = "Confirm",
				Callback = function()
					setLoading(true)
					task.spawn(function()
						local success, result = pcall(function()
							return EconomyAdapter.Transfer(phone, amount, description)
						end)

						setLoading(false)
						refreshAll(false)

						if success and typeof(result) == "table" and result.Success then
							refs.PhoneInput.Text = ""
							refs.AmountInput.Text = ""
							refs.DescriptionInput.Text = ""
							showDialog("Transfer Complete", "Sent " .. money(amount) .. " to " .. phone .. ".\nCurrent balance " .. money(state.Balance), {
								{
									Text = "Done",
									Callback = function()
										setPage("home")
									end,
								},
							})
						else
							local errMsg = "Transfer failed."
							if not success then
								errMsg = "Error executing transfer."
							elseif typeof(result) == "table" and result.Message then
								errMsg = result.Message
							end
							showError(errMsg)
						end
					end)
				end,
			},
		})
	end)

	root.Destroying:Connect(function()
		destroyed = true
		for _, connection in ipairs(connections) do
			if connection then
				connection:Disconnect()
			end
		end
	end)

	render()
	refreshAll(false)
	bindEconomyEvents()

	task.spawn(function()
		while not destroyed and not state.Loaded do
			task.wait(8)
			refreshAll(false)
		end
	end)

	task.spawn(function()
		while not destroyed do
			spinner.Rotation = 0
			TweenService:Create(spinner, TweenInfo.new(0.9, Enum.EasingStyle.Linear), { Rotation = 360 }):Play()
			task.wait(0.92)
		end
	end)

	return root
end

return Bank
