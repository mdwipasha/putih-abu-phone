local SimpleAppView = require(script.Parent.Parent.Shared.Components.SimpleAppView)

return {
	Id = "bank",
	Name = "Bank",
	Icon = { 
		Background = Color3.fromRGB(35, 117, 190), 
	},
	Order = 50,
	Create = function(context)
		return SimpleAppView.new(context, "Bank", Color3.fromRGB(35, 117, 190))
	end,
}
