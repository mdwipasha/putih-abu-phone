--!strict

local profiles: {[number]: {[string]: any}} = {}
local phoneOwners: {[string]: number} = {}

local Cache = {}

function Cache.Set(userId: number, data: {[string]: any})
	profiles[userId] = data
	phoneOwners[data.Phone.Number] = userId
end

function Cache.Get(userId: number): {[string]: any}?
	return profiles[userId]
end

function Cache.GetUserIdByPhone(phoneNumber: string): number?
	return phoneOwners[phoneNumber]
end

function Cache.Remove(userId: number)
	local data = profiles[userId]
	if data then phoneOwners[data.Phone.Number] = nil end
	profiles[userId] = nil
end

function Cache.ResetForTests()
	table.clear(profiles)
	table.clear(phoneOwners)
end

return Cache
