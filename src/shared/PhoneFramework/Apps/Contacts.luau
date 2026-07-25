local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local root = script.Parent.Parent
local Constants = require(root:WaitForChild("Shared"):WaitForChild("Constants"))
local StatusBar = require(root:WaitForChild("Shared"):WaitForChild("Components"):WaitForChild("StatusBar"))
local create = require(root:WaitForChild("Shared"):WaitForChild("Utilities"):WaitForChild("Create"))

local RADAR_RADIUS_STUDS = 40 -- Radius zona AirDrop dalam studs (~13 meter)

local ICONS = {
	Phone = "rbxassetid://71727318918905",
	Message = "rbxassetid://108650574179237",
	AirDrop = "rbxassetid://127578521635782",
	Search = "rbxassetid://139428637585494",
	Star = "rbxassetid://83719759786505",
	Check = "rbxassetid://82537775608740",
	AvatarFallback = "rbxassetid://114778546922350",
	Transfer = "rbxassetid://83051479285340",
}

local COLORS = {
	Background = Color3.fromRGB(242, 242, 247),
	Card = Color3.fromRGB(255, 255, 255),
	CardStroke = Color3.fromRGB(225, 225, 232),
	TextDark = Color3.fromRGB(28, 28, 30),
	TextMuted = Color3.fromRGB(142, 142, 147),
	AccentBlue = Color3.fromRGB(0, 122, 255),
	AccentGreen = Color3.fromRGB(52, 199, 89),
	AccentGold = Color3.fromRGB(255, 149, 0),
	DestructiveRed = Color3.fromRGB(255, 59, 48),
	SectionHeader = Color3.fromRGB(238, 238, 242),
}

