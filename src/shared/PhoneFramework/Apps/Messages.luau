local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = script.Parent.Parent
local Constants = require(root:WaitForChild("Shared"):WaitForChild("Constants"))
local StatusBar = require(root:WaitForChild("Shared"):WaitForChild("Components"):WaitForChild("StatusBar"))
local create = require(root:WaitForChild("Shared"):WaitForChild("Utilities"):WaitForChild("Create"))
local EconomyAdapter = require(root:WaitForChild("Services"):WaitForChild("EconomyAdapter"))

local ICONS = {
	Phone = "rbxassetid://71727318918905",
	Message = "rbxassetid://108650574179237",
	Search = "rbxassetid://91955678829293",
	AvatarFallback = "rbxassetid://114778546922350",
	Compose = "rbxassetid://139428637585494",
}

local COLORS = {
	Background = Color3.fromRGB(242, 242, 247),
	Card = Color3.fromRGB(255, 255, 255),
	CardStroke = Color3.fromRGB(225, 225, 232),
	TextDark = Color3.fromRGB(28, 28, 30),
	TextMuted = Color3.fromRGB(142, 142, 147),
	AccentGreen = Color3.fromRGB(52, 199, 89),
	AccentBlue = Color3.fromRGB(0, 122, 255),
	BubbleOutgoing = Color3.fromRGB(52, 199, 89), -- iOS 7 SMS Green
	BubbleIncoming = Color3.fromRGB(229, 229, 234), -- iOS 7 Gray
	TextOutgoing = Color3.fromRGB(255, 255, 255),
	TextIncoming = Color3.fromRGB(28, 28, 30),
}

local DEFAULT_THREADS = {} -- Tidak ada data dummy, semua dari DataStore

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

local MessagesApp = {
	Id = "messages",
	Name = "Messages",
	Icon = {
		Background = Color3.fromRGB(33, 213, 66),
		Image = "rbxassetid://108650574179237",
	},
	Order = 10,
}

