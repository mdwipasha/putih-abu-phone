local SimpleAppView = require(script.Parent.Parent.Shared.Components.SimpleAppView)

return {
	Id = "clock",
	Name = "Clock",
	Icon = { 
		Background = Color3.fromRGB(42, 42, 42), 
		Image = "rbxassetid://88700018830982",
	},
	Order = 60,
	Create = function(context)
		return SimpleAppView.new(context, "Clock", Color3.fromRGB(42, 42, 42))
	end,
}
