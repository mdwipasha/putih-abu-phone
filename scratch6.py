with open(r"c:\laragon\www\putih-abu-phone\src\shared\PhoneFramework\Apps\Music.luau", "r", encoding="utf-8") as f:
    content = f.read()

# ──────────────────────────────────────────────────────────────────────────
# FIX 1: Duration di Home
# Masalah: Song.Duration = tempSound.TimeLength menyimpan durasi di song table,
# tapi populateSearch selalu re-create row BARU, jadi durationnya hilang.
# Solusi: Cukup set song.Duration sekali (sudah benar), tapi pastikan IsLoaded
# tidak pending sebelum cek TimeLength.
# Perbaikan tambahan: Parent di SoundWorkspace agar bisa load, bukan di row yg bisa hancur.
# ──────────────────────────────────────────────────────────────────────────
old_spawn = """\t\tif not song.Duration then
			task.spawn(function()
				local tempSound = Instance.new("Sound")
				tempSound.SoundId = song.SoundId
				tempSound.Volume = 0
				tempSound.Parent = row
				
				if not tempSound.IsLoaded then
					local t = 0
					while not tempSound.IsLoaded and t < 5 do
						task.wait(0.1)
						t += 0.1
					end
				end
				
				if tempSound.TimeLength > 0 then
					song.Duration = tempSound.TimeLength
					if durationLabel.Parent then
						durationLabel.Text = formatTime(song.Duration)
					end
				end
				tempSound:Destroy()
			end)
		end"""

new_spawn = """\t\tif not song.Duration then
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
		end"""

content = content.replace(old_spawn, new_spawn)

# ──────────────────────────────────────────────────────────────────────────
# FIX 2: Status Bar (tambahkan setelah contentArea)
# ──────────────────────────────────────────────────────────────────────────
old_statusbar = """\tStatusBar.new(appRoot, { Light = false, Battery = "100%" })"""
new_statusbar = """\tStatusBar.new(appRoot, { Light = false, Battery = "100%" })

\t-- ── Status Bar visual separator ──────────────────────────────────
\tcreate("Frame", {
\t\tName = "StatusBarLine",
\t\tBackgroundColor3 = Color3.fromRGB(210, 210, 210),
\t\tBorderSizePixel = 0,
\t\tPosition = UDim2.fromScale(0, Constants.Screen.StatusBarHeight),
\t\tSize = UDim2.fromScale(1, 0.001),
\t\tZIndex = 58,
\t\tParent = appRoot,
\t})"""
content = content.replace(old_statusbar, new_statusbar)

# ──────────────────────────────────────────────────────────────────────────
# FIX 3: Cover — gunakan rbxassetid langsung, bukan rbxthumb
# rbxthumb hanya berfungsi untuk jenis tertentu; decal id langsung lebih andal
# ──────────────────────────────────────────────────────────────────────────
old_cover = """\t\tif currentSong.Cover and currentSong.Cover ~= "" then
			local imageId = currentSong.Cover
			if imageId:match("^rbxassetid://") then
				local id = imageId:match("%d+")
				imageId = "rbxthumb://type=Asset&id=" .. id .. "&w=420&h=420"
			end
			coverImage.Image = imageId
			coverImage.Visible = true
			noteIcon.Visible = false
		else
			coverImage.Visible = false
			noteIcon.Visible = true
		end"""

new_cover = """\t\tif currentSong.Cover and currentSong.Cover ~= "" then
			coverImage.Image = currentSong.Cover  -- langsung pakai rbxassetid decal
			coverImage.Visible = true
			noteIcon.Visible = false
		else
			coverImage.Visible = false
			noteIcon.Visible = true
		end"""
content = content.replace(old_cover, new_cover)

# ──────────────────────────────────────────────────────────────────────────
# FIX 4: Lagu terakhir ketutup mini player
# Tambahkan padding bawah di searchScroll supaya isi bisa discroll naik
# ──────────────────────────────────────────────────────────────────────────
old_list_connect = """\tsearchList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		searchScroll.CanvasSize = UDim2.new(0, 0, 0, searchList.AbsoluteContentSize.Y)
	end)"""
new_list_connect = """\tsearchList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		-- +60 padding agar lagu terakhir tidak ketutup mini player
		searchScroll.CanvasSize = UDim2.new(0, 0, 0, searchList.AbsoluteContentSize.Y + 60)
	end)"""
content = content.replace(old_list_connect, new_list_connect)

with open(r"c:\laragon\www\putih-abu-phone\src\shared\PhoneFramework\Apps\Music.luau", "w", encoding="utf-8") as f:
    f.write(content)

print("All 4 fixes applied successfully.")
