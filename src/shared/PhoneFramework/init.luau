local PhoneController = require(script:WaitForChild("Core"):WaitForChild("PhoneController"))

local PhoneFramework = {}
PhoneFramework.__index = PhoneFramework

local activePhone = nil

function PhoneFramework.Start()
	if activePhone then
		return activePhone
	end

	activePhone = PhoneController.new()
	return activePhone
end

function PhoneFramework.Get()
	return activePhone
end

return PhoneFramework
