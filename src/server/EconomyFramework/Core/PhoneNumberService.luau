--!strict

local Cache = require(script.Parent.Parent.Data.Cache)

local PhoneNumberService = {}

function PhoneNumberService.Get(userId: number): string?
	local data = Cache.Get(userId)
	return if data then data.Phone.Number else nil
end

-- Phone identity is available for players whose profile is currently loaded.
function PhoneNumberService.FindUserId(phoneNumber: string): number?
	if type(phoneNumber) ~= "string" then return nil end
	return Cache.GetUserIdByPhone(phoneNumber)
end

return PhoneNumberService
