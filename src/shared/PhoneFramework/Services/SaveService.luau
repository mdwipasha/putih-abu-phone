local SaveService = {}
SaveService.__index = SaveService

function SaveService.new()
	return setmetatable({
		_values = {},
	}, SaveService)
end

function SaveService:Set(key: string, value: any)
	self._values[key] = value
end

function SaveService:Get(key: string, defaultValue: any?)
	local value = self._values[key]
	if value == nil then
		return defaultValue
	end
	return value
end

return SaveService
