local SimpleAppView = require(script.Parent.Parent.Shared.Components.SimpleAppView)

return {
	Id = "music",
	Name = "Music",
	Icon = { 
		Background = Color3.fromRGB(255, 50, 80), 
		Image = "rbxassetid://75672729282743",
	},
	Order = 130,
	Create = function(context)
		return SimpleAppView.new(context, "Music", Color3.fromRGB(230, 64, 129))
	end,
}
