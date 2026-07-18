local SimpleAppView = require(script.Parent.Parent.Shared.Components.SimpleAppView)

return {
	Id = "settings",
	Name = "Settings",
	Icon = { Background = Color3.fromRGB(174, 174, 174), Glyph = "SET" },
	Order = 70,
	Create = function(context)
		return SimpleAppView.new(context, "Settings", Color3.fromRGB(174, 174, 174))
	end,
}
