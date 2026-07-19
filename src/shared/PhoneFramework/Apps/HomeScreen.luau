local StatusBar = require(script.Parent.Parent.Shared.Components.StatusBar)
local Wallpaper = require(script.Parent.Parent.Shared.Components.Wallpaper)
local IconGrid = require(script.Parent.Parent.Shared.Components.IconGrid)
local create = require(script.Parent.Parent.Shared.Utilities.Create)

local HomeScreen = {
	Id = "home",
	Name = "Home",
	Icon = { Background = Color3.fromRGB(80, 80, 80), Glyph = "HOME" },
	Order = -1,
	IsSystem = true,
}

function HomeScreen.Create(context: any)
	local root = create("Frame", {
		Name = "HomeScreen",
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 20,
	})

	Wallpaper.new(root, "Home", context)
	StatusBar.new(root, { Light = true, Carrier = "ROBLOX", Battery = "100%" })
	IconGrid.new(root, context.GetApps(), context.OpenApp, { "phone", "contacts", "gallery", "music" })

	return root
end

return HomeScreen
