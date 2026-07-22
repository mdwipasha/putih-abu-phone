--!strict

local Config = require(script.Parent.Parent.Config.Config)

local DefaultPlayerData = {}

function DefaultPlayerData.Create(displayName: string, phoneNumber: string): {[string]: any}
	return {
		Profile = { DisplayName = displayName },
		Economy = { Balance = Config.StartingBalance, Transactions = {} },
		Phone = {
			Number = phoneNumber,
			Contacts = {},
			Messages = {},
			CallHistory = {},
		},
		Settings = {},
		Inventory = {},
	}
end

-- Fills new schema fields without replacing data from older profiles.
function DefaultPlayerData.Reconcile(data: {[string]: any}, displayName: string, phoneNumber: string): {[string]: any}
	data.Profile = data.Profile or {}
	data.Profile.DisplayName = data.Profile.DisplayName or displayName
	data.Economy = data.Economy or {}
	data.Economy.Balance = tonumber(data.Economy.Balance) or Config.StartingBalance
	data.Economy.Transactions = data.Economy.Transactions or {}
	data.Phone = data.Phone or {}
	data.Phone.Number = data.Phone.Number or phoneNumber
	if type(data.Phone.Number) ~= "string" or data.Phone.Number:match("^%d+$") == nil then
		data.Phone.Number = phoneNumber
	end
	data.Phone.Contacts = data.Phone.Contacts or {}
	data.Phone.Messages = data.Phone.Messages or {}
	data.Phone.CallHistory = data.Phone.CallHistory or {}
	data.Settings = data.Settings or {}
	data.Inventory = data.Inventory or {}
	return data
end

return DefaultPlayerData
