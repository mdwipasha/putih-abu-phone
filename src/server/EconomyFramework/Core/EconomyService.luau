--!strict

local Cache = require(script.Parent.Parent.Data.Cache)
local DataManager = require(script.Parent.Parent.Data.DataManager)
local Signals = require(script.Parent.Parent.Events.Signals)
local TransactionService = require(script.Parent.TransactionService)
local ValidationService = require(script.Parent.ValidationService)
local TransactionType = require(script.Parent.Parent.Types.TransactionType)

local EconomyService = {}

local function balanceChanged(userId: number, oldBalance: number, newBalance: number)
	DataManager.QueueSave(userId)
	Signals.BalanceChanged:Fire(userId, oldBalance, newBalance)
end

function EconomyService.GetBalance(userId: number): number?
	local data = Cache.Get(userId)
	return if data then data.Economy.Balance else nil
end

function EconomyService.CanAfford(userId: number, amount: number): boolean
	local data = Cache.Get(userId)
	return data ~= nil and type(amount) == "number" and amount > 0 and data.Economy.Balance >= amount
end

function EconomyService.AddMoney(userId: number, amount: number, transactionType: string?, description: string?): (boolean, string?)
	local valid, message = ValidationService.PositiveAmount(amount)
	local data = Cache.Get(userId)
	if not valid then return false, message end
	if not data then return false, "Player data is not loaded." end
	local old = data.Economy.Balance
	data.Economy.Balance += amount
	TransactionService.Create(userId, { Type = transactionType or TransactionType.REWARD, Amount = amount, To = userId, Description = description })
	balanceChanged(userId, old, data.Economy.Balance)
	return true
end

function EconomyService.RemoveMoney(userId: number, amount: number, transactionType: string?, description: string?): (boolean, string?)
	local valid, message = ValidationService.PositiveAmount(amount)
	local data = Cache.Get(userId)
	if not valid then return false, message end
	if not data then return false, "Player data is not loaded." end
	if data.Economy.Balance < amount then return false, "Insufficient balance." end
	local old = data.Economy.Balance
	data.Economy.Balance -= amount
	TransactionService.Create(userId, { Type = transactionType or TransactionType.PURCHASE, Amount = amount, From = userId, Description = description })
	balanceChanged(userId, old, data.Economy.Balance)
	return true
end

function EconomyService.SetBalance(userId: number, amount: number, description: string?): (boolean, string?)
	if type(amount) ~= "number" or amount ~= amount or amount < 0 or amount == math.huge or amount == -math.huge then return false, "Balance must be a finite non-negative number." end
	local data = Cache.Get(userId)
	if not data then return false, "Player data is not loaded." end
	local old = data.Economy.Balance
	data.Economy.Balance = amount
	TransactionService.Create(userId, { Type = TransactionType.ADMIN, Amount = math.abs(amount - old), To = userId, Description = description or "Balance set" })
	balanceChanged(userId, old, amount)
	return true
end

function EconomyService.Transfer(fromUserId: number, toUserId: number, amount: number, description: string?): (boolean, string?)
	local valid, message = ValidationService.Transfer(fromUserId, toUserId, amount)
	if not valid then return false, message end
	local sender = Cache.Get(fromUserId) :: {[string]: any}
	local recipient = Cache.Get(toUserId) :: {[string]: any}
	local oldSender, oldRecipient = sender.Economy.Balance, recipient.Economy.Balance
	sender.Economy.Balance -= amount
	recipient.Economy.Balance += amount
	TransactionService.Create(fromUserId, { Type = TransactionType.TRANSFER, Amount = amount, From = fromUserId, To = toUserId, Description = description })
	TransactionService.Create(toUserId, { Type = TransactionType.TRANSFER, Amount = amount, From = fromUserId, To = toUserId, Description = description })
	balanceChanged(fromUserId, oldSender, sender.Economy.Balance)
	balanceChanged(toUserId, oldRecipient, recipient.Economy.Balance)
	return true
end

return EconomyService
