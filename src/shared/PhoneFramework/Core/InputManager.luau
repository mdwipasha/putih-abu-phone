local UserInputService = game:GetService("UserInputService")

local Constants = require(script.Parent.Parent.Shared.Constants)

local InputManager = {}
InputManager.__index = InputManager

function InputManager.new(phone: any)
	local self = setmetatable({
		_phone = phone,
		_connections = {},
	}, InputManager)

	table.insert(
		self._connections,
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end

			if input.KeyCode == Constants.Input.ToggleKey then
				if phone:IsOpened() then
					phone:Close()
				else
					phone:Open()
				end
			elseif input.KeyCode == Constants.Input.CloseKey and phone:IsOpened() then
				phone:Close()
			end
		end)
	)

	return self
end

function InputManager:Destroy()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
end

return InputManager
