import re

with open(r"c:\laragon\www\putih-abu-phone\src\shared\PhoneFramework\Apps\Music.luau", "r", encoding="utf-8") as f:
    content = f.read()

# 1. Remove Duration from SONGS
content = re.sub(r"\s*Duration\s*=\s*\d+,\s*", " ", content)

# 2. Update createSongRow to lazy load Duration
old_duration_block = """		-- Duration
		create("TextLabel", {
			Name = "Duration",
			BackgroundTransparency = 1,
			Font = Constants.Fonts.Regular,
			Text = formatTime(song.Duration),
			TextColor3 = Color3.fromRGB(142, 142, 147),
			TextScaled = false,
			TextSize = 9,
			TextXAlignment = Enum.TextXAlignment.Right,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(0.96, 0.5),
			Size = UDim2.fromScale(0.14, 0.3),
			ZIndex = 54,
			Parent = row,
		})"""

new_duration_block = """		-- Duration
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
				local ContentProvider = game:GetService("ContentProvider")
				pcall(function()
					ContentProvider:PreloadAsync({tempSound})
				end)
				if tempSound.TimeLength > 0 then
					song.Duration = tempSound.TimeLength
					if durationLabel.Parent then
						durationLabel.Text = formatTime(song.Duration)
					end
				end
				tempSound:Destroy()
			end)
		end"""
content = content.replace(old_duration_block, new_duration_block)

# 3. Update updateNowPlayingUI dur definition
old_dur_1 = """		-- Progress
		local dur = currentSong.Duration or 1"""
new_dur_1 = """		-- Progress
		local dur = (sound and sound.TimeLength > 0) and sound.TimeLength or (currentSong.Duration or 1)"""
content = content.replace(old_dur_1, new_dur_1)

# 4. Update Heartbeat dur definition
old_dur_2 = """		local dur = currentSong.Duration or 200
		if playbackPos >= dur then"""
new_dur_2 = """		local dur = (sound and sound.TimeLength > 0) and sound.TimeLength or (currentSong.Duration or 1)
		if playbackPos >= dur then"""
content = content.replace(old_dur_2, new_dur_2)

# 5. Update updateProgressFromInput dur definition
old_dur_3 = """		local pct = math.clamp((input.Position.X - progressBg.AbsolutePosition.X) / progressBg.AbsoluteSize.X, 0, 1)
		local dur = currentSong.Duration or 1"""
new_dur_3 = """		local pct = math.clamp((input.Position.X - progressBg.AbsolutePosition.X) / progressBg.AbsoluteSize.X, 0, 1)
		local dur = (sound and sound.TimeLength > 0) and sound.TimeLength or (currentSong.Duration or 1)"""
content = content.replace(old_dur_3, new_dur_3)


with open(r"c:\laragon\www\putih-abu-phone\src\shared\PhoneFramework\Apps\Music.luau", "w", encoding="utf-8") as f:
    f.write(content)

print("Duration modification applied successfully.")
