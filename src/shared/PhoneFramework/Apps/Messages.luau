local SimpleAppView = require(script.Parent.Parent.Shared.Components.SimpleAppView)

return {
	Id = "messages",
	Name = "Messages",
	Icon = { Background = Color3.fromRGB(33, 213, 66), Glyph = "MSG" },
	Order = 10,
	Create = function(context)
		return SimpleAppView.new(context, "Messages", Color3.fromRGB(33, 213, 66))
	end,
}
