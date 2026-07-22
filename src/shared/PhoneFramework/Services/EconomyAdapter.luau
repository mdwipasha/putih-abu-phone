--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

export type TransferResult = {
	Success: boolean,
	Code: string?,
	Message: string?,
	Balance: number?,
}

export type Transaction = {
	Id: string,
	Type: string,
	Direction: string,
	Amount: number,
	Description: string,
	Timestamp: number,
	Sender: string,
	Receiver: string,
	Status: string,
}

local EconomyAdapter = {}

local PLACEHOLDER_BALANCE = 0
local PLACEHOLDER_PHONE = "-"
local TIMEOUT_SECONDS = 2

local cachedFolder: Folder? = nil

local function getRemoteFolder(): Folder?
	if cachedFolder and cachedFolder.Parent then
		return cachedFolder
	end

	local network = ReplicatedStorage:FindFirstChild("Network")
	if not network then
		network = ReplicatedStorage:WaitForChild("Network", TIMEOUT_SECONDS)
	end

	if not network then
		return nil
	end

	local economy = network:FindFirstChild("Economy")
	if not economy then
		economy = network:WaitForChild("Economy", TIMEOUT_SECONDS)
	end

	if economy and economy:IsA("Folder") then
		cachedFolder = economy
		return economy
	end

	return nil
end

local function getRemoteFunction(name: string): RemoteFunction?
	local folder = getRemoteFolder()
	if not folder then
		return nil
	end

	local remote = folder:FindFirstChild(name)
	if remote and remote:IsA("RemoteFunction") then
		return remote
	end

	return nil
end

local function getRemoteEvent(name: string): RemoteEvent?
	local folder = getRemoteFolder()
	if not folder then
		return nil
	end

	local remote = folder:FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end

	return nil
end

local function safeInvoke(name: string, ...): any
	local remote = getRemoteFunction(name)
	if not remote then
		return nil
	end

	local success, result = pcall(function(...)
		return remote:InvokeServer(...)
	end, ...)

	if not success then
		warn("[EconomyAdapter]", name, result)
		return nil
	end

	return result
end

local function cleanString(value: any, fallback: string): string
	if typeof(value) == "string" and value ~= "" then
		return value
	end

	return fallback
end

local function normalizeTransaction(raw: any): Transaction?
	if typeof(raw) ~= "table" then
		return nil
	end

	local amount = tonumber(raw.Amount) or 0
	return {
		Id = cleanString(raw.Id, "-"),
		Type = string.upper(cleanString(raw.Type, "TRANSFER")),
		Direction = string.upper(cleanString(raw.Direction, "NEUTRAL")),
		Amount = amount,
		Description = cleanString(raw.Description, "-"),
		Timestamp = tonumber(raw.Timestamp) or 0,
		Sender = cleanString(raw.Sender, "Unknown"),
		Receiver = cleanString(raw.Receiver, "Unknown"),
		Status = cleanString(raw.Status, "Completed"),
	}
end

function EconomyAdapter.GetBalance(): number
	local balance = safeInvoke("GetBalance")
	if typeof(balance) ~= "number" then
		return PLACEHOLDER_BALANCE
	end

	return balance
end

function EconomyAdapter.GetPhoneNumber(): string
	return cleanString(safeInvoke("GetPhoneNumber"), PLACEHOLDER_PHONE)
end

function EconomyAdapter.GetPlayerData(): {[string]: any}
	local data = safeInvoke("GetPlayerData")
	if typeof(data) ~= "table" then
		return {
			Balance = PLACEHOLDER_BALANCE,
			PhoneNumber = PLACEHOLDER_PHONE,
			PlayerName = "Unknown",
			Transactions = {},
			Loaded = false,
		}
	end

	return {
		Balance = if typeof(data.Balance) == "number" then data.Balance else PLACEHOLDER_BALANCE,
		PhoneNumber = cleanString(data.PhoneNumber, PLACEHOLDER_PHONE),
		PlayerName = cleanString(data.PlayerName, "Unknown"),
		Transactions = data.Transactions or {},
		Loaded = data.Loaded == true,
	}
end

function EconomyAdapter.GetTransactionHistory(): {Transaction}
	local history = safeInvoke("GetTransactionHistory")
	if typeof(history) ~= "table" then
		return {}
	end

	local normalized = {}
	for _, transaction in ipairs(history) do
		local item = normalizeTransaction(transaction)
		if item then
			table.insert(normalized, item)
		end
	end

	table.sort(normalized, function(left, right)
		return left.Timestamp > right.Timestamp
	end)

	return normalized
end

function EconomyAdapter.Transfer(phoneNumber: string, amount: number, description: string?): TransferResult
	local result = safeInvoke("TransferByPhone", phoneNumber, amount, description)
	if typeof(result) ~= "table" then
		return {
			Success = false,
			Code = "NETWORK_ERROR",
			Message = "Unable to contact the bank service.",
		}
	end

	return {
		Success = result.Success == true,
		Code = cleanString(result.Code, if result.Success == true then "OK" else "TRANSFER_FAILED"),
		Message = cleanString(result.Message, if result.Success == true then "Transfer complete." else "Transfer failed."),
		Balance = if typeof(result.Balance) == "number" then result.Balance else nil,
	}
end

function EconomyAdapter.OnBalanceChanged(callback: (number) -> ()): RBXScriptConnection?
	local event = getRemoteEvent("BalanceChanged")
	if not event then
		return nil
	end

	return event.OnClientEvent:Connect(function(balance: any)
		callback(if typeof(balance) == "number" then balance else PLACEHOLDER_BALANCE)
	end)
end

function EconomyAdapter.OnTransactionCreated(callback: (Transaction?) -> ()): RBXScriptConnection?
	local event = getRemoteEvent("TransactionCreated")
	if not event then
		return nil
	end

	return event.OnClientEvent:Connect(function(transaction: any)
		callback(normalizeTransaction(transaction))
	end)
end

function EconomyAdapter.OnPlayerDataLoaded(callback: () -> ()): RBXScriptConnection?
	local event = getRemoteEvent("PlayerDataLoaded")
	if not event then
		return nil
	end

	return event.OnClientEvent:Connect(function()
		callback()
	end)
end

return EconomyAdapter
