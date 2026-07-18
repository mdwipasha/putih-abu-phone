local SimpleAppView = require(script.Parent.Parent.Shared.Components.SimpleAppView)

return {
	Id = "camera",
	Name = "Camera",
	Icon = { Background = Color3.fromRGB(164, 164, 164), Glyph = "CAM" },
	Order = 30,
	Create = function(context)
		return SimpleAppView.new(context, "Camera", Color3.fromRGB(120, 120, 120))
	end,
}
