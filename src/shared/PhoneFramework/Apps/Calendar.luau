local SimpleAppView = require(script.Parent.Parent.Shared.Components.SimpleAppView)

return {
	Id = "calendar",
	Name = "Calendar",
	Icon = { Background = Color3.fromRGB(248, 248, 248), Glyph = "11" },
	Order = 20,
	Create = function(context)
		return SimpleAppView.new(context, "Calendar", Color3.fromRGB(248, 248, 248))
	end,
}
