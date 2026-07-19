local SimpleAppView = require(script.Parent.Parent.Shared.Components.SimpleAppView)

return {
	Id = "gallery",
	Name = "Photos",
	Icon = { 
		Background = Color3.fromRGB(255, 255, 255), 
		Image = "rbxassetid://101194280432848",
	},
	Order = 40,
	Create = function(context)
		return SimpleAppView.new(context, "Photos", Color3.fromRGB(255, 205, 80))
	end,
}
