local root = script.Parent.Parent
local Constants = require(root:WaitForChild("Shared"):WaitForChild("Constants"))
local StatusBar = require(root:WaitForChild("Shared"):WaitForChild("Components"):WaitForChild("StatusBar"))
local Wallpaper = require(root:WaitForChild("Shared"):WaitForChild("Components"):WaitForChild("Wallpaper"))
local create = require(root:WaitForChild("Shared"):WaitForChild("Utilities"):WaitForChild("Create"))
local MusicState = require(root:WaitForChild("Services"):WaitForChild("MusicState"))

local LockScreen = {
	Id = "lock",
	Name = "Lock",
	Icon = { Background = Color3.fromRGB(70, 70, 76), Glyph = "LOCK" },
	Order = -2,
	IsSystem = true,
}

-- ── Helper ────────────────────────────────────────────────────────────────
local function formatTime(seconds: number): string
	seconds = math.floor(math.max(seconds, 0))
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%d:%02d", m, s)
end

function LockScreen.Create(context: any)
	local screenRoot = create("Frame", {
		Name = "LockScreen",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 20,
	})

	Wallpaper.new(screenRoot, "Lock", context)
	StatusBar.new(screenRoot, { Light = true, Carrier = "", Battery = "100%" })

	-- ── Jam & Tanggal ────────────────────────────────────────────────────
	local timeText = create("TextLabel", {
		Name = "Time",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Light,
		Text = DateTime.now():FormatLocalTime("h:mm", "en-us"),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.07),
		Size = UDim2.fromScale(0.78, 0.24),
		ZIndex = 30,
		Parent = screenRoot,
	})

	create("TextLabel", {
		Name = "Date",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = DateTime.now():FormatLocalTime("dddd, MMMM D", "en-us"),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.fromScale(0.82, 0.04),
		ZIndex = 30,
		Parent = screenRoot,
	})

	-- ══════════════════════════════════════════════════════════════════════
	--  MUSIC WIDGET  (muncul jika ada lagu yang sedang/pernah diputar)
	-- ══════════════════════════════════════════════════════════════════════
	local musicWidget = create("Frame", {
		Name = "MusicWidget",
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.38),
		Size = UDim2.fromScale(0.86, 0.28),
		ZIndex = 32,
		Visible = false,
		Parent = screenRoot,
	})
	create("UICorner", { CornerRadius = UDim.new(0.07, 0), Parent = musicWidget })

	-- Blur effect via gradient overlay
	local blurGrad = Instance.new("UIGradient")
	blurGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1,   Color3.fromRGB(200, 200, 200)),
	})
	blurGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 0.45),
	})
	blurGrad.Rotation = 135
	blurGrad.Parent = musicWidget

	-- ── Cover art kecil (kiri) ────────────────────────────────────────────
	local coverFrame = create("Frame", {
		Name = "CoverFrame",
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(80, 40, 80),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.04, 0.25),
		Size = UDim2.fromScale(0.18, 0),
		ZIndex = 33,
		Parent = musicWidget,
	})
	create("UIAspectRatioConstraint", { AspectRatio = 1, Parent = coverFrame })
	create("UICorner", { CornerRadius = UDim.new(0.12, 0), Parent = coverFrame })

	local coverImg = create("ImageLabel", {
		Name = "CoverImg",
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Crop,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 34,
		Visible = false,
		Parent = coverFrame,
	})
	create("UICorner", { CornerRadius = UDim.new(0.12, 0), Parent = coverImg })

	local noteLabel = create("TextLabel", {
		Name = "NoteLabel",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "♫",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextTransparency = 0.2,
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.6, 0.6),
		ZIndex = 34,
		Parent = coverFrame,
	})

	-- ── Title & Artist ────────────────────────────────────────────────────
	local titleLabel = create("TextLabel", {
		Name = "SongTitle",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Semibold,
		Text = "Not Playing",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = false,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromScale(0.26, 0.09),
		Size = UDim2.fromScale(0.7, 0.2),
		ZIndex = 33,
		Parent = musicWidget,
	})

	local artistLabel = create("TextLabel", {
		Name = "ArtistName",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "",
		TextColor3 = Color3.fromRGB(252, 60, 92),
		TextScaled = false,
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromScale(0.26, 0.31),
		Size = UDim2.fromScale(0.7, 0.16),
		ZIndex = 33,
		Parent = musicWidget,
	})

	-- ── Progress bar ──────────────────────────────────────────────────────
	local timePosLabel = create("TextLabel", {
		Name = "TimePos",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "0:00",
		TextColor3 = Color3.fromRGB(200, 200, 200),
		TextScaled = false,
		TextSize = 8,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromScale(0.04, 0.5),
		Size = UDim2.fromScale(0.15, 0.12),
		ZIndex = 33,
		Parent = musicWidget,
	})

	local timeRemLabel = create("TextLabel", {
		Name = "TimeRem",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "-0:00",
		TextColor3 = Color3.fromRGB(200, 200, 200),
		TextScaled = false,
		TextSize = 8,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.96, 0.5),
		Size = UDim2.fromScale(0.15, 0.12),
		ZIndex = 33,
		Parent = musicWidget,
	})

	local progressBg = create("Frame", {
		Name = "ProgressBg",
		BackgroundColor3 = Color3.fromRGB(100, 100, 110),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.04, 0.625),
		Size = UDim2.fromScale(0.92, 0.055),
		ZIndex = 33,
		Parent = musicWidget,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = progressBg })

	local progressFill = create("Frame", {
		Name = "ProgressFill",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
		ZIndex = 34,
		Parent = progressBg,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = progressFill })

	-- Thumb bulat
	local thumb = create("Frame", {
		Name = "Thumb",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(7, 7),
		ZIndex = 35,
		Parent = progressBg,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = thumb })

	-- ── Kontrol Playback ──────────────────────────────────────────────────
	local controlsRow = create("Frame", {
		Name = "Controls",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.97),
		Size = UDim2.fromScale(0.55, 0.28),
		ZIndex = 33,
		Parent = musicWidget,
	})

	local prevBtn = create("TextButton", {
		Name = "PrevBtn",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "⏮",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.1, 0.5),
		Size = UDim2.fromScale(0.28, 0.9),
		ZIndex = 34,
		Parent = controlsRow,
	})

	local playPauseBtn = create("TextButton", {
		Name = "PlayPauseBtn",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "▶",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.36, 1),
		ZIndex = 34,
		Parent = controlsRow,
	})

	local nextBtn = create("TextButton", {
		Name = "NextBtn",
		BackgroundTransparency = 1,
		Font = Constants.Fonts.Regular,
		Text = "⏭",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.9, 0.5),
		Size = UDim2.fromScale(0.28, 0.9),
		ZIndex = 34,
		Parent = controlsRow,
	})

	-- ── "slide to unlock" ─────────────────────────────────────────────────
	local slider = create("TextButton", {
		Name = "ClickToUnlock",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.62,
		Font = Constants.Fonts.Light,
		Text = "click to unlock",
		TextColor3 = Color3.fromRGB(225, 225, 225),
		TextScaled = true,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.905),
		Size = UDim2.fromScale(0.72, 0.068),
		ZIndex = 35,
		Parent = screenRoot,
	})
	create("UICorner", { CornerRadius = UDim.new(0.12, 0), Parent = slider })
	slider.Activated:Connect(context.Unlock)

	-- ══════════════════════════════════════════════════════════════════════
	--  Fungsi update widget dari MusicState
	-- ══════════════════════════════════════════════════════════════════════
	local function refreshWidget()
		local state = MusicState.get()

		if not state.Song then
			musicWidget.Visible = false
			return
		end

		musicWidget.Visible = true

		-- Title & Artist
		titleLabel.Text  = state.Song.Title or "Unknown"
		artistLabel.Text = state.Song.Artist or ""

		-- Cover art
		local coverStr = tostring(state.Song.Cover or "")
		local coverId  = coverStr:match("%d+")
		if coverId then
			coverImg.Image   = "rbxthumb://type=Asset&id=" .. coverId .. "&w=150&h=150"
			coverImg.Visible = true
			noteLabel.Visible = false
		else
			coverImg.Visible  = false
			noteLabel.Visible = true
		end

		-- Progress
		local dur = state.Duration > 0 and state.Duration or 1
		local pos = state.Position
		local pct = math.clamp(pos / dur, 0, 1)

		progressFill.Size = UDim2.fromScale(pct, 1)
		thumb.Position    = UDim2.fromScale(pct, 0.5)
		timePosLabel.Text = formatTime(pos)
		timeRemLabel.Text = "-" .. formatTime(dur - pos)

		-- Play/Pause icon
		playPauseBtn.Text = state.IsPlaying and "⏸" or "▶"
	end

	-- Subscribe ke perubahan state musik (fired setiap Heartbeat dari Music app)
	local musicConn = MusicState.get().Changed:Connect(refreshWidget)
	refreshWidget() -- panggil sekali saat pertama kali

	-- ── Kontrol dari LockScreen widget → delegasi ke Music app ──────────
	-- Kita tidak bisa langsung panggil playSong() dari sini karena Music app
	-- di modul terpisah. Tapi kita bisa baca state & fire melalui BindableEvent
	-- yang disimpan di MusicState, atau cukup akses sound clock lokal via state.
	-- Solusi: simpan callback di MusicState saat Music app aktif.

	playPauseBtn.Activated:Connect(function()
		local cb = MusicState.get()._callbacks
		if cb then
			if MusicState.get().IsPlaying then
				if cb.Pause then cb.Pause() end
			else
				if cb.Resume then cb.Resume() end
			end
		end
	end)

	prevBtn.Activated:Connect(function()
		local cb = MusicState.get()._callbacks
		if cb and cb.Prev then cb.Prev() end
	end)

	nextBtn.Activated:Connect(function()
		local cb = MusicState.get()._callbacks
		if cb and cb.Next then cb.Next() end
	end)

	-- ── Clock update setiap 10 detik ─────────────────────────────────────
	task.spawn(function()
		while screenRoot.Parent do
			timeText.Text = DateTime.now():FormatLocalTime("h:mm", "en-us")
			task.wait(10)
		end
	end)

	-- Cleanup
	screenRoot.Destroying:Connect(function()
		if musicConn then musicConn:Disconnect() end
	end)

	return screenRoot
end

return LockScreen
