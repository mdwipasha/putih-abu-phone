local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local root = script.Parent.Parent
local Constants = require(root:WaitForChild("Shared"):WaitForChild("Constants"))
local StatusBar = require(root:WaitForChild("Shared"):WaitForChild("Components"):WaitForChild("StatusBar"))
local create = require(root:WaitForChild("Shared"):WaitForChild("Utilities"):WaitForChild("Create"))
local EconomyAdapter = require(root:WaitForChild("Services"):WaitForChild("EconomyAdapter"))

local RADAR_RADIUS_STUDS = 40 -- Radius zona AirDrop dalam studs (~13 meter)

local ICONS = {
	Phone = "rbxassetid://71727318918905",
	Message = "rbxassetid://108650574179237",
	AirDrop = "rbxassetid://127578521635782",
	Search = "rbxassetid://91955678829293",
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

local DEFAULT_CONTACTS = {}

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

local AVATAR_COLORS = {
	Color3.fromRGB(0, 122, 255),  -- Blue
	Color3.fromRGB(52, 199, 89),  -- Green
	Color3.fromRGB(255, 149, 0),  -- Orange
	Color3.fromRGB(175, 82, 222), -- Purple
	Color3.fromRGB(255, 45, 85),  -- Pink
	Color3.fromRGB(88, 86, 214),  -- Indigo
}

local function isPlayerOnline(contactData: any): boolean
	if contactData.IsSelf then return true end
	if contactData.UserId and tonumber(contactData.UserId) then
		local p = Players:GetPlayerByUserId(tonumber(contactData.UserId))
		return p ~= nil
	end
	return false
end

local function renderAvatarWidget(props: {
	Parent: Instance,
	Contact: any,
	SizeOffset: number,
	Position: UDim2,
	AnchorPoint: Vector2?,
	ZIndex: number?,
})
	local contact = props.Contact
	local sizeOffset = props.SizeOffset or 36
	local isOnline = isPlayerOnline(contact)
	local borderColor = if isOnline then COLORS.AccentGreen else COLORS.DestructiveRed
	local zIndex = props.ZIndex or 54

	local avatarFrame = create("Frame", {
		Name = "AvatarFrame",
		BackgroundColor3 = Color3.fromRGB(235, 238, 245),
		Position = props.Position or UDim2.new(0, 10, 0.5, 0),
		AnchorPoint = props.AnchorPoint or Vector2.new(0, 0.5),
		Size = UDim2.fromOffset(sizeOffset, sizeOffset),
		ZIndex = zIndex,
		Parent = props.Parent,
	})
	rounded(avatarFrame, math.floor(sizeOffset / 2))
	stroke(avatarFrame, borderColor, 2)

	if contact.UserId and tonumber(contact.UserId) then
		local img = create("ImageLabel", {
			Name = "AvatarImg",
			BackgroundTransparency = 1,
			Image = "rbxthumb://type=AvatarBust&id=" .. contact.UserId .. "&w=150&h=150",
			Size = UDim2.fromScale(1, 1),
			ZIndex = zIndex + 1,
			Parent = avatarFrame,
		})
		rounded(img, math.floor(sizeOffset / 2))
	else
		-- Fallback Initial Name Letter
		local nameStr = contact.Name or "K"
		local initial = string.upper(string.sub(nameStr, 1, 1))
		local colorIdx = ((string.byte(initial) or 65) % #AVATAR_COLORS) + 1
		avatarFrame.BackgroundColor3 = AVATAR_COLORS[colorIdx]

		label({
			Name = "InitialLabel",
			Parent = avatarFrame,
			Font = Constants.Fonts.Semibold,
			Text = initial,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.fromScale(1, 1),
			MaxTextSize = math.floor(sizeOffset * 0.48),
			MinTextSize = 8,
			ZIndex = zIndex + 1,
		})
	end

	return avatarFrame
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
		Text = "く",
		TextColor3 = COLORS.AccentBlue,
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
		{ id = "all", name = "All Contacts" },
		{ id = "airdrop", name = "AirDrop" },
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

		renderAvatarWidget({
			Parent = card,
			Contact = { UserId = localPlayer.UserId, Name = localPlayer.DisplayName, IsSelf = true },
			SizeOffset = 42,
			Position = UDim2.new(0, 10, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			ZIndex = 54,
		})

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

		local myPhone = EconomyAdapter.GetPhoneNumber()
		if myPhone == "-" or myPhone == "" then
			myPhone = "08" .. tostring(math.abs(localPlayer.UserId))
		end
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

		card.Activated:Connect(function()
			openDetailModal({
				Id = "my_profile",
				Name = localPlayer.DisplayName .. " (@" .. localPlayer.Name .. ")",
				Phone = myPhone,
				Note = "Profil Utama Pemilik HP",
				UserId = localPlayer.UserId,
				IsSelf = true,
			})
		end)
	end

	-- Render Daftar Kontak
	updateContactsList = function()
		for _, child in ipairs(contactsScroll:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") or child:IsA("ImageLabel") then
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

			if matchQuery then
				table.insert(filtered, contact)
			end
		end

		-- Sort berdasarkan Nama
		table.sort(filtered, function(a, b)
			return string.lower(a.Name or "") < string.lower(b.Name or "")
		end)

		if #filtered == 0 then
			label({
				Name = "EmptyLabel",
				Parent = contactsScroll,
				Font = Constants.Fonts.Regular,
				Text = "No contacts saved.",
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

			-- Avatar Image (with Online/Offline border & initial fallback)
			renderAvatarWidget({
				Parent = row,
				Contact = contact,
				SizeOffset = 36,
				Position = UDim2.new(0, 10, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				ZIndex = 54,
			})

			-- Name
			label({
				Name = "Name",
				Parent = row,
				Font = Constants.Fonts.Semibold,
				Text = contact.Name or "Unnamed Contact",
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
					Title = "📞 Calling Contact",
					Text = "Calling " .. (contact.Name or "Contact") .. " (" .. (contact.Phone or "") .. ")...",
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
			if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") or child:IsA("ImageLabel") then
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
				Text = "No nearby players found within AirDrop zone radius.",
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

			renderAvatarWidget({
				Parent = card,
				Contact = { UserId = target.UserId, Name = target.DisplayName },
				SizeOffset = 38,
				Position = UDim2.new(0, 10, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				ZIndex = 55,
			})

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
				Text = "",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.fromOffset(30, 30),
				ZIndex = 55,
				Parent = card,
			})
			rounded(sendAirDropBtn, 15)

			iconImage({
				Name = "Icon",
				Image = ICONS.AirDrop,
				ImageColor3 = Color3.fromRGB(255, 255, 255),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(16, 16),
				ZIndex = 56,
				Parent = sendAirDropBtn,
			})

			sendAirDropBtn.Activated:Connect(function()
				local myPhone = EconomyAdapter.GetPhoneNumber()
				if myPhone == "-" or myPhone == "" then
					myPhone = "08" .. tostring(math.abs(localPlayer.UserId))
				end
				local contactPayload = {
					Name = localPlayer.DisplayName,
					Phone = myPhone,
					Note = "AirDrop Contact",
					UserId = localPlayer.UserId,
				}

				if remote and remote:IsA("RemoteEvent") then
					remote:FireServer("AirDropContact", {
						targetUserId = target.UserId,
						contactData = contactPayload,
					})
					context.SendNotification({
						Title = "AirDrop Sent",
						Text = "Sending contact to " .. target.DisplayName .. "...",
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

		local cardHeight = if not contact.IsSelf then 240 else 190
		local card = create("Frame", {
			Name = "DetailCard",
			BackgroundColor3 = COLORS.Card,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0.86, 0, 0, cardHeight),
			ZIndex = 101,
			Parent = modalOverlay,
		})
		rounded(card, 14)
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
			TextSize = 15,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.new(0, 22, 0, 22),
			ZIndex = 102,
			Parent = card,
		})
		closeBtn.Activated:Connect(function()
			modalOverlay.Visible = false
		end)

		-- Avatar Ringkas (with Online/Offline border & initial fallback)
		renderAvatarWidget({
			Parent = card,
			Contact = contact,
			SizeOffset = 52,
			Position = UDim2.new(0.5, 0, 0, 6),
			AnchorPoint = Vector2.new(0.5, 0),
			ZIndex = 102,
		})

		-- Name & Phone
		label({
			Name = "DetailName",
			Parent = card,
			Font = Constants.Fonts.Semibold,
			Text = contact.Name or "Tanpa Nama",
			TextColor3 = COLORS.TextDark,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.new(0, 0, 0, 62),
			Size = UDim2.new(1, 0, 0, 18),
			MaxTextSize = 14,
			MinTextSize = 10,
			ZIndex = 102,
		})

		label({
			Name = "DetailPhone",
			Parent = card,
			Text = contact.Phone or "-",
			TextColor3 = COLORS.AccentBlue,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.new(0, 0, 0, 82),
			Size = UDim2.new(1, 0, 0, 14),
			MaxTextSize = 12,
			MinTextSize = 8,
			ZIndex = 102,
		})

		local hasNote = contact.Note and contact.Note ~= ""
		if hasNote then
			local noteBadge = create("Frame", {
				Name = "NoteBadge",
				BackgroundColor3 = Color3.fromRGB(240, 242, 248),
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 98),
				Size = UDim2.new(0.75, 0, 0, 18),
				ZIndex = 102,
				Parent = card,
			})
			rounded(noteBadge, 9)
			label({
				Name = "NoteText",
				Parent = noteBadge,
				Text = contact.Note,
				TextColor3 = COLORS.TextMuted,
				TextXAlignment = Enum.TextXAlignment.Center,
				Position = UDim2.fromScale(0, 0),
				Size = UDim2.fromScale(1, 1),
				MaxTextSize = 9,
				MinTextSize = 6,
				ZIndex = 103,
			})
		end

		-- Action Bar Grid (Panggil, Pesan, AirDrop)
		local actionsY = if hasNote then 120 else 102
		local actionsGrid = create("Frame", {
			Name = "ActionsGrid",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, actionsY),
			Size = UDim2.new(1, 0, 0, 44),
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
				Position = UDim2.new((xIndex - 1) * 0.33 + 0.01, 0, 0, 0),
				Size = UDim2.new(0.31, 0, 1, 0),
				ZIndex = 103,
				Parent = actionsGrid,
			})
			rounded(btn, 8)
			stroke(btn, COLORS.CardStroke, 1)

			iconImage({
				Name = "Icon",
				Image = iconAsset,
				ImageColor3 = color,
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 6),
				Size = UDim2.fromOffset(16, 16),
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
				Position = UDim2.new(0.5, 0, 1, -3),
				Size = UDim2.new(1, 0, 0, 12),
				MaxTextSize = 8,
				MinTextSize = 6,
				ZIndex = 104,
			})

			btn.Activated:Connect(callback)
		end

		makeActionButton("Call", "Call", ICONS.Phone, COLORS.AccentGreen, 1, function()
			context.SendNotification({
				Title = "📞 Phone Call",
				Text = "Calling " .. (contact.Name or "") .. "...",
				Duration = 3,
			})
		end)

		makeActionButton("Msg", "Message", ICONS.Message, COLORS.AccentBlue, 2, function()
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

		-- Action Bottom Buttons (Edit & Delete)
		if not contact.IsSelf then
			local editBtn = create("TextButton", {
				Name = "EditBtn",
				AutoButtonColor = true,
				BackgroundColor3 = COLORS.AccentBlue,
				BorderSizePixel = 0,
				Font = Constants.Fonts.Semibold,
				Text = "Edit Contact",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 11,
				Position = UDim2.new(0, 0, 1, -34),
				Size = UDim2.new(0.48, 0, 0, 30),
				ZIndex = 103,
				Parent = card,
			})
			rounded(editBtn, 8)

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
				Text = "Delete Contact",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 11,
				Position = UDim2.new(0.52, 0, 1, -34),
				Size = UDim2.new(0.48, 0, 0, 30),
				ZIndex = 103,
				Parent = card,
			})
			rounded(deleteBtn, 8)

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
					Title = "🗑️ Contact Deleted",
					Text = "Contact " .. (contact.Name or "") .. " has been deleted.",
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
			Size = UDim2.new(0.86, 0, 0, 245),
			ZIndex = 101,
			Parent = modalOverlay,
		})
		rounded(card, 14)
		stroke(card, COLORS.CardStroke, 2)
		padded(card, 0.04, 0.04, 0.03, 0.04)

		label({
			Name = "FormTitle",
			Parent = card,
			Font = Constants.Fonts.Semibold,
			Text = if isEdit then "Edit Contact" else "New Contact",
			TextColor3 = COLORS.TextDark,
			TextXAlignment = Enum.TextXAlignment.Center,
			Position = UDim2.new(0, 0, 0, 4),
			Size = UDim2.new(1, 0, 0, 18),
			MaxTextSize = 14,
			MinTextSize = 10,
			ZIndex = 102,
		})

		-- Field Input Nama
		label({
			Parent = card,
			Font = Constants.Fonts.Semibold,
			Text = "CONTACT NAME",
			TextColor3 = COLORS.TextMuted,
			Position = UDim2.new(0, 0, 0, 24),
			Size = UDim2.new(1, 0, 0, 12),
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
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 0, 0, 38),
			Size = UDim2.new(1, 0, 0, 28),
			ZIndex = 102,
			Parent = card,
		})
		rounded(nameBox, 7)
		stroke(nameBox, COLORS.CardStroke, 1)
		padded(nameBox, 0.03, 0.03, 0, 0)

		-- Field Input Nomor HP
		label({
			Parent = card,
			Font = Constants.Fonts.Semibold,
			Text = "PHONE NUMBER",
			TextColor3 = COLORS.TextMuted,
			Position = UDim2.new(0, 0, 0, 70),
			Size = UDim2.new(1, 0, 0, 12),
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
			PlaceholderText = "e.g. 0812xxxx",
			Text = if isEdit then (existingContact.Phone or "") else (if (existingContact and existingContact.Phone) then existingContact.Phone else ""),
			TextColor3 = COLORS.TextDark,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 0, 0, 84),
			Size = UDim2.new(1, 0, 0, 28),
			ZIndex = 102,
			Parent = card,
		})
		rounded(phoneBox, 7)
		stroke(phoneBox, COLORS.CardStroke, 1)
		padded(phoneBox, 0.03, 0.03, 0, 0)

		-- Field Input Catatan
		label({
			Parent = card,
			Font = Constants.Fonts.Semibold,
			Text = "NOTE / RELATIONSHIP",
			TextColor3 = COLORS.TextMuted,
			Position = UDim2.new(0, 0, 0, 116),
			Size = UDim2.new(1, 0, 0, 12),
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
			PlaceholderText = "e.g. School Friend",
			Text = if isEdit then (existingContact.Note or "") else "",
			TextColor3 = COLORS.TextDark,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 0, 0, 130),
			Size = UDim2.new(1, 0, 0, 28),
			ZIndex = 102,
			Parent = card,
		})
		rounded(noteBox, 7)
		stroke(noteBox, COLORS.CardStroke, 1)
		padded(noteBox, 0.03, 0.03, 0, 0)

		-- Tombol "Pilih dari Player Terdekat"
		local pickPlayerBtn = create("TextButton", {
			Name = "PickPlayerBtn",
			AutoButtonColor = true,
			BackgroundColor3 = Color3.fromRGB(235, 245, 255),
			BorderSizePixel = 0,
			Font = Constants.Fonts.Semibold,
			Text = "👤 Autofill from Nearby Player",
			TextColor3 = COLORS.AccentBlue,
			TextSize = 10,
			Position = UDim2.new(0, 0, 0, 164),
			Size = UDim2.new(1, 0, 0, 26),
			ZIndex = 102,
			Parent = card,
		})
		rounded(pickPlayerBtn, 7)
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
						noteBox.Text = "Roblox Player (@" .. target.Name .. ")"
						selectedUserId = target.UserId
						context.SendNotification({
							Title = "👤 AutoFill Contact",
							Text = "Filled data from player " .. target.DisplayName,
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
			Text = "Cancel",
			TextColor3 = COLORS.TextDark,
			TextSize = 11,
			Position = UDim2.new(0, 0, 1, -34),
			Size = UDim2.new(0.48, 0, 0, 30),
			ZIndex = 102,
			Parent = card,
		})
		rounded(cancelBtn, 8)
		cancelBtn.Activated:Connect(function()
			modalOverlay.Visible = false
		end)

		local saveBtn = create("TextButton", {
			Name = "SaveBtn",
			AutoButtonColor = true,
			BackgroundColor3 = COLORS.AccentBlue,
			BorderSizePixel = 0,
			Font = Constants.Fonts.Semibold,
			Text = "Save",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 11,
			Position = UDim2.new(0.52, 0, 1, -34),
			Size = UDim2.new(0.48, 0, 0, 30),
			ZIndex = 102,
			Parent = card,
		})
		rounded(saveBtn, 10)

		saveBtn.Activated:Connect(function()
			local nameText = string.gsub(nameBox.Text, "^%s*(.-)%s*$", "%1")
			local phoneText = string.gsub(phoneBox.Text, "^%s*(.-)%s*$", "%1")
			local noteText = string.gsub(noteBox.Text, "^%s*(.-)%s*$", "%1")

			if nameText == "" then
				context.SendNotification({ Title = "⚠️ Warning", Text = "Contact name is required!", Duration = 3 })
				return
			end
			if phoneText == "" then
				context.SendNotification({ Title = "⚠️ Warning", Text = "Phone number is required!", Duration = 3 })
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
				})
			end

			saveService:Set("Contacts", state.Contacts)
			modalOverlay.Visible = false
			updateContactsList()
			context.SendNotification({
				Title = "✅ Contact Saved",
				Text = "Contact " .. nameText .. " successfully saved.",
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
			Text = "📡 Incoming AirDrop Contact",
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
			Text = data.senderName .. " wants to share contact '" .. (cData.Name or "Contact") .. "' (" .. (cData.Phone or "-") .. ").",
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
			Text = "Decline",
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
			Text = "Accept",
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
				Note = "Received via AirDrop from " .. data.senderName,
				UserId = cData.UserId or data.senderUserId,
			})
			saveService:Set("Contacts", state.Contacts)
			modalOverlay.Visible = false
			updateContactsList()
			context.SendNotification({
				Title = "✅ AirDrop Accepted",
				Text = "Contact " .. (cData.Name or data.senderName) .. " saved to your Contacts!",
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

	-- Real-time player online/offline status listener
	local playerJoinedConn = Players.PlayerAdded:Connect(function()
		if rootFrame.Visible then updateContactsList() end
	end)
	local playerLeftConn = Players.PlayerRemoving:Connect(function()
		if rootFrame.Visible then updateContactsList() end
	end)

	rootFrame.Destroying:Connect(function()
		if remoteConnection then remoteConnection:Disconnect() end
		if radarLoopConnection then radarLoopConnection:Disconnect() end
		if saveConnection then saveConnection:Disconnect() end
		if playerJoinedConn then playerJoinedConn:Disconnect() end
		if playerLeftConn then playerLeftConn:Disconnect() end
	end)

	-- Initial Render
	updateContactsList()

	-- Cek jika ada prefill nomor HP dari app Phone (tombol + Tambah ke Kontak)
	local prefillPhone = saveService:Get("_PrefillPhone", nil)
	if prefillPhone and prefillPhone ~= "" then
		saveService:Set("_PrefillPhone", nil)
		task.defer(function()
			openAddEditModal({ Phone = prefillPhone })
		end)
	end

	return rootFrame
end

return ContactsApp
