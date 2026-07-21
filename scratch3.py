import re

with open(r"c:\laragon\www\putih-abu-phone\src\shared\PhoneFramework\Apps\Music.luau", "r", encoding="utf-8") as f:
    content = f.read()

# 1. Backgrounds
content = content.replace('Color3.fromRGB(28, 28, 30)', 'Color3.fromRGB(255, 255, 255)') # Main bg
content = content.replace('Color3.fromRGB(18, 18, 20)', 'Color3.fromRGB(255, 255, 255)') # Gradient top
content = content.replace('Color3.fromRGB(28, 28, 32)', 'Color3.fromRGB(250, 250, 250)') # Gradient mid
content = content.replace('Color3.fromRGB(12, 12, 16)', 'Color3.fromRGB(245, 245, 245)') # Gradient bot
content = content.replace('Color3.fromRGB(20, 20, 22)', 'Color3.fromRGB(248, 248, 248)') # Tab bar
content = content.replace('Color3.fromRGB(60, 60, 65)', 'Color3.fromRGB(210, 210, 210)') # Tab bar sep
content = content.replace('Color3.fromRGB(40, 40, 44)', 'Color3.fromRGB(248, 248, 248)') # Mini player
content = content.replace('Color3.fromRGB(80, 80, 88)', 'Color3.fromRGB(210, 210, 210)') # Mini player sep
content = content.replace('Color3.fromRGB(70, 70, 78)', 'Color3.fromRGB(220, 220, 225)') # Mini player progress bg
content = content.replace('Color3.fromRGB(50, 50, 56)', 'Color3.fromRGB(238, 238, 240)') # Search box bg
content = content.replace('Color3.fromRGB(55, 55, 62)', 'Color3.fromRGB(224, 224, 224)') # Row separator
content = content.replace('Color3.fromRGB(70, 70, 80)', 'Color3.fromRGB(220, 220, 225)') # Progress / Vol track bg
content = content.replace('Color3.fromRGB(200, 200, 215)', 'Color3.fromRGB(180, 180, 180)') # Vol fill

# 2. Texts and icons
content = content.replace('Color3.fromRGB(245, 245, 250)', 'Color3.fromRGB(0, 0, 0)') # Primary text 1
content = content.replace('Color3.fromRGB(252, 252, 255)', 'Color3.fromRGB(0, 0, 0)') # Primary text 2
content = content.replace('Color3.fromRGB(160, 160, 175)', 'Color3.fromRGB(142, 142, 147)') # Secondary text 1
content = content.replace('Color3.fromRGB(140, 140, 155)', 'Color3.fromRGB(142, 142, 147)') # Secondary text 2
content = content.replace('Color3.fromRGB(150, 150, 165)', 'Color3.fromRGB(142, 142, 147)') # Search icon
content = content.replace('Color3.fromRGB(120, 120, 135)', 'Color3.fromRGB(142, 142, 147)') # Search placeholder, unselected tabs
content = content.replace('Color3.fromRGB(130, 130, 140)', 'Color3.fromRGB(142, 142, 147)') # Unselected tabs 2
content = content.replace('Color3.fromRGB(110, 110, 125)', 'Color3.fromRGB(142, 142, 147)') # Duration text

# 3. StatusBar color
content = content.replace('StatusBar.new(appRoot, { Light = false, Battery = "100%" })', 'StatusBar.new(appRoot, { Light = true, Battery = "100%" })')

with open(r"c:\laragon\www\putih-abu-phone\src\shared\PhoneFramework\Apps\Music.luau", "w", encoding="utf-8") as f:
    f.write(content)

print("Color modifications applied successfully.")
