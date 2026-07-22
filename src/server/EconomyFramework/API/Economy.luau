--!strict
-- Public server API. Do not require modules outside this folder from game systems.

local DataManager = require(script.Parent.Parent.Data.DataManager)
local Cache = require(script.Parent.Parent.Data.Cache)
local EconomyService = require(script.Parent.Parent.Core.EconomyService)
local PhoneNumberService = require(script.Parent.Parent.Core.PhoneNumberService)
local ValidationService = require(script.Parent.Parent.Core.ValidationService)
local Signals = require(script.Parent.Parent.Events.Signals)
local TransactionType = require(script.Parent.Parent.Types.TransactionType)

local initialized = false
local Economy = {}

local function userIdOf(playerOrUserId: Player | number): number
	return if type(playerOrUserId) == "number" then playerOrUserId else playerOrUserId.UserId
end

--- Starts loading players, autosave, leave-save, and shutdown-save. Safe to call more than once.
function Economy.Init()
	if initialized then return end
	initialized = true
	DataManager.Init()
end

--- Returns the cached player profile. Treat this result as read-only outside framework extensions.
function Economy.GetPlayerData(playerOrUserId: Player | number): {[string]: any}?
	return Cache.Get(userIdOf(playerOrUserId))
end

function Economy.GetBalance(playerOrUserId: Player | number): number?
	return EconomyService.GetBalance(userIdOf(playerOrUserId))
end

function Economy.CanAfford(playerOrUserId: Player | number, amount: number): boolean
	return EconomyService.CanAfford(userIdOf(playerOrUserId), amount)
end

function Economy.AddMoney(playerOrUserId: Player | number, amount: number, transactionType: string?, description: string?): (boolean, string?)
	return EconomyService.AddMoney(userIdOf(playerOrUserId), amount, transactionType, description)
end

function Economy.RemoveMoney(playerOrUserId: Player | number, amount: number, transactionType: string?, description: string?): (boolean, string?)
	return EconomyService.RemoveMoney(userIdOf(playerOrUserId), amount, transactionType, description)
end

function Economy.SetBalance(playerOrUserId: Player | number, amount: number, description: string?): (boolean, string?)
	return EconomyService.SetBalance(userIdOf(playerOrUserId), amount, description)
end

function Economy.Transfer(sender: Player | number, recipient: Player | number, amount: number, description: string?): (boolean, string?)
	return EconomyService.Transfer(userIdOf(sender), userIdOf(recipient), amount, description)
end

--- Transfers to a currently loaded player found by their permanent phone number.
function Economy.TransferByPhone(sender: Player | number, phoneNumber: string, amount: number, description: string?): (boolean, string?)
	local recipientId = PhoneNumberService.FindUserId(phoneNumber)
	if not recipientId then return false, "Phone number was not found among loaded players." end
	return EconomyService.Transfer(userIdOf(sender), recipientId, amount, description)
end

function Economy.GetPhoneNumber(playerOrUserId: Player | number): string?
	return PhoneNumberService.Get(userIdOf(playerOrUserId))
end

function Economy.FindPlayerByPhone(phoneNumber: string): Player?
	local userId = PhoneNumberService.FindUserId(phoneNumber)
	return if userId then game:GetService("Players"):GetPlayerByUserId(userId) else nil
end

function Economy.GetTransactionHistory(playerOrUserId: Player | number): {any}?
	local data = Cache.Get(userIdOf(playerOrUserId))
	return if data then data.Economy.Transactions else nil
end

function Economy.SavePlayer(playerOrUserId: Player | number): (boolean, string?)
	return DataManager.SaveUserId(userIdOf(playerOrUserId))
end

function Economy.LoadPlayer(player: Player): (boolean, string?)
	return DataManager.LoadPlayer(player)
end

Economy.Events = Signals
Economy.TransactionType = TransactionType
Economy.ValidateAmount = ValidationService.PositiveAmount

return table.freeze(Economy)
