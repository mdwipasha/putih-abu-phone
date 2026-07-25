--!strict

local HttpService = game:GetService("HttpService")
local Config = require(script.Parent.Parent.Config.Config)
local Signals = require(script.Parent.Parent.Events.Signals)
local DataManager = require(script.Parent.Parent.Data.DataManager)

local TransactionService = {}

export type Details = {
	Type: string,
	Amount: number,
	From: number?,
	To: number?,
	Description: string?,
}

function TransactionService.Create(userId: number, details: Details): {[string]: any}?
	local data = require(script.Parent.Parent.Data.Cache).Get(userId)
	if not data then return nil end
	local transaction = {
		Id = HttpService:GenerateGUID(false),
		Type = details.Type,
		Amount = details.Amount,
		From = details.From,
		To = details.To,
		Timestamp = os.time(),
		Description = details.Description or "",
	}
	table.insert(data.Economy.Transactions, 1, transaction)
	while #data.Economy.Transactions > Config.MaxTransactions do
		table.remove(data.Economy.Transactions)
	end
	DataManager.QueueSave(userId)
	Signals.TransactionCreated:Fire(userId, transaction)
	return transaction
end

return TransactionService
