local SimpleAppView = require(script.Parent.Parent.Shared.Components.SimpleAppView)

return {
	Id = "phone",
	Name = "Phone",
	Icon = { 
		Background = Color3.fromRGB(35, 214, 63), 
		Image = "rbxassetid://71727318918905",
	},
	Order = 100,
	Create = function(context)
		return SimpleAppView.new(context, "Phone", Color3.fromRGB(35, 214, 63))
	end,
}
