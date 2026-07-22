--!strict

local Cache = require(script.Parent.Parent.Data.Cache)

local ValidationService = {}

function ValidationService.PositiveAmount(amount: number): (boolean, string?)
	if type(amount) ~= "number" or amount ~= amount or amount == math.huge or amount == -math.huge or amount <= 0 then
		return false, "Amount must be a finite number greater than zero."
	end
	return true
end

function ValidationService.Transfer(fromUserId: number, toUserId: number, amount: number): (boolean, string?)
	local valid, message = ValidationService.PositiveAmount(amount)
	if not valid then return false, message end
	if fromUserId == toUserId then return false, "You cannot transfer money to yourself." end
	local sender = Cache.Get(fromUserId)
	local recipient = Cache.Get(toUserId)
	if not sender then return false, "Sender data is not loaded." end
	if not recipient then return false, "Recipient is not online or loaded." end
	if sender.Economy.Balance < amount then return false, "Insufficient balance." end
	return true
end

return ValidationService
