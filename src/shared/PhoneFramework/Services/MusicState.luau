-- MusicState.luau
-- Singleton shared state antara Music app dan LockScreen widget.
-- Music app menulis ke sini, LockScreen subscribe lewat event Changed.

local MusicState = {}
MusicState.__index = MusicState

-- ── Singleton instance ────────────────────────────────────────────────────
local _instance = nil

function MusicState.get()
	if _instance then return _instance end

	local changed = Instance.new("BindableEvent")

	local self = setmetatable({
		-- State publik (dibaca LockScreen)
		Song       = nil,    -- tabel { Title, Artist, Cover, SoundId, ... }
		IsPlaying  = false,
		Position   = 0,      -- detik playback saat ini
		Duration   = 0,      -- durasi total detik

		-- Callbacks (didaftarkan Music app, dipanggil LockScreen widget)
		-- { Pause, Resume, Prev, Next } — masing-masing fungsi tanpa argumen
		_callbacks = nil,

		-- Event — fire setiap kali Update() dipanggil dengan nilai berubah
		Changed    = changed.Event,
		_bindable  = changed,
	}, MusicState)

	_instance = self
	return self
end

-- Tulis state & fire event (dipanggil dari Music app setiap Heartbeat)
function MusicState:Update(fields: {[string]: any})
	local anyChanged = false
	for k, v in pairs(fields) do
		if self[k] ~= v then
			self[k] = v
			anyChanged = true
		end
	end
	if anyChanged then
		self._bindable:Fire()
	end
end

return MusicState
