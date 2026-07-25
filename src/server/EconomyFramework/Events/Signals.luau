--!strict

local Players = game:GetService("Players")

local folder = Instance.new("Folder")
folder.Name = "EconomyEvents"
folder.Parent = game:GetService("ServerScriptService")

local function newEvent(name: string): BindableEvent
	local event = Instance.new("BindableEvent")
	event.Name = name
	event.Parent = folder
	return event
end

return table.freeze({
	BalanceChanged = newEvent("BalanceChanged"),
	TransactionCreated = newEvent("TransactionCreated"),
	PlayerDataLoaded = newEvent("PlayerDataLoaded"),
	PlayerDataSaved = newEvent("PlayerDataSaved"),
	PlayerRemoving = Players.PlayerRemoving,
})
