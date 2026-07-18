local SimpleAppView = require(script.Parent.Parent.Shared.Components.SimpleAppView)

return {
	Id = "contacts",
	Name = "Contacts",
	Icon = { Background = Color3.fromRGB(205, 205, 198), Glyph = "ID" },
	Order = 110,
	Create = function(context)
		return SimpleAppView.new(context, "Contacts", Color3.fromRGB(205, 205, 198))
	end,
}
