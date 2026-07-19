local TweenService = game:GetService("TweenService")
local RunService  = game:GetService("RunService")

local root = script.Parent.Parent
local Constants = require(root:WaitForChild("Shared"):WaitForChild("Constants"))
local StatusBar  = require(root:WaitForChild("Shared"):WaitForChild("Components"):WaitForChild("StatusBar"))
local create     = require(root:WaitForChild("Shared"):WaitForChild("Utilities"):WaitForChild("Create"))

-- ──────────────────────────────────────────────────────────────────────────
--  SONG CATALOG  (SoundId pakai rbxasset Roblox audio publik)
-- ──────────────────────────────────────────────────────────────────────────
local SONGS = {
	{ Id = 1,  Title = "Blinding Lights",     Artist = "The Weeknd",          Album = "After Hours",         Duration = 200, SoundId = "rbxassetid://1837720822", Cover = "rbxassetid://4483361816" },
	{ Id = 2,  Title = "Shape of You",        Artist = "Ed Sheeran",          Album = "÷ (Divide)",          Duration = 234, SoundId = "rbxassetid://1843042867", Cover = "rbxassetid://4483361816" },
	{ Id = 3,  Title = "Levitating",          Artist = "Dua Lipa",            Album = "Future Nostalgia",    Duration = 203, SoundId = "rbxassetid://1843044785", Cover = "rbxassetid://4483361816" },
	{ Id = 4,  Title = "Stay",                Artist = "The Kid LAROI & Bieber", Album = "F*CK LOVE 3",     Duration = 141, SoundId = "rbxassetid://1843045600", Cover = "rbxassetid://4483361816" },
	{ Id = 5,  Title = "Heat Waves",          Artist = "Glass Animals",       Album = "Dreamland",           Duration = 238, SoundId = "rbxassetid://1843045800", Cover = "rbxassetid://4483361816" },
	{ Id = 6,  Title = "Peaches",             Artist = "Justin Bieber",       Album = "Justice",             Duration = 198, SoundId = "rbxassetid://1843046100", Cover = "rbxassetid://4483361816" },
	{ Id = 7,  Title = "Watermelon Sugar",    Artist = "Harry Styles",        Album = "Fine Line",           Duration = 174, SoundId = "rbxassetid://1843046400", Cover = "rbxassetid://4483361816" },
	{ Id = 8,  Title = "Good 4 U",            Artist = "Olivia Rodrigo",      Album = "SOUR",                Duration = 178, SoundId = "rbxassetid://1843046700", Cover = "rbxassetid://4483361816" },
	{ Id = 9,  Title = "drivers license",     Artist = "Olivia Rodrigo",      Album = "SOUR",                Duration = 242, SoundId = "rbxassetid://1843047000", Cover = "rbxassetid://4483361816" },
	{ Id = 10, Title = "Industry Baby",       Artist = "Lil Nas X",           Album = "Montero",             Duration = 212, SoundId = "rbxassetid://1843047300", Cover = "rbxassetid://4483361816" },
	{ Id = 11, Title = "Butter",              Artist = "BTS",                 Album = "Butter",              Duration = 164, SoundId = "rbxassetid://1843047600", Cover = "rbxassetid://4483361816" },
	{ Id = 12, Title = "As It Was",           Artist = "Harry Styles",        Album = "Harry's House",       Duration = 167, SoundId = "rbxassetid://1843047900", Cover = "rbxassetid://4483361816" },
	{ Id = 13, Title = "Anti-Hero",           Artist = "Taylor Swift",        Album = "Midnights",           Duration = 200, SoundId = "rbxassetid://1843048200", Cover = "rbxassetid://4483361816" },
	{ Id = 14, Title = "Flowers",             Artist = "Miley Cyrus",         Album = "Endless Summer Vacation", Duration = 200, SoundId = "rbxassetid://1843048500", Cover = "rbxassetid://4483361816" },
	{ Id = 15, Title = "Unholy",              Artist = "Sam Smith & Kim Petras", Album = "Gloria",           Duration = 156, SoundId = "rbxassetid://1843048800", Cover = "rbxassetid://4483361816" },
}

-- Warna-warna album art placeholder (bergantian supaya berwarna-warni)
local ALBUM_COLORS = {
	Color3.fromRGB(255, 59, 48),
	Color3.fromRGB(255, 149, 0),
	Color3.fromRGB(52, 199, 89),
	Color3.fromRGB(0, 122, 255),
	Color3.fromRGB(175, 82, 222),
	Color3.fromRGB(255, 45, 85),
	Color3.fromRGB(90, 200, 250),
	Color3.fromRGB(255, 204, 0),
}