local DEFAULT_CONTACTS = {
	{
		Id = "def_1",
		Name = "Layanan Darurat",
		Phone = "112",
		Note = "Darurat & Keamanan",
		IsFavorite = true,
	},
	{
		Id = "def_2",
		Name = "Bank Putih-Abu",
		Phone = "14045",
		Note = "Customer Service Bank",
		IsFavorite = true,
	},
	{
		Id = "def_3",
		Name = "Budi Santoso",
		Phone = "0812-3456-7890",
		Note = "Teman Kelas",
		IsFavorite = false,
	},
	{
		Id = "def_4",
		Name = "Siti Rahma",
		Phone = "0857-1122-3344",
		Note = "Sahabat",
		IsFavorite = false,
	},
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

local function getAvatarUrl(contactData: any): string
	if contactData.UserId and tonumber(contactData.UserId) then
		return "rbxthumb://type=AvatarBust&id=" .. contactData.UserId .. "&w=150&h=150"
	elseif contactData.Avatar and contactData.Avatar ~= "" then
		return contactData.Avatar
	end
	return ICONS.AvatarFallback
end

local ContactsApp = {
	Id = "contacts",
	Name = "Contacts",
	Icon = {
		Background = Color3.fromRGB(205, 205, 198),
		Image = "rbxassetid://114778546922350",
	},
	Order = 110,
}

function ContactsApp.Create(context: any)
	local localPlayer = Players.LocalPlayer
	local saveService = context.Services.SaveService
	local remote = ReplicatedStorage:FindFirstChild(Constants.RemoteName)

	-- State Aplikasi Contacts
	local state = {
		ActiveTab = "all", -- "all", "favorites", "airdrop"
		SearchQuery = "",
		SelectedContact = nil,
		Contacts = {},
		NearbyPlayers = {},
	}

	-- Mengambil atau Inisialisasi Data Kontak dari SaveService
	local savedContacts = saveService:Get("Contacts", nil)
	if not savedContacts or #savedContacts == 0 then
		state.Contacts = DEFAULT_CONTACTS
		saveService:Set("Contacts", DEFAULT_CONTACTS)
	else
		state.Contacts = savedContacts
	end

	-- Root Container
	local rootFrame = create("Frame", {
		Name = "ContactsRoot",
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
		Text = "く Home",
		TextColor3 = COLORS.AccentBlue,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(0, 75, 1, 0),
		ZIndex = 61,
		Parent = navBar,
	})
	backBtn.Activated:Connect(function()
		context.CloseCurrentApp()
	end)

	-- Title Bar
	local titleLabel = label({
		Name = "Title",
		Parent = navBar,
		Font = Constants.Fonts.Semibold,
		Text = "Contacts",
		TextColor3 = COLORS.TextDark,
		TextXAlignment = Enum.TextXAlignment.Center,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.4, 0.6),
		MaxTextSize = 16,
		MinTextSize = 11,
		ZIndex = 61,
	})

	-- AirDrop Radar Action Button di Header
	local airDropHeaderBtn = create("TextButton", {
		Name = "AirDropHeaderBtn",
		AutoButtonColor = true,
		BackgroundTransparency = 1,
		Text = "",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -42, 0.5, 0),
		Size = UDim2.new(0, 28, 0, 28),
		ZIndex = 61,
		Parent = navBar,
	})
	local airDropIconHeader = iconImage({
		Name = "Icon",
		Image = ICONS.AirDrop,
		ImageColor3 = COLORS.AccentGreen,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(20, 20),
		ZIndex = 62,
		Parent = airDropHeaderBtn,
	})

	-- Add Contact Button (+) di Header
	local addContactBtn = create("TextButton", {
		Name = "AddContactBtn",
		AutoButtonColor = true,
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Semibold,
		Text = "＋",
		TextColor3 = COLORS.AccentBlue,
		TextSize = 22,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0, 30, 0, 30),
		ZIndex = 61,
		Parent = navBar,
	})

	-- Area Konten Utama
	local mainContainer = create("Frame", {
		Name = "MainContainer",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0, contentTop),
		Size = UDim2.fromScale(1, 1 - contentTop),
		ZIndex = 51,
		Parent = rootFrame,
	})

	-- Tab Switcher Frame
	local tabFrame = create("Frame", {
		Name = "TabFrame",
		BackgroundColor3 = COLORS.Card,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 36),
		ZIndex = 52,
		Parent = mainContainer,
	})
	stroke(tabFrame, COLORS.CardStroke, 1)

	local tabButtons = {}
	local tabs = {
		{ id = "all", name = "Semua Kontak" },
		{ id = "favorites", name = "★ Favorit" },
		{ id = "airdrop", name = "📡 AirDrop Radar" },
	}

	local tabWidth = 1 / #tabs
	for i, tabInfo in ipairs(tabs) do
		local btn = create("TextButton", {
			Name = "Tab_" .. tabInfo.id,
			AutoButtonColor = true,
			BackgroundTransparency = 1,
			Font = Constants.Fonts.Semibold,
			Text = tabInfo.name,
			TextColor3 = if tabInfo.id == "all" then COLORS.AccentBlue else COLORS.TextMuted,
			TextSize = 12,
			Position = UDim2.new((i - 1) * tabWidth, 0, 0, 0),
			Size = UDim2.new(tabWidth, 0, 1, 0),
			ZIndex = 53,
			Parent = tabFrame,
		})
		tabButtons[tabInfo.id] = btn
	end

	-- Indicator Line di Tab
	local tabIndicator = create("Frame", {
		Name = "TabIndicator",
		BackgroundColor3 = COLORS.AccentBlue,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -2),
		Size = UDim2.new(tabWidth, 0, 0, 2),
		ZIndex = 54,
		Parent = tabFrame,
	})

	-- Search Bar Frame
	local searchFrame = create("Frame", {
		Name = "SearchFrame",
		BackgroundColor3 = COLORS.Card,
		Position = UDim2.new(0.04, 0, 0, 44),
		Size = UDim2.new(0.92, 0, 0, 34),
		ZIndex = 52,
		Parent = mainContainer,
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
		ZIndex = 53,
		Parent = searchFrame,
	})

	local searchBox = create("TextBox", {
		Name = "SearchInput",
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		Font = Constants.Fonts.Regular,
		PlaceholderColor3 = COLORS.TextMuted,
		PlaceholderText = "Cari nama atau nomor HP...",
		Text = "",
		TextColor3 = COLORS.TextDark,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 30, 0, 0),
		Size = UDim2.new(1, -55, 1, 0),
		ZIndex = 53,
		Parent = searchFrame,
	})

	local clearSearchBtn = create("TextButton", {
		Name = "ClearSearchBtn",
		AutoButtonColor = true,
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Semibold,
		Text = "✕",
		TextColor3 = COLORS.TextMuted,
		TextSize = 12,
		Visible = false,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.new(0, 20, 0, 20),
		ZIndex = 53,
		Parent = searchFrame,
	})

	-- Container Halaman List Kontak
	local contactsScroll = create("ScrollingFrame", {
		Name = "ContactsScroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = COLORS.TextMuted,
		Position = UDim2.new(0, 0, 0, 86),
		Size = UDim2.new(1, 0, 1, -86),
		ZIndex = 52,
		Parent = mainContainer,
	})
	padded(contactsScroll, 0.04, 0.04, 0, 0.04)

	local contactsListLayout = create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = contactsScroll,
	})

	-- Container Halaman Radar AirDrop
	local airDropFrame = create("Frame", {
		Name = "AirDropFrame",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 44),
		Size = UDim2.new(1, 0, 1, -44),
		Visible = false,
		ZIndex = 52,
		Parent = mainContainer,
	})
	padded(airDropFrame, 0.04, 0.04, 0.02, 0.04)

	local airDropScroll = create("ScrollingFrame", {
		Name = "AirDropScroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = COLORS.TextMuted,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 53,
		Parent = airDropFrame,
	})
	create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		Parent = airDropScroll,
	})

	-- MODAL SYSTEM (Detail, Add/Edit, AirDrop Confirmation)
	local modalOverlay = create("Frame", {
		Name = "ModalOverlay",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.45,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 100,
		Parent = rootFrame,
	})

	-- Forward reference untuk updateUI & modal handlers
	local updateContactsList
	local updateAirDropRadar
	local openDetailModal
	local openFormModal
	local openAirDropReceiveDialog

	-- Kartu Profil Pemilik (My Profile Card)
	local function createMyProfileCard(parent: Instance)
		local card = create("TextButton", {
			Name = "MyProfileCard",
			AutoButtonColor = true,
			BackgroundColor3 = COLORS.Card,
			BorderSizePixel = 0,
			Text = "",
			Size = UDim2.new(1, 0, 0, 62),
			LayoutOrder = 0,
			ZIndex = 53,
			Parent = parent,
		})
		rounded(card, 12)
		stroke(card, COLORS.CardStroke, 1)

		local avatarFrame = create("ImageLabel", {
			Name = "Avatar",
			BackgroundColor3 = Color3.fromRGB(230, 235, 245),
			Image = "rbxthumb://type=AvatarBust&id=" .. localPlayer.UserId .. "&w=150&h=150",
			Position = UDim2.new(0, 10, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.fromOffset(42, 42),
			ZIndex = 54,
			Parent = card,
		})
		rounded(avatarFrame, 21)

		label({
			Name = "Name",
			Parent = card,
			Font = Constants.Fonts.Semibold,
			Text = localPlayer.DisplayName .. " (Profil Saya)",
			TextColor3 = COLORS.TextDark,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.new(0, 60, 0, 12),
			Size = UDim2.new(0.65, 0, 0, 18),
			MaxTextSize = 13,
			MinTextSize = 9,
			ZIndex = 54,
		})

		local myPhone = saveService:Get("MyPhoneNumber", "08" .. string.sub(tostring(localPlayer.UserId * 73), 1, 8))
		label({
			Name = "Phone",
			Parent = card,
			Text = "HP Saya: " .. myPhone,
			TextColor3 = COLORS.AccentBlue,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.new(0, 60, 0, 32),
			Size = UDim2.new(0.65, 0, 0, 14),
			MaxTextSize = 11,
			MinTextSize = 8,
			ZIndex = 54,
		})

		local shareBtn = create("TextButton", {
			Name = "ShareMyContactBtn",
			AutoButtonColor = true,
			BackgroundColor3 = Color3.fromRGB(235, 245, 255),
			BorderSizePixel = 0,
			Font = Constants.Fonts.Semibold,
			Text = "📡 AirDrop",
			TextColor3 = COLORS.AccentBlue,
			TextSize = 10,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.new(0, 70, 0, 28),
			ZIndex = 54,
			Parent = card,
		})
		rounded(shareBtn, 14)
		stroke(shareBtn, Color3.fromRGB(200, 225, 255), 1)

		shareBtn.Activated:Connect(function()
			-- Switch ke tab AirDrop
			for id, b in pairs(tabButtons) do
				b.TextColor3 = if id == "airdrop" then COLORS.AccentBlue else COLORS.TextMuted
			end
			TweenService:Create(tabIndicator, TweenInfo.new(0.2), { Position = UDim2.new(2 * tabWidth, 0, 1, -2) }):Play()
			state.ActiveTab = "airdrop"
			searchFrame.Visible = false
			contactsScroll.Visible = false
			airDropFrame.Visible = true
			updateAirDropRadar()
		end)

		card.Activated:Connect(function()
			openDetailModal({
				Id = "my_profile",
				Name = localPlayer.DisplayName .. " (@" .. localPlayer.Name .. ")",
				Phone = myPhone,
				Note = "Profil Utama Pemilik HP",
				UserId = localPlayer.UserId,
				IsFavorite = true,
				IsSelf = true,
			})
		end)
	end

	-- Render Daftar Kontak
	updateContactsList = function()
		for _, child in ipairs(contactsScroll:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextButton") then
				child:Destroy()
			end
		end

		createMyProfileCard(contactsScroll)

		-- Filter Kontak Berdasarkan Query dan Tab Active
		local filtered = {}
		local query = string.lower(state.SearchQuery or "")

		for _, contact in ipairs(state.Contacts) do
			local matchQuery = (query == "")
				or string.find(string.lower(contact.Name or ""), query, 1, true)
				or string.find(string.lower(contact.Phone or ""), query, 1, true)
				or string.find(string.lower(contact.Note or ""), query, 1, true)

			local matchTab = (state.ActiveTab == "all") or (state.ActiveTab == "favorites" and contact.IsFavorite)

			if matchQuery and matchTab then
				table.insert(filtered, contact)
			end
		end

		-- Sort berdasarkan Nama
		table.sort(filtered, function(a, b)
			return string.lower(a.Name or "") < string.lower(b.Name or "")
		end)

		if #filtered == 0 then
			local emptyLabel = label({
				Name = "EmptyLabel",
				Parent = contactsScroll,
				Font = Constants.Fonts.Regular,
				Text = if state.ActiveTab == "favorites" then "Belum ada kontak favorit." else "Tidak ada kontak ditemukan.",
				TextColor3 = COLORS.TextMuted,
				TextXAlignment = Enum.TextXAlignment.Center,
				Size = UDim2.new(1, 0, 0, 60),
				MaxTextSize = 13,
				MinTextSize = 10,
				LayoutOrder = 999,
				ZIndex = 53,
			})
			return
		end

		for idx, contact in ipairs(filtered) do
			local row = create("TextButton", {
				Name = "ContactRow_" .. (contact.Id or idx),
				AutoButtonColor = true,
				BackgroundColor3 = COLORS.Card,
				BorderSizePixel = 0,
				Text = "",
				Size = UDim2.new(1, 0, 0, 54),
				LayoutOrder = idx,
				ZIndex = 53,
				Parent = contactsScroll,
			})
			rounded(row, 10)
			stroke(row, COLORS.CardStroke, 1)

			-- Avatar Image
			local avatar = getAvatarUrl(contact)
			local avatarImg = create("ImageLabel", {
				Name = "Avatar",
				BackgroundColor3 = Color3.fromRGB(235, 238, 245),
				Image = avatar,
				Position = UDim2.new(0, 10, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.fromOffset(36, 36),
				ZIndex = 54,
				Parent = row,
			})
			rounded(avatarImg, 18)

			-- Name
			label({
				Name = "Name",
				Parent = row,
				Font = Constants.Fonts.Semibold,
				Text = contact.Name or "Kontak Tanpa Nama",
				TextColor3 = COLORS.TextDark,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Position = UDim2.new(0, 56, 0, 10),
				Size = UDim2.new(0.55, 0, 0, 16),
				MaxTextSize = 13,
				MinTextSize = 9,
				ZIndex = 54,
			})

			-- Phone & Note Subtitle
			local subtitle = contact.Phone or ""
			if contact.Note and contact.Note ~= "" then
				subtitle = subtitle .. " • " .. contact.Note
			end
			label({
				Name = "Subtitle",
				Parent = row,
				Text = subtitle,
				TextColor3 = COLORS.TextMuted,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Position = UDim2.new(0, 56, 0, 28),
				Size = UDim2.new(0.55, 0, 0, 14),
				MaxTextSize = 10,
				MinTextSize = 7,
				ZIndex = 54,
			})

			-- Favorite Badge Icon
			if contact.IsFavorite then
				iconImage({
					Name = "StarBadge",
					Image = ICONS.Star,
					ImageColor3 = COLORS.AccentGold,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -70, 0.5, 0),
					Size = UDim2.fromOffset(14, 14),
					ZIndex = 54,
					Parent = row,
				})
			end

			-- Quick Call Button
			local callBtn = create("TextButton", {
				Name = "CallBtn",
				AutoButtonColor = true,
				BackgroundColor3 = Color3.fromRGB(235, 247, 240),
				BorderSizePixel = 0,
				Text = "",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -38, 0.5, 0),
				Size = UDim2.fromOffset(26, 26),
				ZIndex = 54,
				Parent = row,
			})
			rounded(callBtn, 13)
			iconImage({
				Name = "Icon",
				Image = ICONS.Phone,
				ImageColor3 = COLORS.AccentGreen,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(14, 14),
				ZIndex = 55,
				Parent = callBtn,
			})
			callBtn.Activated:Connect(function()
				context.SendNotification({
					Title = "📞 Memanggil Kontak",
					Text = "Memanggil " .. (contact.Name or "Kontak") .. " (" .. (contact.Phone or "") .. ")...",
					Duration = 4,
				})
			end)

			-- Quick Message Button
			local msgBtn = create("TextButton", {
				Name = "MsgBtn",
				AutoButtonColor = true,
				BackgroundColor3 = Color3.fromRGB(235, 244, 255),
				BorderSizePixel = 0,
				Text = "",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.fromOffset(26, 26),
				ZIndex = 54,
				Parent = row,
			})
			rounded(msgBtn, 13)
			iconImage({
				Name = "Icon",
				Image = ICONS.Message,
				ImageColor3 = COLORS.AccentBlue,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(14, 14),
				ZIndex = 55,
				Parent = msgBtn,
			})
			msgBtn.Activated:Connect(function()
				context.OpenApp("messages")
			end)

			row.Activated:Connect(function()
				openDetailModal(contact)
			end)
		end
	end

	-- Render Radar Scanner AirDrop
	updateAirDropRadar = function()
		for _, child in ipairs(airDropScroll:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextButton") then
				child:Destroy()
			end
		end

		-- Radar Header Visual Box
		local radarBox = create("Frame", {
			Name = "RadarBox",
			BackgroundColor3 = COLORS.Card,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 110),
			LayoutOrder = 0,
			ZIndex = 54,
			Parent = airDropScroll,
		})
		rounded(radarBox, 14)
		stroke(radarBox, COLORS.CardStroke, 1)

		local radarCenter = create("Frame", {
			Name = "RadarCenter",
			BackgroundColor3 = COLORS.AccentGreen,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.4),
			Size = UDim2.fromOffset(36, 36),
			ZIndex = 55,
			Parent = radarBox,
		})
		rounded(radarCenter, 18)
		iconImage({
			Name = "Icon",
			Image = ICONS.AirDrop,
			ImageColor3 = Color3.fromRGB(255, 255, 255),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(22, 22),
			ZIndex = 56,
			Parent = radarCenter,
		})

		-- Pulsing Ring Animation
		local pulseRing = create("Frame", {
			Name = "PulseRing",
			BackgroundTransparency = 0.8,
			BackgroundColor3 = COLORS.AccentGreen,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.4),
			Size = UDim2.fromOffset(40, 40),
			ZIndex = 54,
			Parent = radarBox,
		})
		rounded(pulseRing, 50)

		TweenService:Create(pulseRing, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, -1, true), {
			Size = UDim2.fromOffset(80, 80),
			BackgroundTransparency = 1,
		}):Play()

		label({
			Name = "RadarStatus",
			Parent = radarBox,
			Font = Constants.Fonts.Semibold,
			Text = "Memindai Perangkat di Sekitar (Radius ~13m)...",
			TextColor3 = COLORS.AccentGreen,
			TextXAlignment = Enum.TextXAlignment.Center,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -8),
			Size = UDim2.new(0.9, 0, 0, 16),
			MaxTextSize = 11,
			MinTextSize = 8,
			ZIndex = 55,
		})

		-- Pindai Player di Sekitar Radius
		local myChar = localPlayer.Character
		local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart") :: BasePart?

		local nearby = {}
		for _, target in ipairs(Players:GetPlayers()) do
			if target ~= localPlayer and target.Character then
				local targetHRP = target.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if myHRP and targetHRP then
					local dist = (myHRP.Position - targetHRP.Position).Magnitude
					if dist <= RADAR_RADIUS_STUDS then
						table.insert(nearby, {
							Player = target,
							Distance = math.floor(dist * 0.28 * 10) / 10, -- Jarak meter
							Studs = math.floor(dist),
						})
					end
				end
			end
		end

		if #nearby == 0 then
			local emptyCard = create("Frame", {
				Name = "EmptyNearby",
				BackgroundColor3 = COLORS.Card,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 60),
				LayoutOrder = 1,
				ZIndex = 54,
				Parent = airDropScroll,
			})
			rounded(emptyCard, 10)
			stroke(emptyCard, COLORS.CardStroke, 1)

			label({
				Name = "Text",
				Parent = emptyCard,
				Font = Constants.Fonts.Regular,
				Text = "Tidak ada player terdekat yang berada dalam radius zona AirDrop.",
				TextColor3 = COLORS.TextMuted,
				TextXAlignment = Enum.TextXAlignment.Center,
				Position = UDim2.fromScale(0, 0),
				Size = UDim2.fromScale(1, 1),
				MaxTextSize = 11,
				MinTextSize = 8,
				ZIndex = 55,
			})
			return
		end

		for idx, item in ipairs(nearby) do
			local target = item.Player
			local card = create("Frame", {
				Name = "PlayerCard_" .. target.UserId,
				BackgroundColor3 = COLORS.Card,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 56),
				LayoutOrder = idx,
				ZIndex = 54,
				Parent = airDropScroll,
			})
			rounded(card, 10)
			stroke(card, COLORS.CardStroke, 1)

			local avatar = create("ImageLabel", {
				Name = "Avatar",
				BackgroundColor3 = Color3.fromRGB(230, 235, 245),
				Image = "rbxthumb://type=AvatarBust&id=" .. target.UserId .. "&w=150&h=150",
				Position = UDim2.new(0, 10, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.fromOffset(38, 38),
				ZIndex = 55,
				Parent = card,
			})
			rounded(avatar, 19)

			label({
				Name = "Name",
				Parent = card,
				Font = Constants.Fonts.Semibold,
				Text = target.DisplayName .. " (@" .. target.Name .. ")",
				TextColor3 = COLORS.TextDark,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Position = UDim2.new(0, 58, 0, 10),
				Size = UDim2.new(0.5, 0, 0, 16),
				MaxTextSize = 13,
				MinTextSize = 9,
				ZIndex = 55,
			})

			label({
				Name = "Distance",
				Parent = card,
				Text = "Jarak: " .. item.Distance .. "m (" .. item.Studs .. " studs)",
				TextColor3 = COLORS.AccentGreen,
				Position = UDim2.new(0, 58, 0, 28),
				Size = UDim2.new(0.5, 0, 0, 14),
				MaxTextSize = 10,
				MinTextSize = 7,
				ZIndex = 55,
			})

			local sendAirDropBtn = create("TextButton", {
				Name = "SendAirDropBtn",
				AutoButtonColor = true,
				BackgroundColor3 = COLORS.AccentGreen,
				BorderSizePixel = 0,
				Font = Constants.Fonts.Semibold,
				Text = "Kirim Kontak",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 11,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.new(0, 85, 0, 30),
				ZIndex = 55,
				Parent = card,
			})
			rounded(sendAirDropBtn, 15)

			sendAirDropBtn.Activated:Connect(function()
				local myPhone = saveService:Get("MyPhoneNumber", "08" .. string.sub(tostring(localPlayer.UserId * 73), 1, 8))
				local contactPayload = {
					Name = localPlayer.DisplayName,
					Phone = myPhone,
					Note = "Kontak via AirDrop",
					UserId = localPlayer.UserId,
					IsFavorite = false,
				}

				if remote and remote:IsA("RemoteEvent") then
					remote:FireServer("AirDropContact", {
						targetUserId = target.UserId,
						contactData = contactPayload,
					})
					context.SendNotification({
						Title = "📡 AirDrop Dikirim",
						Text = "Mengirim kontak ke " .. target.DisplayName .. "...",
						Duration = 3,
					})
				end
			end)
		end
	end

	-- MODAL DETAIL KONTAK
	openDetailModal = function(contact: any)
		modalOverlay.Visible = true
		for _, child in ipairs(modalOverlay:GetChildren()) do
			child:Destroy()
		end

		local card = create("Frame", {
			Name = "DetailCard",
			BackgroundColor3 = COLORS.Card,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0.88, 0, 0, 340),
			ZIndex = 101,
			Parent = modalOverlay,
		})
		rounded(card, 16)
		stroke(card, COLORS.CardStroke, 2)
		padded(card, 0.04, 0.04, 0.03, 0.04)

		-- Close Button
		local closeBtn = create("TextButton", {
			Name = "CloseBtn",
			AutoButtonColor = true,
			BackgroundTransparency = 1,
			Font = Constants.Fonts.Semibold,
			Text = "✕",
			TextColor3 = COLORS.TextMuted,
			TextSize = 16,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.new(0, 24, 0, 24),
			ZIndex = 102,
			Parent = card,
		})
		closeBtn.Activated:Connect(function()
			modalOverlay.Visible = false
		end)

		-- Avatar Besar
		local avatar = getAvatarUrl(contact)
		local avatarImg = create("ImageLabel", {
			Name = "Avatar",
			BackgroundColor3 = Color3.fromRGB(235, 238, 245),
			Image = avatar,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 10),
			Size = UDim2.fromOffset(68, 68),
			ZIndex = 102,
			Parent = card,
		})
		rounded(avatarImg, 34)
		stroke(avatarImg, COLORS.AccentBlue, 2)

		-- Name & Phone
		label({
			Name = "DetailName",
			Parent = card,
			Font = Constants.Fonts.Semibold,
			Text = contact.Name or "Tanpa Nama",
			TextColor3 = COLORS.TextDark,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.new(0, 0, 0, 84),
			Size = UDim2.new(1, 0, 0, 20),
			MaxTextSize = 16,
			MinTextSize = 11,
			ZIndex = 102,
		})

		label({
			Name = "DetailPhone",
			Parent = card,
			Text = contact.Phone or "-",
			TextColor3 = COLORS.AccentBlue,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.new(0, 0, 0, 106),
			Size = UDim2.new(1, 0, 0, 16),
			MaxTextSize = 13,
			MinTextSize = 9,
			ZIndex = 102,
		})

		if contact.Note and contact.Note ~= "" then
			local noteBadge = create("Frame", {
				Name = "NoteBadge",
				BackgroundColor3 = Color3.fromRGB(240, 242, 248),
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 126),
				Size = UDim2.new(0.7, 0, 0, 22),
				ZIndex = 102,
				Parent = card,
			})
			rounded(noteBadge, 11)
			label({
				Name = "NoteText",
				Parent = noteBadge,
				Text = contact.Note,
				TextColor3 = COLORS.TextMuted,
				TextXAlignment = Enum.TextXAlignment.Center,
				Position = UDim2.fromScale(0, 0),
				Size = UDim2.fromScale(1, 1),
				MaxTextSize = 10,
				MinTextSize = 7,
				ZIndex = 103,
			})
		end

		-- Action Bar Grid (Panggil, Pesan, AirDrop, Favorit)
		local actionsGrid = create("Frame", {
			Name = "ActionsGrid",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 156),
			Size = UDim2.new(1, 0, 0, 56),
			ZIndex = 102,
			Parent = card,
		})

		local function makeActionButton(name, titleText, iconAsset, color, xIndex, callback)
			local btn = create("TextButton", {
				Name = name,
				AutoButtonColor = true,
				BackgroundColor3 = Color3.fromRGB(246, 248, 252),
				BorderSizePixel = 0,
				Text = "",
				Position = UDim2.new((xIndex - 1) * 0.25 + 0.02, 0, 0, 0),
				Size = UDim2.new(0.21, 0, 1, 0),
				ZIndex = 103,
				Parent = actionsGrid,
			})
			rounded(btn, 10)
			stroke(btn, COLORS.CardStroke, 1)

			iconImage({
				Name = "Icon",
				Image = iconAsset,
				ImageColor3 = color,
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 8),
				Size = UDim2.fromOffset(20, 20),
				ZIndex = 104,
				Parent = btn,
			})

			label({
				Name = "Label",
				Parent = btn,
				Font = Constants.Fonts.Semibold,
				Text = titleText,
				TextColor3 = COLORS.TextDark,
				TextXAlignment = Enum.TextXAlignment.Center,
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -4),
				Size = UDim2.new(1, 0, 0, 14),
				MaxTextSize = 9,
				MinTextSize = 7,
				ZIndex = 104,
			})

			btn.Activated:Connect(callback)
		end

		makeActionButton("Call", "Panggil", ICONS.Phone, COLORS.AccentGreen, 1, function()
			context.SendNotification({
				Title = "📞 Panggilan Telepon",
				Text = "Memanggil " .. (contact.Name or "") .. "...",
				Duration = 3,
			})
		end)

		makeActionButton("Msg", "Pesan", ICONS.Message, COLORS.AccentBlue, 2, function()
			modalOverlay.Visible = false
			context.OpenApp("messages")
		end)

		makeActionButton("AirDrop", "AirDrop", ICONS.AirDrop, COLORS.AccentGreen, 3, function()
			modalOverlay.Visible = false
			for id, b in pairs(tabButtons) do
				b.TextColor3 = if id == "airdrop" then COLORS.AccentBlue else COLORS.TextMuted
			end
			TweenService:Create(tabIndicator, TweenInfo.new(0.2), { Position = UDim2.new(2 * tabWidth, 0, 1, -2) }):Play()
			state.ActiveTab = "airdrop"
			searchFrame.Visible = false
			contactsScroll.Visible = false
			airDropFrame.Visible = true
			updateAirDropRadar()
		end)

		local favColor = if contact.IsFavorite then COLORS.AccentGold else COLORS.TextMuted
		makeActionButton("Fav", if contact.IsFavorite then "Favorit ★" else "Favorit ☆", ICONS.Star, favColor, 4, function()
			contact.IsFavorite = not contact.IsFavorite
			saveService:Set("Contacts", state.Contacts)
			modalOverlay.Visible = false
			updateContactsList()
		end)

		-- Action Bottom Buttons (Edit & Delete)
		if not contact.IsSelf then
			local editBtn = create("TextButton", {
				Name = "EditBtn",
				AutoButtonColor = true,
				BackgroundColor3 = COLORS.AccentBlue,
				BorderSizePixel = 0,
				Font = Constants.Fonts.Semibold,
				Text = "Edit Kontak",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 12,
				Position = UDim2.new(0, 0, 1, -44),
				Size = UDim2.new(0.48, 0, 0, 36),
				ZIndex = 103,
				Parent = card,
			})
			rounded(editBtn, 10)

			editBtn.Activated:Connect(function()
				modalOverlay.Visible = false
				openFormModal(contact)
			end)

			local deleteBtn = create("TextButton", {
				Name = "DeleteBtn",
				AutoButtonColor = true,
				BackgroundColor3 = COLORS.DestructiveRed,
				BorderSizePixel = 0,
				Font = Constants.Fonts.Semibold,
				Text = "Hapus Kontak",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 12,
				Position = UDim2.new(0.52, 0, 1, -44),
				Size = UDim2.new(0.48, 0, 0, 36),
				ZIndex = 103,
				Parent = card,
			})
			rounded(deleteBtn, 10)

			deleteBtn.Activated:Connect(function()
				for i, c in ipairs(state.Contacts) do
					if c.Id == contact.Id or (c.Phone == contact.Phone and c.Name == contact.Name) then
						table.remove(state.Contacts, i)
						break
					end
				end
				saveService:Set("Contacts", state.Contacts)
				modalOverlay.Visible = false
				updateContactsList()
				context.SendNotification({
					Title = "🗑️ Kontak Dihapus",
					Text = "Kontak " .. (contact.Name or "") .. " telah dihapus.",
					Duration = 3,
				})
			end)
		end
	end

	-- MODAL FORM TAMBAH / EDIT KONTAK
	openFormModal = function(existingContact: any?)
		modalOverlay.Visible = true
		for _, child in ipairs(modalOverlay:GetChildren()) do
			child:Destroy()
		end

		local isEdit = existingContact ~= nil
		local card = create("Frame", {
			Name = "FormCard",
			BackgroundColor3 = COLORS.Card,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0.88, 0, 0, 350),
			ZIndex = 101,
			Parent = modalOverlay,
		})
		rounded(card, 16)
		stroke(card, COLORS.CardStroke, 2)
		padded(card, 0.04, 0.04, 0.03, 0.04)

		label({
			Name = "FormTitle",
			Parent = card,
			Font = Constants.Fonts.Semibold,
			Text = if isEdit then "Edit Kontak" else "Tambah Kontak Baru",
			TextColor3 = COLORS.TextDark,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.new(0, 0, 0, 4),
			Size = UDim2.new(1, 0, 0, 22),
			MaxTextSize = 15,
			MinTextSize = 11,
			ZIndex = 102,
		})

		-- Field Input Nama
		label({
			Parent = card,
			Font = Constants.Fonts.Semibold,
			Text = "NAMA KONTAK",
			TextColor3 = COLORS.TextMuted,
			Position = UDim2.new(0, 0, 0, 34),
			Size = UDim2.new(1, 0, 0, 14),
			MaxTextSize = 9,
			MinTextSize = 7,
			ZIndex = 102,
		})
		local nameBox = create("TextBox", {
			Name = "NameInput",
			BackgroundColor3 = Color3.fromRGB(246, 247, 250),
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
			Font = Constants.Fonts.Regular,
			PlaceholderColor3 = COLORS.TextMuted,
			PlaceholderText = "Masukkan Nama...",
			Text = if isEdit then (existingContact.Name or "") else "",
			TextColor3 = COLORS.TextDark,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 0, 0, 50),
			Size = UDim2.new(1, 0, 0, 34),
			ZIndex = 102,
			Parent = card,
		})
		rounded(nameBox, 8)
		stroke(nameBox, COLORS.CardStroke, 1)
		padded(nameBox, 0.03, 0.03, 0, 0)

		-- Field Input Nomor HP
		label({
			Parent = card,
			Font = Constants.Fonts.Semibold,
			Text = "NOMOR TELEPON",
			TextColor3 = COLORS.TextMuted,
			Position = UDim2.new(0, 0, 0, 92),
			Size = UDim2.new(1, 0, 0, 14),
			MaxTextSize = 9,
			MinTextSize = 7,
			ZIndex = 102,
		})
		local phoneBox = create("TextBox", {
			Name = "PhoneInput",
			BackgroundColor3 = Color3.fromRGB(246, 247, 250),
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
			Font = Constants.Fonts.Regular,
			PlaceholderColor3 = COLORS.TextMuted,
			PlaceholderText = "Contoh: 0812-xxxx-xxxx",
			Text = if isEdit then (existingContact.Phone or "") else "",
			TextColor3 = COLORS.TextDark,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 0, 0, 108),
			Size = UDim2.new(1, 0, 0, 34),
			ZIndex = 102,
			Parent = card,
		})
		rounded(phoneBox, 8)
		stroke(phoneBox, COLORS.CardStroke, 1)
		padded(phoneBox, 0.03, 0.03, 0, 0)

		-- Field Input Catatan
		label({
			Parent = card,
			Font = Constants.Fonts.Semibold,
			Text = "CATATAN / HUBUNGAN",
			TextColor3 = COLORS.TextMuted,
			Position = UDim2.new(0, 0, 0, 150),
			Size = UDim2.new(1, 0, 0, 14),
			MaxTextSize = 9,
			MinTextSize = 7,
			ZIndex = 102,
		})
		local noteBox = create("TextBox", {
			Name = "NoteInput",
			BackgroundColor3 = Color3.fromRGB(246, 247, 250),
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
			Font = Constants.Fonts.Regular,
			PlaceholderColor3 = COLORS.TextMuted,
			PlaceholderText = "Contoh: Teman Sekolah / Kerja",
			Text = if isEdit then (existingContact.Note or "") else "",
			TextColor3 = COLORS.TextDark,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 0, 0, 166),
			Size = UDim2.new(1, 0, 0, 34),
			ZIndex = 102,
			Parent = card,
		})
		rounded(noteBox, 8)
		stroke(noteBox, COLORS.CardStroke, 1)
		padded(noteBox, 0.03, 0.03, 0, 0)

		-- Tombol "Pilih dari Player Terdekat"
		local pickPlayerBtn = create("TextButton", {
			Name = "PickPlayerBtn",
			AutoButtonColor = true,
			BackgroundColor3 = Color3.fromRGB(235, 245, 255),
			BorderSizePixel = 0,
			Font = Constants.Fonts.Semibold,
			Text = "👤 Autofill dari Player Terdekat",
			TextColor3 = COLORS.AccentBlue,
			TextSize = 11,
			Position = UDim2.new(0, 0, 0, 210),
			Size = UDim2.new(1, 0, 0, 32),
			ZIndex = 102,
			Parent = card,
		})
		rounded(pickPlayerBtn, 8)
		stroke(pickPlayerBtn, Color3.fromRGB(200, 225, 255), 1)

		local selectedUserId = if isEdit then existingContact.UserId else nil
		pickPlayerBtn.Activated:Connect(function()
			local myChar = localPlayer.Character
			local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart") :: BasePart?
			for _, target in ipairs(Players:GetPlayers()) do
				if target ~= localPlayer and target.Character then
					local targetHRP = target.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
					if myHRP and targetHRP and (myHRP.Position - targetHRP.Position).Magnitude <= RADAR_RADIUS_STUDS then
						nameBox.Text = target.DisplayName
						phoneBox.Text = "08" .. string.sub(tostring(target.UserId * 73), 1, 8)
						noteBox.Text = "Pemain Roblox (@" .. target.Name .. ")"
						selectedUserId = target.UserId
						context.SendNotification({
							Title = "👤 AutoFill Kontak",
							Text = "Mengisi data dari player " .. target.DisplayName,
							Duration = 2,
						})
						break
					end
				end
			end
		end)

		-- Action Buttons (Batal & Simpan)
		local cancelBtn = create("TextButton", {
			Name = "CancelBtn",
			AutoButtonColor = true,
			BackgroundColor3 = Color3.fromRGB(240, 242, 245),
			BorderSizePixel = 0,
			Font = Constants.Fonts.Semibold,
			Text = "Batal",
			TextColor3 = COLORS.TextDark,
			TextSize = 12,
			Position = UDim2.new(0, 0, 1, -44),
			Size = UDim2.new(0.48, 0, 0, 36),
			ZIndex = 102,
			Parent = card,
		})
		rounded(cancelBtn, 10)
		cancelBtn.Activated:Connect(function()
			modalOverlay.Visible = false
		end)

		local saveBtn = create("TextButton", {
			Name = "SaveBtn",
			AutoButtonColor = true,
			BackgroundColor3 = COLORS.AccentBlue,
			BorderSizePixel = 0,
			Font = Constants.Fonts.Semibold,
			Text = "Simpan",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 12,
			Position = UDim2.new(0.52, 0, 1, -44),
			Size = UDim2.new(0.48, 0, 0, 36),
			ZIndex = 102,
			Parent = card,
		})
		rounded(saveBtn, 10)

		saveBtn.Activated:Connect(function()
			local nameText = string.gsub(nameBox.Text, "^%s*(.-)%s*$", "%1")
			local phoneText = string.gsub(phoneBox.Text, "^%s*(.-)%s*$", "%1")
			local noteText = string.gsub(noteBox.Text, "^%s*(.-)%s*$", "%1")

			if nameText == "" then
				context.SendNotification({ Title = "⚠️ Peringatan", Text = "Nama kontak wajib diisi!", Duration = 3 })
				return
			end
			if phoneText == "" then
				context.SendNotification({ Title = "⚠️ Peringatan", Text = "Nomor HP wajib diisi!", Duration = 3 })
				return
			end

			if isEdit then
				existingContact.Name = nameText
				existingContact.Phone = phoneText
				existingContact.Note = noteText
				if selectedUserId then existingContact.UserId = selectedUserId end
			else
				table.insert(state.Contacts, {
					Id = "c_" .. tick(),
					Name = nameText,
					Phone = phoneText,
					Note = noteText,
					UserId = selectedUserId,
					IsFavorite = false,
				})
			end

			saveService:Set("Contacts", state.Contacts)
			modalOverlay.Visible = false
			updateContactsList()
			context.SendNotification({
				Title = "✅ Kontak Disimpan",
				Text = "Kontak " .. nameText .. " berhasil disimpan.",
				Duration = 3,
			})
		end)
	end

	-- DIALOG PENERIMAAN AIRDROP KONTAK
	openAirDropReceiveDialog = function(data: { senderUserId: number, senderName: string, contactData: any })
		modalOverlay.Visible = true
		for _, child in ipairs(modalOverlay:GetChildren()) do
			child:Destroy()
		end

		local card = create("Frame", {
			Name = "AirDropReceiveCard",
			BackgroundColor3 = COLORS.Card,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0.88, 0, 0, 240),
			ZIndex = 101,
			Parent = modalOverlay,
		})
		rounded(card, 16)
		stroke(card, COLORS.AccentGreen, 2)
		padded(card, 0.04, 0.04, 0.03, 0.04)

		local iconHeader = iconImage({
			Name = "AirDropIcon",
			Image = ICONS.AirDrop,
			ImageColor3 = COLORS.AccentGreen,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 10),
			Size = UDim2.fromOffset(36, 36),
			ZIndex = 102,
			Parent = card,
		})

		label({
			Name = "Title",
			Parent = card,
			Font = Constants.Fonts.Semibold,
			Text = "📡 AirDrop Kontak Masuk",
			TextColor3 = COLORS.TextDark,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.new(0, 0, 0, 52),
			Size = UDim2.new(1, 0, 0, 20),
			MaxTextSize = 15,
			MinTextSize = 11,
			ZIndex = 102,
		})

		local cData = data.contactData or {}
		label({
			Name = "Message",
			Parent = card,
			Text = data.senderName .. " ingin membagikan kontak '" .. (cData.Name or "Kontak") .. "' (" .. (cData.Phone or "-") .. ").",
			TextColor3 = COLORS.TextMuted,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.new(0, 0, 0, 76),
			Size = UDim2.new(1, 0, 0, 36),
			MaxTextSize = 11,
			MinTextSize = 8,
			ZIndex = 102,
		})

		local declineBtn = create("TextButton", {
			Name = "DeclineBtn",
			AutoButtonColor = true,
			BackgroundColor3 = Color3.fromRGB(240, 242, 245),
			BorderSizePixel = 0,
			Font = Constants.Fonts.Semibold,
			Text = "Tolak",
			TextColor3 = COLORS.TextDark,
			TextSize = 12,
			Position = UDim2.new(0, 0, 1, -44),
			Size = UDim2.new(0.48, 0, 0, 36),
			ZIndex = 102,
			Parent = card,
		})
		rounded(declineBtn, 10)
		declineBtn.Activated:Connect(function()
			modalOverlay.Visible = false
		end)

		local acceptBtn = create("TextButton", {
			Name = "AcceptBtn",
			AutoButtonColor = true,
			BackgroundColor3 = COLORS.AccentGreen,
			BorderSizePixel = 0,
			Font = Constants.Fonts.Semibold,
			Text = "Terima & Simpan",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 12,
			Position = UDim2.new(0.52, 0, 1, -44),
			Size = UDim2.new(0.48, 0, 0, 36),
			ZIndex = 102,
			Parent = card,
		})
		rounded(acceptBtn, 10)

		acceptBtn.Activated:Connect(function()
			table.insert(state.Contacts, {
				Id = "airdrop_" .. tick(),
				Name = cData.Name or data.senderName,
				Phone = cData.Phone or "08xxxxxx",
				Note = "Diterima via AirDrop dari " .. data.senderName,
				UserId = cData.UserId or data.senderUserId,
				IsFavorite = false,
			})
			saveService:Set("Contacts", state.Contacts)
			modalOverlay.Visible = false
			updateContactsList()
			context.SendNotification({
				Title = "✅ AirDrop Diterima",
				Text = "Kontak " .. (cData.Name or data.senderName) .. " berhasil disimpan ke Kontak Anda!",
				Duration = 4,
			})
		end)
	end

	-- EVENT LISTENERS & LOGIC BINDINGS

	-- Switch Tab Event
	for id, btn in pairs(tabButtons) do
		btn.Activated:Connect(function()
			state.ActiveTab = id
			for tid, b in pairs(tabButtons) do
				b.TextColor3 = if tid == id then COLORS.AccentBlue else COLORS.TextMuted
			end

			local targetX = 0
			if id == "favorites" then
				targetX = tabWidth
			elseif id == "airdrop" then
				targetX = 2 * tabWidth
			end
			TweenService:Create(tabIndicator, TweenInfo.new(0.2), { Position = UDim2.new(targetX, 0, 1, -2) }):Play()

			if id == "airdrop" then
				searchFrame.Visible = false
				contactsScroll.Visible = false
				airDropFrame.Visible = true
				updateAirDropRadar()
			else
				searchFrame.Visible = true
				contactsScroll.Visible = true
				airDropFrame.Visible = false
				updateContactsList()
			end
		end)
	end

	-- Search Input Event
	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		state.SearchQuery = searchBox.Text
		clearSearchBtn.Visible = (searchBox.Text ~= "")
		updateContactsList()
	end)

	clearSearchBtn.Activated:Connect(function()
		searchBox.Text = ""
		state.SearchQuery = ""
		clearSearchBtn.Visible = false
		updateContactsList()
	end)

	-- Header Add Button
	addContactBtn.Activated:Connect(function()
		openFormModal(nil)
	end)

	-- Header AirDrop Button
	airDropHeaderBtn.Activated:Connect(function()
		for id, b in pairs(tabButtons) do
			b.TextColor3 = if id == "airdrop" then COLORS.AccentBlue else COLORS.TextMuted
		end
		TweenService:Create(tabIndicator, TweenInfo.new(0.2), { Position = UDim2.new(2 * tabWidth, 0, 1, -2) }):Play()
		state.ActiveTab = "airdrop"
		searchFrame.Visible = false
		contactsScroll.Visible = false
		airDropFrame.Visible = true
		updateAirDropRadar()
	end)

	-- Listener Remote Event Server untuk AirDrop Masuk
	local remoteConnection
	if remote and remote:IsA("RemoteEvent") then
		remoteConnection = remote.OnClientEvent:Connect(function(action: string, payload: any)
			if action == "ReceiveAirDropContact" and payload then
				openAirDropReceiveDialog(payload)
			end
		end)
	end

	-- Auto Refresh Radar AirDrop saat berada di Tab AirDrop
	local radarLoopConnection = RunService.Heartbeat:Connect(function()
		if rootFrame.Visible and state.ActiveTab == "airdrop" then
			-- Periodik update setiap heartbeat jika diperlukan
		end
	end)

	-- SaveService Change Listener
	local saveConnection = saveService.Changed:Connect(function(key: string, value: any)
		if key == "Contacts" and type(value) == "table" then
			state.Contacts = value
			updateContactsList()
		end
	end)

	rootFrame.Destroying:Connect(function()
		if remoteConnection then remoteConnection:Disconnect() end
		if radarLoopConnection then radarLoopConnection:Disconnect() end
		if saveConnection then saveConnection:Disconnect() end
	end)

	-- Initial Render
	updateContactsList()

	return rootFrame
end

return ContactsApp
