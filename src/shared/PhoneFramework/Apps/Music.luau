local TweenService = game:GetService("TweenService")
local RunService  = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local root = script.Parent.Parent
local Constants = require(root:WaitForChild("Shared"):WaitForChild("Constants"))
local StatusBar  = require(root:WaitForChild("Shared"):WaitForChild("Components"):WaitForChild("StatusBar"))
local create     = require(root:WaitForChild("Shared"):WaitForChild("Utilities"):WaitForChild("Create"))
local MusicState = require(root:WaitForChild("Services"):WaitForChild("MusicState"))

-- RemoteEvent untuk komunikasi client → server (zona suara 3D)
local remote = ReplicatedStorage:WaitForChild(Constants.RemoteName, 10)

-- ──────────────────────────────────────────────────────────────────────────
--  SONG CATALOG  (SoundId pakai rbxasset Roblox audio publik)
-- ──────────────────────────────────────────────────────────────────────────
local SONGS = {
	{ Id = 1, Title = "Seandainya",          Artist = "Vierra", Album = "My First Love", SoundId = "rbxassetid://122627153664904", Cover = "rbxassetid://94969502719436" },
	{ Id = 2,  Title = "Terlalu Lama",        Artist = "Vierra",          Album = "My First Love", SoundId = "rbxassetid://78065315164870", Cover = "rbxassetid://94969502719436" },
	{ Id = 3,  Title = "Payphone",          Artist = "Maroon 5",            Album = "Overexposed", SoundId = "rbxassetid://73178465382668", Cover = "rbxassetid://90546379856263" },
	{ Id = 4,  Title = "Baby",                Artist = "Justin Bieber", Album = "My World 2.0", SoundId = "rbxassetid://108005414313766", Cover = "rbxassetid://125096157303610" },
	{ Id = 5,  Title = "Tabola Bale Bale",                Artist = "Silet Open Up", Album = "", SoundId = "rbxassetid://104207837699519", Cover = "" },
	{ Id = 6,  Title = "Duka",             Artist = "Last Child",       Album = "Duka", SoundId = "rbxassetid://87619136997417", Cover = "" },
	{ Id = 7,  Title = "Diary Depresiku",    Artist = "Last Child",        Album = "Everything We Are Everything", SoundId = "rbxassetid://93093345512049", Cover = "" },
	{ Id = 8,  Title = "Lapang Dada",            Artist = "Sheila On 7",      Album = "Musim Yang Baik", SoundId = "rbxassetid://87418834280501", Cover = "" },
	{ Id = 9,  Title = "No !",     Artist = "Vierra",      Album = "My First Love", SoundId = "rbxassetid://86229112891958", Cover = "rbxassetid://94969502719436" },
	{ Id = 10, Title = "Perih",       Artist = "Vierra",           Album = "My First Love", SoundId = "rbxassetid://99291795667380", Cover = "rbxassetid://94969502719436" },
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
	local currentTabId     = "home"  -- "home" | "now"
	local sound            = nil   -- Instance Sound lokal (silent, untuk clock/progress UI)
	local isDraggingProgress = false
	local currentVolume    = 0.25    -- Volume yang disimpan (0-1), default 25% agar tidak terlalu kencang

	local Players   = game:GetService("Players")
	local localPlayer = Players.LocalPlayer

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

	-- ── Status Bar visual separator ──────────────────────────────────
	create("Frame", {
		Name = "StatusBarLine",
		BackgroundColor3 = Color3.fromRGB(210, 210, 210),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, Constants.Screen.StatusBarHeight),
		Size = UDim2.fromScale(1, 0.001),
		ZIndex = 58,
		Parent = appRoot,
	})

	-- ── Gradient Background ────────────────────────────────────────────
	local bgFrame = create("Frame", {
		Name = "Background",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel  = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 39,  -- Harus di bawah StatusBar (ZIndex 40)
		Parent = appRoot,
	})
	local bgGradient = Instance.new("UIGradient")
	bgGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(250, 250, 250)),
		ColorSequenceKeypoint.new(1,   Color3.fromRGB(245, 245, 245)),
	})
	bgGradient.Rotation = 135
	bgGradient.Parent = bgFrame

	-- ── Tab Bar (bawah) ────────────────────────────────────────────────
	local tabBar = create("Frame", {
		Name = "TabBar",
		BackgroundColor3 = Color3.fromRGB(248, 248, 248),
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
		BackgroundColor3 = Color3.fromRGB(210, 210, 210),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 61,
		Parent = tabBar,
	})

	local TAB_DEFS = {
		{ id = "home",  label = "Home",    emoji = "⌂" },
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
			TextColor3 = Color3.fromRGB(142, 142, 147),
			TextScaled = false,
			TextSize = 12,
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
		BackgroundColor3 = Color3.fromRGB(248, 248, 248),
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
		BackgroundColor3 = Color3.fromRGB(210, 210, 210),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1),
		ZIndex = 59,
		Parent = miniPlayer,
	})
	-- Progress bar tipis di atas mini player
	local miniProgressBg = create("Frame", {
		Name = "MiniProgressBg",
		BackgroundColor3 = Color3.fromRGB(220, 220, 225),
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
		TextColor3 = Color3.fromRGB(0, 0, 0),
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
		TextColor3 = Color3.fromRGB(142, 142, 147),
		TextScaled = false,
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromScale(0.04, 0.58),
		Size = UDim2.fromScale(0.6, 0.3),
		ZIndex = 59,
		Parent = miniPlayer,
	})
	local miniPlayBtn = create("ImageButton", {
		Name = "MiniPlayButton",
		BackgroundTransparency = 1,
		Image = "rbxassetid://124090122421689", -- play icon
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		Position = UDim2.fromScale(0.72, 0.25),
		Size = UDim2.fromScale(0.095, 0.5),
		ZIndex = 59,
		Parent = miniPlayer,
	})
	local miniNextBtn = create("ImageButton", {
		Name = "MiniNextButton",
		BackgroundTransparency = 1,
		Image = "rbxassetid://115488581897890", -- skip next icon
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		Position = UDim2.fromScale(0.86, 0.25),
		Size = UDim2.fromScale(0.095, 0.5),
		ZIndex = 59,
		Parent = miniPlayer,
	})

	-- ─── HOME PANEL ────────────────────────────────────────────────
	local searchPanel = create("Frame", {
		Name = "HomePanel",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 52,
		Visible = false,
		Parent = contentArea,
	})

	-- Nav Search
	local searchNav = create("Frame", {
		Name = "HomeNav",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 38),
		ZIndex = 54,
		Parent = searchPanel,
	})
	create("TextLabel", {
		Name = "HomeTitle",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Semibold,
		Text = "Music",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextScaled = false,
		TextSize = 16,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.7, 0.6),
		ZIndex = 55,
		Parent = searchNav,
	})
	local searchBackBtn = create("TextButton", {
		Name = "HomeBackBtn",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "く",
		TextColor3 = Color3.fromRGB(252, 60, 92),
		TextScaled = true,
		Position = UDim2.fromScale(0.02, 0.15),
		Size = UDim2.fromScale(0.1, 0.65),
		ZIndex = 55,
		Parent = searchNav,
	})
	searchBackBtn.Activated:Connect(context.CloseCurrentApp)

	-- Search Box
	local searchBoxBg = create("Frame", {
		Name = "SearchBoxBg",
		BackgroundColor3 = Color3.fromRGB(238, 238, 240),
		BorderSizePixel = 0,
		Position = UDim2.new(0.04, 0, 0, 42),
		Size = UDim2.new(0.92, 0, 0, 26),
		ZIndex = 54,
		Parent = searchPanel,
	})
	create("UICorner", { CornerRadius = UDim.new(0.4, 0), Parent = searchBoxBg })
	create("ImageLabel", {
		Name = "SearchIcon",
		BackgroundTransparency = 1,
		Image = "rbxassetid://91955678829293",
		Position = UDim2.fromScale(0.025, 0.2),
		Size = UDim2.fromScale(0.095, 0.6),
		ZIndex = 55,
		Parent = searchBoxBg,
	})
	local searchInput = create("TextBox", {
		Name = "SearchInput",
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		Font = Constants.Fonts.Regular,
		PlaceholderText = "Songs, Artists, Albums...",
		PlaceholderColor3 = Color3.fromRGB(142, 142, 147),
		Text = "",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextScaled = false,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.15, 0.05),
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
		-- +60 padding agar lagu terakhir tidak ketutup mini player
		searchScroll.CanvasSize = UDim2.new(0, 0, 0, searchList.AbsoluteContentSize.Y + 60)
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
		Position = UDim2.fromScale(0.5, 0.06),
		Size = UDim2.fromScale(0.7, 0.7),
		SizeConstraint = Enum.SizeConstraint.RelativeXX,
		ZIndex = 54,
		Parent = nowPanel,
	})
	create("UICorner", { CornerRadius = UDim.new(0.06, 0), Parent = artworkFrame })
	-- Note icon di tengah artwork
	local noteIcon = create("TextLabel", {
		Name = "NoteIcon",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "🎵",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextTransparency = 0.3,
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.55, 0.55),
		ZIndex = 55,
		Parent = artworkFrame,
	})
	-- ImageLabel untuk cover
	local coverImage = create("ImageLabel", {
		Name = "CoverImage",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 60,
		Visible = false,
		Parent = artworkFrame,
	})
	create("UICorner", { CornerRadius = UDim.new(0.06, 0), Parent = coverImage })

	-- Info lagu
	local songTitle = create("TextLabel", {
		Name = "SongTitle",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Semibold,
		Text = "Not Playing",
		TextColor3 = Color3.fromRGB(0, 0, 0),
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


	-- Progress Bar
	local progressBg = create("Frame", {
		Name = "ProgressBg",
		BackgroundColor3 = Color3.fromRGB(220, 220, 225),
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
		TextColor3 = Color3.fromRGB(142, 142, 147),
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
		TextColor3 = Color3.fromRGB(142, 142, 147),
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

	-- Icon asset IDs untuk kontrol playback (Roblox built-in icons)
	-- rbxassetid://7743869985 = skip next | 7743870447 = skip prev
	-- rbxassetid://7733960981 = play      | 7743870727 = pause
	-- rbxassetid://7743871135 = shuffle   | 7743870013 = repeat
	local shuffleBtn = create("ImageButton", {
		Name = "ShuffleBtn",
		BackgroundTransparency = 1,
		BackgroundColor3 = Color3.fromRGB(220, 220, 225),
		Image = "rbxassetid://139426024335886", -- shuffle icon
		ImageColor3 = Color3.fromRGB(142, 142, 147),
		Position = UDim2.fromScale(0, 0.1),
		Size = UDim2.fromScale(0.12, 0.75),
		ZIndex = 55,
		Parent = controlRow,
	})
	create("UICorner", { CornerRadius = UDim.new(0.25, 0), Parent = shuffleBtn })
	local prevBtn = create("ImageButton", {
		Name = "PrevBtn",
		BackgroundTransparency = 1,
		Image = "rbxassetid://106280938766613", -- skip previous icon
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		Position = UDim2.fromScale(0.19, 0.05),
		Size = UDim2.fromScale(0.16, 0.85),
		ZIndex = 55,
		Parent = controlRow,
	})
	local playPauseBtn = create("ImageButton", {
		Name = "PlayPauseBtn",
		BackgroundTransparency = 1,
		Image = "rbxassetid://124090122421689", -- play icon (default)
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		Position = UDim2.fromScale(0.4, 0),
		Size = UDim2.fromScale(0.18, 0.95),
		ZIndex = 55,
		Parent = controlRow,
	})
	local nextBtn = create("ImageButton", {
		Name = "NextBtn",
		BackgroundTransparency = 1,
		Image = "rbxassetid://115488581897890", -- skip next icon
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		Position = UDim2.fromScale(0.64, 0.05),
		Size = UDim2.fromScale(0.16, 0.85),
		ZIndex = 55,
		Parent = controlRow,
	})
	local repeatBtn = create("ImageButton", {
		Name = "RepeatBtn",
		BackgroundTransparency = 1,
		BackgroundColor3 = Color3.fromRGB(220, 220, 225),
		Image = "rbxassetid://134609968314396", -- repeat icon
		ImageColor3 = Color3.fromRGB(142, 142, 147),
		Position = UDim2.fromScale(0.86, 0.1),
		Size = UDim2.fromScale(0.12, 0.75),
		ZIndex = 55,
		Parent = controlRow,
	})
	create("UICorner", { CornerRadius = UDim.new(0.25, 0), Parent = repeatBtn })

	-- Volume Slider
	local volRow = create("Frame", {
		Name = "VolumeRow",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.06, 0.9),
		Size = UDim2.fromScale(0.88, 0.04),
		ZIndex = 54,
		Parent = nowPanel,
	})
	create("TextLabel", {
		Name = "VolIconL",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "🔈",
		TextColor3 = Color3.fromRGB(142, 142, 147),
		TextScaled = true,
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(0.07, 1),
		ZIndex = 55,
		Parent = volRow,
	})
	local volTrack = create("Frame", {
		Name = "VolumeTrack",
		BackgroundColor3 = Color3.fromRGB(220, 220, 225),
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
		BackgroundColor3 = Color3.fromRGB(180, 180, 180),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(currentVolume, 1),
		ZIndex = 56,
		Parent = volTrack,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = volFill })
	create("TextLabel", {
		Name = "VolIconR",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "🔊",
		TextColor3 = Color3.fromRGB(142, 142, 147),
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
		
		if currentSong.Cover and currentSong.Cover ~= "" then
			local id = tostring(currentSong.Cover):match("%d+")
			if id then
				-- Gunakan rbxthumb agar Decal ID bisa dirender sebagai image
				coverImage.Image = "rbxthumb://type=Asset&id=" .. id .. "&w=420&h=420"
			else
				coverImage.Image = currentSong.Cover
			end
			coverImage.Visible = true
			noteIcon.Visible = false
		else
			coverImage.Visible = false
			noteIcon.Visible = true
		end

		songTitle.Text   = currentSong.Title
		artistLabel.Text = currentSong.Artist

		miniPlayer.Visible    = (currentTabId ~= "now")
		miniSongTitle.Text    = currentSong.Title
		miniArtistLabel.Text  = currentSong.Artist

		-- Play/Pause icons (pakai ImageColor3 karena sudah ImageButton)
		if isPlaying then
			playPauseBtn.Image = "rbxassetid://72750581362856" -- pause icon
			miniPlayBtn.Image  = "rbxassetid://72750581362856"
		else
			playPauseBtn.Image = "rbxassetid://124090122421689" -- play icon
			miniPlayBtn.Image  = "rbxassetid://124090122421689"
		end

		-- Progress
		local dur = (sound and sound.TimeLength > 0) and sound.TimeLength or (currentSong.Duration or 1)
		local pct = math.clamp(playbackPos / dur, 0, 1)
		progressFill.Size = UDim2.fromScale(pct, 1)
		progressThumb.Position = UDim2.fromScale(pct, 0.5)
		miniProgressBar.Size = UDim2.fromScale(pct, 1)

		timeLeft.Text  = formatTime(playbackPos)
		timeRight.Text = "-" .. formatTime(dur - playbackPos)

		-- Sync ke shared MusicState agar LockScreen widget bisa update
		MusicState.get():Update({
			Song      = currentSong,
			IsPlaying = isPlaying,
			Position  = playbackPos,
			Duration  = dur,
		})
	end

	local function playSong(song)
		-- Stop & destroy sound lokal (clock) yang lama
		if sound then
			sound:Stop()
			sound:Destroy()
			sound = nil
		end

		currentSong = song
		playbackPos = 0
		isPlaying   = true

		-- ─── Server-side spatial sound (zona suara 3D) ───────────────────
		-- Fire ke server agar Part+Sound dibuat di dalam character,
		-- sehingga direplikasi ke SEMUA pemain di server.
		if remote then
			remote:FireServer("PlayMusic", {
				soundId    = song.SoundId,
				looped     = (repeatMode == 2),
				rollOffMin = 40,
				rollOffMax = 80,
				volume     = currentVolume,
			})
		end

		-- ─── Local silent sound (clock) untuk UI progress ────────────────
		-- Sound ini hanya digunakan untuk mendapatkan TimeLength & TimePosition
		-- yang akurat. Volume-nya 0 agar tidak double-play di client sendiri.
		local clockSound = Instance.new("Sound")
		clockSound.SoundId = song.SoundId
		clockSound.Volume  = 0   -- silent — suara asli sudah dari server
		clockSound.Looped  = (repeatMode == 2)
		clockSound.RollOffMaxDistance = 0
		clockSound.Parent  = game:GetService("SoundService")
		pcall(function() clockSound:Play() end)
		sound = clockSound

		-- Artwork bounce animation
		TweenService:Create(artworkFrame, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(0.72, 0.72),
		}):Play()
		task.delay(0.15, function()
			TweenService:Create(artworkFrame, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = UDim2.fromScale(0.7, 0.7),
			}):Play()
		end)

		updateNowPlayingUI()
	end

	local function stopPlayback()
		isPlaying = false
		if sound then sound:Pause() end
		-- Pause di server juga
		if remote then remote:FireServer("PauseMusic") end
		updateNowPlayingUI()
		-- Update shared state
		MusicState.get():Update({ IsPlaying = false })
	end

	local function resumePlayback()
		isPlaying = true
		if sound then pcall(function() sound:Resume() end) end
		-- Resume di server juga
		if remote then remote:FireServer("ResumeMusic") end
		updateNowPlayingUI()
		-- Update shared state
		MusicState.get():Update({ IsPlaying = true })
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

	-- ── Daftarkan callbacks ke MusicState agar LockScreen bisa kontrol ──
	-- Ini harus dipanggil setelah semua fungsi lokal didefinisikan
	MusicState.get()._callbacks = {
		Pause  = stopPlayback,
		Resume = resumePlayback,
		Prev   = playPrev,
		Next   = playNext,
	}

	-- ── Update progress setiap frame ───────────────────────────────────
	local lastTick = os.clock()
	local conn = RunService.Heartbeat:Connect(function()
		if not isPlaying or not currentSong then return end
		local now = os.clock()
		local dt  = now - lastTick
		lastTick  = now

		-- Sync dengan sound jika ada, kalau tidak simulate
		if not isDraggingProgress then
			if sound and sound.IsPlaying then
				playbackPos = sound.TimePosition
			else
				playbackPos = playbackPos + dt
			end
		end

		local dur = (sound and sound.TimeLength > 0) and sound.TimeLength or (currentSong.Duration or 1)
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

		-- Song info
		create("TextLabel", {
			Name = "Title",
			BackgroundTransparency = 1,
			Font = Constants.Fonts.Semibold,
			Text = song.Title,
			TextColor3 = Color3.fromRGB(0, 0, 0),
			TextScaled = false,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.fromScale(0.04, 0.12),
			Size = UDim2.fromScale(0.8, 0.38),
			ZIndex = 54,
			Parent = row,
		})
		create("TextLabel", {
			Name = "Artist",
			BackgroundTransparency = 1,
			Font = Constants.Fonts.Regular,
			Text = song.Artist,
			TextColor3 = Color3.fromRGB(142, 142, 147),
			TextScaled = false,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Position = UDim2.fromScale(0.04, 0.52),
			Size = UDim2.fromScale(0.8, 0.32),
			ZIndex = 54,
			Parent = row,
		})

		-- Duration
		local durationLabel = create("TextLabel", {
			Name = "Duration",
			BackgroundTransparency = 1,
			Font = Constants.Fonts.Regular,
			Text = song.Duration and formatTime(song.Duration) or "--:--",
			TextColor3 = Color3.fromRGB(142, 142, 147),
			TextScaled = false,
			TextSize = 9,
			TextXAlignment = Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(0.96, 0.5),
			Size = UDim2.fromScale(0.14, 0.3),
			ZIndex = 54,
			Parent = row,
		})

		if not song.Duration then
			task.spawn(function()
				local tempSound = Instance.new("Sound")
				tempSound.SoundId = song.SoundId
				tempSound.Volume = 0
				tempSound.RollOffMaxDistance = 0
				tempSound.Parent = game:GetService("SoundService")
				
				local waited = 0
				repeat
					task.wait(0.2)
					waited += 0.2
				until tempSound.IsLoaded or waited >= 8
				
				if tempSound.TimeLength > 0 then
					song.Duration = tempSound.TimeLength
					-- Update semua durationLabel yang ada di UI sekarang
					if durationLabel and durationLabel.Parent then
						durationLabel.Text = formatTime(song.Duration)
					end
				end
				tempSound:Destroy()
			end)
		end

		-- Separator
		create("Frame", {
			Name = "Sep",
			BackgroundColor3 = Color3.fromRGB(224, 224, 224),
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
		end)

		return row
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
				TextColor3 = Color3.fromRGB(142, 142, 147),
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
		searchPanel.Visible  = (tabId == "home")
		nowPanel.Visible     = (tabId == "now")

		for id, btn in pairs(tabButtons) do
			btn.TextColor3 = (id == tabId)
				and Color3.fromRGB(252, 60, 92)
				or Color3.fromRGB(142, 142, 147)
		end

		if currentSong then
			miniPlayer.Visible = (tabId ~= "now")
		end

		if tabId == "home" then
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
		shuffleBtn.BackgroundTransparency = isShuffle and 0.4 or 1
		shuffleBtn.ImageColor3 = isShuffle
			and Color3.fromRGB(252, 60, 92)
			or Color3.fromRGB(142, 142, 147)
	end)

	repeatBtn.Activated:Connect(function()
		repeatMode = (repeatMode + 1) % 3
		if repeatMode == 0 then
			-- off
			repeatBtn.BackgroundTransparency = 1
			repeatBtn.ImageColor3 = Color3.fromRGB(142, 142, 147)
			repeatBtn.Image = "rbxassetid://134609968314396" -- repeat icon normal
		elseif repeatMode == 1 then
			-- repeat all
			repeatBtn.BackgroundTransparency = 0.4
			repeatBtn.ImageColor3 = Color3.fromRGB(252, 60, 92)
			repeatBtn.Image = "rbxassetid://134609968314396" -- repeat icon aktif
		else
			-- repeat one
			repeatBtn.BackgroundTransparency = 0.4
			repeatBtn.ImageColor3 = Color3.fromRGB(252, 60, 92)
			repeatBtn.Image = "rbxassetid://132258851381293" -- repeat-one icon
		end
		if sound then sound.Looped = (repeatMode == 2) end
	end)


	-- ── Progress & Volume Dragging ────────────────────────────────────
	local function updateProgressFromInput(input)
		if not currentSong then return end
		local pct = math.clamp((input.Position.X - progressBg.AbsolutePosition.X) / progressBg.AbsoluteSize.X, 0, 1)
		local dur = (sound and sound.TimeLength > 0) and sound.TimeLength or (currentSong.Duration or 1)
		playbackPos = pct * dur
		-- Seek clock lokal
		if sound then
			pcall(function() sound.TimePosition = playbackPos end)
		end
		-- Seek server-side sound juga dengan restart pada posisi baru
		-- (Server tidak support seek langsung, jadi kita PlayMusic ulang dengan TimePosition baru)
		if remote and currentSong then
			remote:FireServer("PlayMusic", {
				soundId      = currentSong.SoundId,
				looped       = (repeatMode == 2),
				rollOffMin   = 40,
				rollOffMax   = 80,
				timePosition = playbackPos,
			})
		end
		updateNowPlayingUI()
	end

	progressBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDraggingProgress = true
			updateProgressFromInput(input)
		end
	end)

	local function updateVolumeFromInput(input)
		local pct = math.clamp((input.Position.X - volTrack.AbsolutePosition.X) / volTrack.AbsoluteSize.X, 0, 1)
		currentVolume = pct
		-- Clock lokal tidak perlu volume (sudah 0), tapi kita kirim ke server
		if remote then remote:FireServer("SetMusicVolume", pct) end
		volFill.Size = UDim2.fromScale(pct, 1)
	end

	volTrack.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDraggingVolume = true
			updateVolumeFromInput(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if isDraggingProgress and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateProgressFromInput(input)
		elseif isDraggingVolume and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateVolumeFromInput(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			isDraggingProgress = false
			isDraggingVolume = false
		end
	end)

	-- Search real-time
	searchInput:GetPropertyChangedSignal("Text"):Connect(function()
		populateSearch(searchInput.Text)
	end)

	-- ── Initial state ─────────────────────────────────────────────────
	populateSearch("")
	switchTab("home")
	updateNowPlayingUI()

	-- ── Cleanup saat app di-destroy ────────────────────────────────────
	appRoot.Destroying:Connect(function()
		for _, c in ipairs(activeConnections) do c:Disconnect() end
		if sound then sound:Destroy() end
		-- Hentikan server-side sound juga
		if remote then pcall(function() remote:FireServer("StopMusic") end) end
	end)

	return appRoot
end

return MusicApp
