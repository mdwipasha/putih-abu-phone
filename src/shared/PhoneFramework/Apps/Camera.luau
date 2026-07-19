local SimpleAppView = require(script.Parent.Parent.Shared.Components.SimpleAppView)

return {
	Id = "camera",
	Name = "Camera",
	Icon = { 
		Background = Color3.fromRGB(255, 255, 255),
		Image = "rbxassetid://6125281128", 
	},
	Order = 30,
	Create = function(context)
		return SimpleAppView.new(context, "Camera", Color3.fromRGB(120, 120, 120))
	end,
}