local MusicApp = {
	Id    = "music",
	Name  = "Music",
	Icon  = {
		Background = Color3.fromRGB(252, 45, 90),
		Image      = "rbxassetid://75672729282743",
	},
	Order = 130,
}

-- ──────────────────────────────────────────────────────────────────────────
function MusicApp.Create(context: any)
	-- ── State ──────────────────────────────────────────────────────────
	local currentSong      = nil   -- song table yang sedang diputar
	local isPlaying        = false
	local isShuffle        = false
	local repeatMode       = 0     -- 0=off 1=all 2=one
	local playbackPos      = 0     -- detik saat ini (simulasi)
	local activeConnections = {}
	local currentTabId     = "library"  -- "library" | "search" | "now"
	local sound            = nil   -- Instance Sound aktif

	-- Daftar song yang sedang ditampilkan di library/search
	local displayedSongs   = SONGS

	-- ── Root ───────────────────────────────────────────────────────────
	local appRoot = create("Frame", {
		Name = "MusicApp",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel  = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
	})
	StatusBar.new(appRoot, { Light = false, Battery = "100%" })

	-- ── Gradient Background ────────────────────────────────────────────
	local bgFrame = create("Frame", {
		Name = "Background",
		BackgroundColor3 = Color3.fromRGB(28, 28, 30),
		BorderSizePixel  = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
		Parent = appRoot,
	})
	local bgGradient = Instance.new("UIGradient")
	bgGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,   Color3.fromRGB(18, 18, 20)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(28, 28, 32)),
		ColorSequenceKeypoint.new(1,   Color3.fromRGB(12, 12, 16)),
	})
	bgGradient.Rotation = 135
	bgGradient.Parent = bgFrame

	-- ── Tab Bar (bawah) ────────────────────────────────────────────────
	local tabBar = create("Frame", {
		Name = "TabBar",
		BackgroundColor3 = Color3.fromRGB(20, 20, 22),
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, 0.12),
		ZIndex = 60,
		Parent = appRoot,
	})
	create("Frame", {
		Name = "Separator",
		BackgroundColor3 = Color3.fromRGB(60, 60, 65),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 61,
		Parent = tabBar,
	})

	local TAB_DEFS = {
		{ id = "library", label = "Library",   emoji = "♫" },
		{ id = "search",  label = "Search",    emoji = "⌕" },
		{ id = "now",     label = "Now Playing",emoji = "▶" },
	}
	local tabButtons = {}

	for i, tDef in ipairs(TAB_DEFS) do
		local tabW = 1 / #TAB_DEFS
		local tabBtn = create("TextButton", {
			Name = tDef.id .. "Tab",
			BackgroundTransparency = 1,
			Font = Constants.Fonts.Regular,
			Text = tDef.emoji .. "\n" .. tDef.label,
			TextColor3 = Color3.fromRGB(130, 130, 140),
			TextScaled = false,
			TextSize = 8,
			Position = UDim2.fromScale((i - 1) * tabW, 0.08),
			Size = UDim2.fromScale(tabW, 0.9),
			ZIndex = 62,
			Parent = tabBar,
		})
		tabButtons[tDef.id] = tabBtn
	end

	-- ══════════════════════════════════════════════════════════════════
	--  PANELS (Library, Search, Now Playing)
	-- ══════════════════════════════════════════════════════════════════

	-- Semua panel di dalam contentArea supaya tidak overlap dengan tabBar
	local contentArea = create("Frame", {
		Name = "ContentArea",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, Constants.Screen.StatusBarHeight),
		Size = UDim2.new(1, 0, 0.88 - Constants.Screen.StatusBarHeight, 0),
		ZIndex = 51,
		Parent = appRoot,
	})

	-- ─── MINI PLAYER (strip tipis di atas tab bar, tersedia di semua tab) ───
	local miniPlayer = create("Frame", {
		Name = "MiniPlayer",
		BackgroundColor3 = Color3.fromRGB(40, 40, 44),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 0.88),
		Size = UDim2.new(1, 0, 0.1, 0),
		ZIndex = 58,
		Visible = false,
		Parent = appRoot,
	})
	create("Frame", {
		Name = "MiniSeparator",
		BackgroundColor3 = Color3.fromRGB(80, 80, 88),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 59,
		Parent = miniPlayer,
	})
	-- Progress bar tipis di atas mini player
	local miniProgressBg = create("Frame", {
		Name = "MiniProgressBg",
		BackgroundColor3 = Color3.fromRGB(70, 70, 78),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 2),
		ZIndex = 59,
		Parent = miniPlayer,
	})
	local miniProgressBar = create("Frame", {
		Name = "MiniProgressBar",
		BackgroundColor3 = Color3.fromRGB(252, 60, 92),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
		ZIndex = 60,
		Parent = miniProgressBg,
	})
	local miniSongTitle = create("TextLabel", {
		Name = "MiniTitle",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Semibold,
		Text = "Not Playing",
		TextColor3 = Color3.fromRGB(245, 245, 250),
		TextScaled = false,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromScale(0.04, 0.18),
		Size = UDim2.fromScale(0.6, 0.38),
		ZIndex = 59,
		Parent = miniPlayer,
	})
	local miniArtistLabel = create("TextLabel", {
		Name = "MiniArtist",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "",
		TextColor3 = Color3.fromRGB(160, 160, 175),
		TextScaled = false,
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromScale(0.04, 0.58),
		Size = UDim2.fromScale(0.6, 0.3),
		ZIndex = 59,
		Parent = miniPlayer,
	})
	local miniPlayBtn = create("TextButton", {
		Name = "MiniPlayButton",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "▶",
		TextColor3 = Color3.fromRGB(245, 245, 250),
		TextScaled = true,
		Position = UDim2.fromScale(0.72, 0.12),
		Size = UDim2.fromScale(0.12, 0.76),
		ZIndex = 59,
		Parent = miniPlayer,
	})
	local miniNextBtn = create("TextButton", {
		Name = "MiniNextButton",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "⏭",
		TextColor3 = Color3.fromRGB(245, 245, 250),
		TextScaled = true,
		Position = UDim2.fromScale(0.86, 0.12),
		Size = UDim2.fromScale(0.12, 0.76),
		ZIndex = 59,
		Parent = miniPlayer,
	})

	-- ─── LIBRARY PANEL ───────────────────────────────────────────────
	local libraryPanel = create("Frame", {
		Name = "LibraryPanel",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 52,
		Parent = contentArea,
	})

	-- Nav bar Library
	local libNav = create("Frame", {
		Name = "LibNav",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 38),
		ZIndex = 54,
		Parent = libraryPanel,
	})
	create("TextLabel", {
		Name = "LibTitle",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Semibold,
		Text = "Library",
		TextColor3 = Color3.fromRGB(252, 252, 255),
		TextScaled = false,
		TextSize = 16,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.55),
		Size = UDim2.fromScale(0.7, 0.6),
		ZIndex = 55,
		Parent = libNav,
	})
	local libBackBtn = create("TextButton", {
		Name = "LibBackBtn",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "く",
		TextColor3 = Color3.fromRGB(252, 60, 92),
		TextScaled = true,
		Position = UDim2.fromScale(0.02, 0.15),
		Size = UDim2.fromScale(0.1, 0.7),
		ZIndex = 55,
		Parent = libNav,
	})
	libBackBtn.Activated:Connect(context.CloseCurrentApp)

	-- Scrolling list lagu
	local libScroll = create("ScrollingFrame", {
		Name = "LibScroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 40),
		Size = UDim2.new(1, 0, 1, -40),
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Color3.fromRGB(252, 60, 92),
		CanvasSize = UDim2.fromScale(0, 0),
		ZIndex = 53,
		Parent = libraryPanel,
	})
	local libList = create("UIListLayout", {
		Padding = UDim.new(0, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = libScroll,
	})
	libList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		libScroll.CanvasSize = UDim2.new(0, 0, 0, libList.AbsoluteContentSize.Y)
	end)

	-- ─── SEARCH PANEL ────────────────────────────────────────────────
	local searchPanel = create("Frame", {
		Name = "SearchPanel",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 52,
		Visible = false,
		Parent = contentArea,
	})

	-- Nav Search
	local searchNav = create("Frame", {
		Name = "SearchNav",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 38),
		ZIndex = 54,
		Parent = searchPanel,
	})
	create("TextLabel", {
		Name = "SearchTitle",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Semibold,
		Text = "Search",
		TextColor3 = Color3.fromRGB(252, 252, 255),
		TextScaled = false,
		TextSize = 16,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.55),
		Size = UDim2.fromScale(0.7, 0.6),
		ZIndex = 55,
		Parent = searchNav,
	})

	-- Search Box
	local searchBoxBg = create("Frame", {
		Name = "SearchBoxBg",
		BackgroundColor3 = Color3.fromRGB(50, 50, 56),
		BorderSizePixel = 0,
		Position = UDim2.new(0.04, 0, 0, 42),
		Size = UDim2.new(0.92, 0, 0, 26),
		ZIndex = 54,
		Parent = searchPanel,
	})
	create("UICorner", { CornerRadius = UDim.new(0.4, 0), Parent = searchBoxBg })
	create("TextLabel", {
		Name = "SearchIcon",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "⌕",
		TextColor3 = Color3.fromRGB(150, 150, 165),
		TextScaled = true,
		Position = UDim2.fromScale(0.02, 0.05),
		Size = UDim2.fromScale(0.1, 0.9),
		ZIndex = 55,
		Parent = searchBoxBg,
	})
	local searchInput = create("TextBox", {
		Name = "SearchInput",
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		Font = Constants.Fonts.Regular,
		PlaceholderText = "Songs, Artists, Albums...",
		PlaceholderColor3 = Color3.fromRGB(120, 120, 135),
		Text = "",
		TextColor3 = Color3.fromRGB(245, 245, 250),
		TextScaled = false,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.12, 0.05),
		Size = UDim2.fromScale(0.85, 0.9),
		ZIndex = 55,
		Parent = searchBoxBg,
	})

	-- Scroll Hasil Search
	local searchScroll = create("ScrollingFrame", {
		Name = "SearchScroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 74),
		Size = UDim2.new(1, 0, 1, -74),
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Color3.fromRGB(252, 60, 92),
		CanvasSize = UDim2.fromScale(0, 0),
		ZIndex = 53,
		Parent = searchPanel,
	})
	local searchList = create("UIListLayout", {
		Padding = UDim.new(0, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = searchScroll,
	})
	searchList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		searchScroll.CanvasSize = UDim2.new(0, 0, 0, searchList.AbsoluteContentSize.Y)
	end)

	-- ─── NOW PLAYING PANEL ───────────────────────────────────────────
	local nowPanel = create("Frame", {
		Name = "NowPlayingPanel",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 52,
		Visible = false,
		Parent = contentArea,
	})

	-- Artwork (besar, tengah)
	local artworkFrame = create("Frame", {
		Name = "ArtworkFrame",
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(252, 60, 92),
		Position = UDim2.fromScale(0.5, 0.04),
		Size = UDim2.fromScale(0.7, 0),
		ZIndex = 54,
		Parent = nowPanel,
	})
	create("UIAspectRatioConstraint", { AspectRatio = 1, Parent = artworkFrame })
	create("UICorner", { CornerRadius = UDim.new(0.06, 0), Parent = artworkFrame })
	-- Note icon di tengah artwork
	create("TextLabel", {
		Name = "NoteIcon",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "♫",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextTransparency = 0.3,
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.55, 0.55),
		ZIndex = 55,
		Parent = artworkFrame,
	})

	-- Shadow bawah artwork
	local artShadow = create("Frame", {
		Name = "ArtShadow",
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.6,
		Position = UDim2.fromScale(0.5, 0.04),
		Size = UDim2.fromScale(0.72, 0.005),
		ZIndex = 53,
		Parent = nowPanel,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = artShadow })

	-- Info lagu
	local songTitle = create("TextLabel", {
		Name = "SongTitle",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Semibold,
		Text = "Not Playing",
		TextColor3 = Color3.fromRGB(252, 252, 255),
		TextScaled = false,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromScale(0.06, 0.57),
		Size = UDim2.fromScale(0.72, 0.055),
		ZIndex = 54,
		Parent = nowPanel,
	})
	local artistLabel = create("TextLabel", {
		Name = "ArtistLabel",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "",
		TextColor3 = Color3.fromRGB(252, 60, 92),
		TextScaled = false,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromScale(0.06, 0.635),
		Size = UDim2.fromScale(0.75, 0.04),
		ZIndex = 54,
		Parent = nowPanel,
	})

	-- Love button (jantung)
	local loveBtn = create("TextButton", {
		Name = "LoveButton",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "♡",
		TextColor3 = Color3.fromRGB(180, 180, 192),
		TextScaled = true,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.96, 0.57),
		Size = UDim2.fromScale(0.1, 0.07),
		ZIndex = 54,
		Parent = nowPanel,
	})
	local isFavorited = false

	-- Progress Bar
	local progressBg = create("Frame", {
		Name = "ProgressBg",
		BackgroundColor3 = Color3.fromRGB(70, 70, 80),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.06, 0.695),
		Size = UDim2.fromScale(0.88, 0.012),
		ZIndex = 54,
		Parent = nowPanel,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = progressBg })
	local progressFill = create("Frame", {
		Name = "ProgressFill",
		BackgroundColor3 = Color3.fromRGB(252, 60, 92),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
		ZIndex = 55,
		Parent = progressBg,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = progressFill })
	-- Thumb bulat di ujung progress
	local progressThumb = create("Frame", {
		Name = "ProgressThumb",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(252, 60, 92),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(8, 8),
		ZIndex = 56,
		Parent = progressBg,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = progressThumb })

	-- Waktu
	local timeLeft = create("TextLabel", {
		Name = "TimeLeft",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "0:00",
		TextColor3 = Color3.fromRGB(160, 160, 175),
		TextScaled = false,
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.06, 0.715),
		Size = UDim2.fromScale(0.2, 0.03),
		ZIndex = 54,
		Parent = nowPanel,
	})
	local timeRight = create("TextLabel", {
		Name = "TimeRight",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "-0:00",
		TextColor3 = Color3.fromRGB(160, 160, 175),
		TextScaled = false,
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.94, 0.715),
		Size = UDim2.fromScale(0.2, 0.03),
		ZIndex = 54,
		Parent = nowPanel,
	})

	-- Kontrol Playback
	local controlRow = create("Frame", {
		Name = "Controls",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.04, 0.76),
		Size = UDim2.fromScale(0.92, 0.1),
		ZIndex = 54,
		Parent = nowPanel,
	})

	local shuffleBtn = create("TextButton", {
		Name = "ShuffleBtn",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "⇄",
		TextColor3 = Color3.fromRGB(120, 120, 135),
		TextScaled = true,
		Position = UDim2.fromScale(0, 0.1),
		Size = UDim2.fromScale(0.14, 0.8),
		ZIndex = 55,
		Parent = controlRow,
	})
	local prevBtn = create("TextButton", {
		Name = "PrevBtn",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "⏮",
		TextColor3 = Color3.fromRGB(245, 245, 250),
		TextScaled = true,
		Position = UDim2.fromScale(0.19, 0.05),
		Size = UDim2.fromScale(0.18, 0.9),
		ZIndex = 55,
		Parent = controlRow,
	})
	local playPauseBtn = create("TextButton", {
		Name = "PlayPauseBtn",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "▶",
		TextColor3 = Color3.fromRGB(245, 245, 250),
		TextScaled = true,
		Position = UDim2.fromScale(0.4, 0),
		Size = UDim2.fromScale(0.2, 1),
		ZIndex = 55,
		Parent = controlRow,
	})
	local nextBtn = create("TextButton", {
		Name = "NextBtn",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "⏭",
		TextColor3 = Color3.fromRGB(245, 245, 250),
		TextScaled = true,
		Position = UDim2.fromScale(0.64, 0.05),
		Size = UDim2.fromScale(0.18, 0.9),
		ZIndex = 55,
		Parent = controlRow,
	})
	local repeatBtn = create("TextButton", {
		Name = "RepeatBtn",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "↻",
		TextColor3 = Color3.fromRGB(120, 120, 135),
		TextScaled = true,
		Position = UDim2.fromScale(0.86, 0.1),
		Size = UDim2.fromScale(0.14, 0.8),
		ZIndex = 55,
		Parent = controlRow,
	})

	-- Volume Slider
	local volRow = create("Frame", {
		Name = "VolumeRow",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.06, 0.875),
		Size = UDim2.fromScale(0.88, 0.04),
		ZIndex = 54,
		Parent = nowPanel,
	})
	create("TextLabel", {
		Name = "VolIconL",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "🔈",
		TextColor3 = Color3.fromRGB(140, 140, 155),
		TextScaled = true,
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(0.07, 1),
		ZIndex = 55,
		Parent = volRow,
	})
	local volTrack = create("Frame", {
		Name = "VolumeTrack",
		BackgroundColor3 = Color3.fromRGB(70, 70, 80),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.09, 0.5),
		Size = UDim2.fromScale(0.82, 0.3),
		ZIndex = 55,
		Parent = volRow,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = volTrack })
	local volFill = create("Frame", {
		Name = "VolumeFill",
		BackgroundColor3 = Color3.fromRGB(200, 200, 215),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0.7, 1),
		ZIndex = 56,
		Parent = volTrack,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = volFill })
	create("TextLabel", {
		Name = "VolIconR",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "🔊",
		TextColor3 = Color3.fromRGB(140, 140, 155),
		TextScaled = true,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(0.07, 1),
		ZIndex = 55,
		Parent = volRow,
	})

	-- ══════════════════════════════════════════════════════════════════
	--  HELPER FUNCTIONS
	-- ══════════════════════════════════════════════════════════════════

	local function formatTime(seconds: number): string
		seconds = math.floor(seconds)
		local m = math.floor(seconds / 60)
		local s = seconds % 60
		return string.format("%d:%02d", m, s)
	end

	local function getAlbumColor(song)
		local idx = (song.Id % #ALBUM_COLORS) + 1
		return ALBUM_COLORS[idx]
	end

	local function updateNowPlayingUI()
		if not currentSong then
			songTitle.Text  = "Not Playing"
			artistLabel.Text = ""
			miniSongTitle.Text   = "Not Playing"
			miniArtistLabel.Text = ""
			miniPlayer.Visible   = false
			return
		end

		local col = getAlbumColor(currentSong)
		artworkFrame.BackgroundColor3 = col

		songTitle.Text   = currentSong.Title
		artistLabel.Text = currentSong.Artist

		miniPlayer.Visible    = true
		miniSongTitle.Text    = currentSong.Title
		miniArtistLabel.Text  = currentSong.Artist

		-- Play/Pause icons
		if isPlaying then
			playPauseBtn.Text = "⏸"
			miniPlayBtn.Text  = "⏸"
		else
			playPauseBtn.Text = "▶"
			miniPlayBtn.Text  = "▶"
		end

		-- Progress
		local dur = currentSong.Duration or 1
		local pct = math.clamp(playbackPos / dur, 0, 1)
		progressFill.Size = UDim2.fromScale(pct, 1)
		progressThumb.Position = UDim2.fromScale(pct, 0.5)
		miniProgressBar.Size = UDim2.fromScale(pct, 1)

		timeLeft.Text  = formatTime(playbackPos)
		timeRight.Text = "-" .. formatTime(dur - playbackPos)
	end

	local function playSong(song)
		-- Stop previous sound
		if sound then
			sound:Stop()
			sound:Destroy()
			sound = nil
		end

		currentSong = song
		playbackPos = 0
		isPlaying   = true

		-- Buat Sound baru
		sound = Instance.new("Sound")
		sound.SoundId = song.SoundId
		sound.Volume  = 0.5
		sound.Looped  = (repeatMode == 2)
		sound.Parent  = appRoot

		-- Coba play (mungkin audio tidak tersedia di beberapa aset, graceful)
		local ok = pcall(function() sound:Play() end)

		-- Artwork bounce animation
		TweenService:Create(artworkFrame, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(0.72, 0),
		}):Play()
		task.delay(0.15, function()
			TweenService:Create(artworkFrame, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = UDim2.fromScale(0.7, 0),
			}):Play()
		end)

		updateNowPlayingUI()
	end

	local function stopPlayback()
		isPlaying = false
		if sound then
			sound:Pause()
		end
		updateNowPlayingUI()
	end

	local function resumePlayback()
		isPlaying = true
		if sound then
			pcall(function() sound:Resume() end)
		end
		updateNowPlayingUI()
	end

	local function getSongIndex(song)
		for i, s in ipairs(SONGS) do
			if s.Id == song.Id then return i end
		end
		return 1
	end

	local function playNext()
		if not currentSong then
			playSong(SONGS[1])
			return
		end
		local idx = getSongIndex(currentSong)
		if isShuffle then
			idx = math.random(1, #SONGS)
		else
			idx = (idx % #SONGS) + 1
		end
		playSong(SONGS[idx])
	end

	local function playPrev()
		if not currentSong then
			playSong(SONGS[1])
			return
		end
		if playbackPos > 4 then
			playbackPos = 0
			if sound then sound.TimePosition = 0 end
			updateNowPlayingUI()
			return
		end
		local idx = getSongIndex(currentSong)
		idx = idx - 1
		if idx < 1 then idx = #SONGS end
		playSong(SONGS[idx])
	end

	-- ── Update progress setiap frame ───────────────────────────────────
	local lastTick = os.clock()
	local conn = RunService.Heartbeat:Connect(function()
		if not isPlaying or not currentSong then return end
		local now = os.clock()
		local dt  = now - lastTick
		lastTick  = now

		-- Sync dengan sound jika ada, kalau tidak simulate
		if sound and sound.IsPlaying then
			playbackPos = sound.TimePosition
		else
			playbackPos = playbackPos + dt
		end

		local dur = currentSong.Duration or 200
		if playbackPos >= dur then
			if repeatMode == 2 then
				playbackPos = 0
				if sound then sound.TimePosition = 0 end
			elseif repeatMode == 1 then
				playNext()
			else
				playNext()
			end
		end

		updateNowPlayingUI()
	end)
	table.insert(activeConnections, conn)

	-- ── Build song row UI ─────────────────────────────────────────────
	local function createSongRow(song, parent, layoutOrder)
		local row = create("Frame", {
			Name = "SongRow_" .. song.Id,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 46),
			LayoutOrder = layoutOrder,
			ZIndex = 53,
			Parent = parent,
		})

		-- Album color swatch
		local swatch = create("Frame", {
			Name = "Swatch",
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = getAlbumColor(song),
			Position = UDim2.fromScale(0.04, 0.5),
			Size = UDim2.fromOffset(32, 32),
			ZIndex = 54,
			Parent = row,
		})
		create("UICorner", { CornerRadius = UDim.new(0.15, 0), Parent = swatch })
		create("TextLabel", {
			Name = "SwatchNote",
			BackgroundTransparency = 1,
			Font = Constants.Fonts.Regular,
			Text = "♫",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextTransparency = 0.3,
			TextScaled = true,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.65, 0.65),
			ZIndex = 55,
			Parent = swatch,
		})

		-- Song info
		create("TextLabel", {
			Name = "Title",
			BackgroundTransparency = 1,
			Font = Constants.Fonts.Semibold,
			Text = song.Title,
			TextColor3 = Color3.fromRGB(245, 245, 250),
			TextScaled = false,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.fromScale(0.22, 0.12),
			Size = UDim2.fromScale(0.62, 0.38),
			ZIndex = 54,
			Parent = row,
		})
		create("TextLabel", {
			Name = "Artist",
			BackgroundTransparency = 1,
			Font = Constants.Fonts.Regular,
			Text = song.Artist,
			TextColor3 = Color3.fromRGB(140, 140, 155),
			TextScaled = false,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.fromScale(0.22, 0.52),
			Size = UDim2.fromScale(0.62, 0.32),
			ZIndex = 54,
			Parent = row,
		})

		-- Duration
		create("TextLabel", {
			Name = "Duration",
			BackgroundTransparency = 1,
			Font = Constants.Fonts.Regular,
			Text = formatTime(song.Duration),
			TextColor3 = Color3.fromRGB(110, 110, 125),
			TextScaled = false,
			TextSize = 9,
			TextXAlignment = Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(0.96, 0.5),
			Size = UDim2.fromScale(0.14, 0.3),
			ZIndex = 54,
			Parent = row,
		})

		-- Separator
		create("Frame", {
			Name = "Sep",
			BackgroundColor3 = Color3.fromRGB(55, 55, 62),
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0.04, 0, 1, 0),
			Size = UDim2.new(0.92, 0, 0, 1),
			ZIndex = 53,
			Parent = row,
		})

		-- Hit area
		local hitBtn = create("TextButton", {
			Name = "HitBtn",
			BackgroundTransparency = 1,
			Text = "",
			Size = UDim2.fromScale(1, 1),
			ZIndex = 56,
			Parent = row,
		})
		hitBtn.Activated:Connect(function()
			-- Highlight flash
			TweenService:Create(row, TweenInfo.new(0.08), {
				BackgroundTransparency = 0.85,
				BackgroundColor3 = Color3.fromRGB(252, 60, 92)
			}):Play()
			task.delay(0.12, function()
				TweenService:Create(row, TweenInfo.new(0.15), {
					BackgroundTransparency = 1,
				}):Play()
			end)

			playSong(song)
			-- Pindah ke Now Playing tab
			currentTabId = "now"
			for _, p in ipairs({libraryPanel, searchPanel, nowPanel}) do
				p.Visible = false
			end
			nowPanel.Visible = true
			for id, btn in pairs(tabButtons) do
				btn.TextColor3 = (id == "now") and Color3.fromRGB(252, 60, 92) or Color3.fromRGB(130, 130, 140)
			end
		end)

		return row
	end

	-- ── Populate Library ──────────────────────────────────────────────
	local function populateLibrary()
		for _, child in ipairs(libScroll:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		-- Header "Songs" section
		local header = create("Frame", {
			Name = "LibHeader",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 28),
			LayoutOrder = 0,
			ZIndex = 53,
			Parent = libScroll,
		})
		create("TextLabel", {
			Name = "HeaderLabel",
			BackgroundTransparency = 1,
			Font = Constants.Fonts.Semibold,
			Text = "Songs",
			TextColor3 = Color3.fromRGB(252, 252, 255),
			TextScaled = false,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.fromScale(0.04, 0.2),
			Size = UDim2.fromScale(0.5, 0.7),
			ZIndex = 54,
			Parent = header,
		})

		for i, song in ipairs(SONGS) do
			createSongRow(song, libScroll, i)
		end
	end

	-- ── Populate Search ───────────────────────────────────────────────
	local function populateSearch(query: string)
		for _, child in ipairs(searchScroll:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		local q = query:lower():gsub("^%s+", ""):gsub("%s+$", "")

		if q == "" then
			-- Tampilkan semua
			for i, song in ipairs(SONGS) do
				createSongRow(song, searchScroll, i)
			end
			return
		end

		local results = {}
		for _, song in ipairs(SONGS) do
			if song.Title:lower():find(q, 1, true)
			or song.Artist:lower():find(q, 1, true)
			or song.Album:lower():find(q, 1, true) then
				table.insert(results, song)
			end
		end

		if #results == 0 then
			-- Empty state
			local empty = create("Frame", {
				Name = "EmptyState",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 80),
				LayoutOrder = 1,
				ZIndex = 53,
				Parent = searchScroll,
			})
			create("TextLabel", {
				Name = "EmptyText",
				BackgroundTransparency = 1,
				Font = Constants.Fonts.Regular,
				Text = "No results for \"" .. query .. "\"",
				TextColor3 = Color3.fromRGB(120, 120, 135),
				TextScaled = false,
				TextSize = 11,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.85, 0.5),
				ZIndex = 54,
				Parent = empty,
			})
		else
			for i, song in ipairs(results) do
				createSongRow(song, searchScroll, i)
			end
		end
	end

	-- ── Tab switching ─────────────────────────────────────────────────
	local function switchTab(tabId: string)
		currentTabId = tabId
		libraryPanel.Visible = (tabId == "library")
		searchPanel.Visible  = (tabId == "search")
		nowPanel.Visible     = (tabId == "now")

		for id, btn in pairs(tabButtons) do
			btn.TextColor3 = (id == tabId)
				and Color3.fromRGB(252, 60, 92)
				or Color3.fromRGB(130, 130, 140)
		end

		if tabId == "search" then
			populateSearch(searchInput.Text)
		end
	end

	-- Hubungkan tombol tab
	for _, tDef in ipairs(TAB_DEFS) do
		tabButtons[tDef.id].Activated:Connect(function()
			switchTab(tDef.id)
		end)
	end

	-- Mini player → buka Now Playing
	miniPlayer.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			switchTab("now")
		end
	end)

	-- ── Controls ──────────────────────────────────────────────────────
	playPauseBtn.Activated:Connect(function()
		if isPlaying then stopPlayback() else resumePlayback() end
		lastTick = os.clock()
	end)
	miniPlayBtn.Activated:Connect(function()
		if isPlaying then stopPlayback() else resumePlayback() end
		lastTick = os.clock()
	end)
	nextBtn.Activated:Connect(function() playNext() end)
	prevBtn.Activated:Connect(function() playPrev() end)
	miniNextBtn.Activated:Connect(function() playNext() end)

	shuffleBtn.Activated:Connect(function()
		isShuffle = not isShuffle
		shuffleBtn.TextColor3 = isShuffle
			and Color3.fromRGB(252, 60, 92)
			or Color3.fromRGB(120, 120, 135)
	end)

	repeatBtn.Activated:Connect(function()
		repeatMode = (repeatMode + 1) % 3
		if repeatMode == 0 then
			repeatBtn.TextColor3 = Color3.fromRGB(120, 120, 135)
			repeatBtn.Text = "↻"
		elseif repeatMode == 1 then
			repeatBtn.TextColor3 = Color3.fromRGB(252, 60, 92)
			repeatBtn.Text = "↻"
		else
			repeatBtn.TextColor3 = Color3.fromRGB(252, 60, 92)
			repeatBtn.Text = "①"
		end
		if sound then sound.Looped = (repeatMode == 2) end
	end)

	loveBtn.Activated:Connect(function()
		isFavorited = not isFavorited
		loveBtn.Text = isFavorited and "♥" or "♡"
		loveBtn.TextColor3 = isFavorited
			and Color3.fromRGB(252, 60, 92)
			or Color3.fromRGB(180, 180, 192)
		-- Bounce
		TweenService:Create(loveBtn, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextSize = 20
		}):Play()
		task.delay(0.15, function()
			TweenService:Create(loveBtn, TweenInfo.new(0.1), { TextSize = 16 }):Play()
		end)
	end)

	-- Search real-time
	searchInput:GetPropertyChangedSignal("Text"):Connect(function()
		populateSearch(searchInput.Text)
	end)

	-- ── Initial state ─────────────────────────────────────────────────
	populateLibrary()
	switchTab("library")
	updateNowPlayingUI()

	-- ── Cleanup saat app di-destroy ────────────────────────────────────
	appRoot.Destroying:Connect(function()
		for _, c in ipairs(activeConnections) do c:Disconnect() end
		if sound then sound:Destroy() end
	end)

	return appRoot
end

return MusicApp
