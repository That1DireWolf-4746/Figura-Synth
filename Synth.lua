json = require("json")

local PACKETTIME = 20

local instruments = {}
local line = 1
local songName = ""
local song = nil
local endsong = false
local currentSet = ""
local _nextNote = 0
local pitch = {
["C"] = 261.63/369.99,
["Cs"] = 277.18/369.99,
["D"] = 293.66/369.99,
["Ds"] = 311.13/369.99,
["E"] = 329.63/369.99,
["F"] = 349.23/369.99,
["Fs"] = 369.99/369.99,
["G"] = 392/369.99,
["Gs"] = 415.3/369.99,
["A"] = 440/369.99,
["As"] = 466.16/369.99,
["B"] = 493.88/369.99
}

function events.tick()
	if string.len(songName) > 0 then
		playLine()
	end
end

function play(sn)
	endsong = false
	line = 1
	if host:isHost() then
		songName = sn
		song = json.decode(file:readString("music/" .. songName .. ".json"))
		instruments = song["instruments"]
		pings.sendInstruments(instruments)
		nextSet()
	end
end

function stop()
	endsong = true
	line = 1
	currentLine = {}
end

function clear()
	currentSet = ""
	_nextNote = 0
end

function nextSet()
	local ticker = 0
	local toSend = ""
	while ticker < PACKETTIME do
		local currentLine = song["song"][line]
		line = line + 1
		ticker = ticker + 1
		if song["song"][line] == nil then
			pings.sentCurrentSet(toSend)
			stop()
			return nil
		end
		if currentLine[1] ~= nil then
			toSend = toSend .. ";" .. tostring(ticker - 1) .. "-"
		end
		for _, note in ipairs(currentLine) do
			toSend = toSend .. tostring(note[1]) .. note[2] .. note[3] .. "-"
		end
		
	end
	pings.sentCurrentSet(toSend)
end

function playLine()
	local play = parseTime()
	if play ~= nil then
		local toPlay = parse(play)
		if toPlay ~= nil then
			for _, note in ipairs(toPlay) do
				sounds["block.note_block." .. instruments[note[1]]]:play():setPos(player:getPos() + vec(0, 0.1, 0)):setPitch((pitch[note[2]] * 2^(note[3] - 4)))
			end
		end
	end
	_nextNote = _nextNote + 1
	if _nextNote >= PACKETTIME and not endsong then
		if setLengthBelowLimit() then
			nextSet()
		end
		_nextNote = 0
	end
end

function setLengthBelowLimit()
	local count = 0
	for note in string.gmatch(currentSet, ";") do
		count = count + 1
	end
	return count < 45
end

function parse(pos)
	local toPlayEnd = string.find(currentSet, ";", 2)
	if toPlayEnd == nil then
		toPlayEnd = -1
	end
	local toPlayString = string.sub(currentSet, 1, toPlayEnd)
	local result = {}
	for note in string.gmatch(toPlayString, "%d+%a+%d+%-") do
		if note ~= nil then
			local noteTable = {
				tonumber(string.match(note, "%d+")), 
				string.match(note, "%a+"), 
				tonumber(string.sub(string.match(note, "%d+%-"), 0, -2))
			}
			result[#result + 1] = noteTable 
		end
	end
	currentSet = string.sub(currentSet, toPlayEnd, -1)
	return result
end

function parseTime()
	local nextpos = string.find(currentSet, "%-", 2, false)
	if nextpos == nil then
		nextpos = -1
	end
	local lineNumber = string.sub(currentSet, 2, nextpos - 1)
	if tonumber(lineNumber) ~=nil then
		if _nextNote == tonumber(lineNumber) then
			return lineNumber
		end
	end
	return nil
end

function pings.sendInstruments(list)
	instruments = list
end

function pings.sentCurrentSet(string)
	currentSet = currentSet .. string
	currentSet = string.match(currentSet, ";.*")
end
