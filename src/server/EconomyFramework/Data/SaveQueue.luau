--!strict

local queued: {[number]: number} = {}

local SaveQueue = {}

function SaveQueue.Add(userId: number)
	queued[userId] = (queued[userId] or 0) + 1
end

function SaveQueue.Remove(userId: number)
	queued[userId] = nil
end

function SaveQueue.GetVersion(userId: number): number?
	return queued[userId]
end

function SaveQueue.Snapshot(): {[number]: number}
	local result: {[number]: number} = {}
	for userId, version in queued do result[userId] = version end
	return result
end

-- Do not discard a queue entry that was marked dirty again during an async save.
function SaveQueue.MarkSaved(userId: number, savedVersion: number)
	if queued[userId] == savedVersion then queued[userId] = nil end
end

function SaveQueue.ResetForTests()
	table.clear(queued)
end

return SaveQueue
