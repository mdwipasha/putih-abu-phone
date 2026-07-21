import re

with open(r"c:\laragon\www\putih-abu-phone\src\shared\PhoneFramework\Apps\Music.luau", "r", encoding="utf-8") as f:
    content = f.read()

# 1. Add UserInputService
content = content.replace('local RunService  = game:GetService("RunService")',
                          'local RunService  = game:GetService("RunService")\nlocal UserInputService = game:GetService("UserInputService")')

# 2. State variables for dragging
content = content.replace('local sound            = nil   -- Instance Sound aktif',
                          'local sound            = nil   -- Instance Sound aktif\n\tlocal isDraggingProgress = false\n\tlocal isDraggingVolume   = false')

# 3. Add CoverImage
old_artwork = """	-- Artwork (besar, tengah)
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
	})"""

new_artwork = """	-- Artwork (besar, tengah)
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
	local noteIcon = create("TextLabel", {
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
	-- ImageLabel untuk cover
	local coverImage = create("ImageLabel", {
		Name = "CoverImage",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 56,
		Visible = false,
		Parent = artworkFrame,
	})
	create("UICorner", { CornerRadius = UDim.new(0.06, 0), Parent = coverImage })"""
content = content.replace(old_artwork, new_artwork)

# 4. Remove loveBtn creation
content = re.sub(r"\t-- Love button \(jantung\).*?local isFavorited = false\n", "", content, flags=re.DOTALL)

# 5. Remove loveBtn connections
content = re.sub(r"\tloveBtn\.Activated:Connect.*?end\)\n", "", content, flags=re.DOTALL)

# 6. Update updateNowPlayingUI
old_update = """		local col = getAlbumColor(currentSong)
		artworkFrame.BackgroundColor3 = col

		songTitle.Text   = currentSong.Title
		artistLabel.Text = currentSong.Artist"""

new_update = """		local col = getAlbumColor(currentSong)
		artworkFrame.BackgroundColor3 = col
		
		if currentSong.Cover and currentSong.Cover ~= "" then
			coverImage.Image = currentSong.Cover
			coverImage.Visible = true
			noteIcon.Visible = false
		else
			coverImage.Visible = false
			noteIcon.Visible = true
		end

		songTitle.Text   = currentSong.Title
		artistLabel.Text = currentSong.Artist"""
content = content.replace(old_update, new_update)

# 7. Update heartbeat loop to respect isDraggingProgress
old_hb = """		-- Sync dengan sound jika ada, kalau tidak simulate
		if sound and sound.IsPlaying then
			playbackPos = sound.TimePosition
		else
			playbackPos = playbackPos + dt
		end"""

new_hb = """		-- Sync dengan sound jika ada, kalau tidak simulate
		if not isDraggingProgress then
			if sound and sound.IsPlaying then
				playbackPos = sound.TimePosition
			else
				playbackPos = playbackPos + dt
			end
		end"""
content = content.replace(old_hb, new_hb)

# 8. Add dragging logic for progress and volume
old_controls_init = """	-- Search real-time
	searchInput:GetPropertyChangedSignal("Text"):Connect(function()"""

new_controls_init = """	-- ── Progress & Volume Dragging ────────────────────────────────────
	local function updateProgressFromInput(input)
		if not currentSong then return end
		local pct = math.clamp((input.Position.X - progressBg.AbsolutePosition.X) / progressBg.AbsoluteSize.X, 0, 1)
		local dur = currentSong.Duration or 1
		playbackPos = pct * dur
		if sound then sound.TimePosition = playbackPos end
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
		if sound then sound.Volume = pct end
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
	searchInput:GetPropertyChangedSignal("Text"):Connect(function()"""
content = content.replace(old_controls_init, new_controls_init)

# 9. Remove HitBtn tab switching logic
old_hit = """			playSong(song)
			-- Pindah ke Now Playing tab
			currentTabId = "now"
			for _, p in ipairs({searchPanel, nowPanel}) do
				p.Visible = false
			end
			nowPanel.Visible = true
			for id, btn in pairs(tabButtons) do
				btn.TextColor3 = (id == "now") and Color3.fromRGB(252, 60, 92) or Color3.fromRGB(130, 130, 140)
			end
			miniPlayer.Visible = false
		end)"""
new_hit = """			playSong(song)
		end)"""
content = content.replace(old_hit, new_hit)

with open(r"c:\laragon\www\putih-abu-phone\src\shared\PhoneFramework\Apps\Music.luau", "w", encoding="utf-8") as f:
    f.write(content)

print("Modifications applied successfully.")
