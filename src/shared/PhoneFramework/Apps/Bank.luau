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
	Background = Color3.fromRGB(239, 239, 244),
	Card = Color3.fromRGB(255, 255, 255),
	Line = Color3.fromRGB(213, 213, 218),
	Text = Color3.fromRGB(23, 23, 25),
	Muted = Color3.fromRGB(116, 116, 122),
	Blue = Color3.fromRGB(0, 122, 255),
	Green = Color3.fromRGB(18, 129, 91),
	Red = Color3.fromRGB(214, 58, 58),
	Gold = Color3.fromRGB(198, 143, 45),
}

local PAGE_SIZE = 12

local function money(value)
	local amount = math.floor((tonumber(value) or 0) + 0.5)
	local text = tostring(amount)
	local result = ""
	while #text > 3 do
		result = "," .. string.sub(text, -3) .. result
		text = string.sub(text, 1, #text - 3)
	end
	return "$" .. text .. result
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

local function rounded(instance, scale)
	create("UICorner", {
		CornerRadius = UDim.new(scale, 0),
		Parent = instance,
	})
end

local function padded(instance, left, right, top, bottom)
	create("UIPadding", {
		PaddingLeft = UDim.new(left, 0),
		PaddingRight = UDim.new(right or left, 0),
		PaddingTop = UDim.new(top or 0, 0),
		PaddingBottom = UDim.new(bottom or top or 0, 0),
		Parent = instance,
	})
end

local function label(props)
	local defaults = {
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		TextColor3 = COLORS.Text,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}
	for key, value in pairs(props) do
		defaults[key] = value
	end
	return create("TextLabel", defaults)
end

local function button(props)
	local defaults = {
		AutoButtonColor = true,
		BackgroundColor3 = COLORS.Blue,
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
	rounded(instance, 0.08)
	return instance
end

local function input(props)
	local defaults = {
		BackgroundColor3 = Color3.fromRGB(248, 248, 250),
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Font = Constants.Fonts.Regular,
		PlaceholderColor3 = COLORS.Muted,
		Text = "",
		TextColor3 = COLORS.Text,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Selectable = true,
	}
	for key, value in pairs(props) do
		defaults[key] = value
	end
	local instance = create("TextBox", defaults)
	rounded(instance, 0.06)
	padded(instance, 0.04, 0.04)
	return instance
end

local function clear(container)
	for _, child in ipairs(container:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") and not child:IsA("UICorner") then
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
		Size = UDim2.new(1, 0, 0, 58),
		ZIndex = zIndex,
		Parent = parent,
	})

	local iconColor = COLORS.Gold
	if transaction.Direction == "INCOMING" then
		iconColor = COLORS.Green
	elseif transaction.Direction == "OUTGOING" then
		iconColor = COLORS.Red
	end

	local icon = create("Frame", {
		Name = "TypeIcon",
		BackgroundColor3 = iconColor,
		Position = UDim2.fromScale(0.035, 0.22),
		Size = UDim2.fromScale(0.115, 0.56),
		ZIndex = zIndex + 1,
		Parent = row,
	})
	rounded(icon, 0.5)

	label({
		Name = "Glyph",
		Parent = icon,
		Font = Constants.Fonts.Semibold,
		Text = if transaction.Direction == "OUTGOING" then "-" else "+",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		ZIndex = zIndex + 2,
	})

	label({
		Name = "Title",
		Parent = row,
		Font = Constants.Fonts.Semibold,
		Text = transactionTitle(transaction),
		TextColor3 = COLORS.Text,
		Position = UDim2.fromScale(0.18, 0.15),
		Size = UDim2.fromScale(0.46, 0.28),
		ZIndex = zIndex + 1,
	})

	label({
		Name = "Subtitle",
		Parent = row,
		Text = transaction.Description or "-",
		TextColor3 = COLORS.Muted,
		Position = UDim2.fromScale(0.18, 0.51),
		Size = UDim2.fromScale(0.47, 0.22),
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
		Position = UDim2.fromScale(0.64, 0.17),
		Size = UDim2.fromScale(0.31, 0.28),
		ZIndex = zIndex + 1,
	})

	label({
		Name = "Time",
		Parent = row,
		Text = shortDate(transaction.Timestamp),
		TextColor3 = COLORS.Muted,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromScale(0.66, 0.53),
		Size = UDim2.fromScale(0.29, 0.2),
		ZIndex = zIndex + 1,
	})

	create("Frame", {
		Name = "Separator",
		BackgroundColor3 = COLORS.Line,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.18, 0.985),
		Size = UDim2.fromScale(0.82, 0.015),
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
		PlayerName = "Unknown",
		Transactions = {},
		Loaded = false,
		Loading = false,
		Error = nil,
		Page = "home",
		VisibleHistory = PAGE_SIZE,
		SelectedTransaction = nil,
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

	local nav = create("Frame", {
		Name = "NavigationBar",
		BackgroundColor3 = Color3.fromRGB(248, 248, 248),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, Constants.Screen.StatusBarHeight),
		Size = UDim2.fromScale(1, 0.08),
		ZIndex = 80,
		Parent = root,
	})

	local back = create("TextButton", {
		Name = "BackButton",
		AutoButtonColor = true,
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "<",
		TextColor3 = COLORS.Blue,
		TextScaled = true,
		Position = UDim2.fromScale(0.02, 0.15),
		Size = UDim2.fromScale(0.12, 0.7),
		ZIndex = 81,
		Parent = nav,
	})

	refs.Title = label({
		Name = "Title",
		Parent = nav,
		Font = Constants.Fonts.Semibold,
		Text = "Bank",
		TextColor3 = COLORS.Text,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.55, 0.55),
		ZIndex = 81,
	})

	refs.RefreshButton = create("TextButton", {
		Name = "RefreshButton",
		AutoButtonColor = true,
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Semibold,
		Text = "Reload",
		TextColor3 = COLORS.Blue,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.fromScale(0.76, 0.22),
		Size = UDim2.fromScale(0.2, 0.5),
		ZIndex = 81,
		Parent = nav,
	})

	local pages = create("Frame", {
		Name = "Pages",
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = UDim2.fromScale(0, 0.116),
		Size = UDim2.fromScale(1, 0.884),
		ZIndex = 51,
		Parent = root,
	})

	local home = create("ScrollingFrame", {
		Name = "HomePage",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromScale(0, 1.25),
		ScrollBarThickness = 3,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 51,
		Parent = pages,
	})

	local balanceCard = create("Frame", {
		Name = "BalanceCard",
		BackgroundColor3 = COLORS.Green,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.035, 0.025),
		Size = UDim2.fromScale(0.93, 0.245),
		ZIndex = 52,
		Parent = home,
	})
	rounded(balanceCard, 0.045)

	label({
		Name = "BalanceLabel",
		Parent = balanceCard,
		Text = "Current Balance",
		TextColor3 = Color3.fromRGB(220, 247, 237),
		Position = UDim2.fromScale(0.06, 0.1),
		Size = UDim2.fromScale(0.7, 0.16),
		ZIndex = 53,
	})

	refs.BalanceText = label({
		Name = "Balance",
		Parent = balanceCard,
		Font = Constants.Fonts.Light,
		Text = money(0),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.fromScale(0.055, 0.32),
		Size = UDim2.fromScale(0.88, 0.28),
		ZIndex = 53,
	})

	refs.PhoneText = label({
		Name = "PhoneNumber",
		Parent = balanceCard,
		Text = "Phone -",
		TextColor3 = Color3.fromRGB(220, 247, 237),
		Position = UDim2.fromScale(0.06, 0.74),
		Size = UDim2.fromScale(0.86, 0.14),
		ZIndex = 53,
	})

	label({
		Name = "QuickActionsTitle",
		Parent = home,
		Font = Constants.Fonts.Semibold,
		Text = "Quick Actions",
		Position = UDim2.fromScale(0.045, 0.305),
		Size = UDim2.fromScale(0.6, 0.045),
		ZIndex = 52,
	})

	refs.TransferQuick = button({
		Name = "TransferQuick",
		Parent = home,
		Text = "Transfer",
		BackgroundColor3 = COLORS.Blue,
		Position = UDim2.fromScale(0.035, 0.365),
		Size = UDim2.fromScale(0.45, 0.088),
		ZIndex = 52,
	})

	refs.HistoryQuick = button({
		Name = "HistoryQuick",
		Parent = home,
		Text = "History",
		BackgroundColor3 = COLORS.Card,
		TextColor3 = COLORS.Blue,
		Position = UDim2.fromScale(0.515, 0.365),
		Size = UDim2.fromScale(0.45, 0.088),
		ZIndex = 52,
	})

	label({
		Name = "RecentTitle",
		Parent = home,
		Font = Constants.Fonts.Semibold,
		Text = "Last Transactions",
		Position = UDim2.fromScale(0.045, 0.49),
		Size = UDim2.fromScale(0.65, 0.045),
		ZIndex = 52,
	})

	refs.RecentList = create("Frame", {
		Name = "RecentList",
		BackgroundColor3 = COLORS.Card,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.035, 0.55),
		Size = UDim2.fromScale(0.93, 0.54),
		ZIndex = 52,
		Parent = home,
	})
	rounded(refs.RecentList, 0.025)
	create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = refs.RecentList,
	})

	local transfer = create("Frame", {
		Name = "TransferPage",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 51,
		Parent = pages,
	})

	local form = create("Frame", {
		Name = "TransferForm",
		BackgroundColor3 = COLORS.Card,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.035, 0.04),
		Size = UDim2.fromScale(0.93, 0.54),
		ZIndex = 52,
		Parent = transfer,
	})
	rounded(form, 0.025)

	label({
		Parent = form,
		Font = Constants.Fonts.Semibold,
		Text = "Recipient Phone Number",
		Position = UDim2.fromScale(0.05, 0.06),
		Size = UDim2.fromScale(0.9, 0.08),
		ZIndex = 53,
	})
	refs.PhoneInput = input({
		Name = "PhoneInput",
		Parent = form,
		PlaceholderText = "Numbers only",
		Position = UDim2.fromScale(0.05, 0.16),
		Size = UDim2.fromScale(0.9, 0.13),
		ZIndex = 53,
	})

	label({
		Parent = form,
		Font = Constants.Fonts.Semibold,
		Text = "Amount",
		Position = UDim2.fromScale(0.05, 0.33),
		Size = UDim2.fromScale(0.9, 0.08),
		ZIndex = 53,
	})
	refs.AmountInput = input({
		Name = "AmountInput",
		Parent = form,
		PlaceholderText = "0",
		Position = UDim2.fromScale(0.05, 0.43),
		Size = UDim2.fromScale(0.9, 0.13),
		ZIndex = 53,
	})

	label({
		Parent = form,
		Font = Constants.Fonts.Semibold,
		Text = "Description",
		Position = UDim2.fromScale(0.05, 0.6),
		Size = UDim2.fromScale(0.9, 0.08),
		ZIndex = 53,
	})
	refs.DescriptionInput = input({
		Name = "DescriptionInput",
		Parent = form,
		PlaceholderText = "Optional",
		Position = UDim2.fromScale(0.05, 0.7),
		Size = UDim2.fromScale(0.9, 0.13),
		ZIndex = 53,
	})

	refs.TransferButton = button({
		Name = "TransferButton",
		Parent = transfer,
		Text = "Transfer",
		Position = UDim2.fromScale(0.035, 0.625),
		Size = UDim2.fromScale(0.93, 0.09),
		ZIndex = 52,
	})

	refs.TransferHint = label({
		Name = "TransferHint",
		Parent = transfer,
		Text = "Bank service unavailable. You can still browse while data loads.",
		TextColor3 = COLORS.Muted,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromScale(0.06, 0.745),
		Size = UDim2.fromScale(0.88, 0.055),
		ZIndex = 52,
	})

	local history = create("Frame", {
		Name = "HistoryPage",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 51,
		Parent = pages,
	})

	refs.HistoryList = create("ScrollingFrame", {
		Name = "HistoryList",
		BackgroundColor3 = COLORS.Card,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		Position = UDim2.fromScale(0.035, 0.035),
		ScrollBarThickness = 3,
		Size = UDim2.fromScale(0.93, 0.92),
		ZIndex = 52,
		Parent = history,
	})
	rounded(refs.HistoryList, 0.025)
	create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = refs.HistoryList,
	})

	local details = create("Frame", {
		Name = "DetailsPage",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 51,
		Parent = pages,
	})

	refs.DetailsCard = create("Frame", {
		Name = "DetailsCard",
		BackgroundColor3 = COLORS.Card,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.035, 0.04),
		Size = UDim2.fromScale(0.93, 0.78),
		ZIndex = 52,
		Parent = details,
	})
	rounded(refs.DetailsCard, 0.025)

	refs.LoadingOverlay = create("Frame", {
		Name = "LoadingOverlay",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 120,
		Parent = root,
	})

	local spinner = create("Frame", {
		Name = "Spinner",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromScale(0.11, 0.062),
		ZIndex = 121,
		Parent = refs.LoadingOverlay,
	})
	rounded(spinner, 0.5)

	label({
		Name = "LoadingText",
		Parent = refs.LoadingOverlay,
		Text = "Loading",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.55),
		Size = UDim2.fromScale(0.5, 0.04),
		ZIndex = 121,
	})

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

	local function setPage(page)
		state.Page = page
		home.Visible = page == "home"
		transfer.Visible = page == "transfer"
		history.Visible = page == "history"
		details.Visible = page == "details"
		refs.Title.Text = if page == "transfer" then "Transfer" elseif page == "history" then "History" elseif page == "details" then "Details" else "Bank"
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
			BackgroundColor3 = Color3.fromRGB(248, 248, 248),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.82, 0.36),
			ZIndex = 131,
			Parent = refs.DialogLayer,
		})
		rounded(card, 0.035)

		label({
			Parent = card,
			Font = Constants.Fonts.Semibold,
			Text = title,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.fromScale(0.08, 0.1),
			Size = UDim2.fromScale(0.84, 0.14),
			ZIndex = 132,
		})

		label({
			Parent = card,
			Text = body,
			TextColor3 = COLORS.Muted,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextWrapped = true,
			Position = UDim2.fromScale(0.08, 0.29),
			Size = UDim2.fromScale(0.84, 0.33),
			ZIndex = 132,
		})

		for index, action in ipairs(actions) do
			local width = if #actions == 1 then 0.84 else 0.39
			local x = if #actions == 1 then 0.08 else 0.08 + (index - 1) * 0.45
			local actionButton = button({
				Parent = card,
				Text = action.Text,
				BackgroundColor3 = action.Color or COLORS.Blue,
				TextColor3 = action.TextColor or Color3.fromRGB(255, 255, 255),
				Position = UDim2.fromScale(x, 0.72),
				Size = UDim2.fromScale(width, 0.17),
				ZIndex = 132,
			})
			actionButton.Activated:Connect(function()
				refs.DialogLayer.Visible = false
				if action.Callback then
					action.Callback()
				end
			end)
		end

		card.Size = UDim2.fromScale(0.74, 0.3)
		TweenService:Create(card, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(0.82, 0.36),
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

		local fields = {
			{ "Transaction ID", transaction.Id },
			{ "Type", transaction.Type },
			{ "Amount", money(transaction.Amount) },
			{ "Description", transaction.Description },
			{ "Timestamp", shortDate(transaction.Timestamp) },
			{ "Sender", transaction.Sender },
			{ "Receiver", transaction.Receiver },
			{ "Status", transaction.Status },
		}

		for fieldIndex, field in ipairs(fields) do
			local y = 0.045 + (fieldIndex - 1) * 0.112
			label({
				Parent = refs.DetailsCard,
				Text = field[1],
				TextColor3 = COLORS.Muted,
				Position = UDim2.fromScale(0.06, y),
				Size = UDim2.fromScale(0.36, 0.055),
				ZIndex = 53,
			})
			label({
				Parent = refs.DetailsCard,
				Font = Constants.Fonts.Semibold,
				Text = tostring(field[2] or "-"),
				TextXAlignment = Enum.TextXAlignment.Right,
				TextWrapped = true,
				Position = UDim2.fromScale(0.42, y),
				Size = UDim2.fromScale(0.52, 0.06),
				ZIndex = 53,
			})
		end
	end

	local function renderRecent()
		clear(refs.RecentList)
		if #state.Transactions == 0 then
			label({
				Parent = refs.RecentList,
				Text = "No transactions yet.",
				TextColor3 = COLORS.Muted,
				TextXAlignment = Enum.TextXAlignment.Center,
				Size = UDim2.new(1, 0, 0, 62),
				ZIndex = 53,
			})
			return
		end

		for index = 1, math.min(5, #state.Transactions) do
			makeTransactionRow(refs.RecentList, state.Transactions[index], function(transaction)
				openTransactionDetails(transaction)
			end, 53).LayoutOrder = index
		end
	end

	local function renderHistory()
		clear(refs.HistoryList)
		local visibleCount = math.min(state.VisibleHistory, #state.Transactions)
		refs.HistoryList.CanvasSize = UDim2.fromOffset(0, math.max(visibleCount * 58, refs.HistoryList.AbsoluteSize.Y + 1))

		if #state.Transactions == 0 then
			label({
				Parent = refs.HistoryList,
				Text = if state.Loading then "Loading transactions..." else "No transactions yet.",
				TextColor3 = COLORS.Muted,
				TextXAlignment = Enum.TextXAlignment.Center,
				Size = UDim2.new(1, 0, 0, 80),
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
		refs.BalanceText.Text = money(state.Balance)
		refs.PhoneText.Text = "Phone " .. (state.PhoneNumber or "-")
		refs.TransferButton.Active = state.Loaded and not state.Loading
		refs.TransferButton.AutoButtonColor = state.Loaded and not state.Loading
		refs.TransferButton.BackgroundColor3 = if state.Loaded then COLORS.Blue else Color3.fromRGB(170, 170, 176)
		refs.TransferHint.Visible = not state.Loaded
		renderRecent()
		renderHistory()
	end

	local function sendTransactionNotification(transaction)
		if not transaction then
			return
		end

		local amountText = money(transaction.Amount)
		local description = transaction.Description or "-"
		local title = "Bank Transaction"
		local body = amountText .. " - " .. description

		if transaction.Direction == "INCOMING" then
			title = "Money Received"
			body = "+" .. amountText .. " from " .. (transaction.Sender or "Unknown")
		elseif transaction.Direction == "OUTGOING" then
			title = "Money Sent"
			body = "-" .. amountText .. " to " .. (transaction.Receiver or "Unknown")
		end

		if description ~= "-" then
			body = body .. " - " .. description
		end

		if context.SendNotification then
			context.SendNotification({
				Title = title,
				Body = body,
			})
		end
	end

	local function refreshAll(showOverlay)
		if destroyed then
			return
		end

		if showOverlay then
			setLoading(true)
		end

		task.spawn(function()
			local data = EconomyAdapter.GetPlayerData()
			local history = EconomyAdapter.GetTransactionHistory()

			state.Balance = data.Balance or 0
			state.PhoneNumber = data.PhoneNumber or "-"
			state.PlayerName = data.PlayerName or "Unknown"
			state.Transactions = history
			state.Loaded = data.Loaded == true or state.PhoneNumber ~= "-"
			state.Error = if state.Loaded then nil else "Unable to load data."

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
						local result = EconomyAdapter.Transfer(phone, amount, description)
						refreshAll(false)
						task.wait(0.2)
						setLoading(false)

						if result.Success then
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
							showError(result.Message or "Transfer failed.")
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
