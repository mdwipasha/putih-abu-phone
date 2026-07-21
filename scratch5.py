import re

with open(r"c:\laragon\www\putih-abu-phone\src\shared\PhoneFramework\Apps\Music.luau", "r", encoding="utf-8") as f:
    content = f.read()

# 1. Fix contentArea offset
old_content = """	local contentArea = create("Frame", {
		Name = "ContentArea",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, Constants.Screen.StatusBarHeight),
		Size = UDim2.new(1, 0, 0.88 - Constants.Screen.StatusBarHeight, 0),"""
new_content = """	local contentArea = create("Frame", {
		Name = "ContentArea",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, Constants.Screen.StatusBarHeight),
		Size = UDim2.fromScale(1, 1 - Constants.Screen.StatusBarHeight - 0.12),"""
content = content.replace(old_content, new_content)

# 2. Fix lazy load duration
old_spawn = """		if not song.Duration then
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
new_spawn = """		if not song.Duration then
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
content = content.replace(old_spawn, new_spawn)

# 3. Fix cover image URL
old_cover = """		if currentSong.Cover and currentSong.Cover ~= "" then
			coverImage.Image = currentSong.Cover
			coverImage.Visible = true
			noteIcon.Visible = false
		else"""
new_cover = """		if currentSong.Cover and currentSong.Cover ~= "" then
			local imageId = currentSong.Cover
			if imageId:match("^rbxassetid://") then
				local id = imageId:match("%d+")
				imageId = "rbxthumb://type=Asset&id=" .. id .. "&w=420&h=420"
			end
			coverImage.Image = imageId
			coverImage.Visible = true
			noteIcon.Visible = false
		else"""
content = content.replace(old_cover, new_cover)


with open(r"c:\laragon\www\putih-abu-phone\src\shared\PhoneFramework\Apps\Music.luau", "w", encoding="utf-8") as f:
    f.write(content)

print("Patch applied successfully.")