function MessagesApp.Create(context: any)
	local localPlayer = Players.LocalPlayer
	local saveService = context.Services.SaveService
	local remote = ReplicatedStorage:FindFirstChild(Constants.RemoteName)

	-- State Aplikasi Messages
	local state = {
		ActiveView = "list", -- "list", "chat"
		ActiveThread = nil,
		SearchQuery = "",
		Threads = saveService:Get("MessagesHistory", {}),
	}

	local function cleanPhoneStr(pStr: any): string
		if type(pStr) ~= "string" then return "" end
		return string.gsub(pStr, "[%s%-]", "")
	end

	local function resolveContactName(phone: string?, fallbackPhone: string?): string
		local rawPhone = phone or fallbackPhone or ""
		local targetClean = cleanPhoneStr(rawPhone)
		if targetClean == "" then
			return rawPhone ~= "" and rawPhone or "Message"
		end

		local contacts = saveService:Get("Contacts", {})
		for _, c in ipairs(contacts) do
			if cleanPhoneStr(c.Phone) == targetClean then
				if c.Name and c.Name ~= "" then
					return c.Name
				end
			end
		end

		-- Jika tidak ada di daftar kontak, tampilkan NOMOR HP SAJA (bukan DisplayName)
		return rawPhone
	end

	-- Root Container
	local rootFrame = create("Frame", {
		Name = "MessagesRoot",
		BackgroundColor3 = COLORS.Background,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
	})

	-- Status Bar Atas
	StatusBar.new(rootFrame, { Light = false })

	local navHeight = 0.075
	local contentTop = Constants.Screen.StatusBarHeight + navHeight

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

	-- Back Button
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

	-- Title Bar
	local titleLabel = label({
		Name = "Title",
		Parent = navBar,
		Font = Constants.Fonts.Semibold,
		Text = "Messages",
		TextColor3 = COLORS.TextDark,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.4, 0.6),
		MaxTextSize = 16,
		MinTextSize = 11,
		ZIndex = 61,
	})

	-- Compose Button (Pesan Baru)
	local composeBtn = create("TextButton", {
		Name = "ComposeBtn",
		AutoButtonColor = true,
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Semibold,
		Text = "✎",
		TextColor3 = COLORS.AccentGreen,
		TextSize = 20,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(30, 30),
		ZIndex = 61,
		Parent = navBar,
	})

	-- Call Shortcut Button di Header Chat Room
	local callHeaderBtn = create("TextButton", {
		Name = "CallHeaderBtn",
		AutoButtonColor = true,
		BackgroundTransparency = 1,
		Text = "",
		Visible = false,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(30, 30),
		ZIndex = 61,
		Parent = navBar,
	})
	iconImage({
		Name = "Icon",
		Image = ICONS.Phone,
		ImageColor3 = COLORS.AccentGreen,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(18, 18),
		ZIndex = 62,
		Parent = callHeaderBtn,
	})

	-- Main Container Views
	local mainContainer = create("Frame", {
		Name = "MainContainer",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0, contentTop),
		Size = UDim2.fromScale(1, 1 - contentTop),
		ZIndex = 51,
		Parent = rootFrame,
	})

	-- 1. THREAD LIST VIEW
	local threadListView = create("Frame", {
		Name = "ThreadListView",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 52,
		Parent = mainContainer,
	})

	-- Search Bar Frame
	local searchFrame = create("Frame", {
		Name = "SearchFrame",
		BackgroundColor3 = COLORS.Card,
		Position = UDim2.new(0.04, 0, 0, 8),
		Size = UDim2.new(0.92, 0, 0, 34),
		ZIndex = 53,
		Parent = threadListView,
	})
	rounded(searchFrame, 10)
	stroke(searchFrame, COLORS.CardStroke, 1)

	iconImage({
		Name = "SearchIcon",
		Image = ICONS.Search,
		ImageColor3 = COLORS.TextMuted,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 8, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		ZIndex = 54,
		Parent = searchFrame,
	})

	local searchBox = create("TextBox", {
		Name = "SearchInput",
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		Font = Constants.Fonts.Regular,
		PlaceholderColor3 = COLORS.TextMuted,
		PlaceholderText = "Cari percakapan...",
		Text = "",
		TextColor3 = COLORS.TextDark,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 30, 0, 0),
		Size = UDim2.new(1, -35, 1, 0),
		ZIndex = 54,
		Parent = searchFrame,
	})

	local threadScroll = create("ScrollingFrame", {
		Name = "ThreadScroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = COLORS.TextMuted,
		Position = UDim2.new(0, 0, 0, 50),
		Size = UDim2.new(1, 0, 1, -50),
		ZIndex = 53,
		Parent = threadListView,
	})
	padded(threadScroll, 0.04, 0.04, 0, 0.04)
	create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = threadScroll })

	-- 2. CHAT ROOM VIEW
	local chatRoomView = create("Frame", {
		Name = "ChatRoomView",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 52,
		Parent = mainContainer,
	})

	local chatMessagesScroll = create("ScrollingFrame", {
		Name = "ChatMessagesScroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = COLORS.TextMuted,
		Position = UDim2.new(0, 0, 0, 4),
		Size = UDim2.new(1, 0, 1, -50),
		ZIndex = 53,
		Parent = chatRoomView,
	})
	padded(chatMessagesScroll, 0.04, 0.04, 0.02, 0.04)
	create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = chatMessagesScroll })

	-- Message Input Bar At Atas Bottom
	local inputBar = create("Frame", {
		Name = "InputBar",
		BackgroundColor3 = COLORS.Card,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -44),
		Size = UDim2.new(1, 0, 0, 44),
		ZIndex = 54,
		Parent = chatRoomView,
	})
	stroke(inputBar, COLORS.CardStroke, 1)

	local messageInputBox = create("TextBox", {
		Name = "MessageInput",
		BackgroundColor3 = Color3.fromRGB(246, 247, 250),
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Font = Constants.Fonts.Regular,
		PlaceholderColor3 = COLORS.TextMuted,
		PlaceholderText = "Type a message...",
		Text = "",
		TextColor3 = COLORS.TextDark,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0.04, 0, 0.15, 0),
		Size = UDim2.new(0.81, 0, 0.7, 0),
		ZIndex = 55,
		Parent = inputBar,
	})
	rounded(messageInputBox, 16)
	stroke(messageInputBox, COLORS.CardStroke, 1)
	padded(messageInputBox, 0.04, 0.04, 0, 0)

	local sendBtn = create("TextButton", {
		Name = "SendBtn",
		AutoButtonColor = true,
		BackgroundColor3 = COLORS.AccentGreen,
		BorderSizePixel = 0,
		Font = Constants.Fonts.Semibold,
		Text = "▲",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 13,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(30, 30),
		ZIndex = 55,
		Parent = inputBar,
	})
	rounded(sendBtn, 15)

	-- MODAL SELECTOR PESAN BARU
	local composeModal = create("Frame", {
		Name = "ComposeModal",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.45,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 100,
		Parent = rootFrame,
	})

	-- Forward references
	local renderThreadList
	local openChatRoom
	local sendChatMessage

	-- Render List Thread
	renderThreadList = function()
		for _, child in ipairs(threadScroll:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") or child:IsA("ImageLabel") then
				child:Destroy()
			end
		end

		local query = string.lower(state.SearchQuery or "")
		local filtered = {}

		for _, thread in ipairs(state.Threads) do
			local nameMatch = string.find(string.lower(thread.PartnerName or ""), query, 1, true)
			local phoneMatch = string.find(string.lower(thread.PartnerPhone or ""), query, 1, true)
			if query == "" or nameMatch or phoneMatch then
				table.insert(filtered, thread)
			end
		end

		if #filtered == 0 then
			local emptyText = if state.SearchQuery ~= "" then "No conversations found matching keyword." else "No conversations yet.\nTap ✎ to start a new chat."
			label({
				Parent = threadScroll,
				Font = Constants.Fonts.Regular,
				Text = emptyText,
				TextColor3 = COLORS.TextMuted,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextWrapped = true,
				Size = UDim2.new(1, 0, 0, 80),
				MaxTextSize = 13,
				MinTextSize = 9,
				ZIndex = 54,
			})
			return
		end

		for idx, thread in ipairs(filtered) do
			local lastMsg = if #thread.Messages > 0 then thread.Messages[#thread.Messages] else nil
			local card = create("TextButton", {
				Name = "Thread_" .. idx,
				AutoButtonColor = true,
				BackgroundColor3 = COLORS.Card,
				BorderSizePixel = 0,
				Text = "",
				Size = UDim2.new(1, 0, 0, 60),
				LayoutOrder = idx,
				ZIndex = 54,
				Parent = threadScroll,
			})
			rounded(card, 12)
			stroke(card, COLORS.CardStroke, 1)

			local avatar = create("ImageLabel", {
				Name = "Avatar",
				BackgroundColor3 = Color3.fromRGB(230, 235, 245),
				Image = if thread.PartnerUserId then ("rbxthumb://type=AvatarBust&id=" .. thread.PartnerUserId .. "&w=150&h=150") else ICONS.AvatarFallback,
				Position = UDim2.new(0, 10, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.fromOffset(40, 40),
				ZIndex = 55,
				Parent = card,
			})
			rounded(avatar, 20)

			local displayName = resolveContactName(thread.PartnerPhone, thread.PartnerName)

			label({
				Name = "Name",
				Parent = card,
				Font = Constants.Fonts.Semibold,
				Text = displayName,
				TextColor3 = COLORS.TextDark,
				Position = UDim2.new(0, 60, 0, 10),
				Size = UDim2.new(0.55, 0, 0, 18),
				MaxTextSize = 13,
				MinTextSize = 9,
				ZIndex = 55,
			})

			local previewText = if lastMsg then lastMsg.Text else "No messages yet."
			label({
				Name = "Preview",
				Parent = card,
				Text = previewText,
				TextColor3 = COLORS.TextMuted,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Position = UDim2.new(0, 60, 0, 30),
				Size = UDim2.new(0.65, 0, 0, 14),
				MaxTextSize = 10,
				MinTextSize = 7,
				ZIndex = 55,
			})

			local timeText = if lastMsg and lastMsg.Timestamp then os.date("%H:%M", lastMsg.Timestamp) else ""
			label({
				Name = "Time",
				Parent = card,
				Text = timeText,
				TextColor3 = COLORS.TextMuted,
				TextXAlignment = Enum.TextXAlignment.Right,
				Position = UDim2.new(0.7, 0, 0, 10),
				Size = UDim2.new(0.26, 0, 0, 14),
				MaxTextSize = 10,
				MinTextSize = 7,
				ZIndex = 55,
			})

			card.Activated:Connect(function()
				openChatRoom(thread)
			end)
		end
	end

	-- Render Chat Room
	openChatRoom = function(thread: any)
		state.ActiveView = "chat"
		state.ActiveThread = thread

		threadListView.Visible = false
		chatRoomView.Visible = true
		composeBtn.Visible = false
		callHeaderBtn.Visible = true
		local displayName = resolveContactName(thread.PartnerPhone, thread.PartnerName)
		titleLabel.Text = displayName
		backBtn.Text = "く"

		for _, child in ipairs(chatMessagesScroll:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") or child:IsA("ImageLabel") then
				child:Destroy()
			end
		end

		for idx, msg in ipairs(thread.Messages or {}) do
			local isOut = msg.IsOutgoing
			local row = create("Frame", {
				Name = "MsgRow_" .. idx,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = idx,
				ZIndex = 54,
				Parent = chatMessagesScroll,
			})

			local bubble = create("Frame", {
				Name = "Bubble",
				BackgroundColor3 = if isOut then COLORS.BubbleOutgoing else COLORS.BubbleIncoming,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(if isOut then 1 else 0, 0),
				Position = UDim2.new(if isOut then 1 else 0, 0, 0, 0),
				Size = UDim2.new(0, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.XY,
				ZIndex = 55,
				Parent = row,
			})
			rounded(bubble, 14)
			stroke(bubble, if isOut then Color3.fromRGB(42, 185, 75) else Color3.fromRGB(215, 215, 220), 1)

			create("UIPadding", {
				PaddingLeft = UDim.new(0, 11),
				PaddingRight = UDim.new(0, 11),
				PaddingTop = UDim.new(0, 7),
				PaddingBottom = UDim.new(0, 7),
				Parent = bubble,
			})

			create("UISizeConstraint", {
				MaxSize = Vector2.new(205, 1000),
				MinSize = Vector2.new(24, 24),
				Parent = bubble,
			})

			create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
				HorizontalAlignment = if isOut then Enum.HorizontalAlignment.Right else Enum.HorizontalAlignment.Left,
				Parent = bubble,
			})

			label({
				Name = "Text",
				Parent = bubble,
				LayoutOrder = 1,
				Font = Constants.Fonts.Regular,
				Text = msg.Text or "",
				TextColor3 = if isOut then COLORS.TextOutgoing else COLORS.TextIncoming,
				TextSize = 12,
				TextWrapped = true,
				TextScaled = false,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutomaticSize = Enum.AutomaticSize.XY,
				Size = UDim2.new(0, 0, 0, 0),
				ZIndex = 56,
			})

			local timeStr = os.date("%H:%M", msg.Timestamp or os.time())
			label({
				Name = "Time",
				Parent = bubble,
				LayoutOrder = 2,
				Font = Constants.Fonts.Regular,
				Text = timeStr,
				TextColor3 = if isOut then Color3.fromRGB(225, 245, 230) else Color3.fromRGB(142, 142, 147),
				TextSize = 9,
				TextScaled = false,
				TextXAlignment = if isOut then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left,
				AutomaticSize = Enum.AutomaticSize.XY,
				Size = UDim2.new(0, 0, 0, 0),
				ZIndex = 56,
			})
		end

		task.defer(function()
			chatMessagesScroll.CanvasPosition = Vector2.new(0, chatMessagesScroll.AbsoluteCanvasSize.Y)
		end)
	end

	-- Kirim Pesan Chat
	sendChatMessage = function()
		local text = string.gsub(messageInputBox.Text, "^%s*(.-)%s*$", "%1")
		if text == "" or not state.ActiveThread then return end

		local newMsg = {
			Text = text,
			IsOutgoing = true,
			Timestamp = os.time(),
		}
		table.insert(state.ActiveThread.Messages, newMsg)
		messageInputBox.Text = ""

		saveService:Set("MessagesHistory", state.Threads)
		openChatRoom(state.ActiveThread)

		if remote and remote:IsA("RemoteEvent") then
			remote:FireServer("SendSMS", {
				targetUserId = state.ActiveThread.PartnerUserId,
				targetPhone = state.ActiveThread.PartnerPhone,
				messageText = text,
			})
		end
	end

	sendBtn.Activated:Connect(sendChatMessage)
	messageInputBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then sendChatMessage() end
	end)

	-- Navigation Back Button Handler
	backBtn.Activated:Connect(function()
		if state.ActiveView == "chat" then
			state.ActiveView = "list"
			state.ActiveThread = nil
			chatRoomView.Visible = false
			threadListView.Visible = true
			composeBtn.Visible = true
			callHeaderBtn.Visible = false
			titleLabel.Text = "Messages"
			backBtn.Text = "く"
			renderThreadList()
		else
			context.CloseCurrentApp()
		end
	end)

	callHeaderBtn.Activated:Connect(function()
		if state.ActiveThread then
			context.OpenApp("phone")
		end
	end)

	-- Modal Pesan Baru (Compose Modal)
	composeBtn.Activated:Connect(function()
		composeModal.Visible = true
		for _, child in ipairs(composeModal:GetChildren()) do child:Destroy() end

		local selectedContact = nil

		local card = create("Frame", {
			Name = "ComposeCard",
			BackgroundColor3 = COLORS.Card,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0.86, 0, 0, 205),
			ZIndex = 101,
			Parent = composeModal,
		})
		rounded(card, 14)
		stroke(card, COLORS.CardStroke, 2)
		padded(card, 0.04, 0.04, 0.03, 0.04)

		-- Header Title
		label({
			Parent = card,
			Font = Constants.Fonts.Semibold,
			Text = "✎ New Message",
			TextColor3 = COLORS.TextDark,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.new(0, 0, 0, 4),
			Size = UDim2.new(1, 0, 0, 18),
			MaxTextSize = 14,
			MinTextSize = 10,
			ZIndex = 102,
		})

		-- Label & Input Bar untuk Nomor HP + Tombol Kontak
		label({
			Parent = card,
			Font = Constants.Fonts.Semibold,
			Text = "RECIPIENT / PHONE NUMBER",
			TextColor3 = COLORS.TextMuted,
			Position = UDim2.new(0, 0, 0, 26),
			Size = UDim2.new(1, 0, 0, 12),
			MaxTextSize = 9,
			MinTextSize = 7,
			ZIndex = 102,
		})

		local targetBox = create("TextBox", {
			Name = "TargetBox",
			BackgroundColor3 = Color3.fromRGB(246, 247, 250),
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
			Font = Constants.Fonts.Regular,
			PlaceholderColor3 = COLORS.TextMuted,
			PlaceholderText = "Enter Phone Number...",
			Text = "",
			TextColor3 = COLORS.TextDark,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 0, 0, 40),
			Size = UDim2.new(0.70, 0, 0, 28),
			ZIndex = 102,
			Parent = card,
		})
		rounded(targetBox, 7)
		stroke(targetBox, COLORS.CardStroke, 1)
		padded(targetBox, 0.03, 0.03, 0, 0)

		local pickContactBtn = create("TextButton", {
			Name = "PickContactBtn",
			AutoButtonColor = true,
			BackgroundColor3 = Color3.fromRGB(235, 245, 255),
			BorderSizePixel = 0,
			Font = Constants.Fonts.Semibold,
			Text = "👤 Contact",
			TextColor3 = COLORS.AccentBlue,
			TextSize = 10,
			Position = UDim2.new(0.73, 0, 0, 40),
			Size = UDim2.new(0.27, 0, 0, 28),
			ZIndex = 102,
			Parent = card,
		})
		rounded(pickContactBtn, 7)
		stroke(pickContactBtn, Color3.fromRGB(200, 225, 255), 1)

		-- Label & Input Bar Isi Pesan
		label({
			Parent = card,
			Font = Constants.Fonts.Semibold,
			Text = "MESSAGE CONTENT",
			TextColor3 = COLORS.TextMuted,
			Position = UDim2.new(0, 0, 0, 74),
			Size = UDim2.new(1, 0, 0, 12),
			MaxTextSize = 9,
			MinTextSize = 7,
			ZIndex = 102,
		})

		local contentBox = create("TextBox", {
			Name = "ContentBox",
			BackgroundColor3 = Color3.fromRGB(246, 247, 250),
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
			Font = Constants.Fonts.Regular,
			PlaceholderColor3 = COLORS.TextMuted,
			PlaceholderText = "Type message content...",
			Text = "",
			TextColor3 = COLORS.TextDark,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 0, 0, 88),
			Size = UDim2.new(1, 0, 0, 48),
			ZIndex = 102,
			Parent = card,
		})
		rounded(contentBox, 7)
		stroke(contentBox, COLORS.CardStroke, 1)
		padded(contentBox, 0.03, 0.03, 0.02, 0.02)

		-- Action Buttons (Batal & Kirim SMS)
		local cancelBtn = create("TextButton", {
			Name = "CancelBtn",
			AutoButtonColor = true,
			BackgroundColor3 = Color3.fromRGB(240, 242, 245),
			BorderSizePixel = 0,
			Font = Constants.Fonts.Semibold,
			Text = "Batal",
			TextColor3 = COLORS.TextDark,
			TextSize = 11,
			Position = UDim2.new(0, 0, 1, -32),
			Size = UDim2.new(0.48, 0, 0, 30),
			ZIndex = 102,
			Parent = card,
		})
		rounded(cancelBtn, 8)
		cancelBtn.Activated:Connect(function() composeModal.Visible = false end)

		local sendNewBtn = create("TextButton", {
			Name = "SendNewBtn",
			AutoButtonColor = true,
			BackgroundColor3 = COLORS.AccentGreen,
			BorderSizePixel = 0,
			Font = Constants.Fonts.Semibold,
			Text = "Kirim SMS →",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 11,
			Position = UDim2.new(0.52, 0, 1, -32),
			Size = UDim2.new(0.48, 0, 0, 30),
			ZIndex = 102,
			Parent = card,
		})
		rounded(sendNewBtn, 8)

		-- Modal Terpisah untuk Memilih Kontak
		pickContactBtn.Activated:Connect(function()
			local pickerOverlay = create("Frame", {
				Name = "ContactPickerOverlay",
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.35,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 200,
				Parent = composeModal,
			})

			local pickerCard = create("Frame", {
				Name = "PickerCard",
				BackgroundColor3 = COLORS.Card,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(0.84, 0, 0, 220),
				ZIndex = 201,
				Parent = pickerOverlay,
			})
			rounded(pickerCard, 12)
			stroke(pickerCard, COLORS.CardStroke, 2)
			padded(pickerCard, 0.04, 0.04, 0.03, 0.04)

			label({
				Parent = pickerCard,
				Font = Constants.Fonts.Semibold,
				Text = "Select Contact",
				TextColor3 = COLORS.TextDark,
				TextXAlignment = Enum.TextXAlignment.Center,
				Position = UDim2.new(0, 0, 0, 4),
				Size = UDim2.new(1, 0, 0, 18),
				MaxTextSize = 14,
				MinTextSize = 10,
				ZIndex = 202,
			})

			local pickerCloseBtn = create("TextButton", {
				Name = "PickerCloseBtn",
				AutoButtonColor = true,
				BackgroundTransparency = 1,
				Font = Constants.Fonts.Semibold,
				Text = "✕",
				TextColor3 = COLORS.TextMuted,
				TextSize = 14,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 0, 0, 0),
				Size = UDim2.new(0, 20, 0, 20),
				ZIndex = 202,
				Parent = pickerCard,
			})
			pickerCloseBtn.Activated:Connect(function()
				pickerOverlay:Destroy()
			end)

			local pickerScroll = create("ScrollingFrame", {
				Name = "PickerScroll",
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				ScrollBarThickness = 3,
				ScrollBarImageColor3 = COLORS.TextMuted,
				Position = UDim2.new(0, 0, 0, 28),
				Size = UDim2.new(1, 0, 1, -32),
				ZIndex = 202,
				Parent = pickerCard,
			})
			create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = pickerScroll })

			local contactsList = saveService:Get("Contacts", {})
			if #contactsList == 0 then
				label({
					Parent = pickerScroll,
					Font = Constants.Fonts.Regular,
					Text = "No contacts saved.",
					TextColor3 = COLORS.TextMuted,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextWrapped = true,
					Size = UDim2.new(1, 0, 0, 60),
					MaxTextSize = 11,
					MinTextSize = 8,
					ZIndex = 203,
				})
			else
				for idx, contact in ipairs(contactsList) do
					local row = create("TextButton", {
						Name = "Row_" .. idx,
						AutoButtonColor = true,
						BackgroundColor3 = Color3.fromRGB(248, 249, 252),
						BorderSizePixel = 0,
						Text = "",
						Size = UDim2.new(1, 0, 0, 42),
						LayoutOrder = idx,
						ZIndex = 203,
						Parent = pickerScroll,
					})
					rounded(row, 8)
					stroke(row, COLORS.CardStroke, 1)

					local avatarImg = create("ImageLabel", {
						Name = "Avatar",
						BackgroundColor3 = Color3.fromRGB(230, 235, 245),
						Image = if contact.UserId then ("rbxthumb://type=AvatarBust&id=" .. contact.UserId .. "&w=150&h=150") else ICONS.AvatarFallback,
						Position = UDim2.new(0, 6, 0.5, 0),
						AnchorPoint = Vector2.new(0, 0.5),
						Size = UDim2.fromOffset(30, 30),
						ZIndex = 204,
						Parent = row,
					})
					rounded(avatarImg, 15)

					label({
						Parent = row,
						Font = Constants.Fonts.Semibold,
						Text = contact.Name or "Tanpa Nama",
						TextColor3 = COLORS.TextDark,
						TextTruncate = Enum.TextTruncate.AtEnd,
						Position = UDim2.new(0, 44, 0, 5),
						Size = UDim2.new(0.8, 0, 0, 14),
						MaxTextSize = 12,
						MinTextSize = 8,
						ZIndex = 204,
					})

					label({
						Parent = row,
						Font = Constants.Fonts.Regular,
						Text = contact.Phone or "-",
						TextColor3 = COLORS.AccentBlue,
						TextTruncate = Enum.TextTruncate.AtEnd,
						Position = UDim2.new(0, 44, 0, 21),
						Size = UDim2.new(0.8, 0, 0, 12),
						MaxTextSize = 10,
						MinTextSize = 7,
						ZIndex = 204,
					})

					row.Activated:Connect(function()
						targetBox.Text = contact.Phone or ""
						selectedContact = contact
						pickerOverlay:Destroy()
					end)
				end
			end
		end)

		sendNewBtn.Activated:Connect(function()
			local targetVal = string.gsub(targetBox.Text, "^%s*(.-)%s*$", "%1")
			local msgVal = string.gsub(contentBox.Text, "^%s*(.-)%s*$", "%1")

			if targetVal == "" or msgVal == "" then
				context.SendNotification({ Title = "⚠️ Warning", Text = "Recipient and message content are required!", Duration = 3 })
				return
			end

			local partnerName = if selectedContact then selectedContact.Name else targetVal
			local partnerPhone = targetVal
			local partnerUserId = if selectedContact then selectedContact.UserId else nil

			if not partnerUserId then
				for _, p in ipairs(Players:GetPlayers()) do
					if p.DisplayName == partnerName or p.Name == partnerName then
						partnerUserId = p.UserId
						partnerName = p.DisplayName
						break
					end
				end
			end

			local existingThread = nil
			for _, th in ipairs(state.Threads) do
				if th.PartnerPhone == partnerPhone or (partnerUserId and th.PartnerUserId == partnerUserId) then
					existingThread = th
					break
				end
			end

			if not existingThread then
				existingThread = {
					Id = "th_" .. tick(),
					PartnerName = partnerName,
					PartnerPhone = partnerPhone,
					PartnerUserId = partnerUserId,
					Messages = {},
				}
				table.insert(state.Threads, 1, existingThread)
			end

			table.insert(existingThread.Messages, { Text = msgVal, IsOutgoing = true, Timestamp = os.time() })
			saveService:Set("MessagesHistory", state.Threads)

			if remote and remote:IsA("RemoteEvent") then
				remote:FireServer("SendSMS", {
					targetUserId = partnerUserId,
					targetPhone = partnerPhone,
					messageText = msgVal,
				})
			end

			composeModal.Visible = false
			openChatRoom(existingThread)
		end)
	end)

	-- Search Listener
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		state.SearchQuery = searchBox.Text
		renderThreadList()
	end)

	-- Remote Event Client Listener (SMS Masuk & SMSFailed Real-Time)
	local remoteConnection
	if remote and remote:IsA("RemoteEvent") then
		remoteConnection = remote.OnClientEvent:Connect(function(action: string, payload: any)
			if action == "ReceiveSMS" and payload then
				local senderPhone = payload.senderPhone or ""
				local displayName = resolveContactName(senderPhone, payload.senderName)

				local existingThread = nil
				for _, th in ipairs(state.Threads) do
					if cleanPhoneStr(th.PartnerPhone) == cleanPhoneStr(senderPhone) or (payload.senderUserId and th.PartnerUserId == payload.senderUserId) then
						existingThread = th
						break
					end
				end

				if not existingThread then
					existingThread = {
						Id = "th_" .. tick(),
						PartnerName = displayName,
						PartnerPhone = senderPhone,
						PartnerUserId = payload.senderUserId,
						Messages = {},
					}
					table.insert(state.Threads, 1, existingThread)
				else
					existingThread.PartnerName = displayName
				end

				table.insert(existingThread.Messages, {
					Text = payload.messageText or "",
					IsOutgoing = false,
					Timestamp = payload.timestamp or os.time(),
				})

				saveService:Set("MessagesHistory", state.Threads)

				if state.ActiveView == "chat" and state.ActiveThread and state.ActiveThread.Id == existingThread.Id then
					openChatRoom(existingThread)
				else
					renderThreadList()
				end

			elseif action == "SMSFailed" and payload and payload.reason then
				context.SendNotification({
					Title = "❌ SMS Gagal",
					Text = payload.reason,
					Duration = 4,
				})
			end
		end)
	end

	rootFrame.Destroying:Connect(function()
		if remoteConnection then remoteConnection:Disconnect() end
	end)

	renderThreadList()

	return rootFrame
end

return MessagesApp
