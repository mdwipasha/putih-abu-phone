local Signal = {}
Signal.__index = Signal

export type Signal = typeof(setmetatable(
	{} :: {
		_bindings: { (...any) -> () },
	},
	Signal
))

function Signal.new(): Signal
	return setmetatable({
		_bindings = {},
	}, Signal)
end

function Signal:Connect(callback: (...any) -> ())
	table.insert(self._bindings, callback)

	local disconnected = false
	return {
		Disconnect = function()
			if disconnected then
				return
			end

			disconnected = true
			local index = table.find(self._bindings, callback)
			if index then
				table.remove(self._bindings, index)
			end
		end,
	}
end

function Signal:Fire(...: any)
	for _, callback in ipairs(table.clone(self._bindings)) do
		callback(...)
	end
end

function Signal:Destroy()
	table.clear(self._bindings)
end

return Signal
