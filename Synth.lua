json = require("json")

local PACKETTIME = 20

local instruments = {}
local currentLine = {}
local line = 1
local songName = ""
local song = nil
local endsong = false
local currentSet = ""
local _endtime = 2
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
	currentSet = ""
	if host:isHost() then
		songName = sn
		song = json.decode(file:readString("music/" .. songName .. ".json"))
		instruments = song["instruments"]
		pings.sendInstruments(instruments)
		nextSet()
	end
end

function play(sn, pingtime)
	endsong = false
	PACKETTIME = pingtime
	currentSet = ""
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
	currentSet = ""
	_nextNote = 0
	currentLine = {}
end

function nextSet()
	local ticker = 0
	local toSend = ""
	while ticker < PACKETTIME do
		currentLine = song["song"][line]
		line = line + 1
		ticker = ticker + 1
		if song["song"][line] == nil then
			stop()
			break
		end
		if currentLine[1] ~= nil then
			toSend = toSend .. ";" .. tostring(ticker - 1) .. "-"
		end
		for _, note in ipairs(currentLine) do
			toSend = toSend .. tostring(note[1]) .. note[2] .. note[3] .. "-"
		end
		
	end
	pings.sentCurrentSet(toSend)
	ticker = 0
end

function playLine()
	local play = parseTime()
	if play ~= nil then
		local toPlay = parse(play)
		if toPlay ~= nil then
			for _, note in ipairs(toPlay) do
				if note ~= nil then
					sounds:playSound("block.note_block." .. instruments[note[1]], player:getPos() + vec(0, 0.1, 0), 1, (pitch[note[2]] * 2^(note[3] - 4)), false)
				end
			end
		end
	end
	_nextNote = _nextNote + 1
	if _nextNote >= PACKETTIME and not endsong then
		nextSet()
		_nextNote = 0
		_endtime = 2
		_endpos = 1
	end
end

function parse(pos)
	local toPlayStart = string.find(currentSet, ";" .. pos)
	if toPlayStart == nil then
		toPlayStart = -1
	end
	local toPlayEnd = string.find(currentSet, ";", toPlayStart + 1)
	if toPlayEnd == nil then
		toPlayEnd = -1
	end
	local toPlayString = string.sub(currentSet, toPlayStart, toPlayEnd)
	local result = {}
	for note in string.gmatch(toPlayString, "%-%d+%a+%d+%-") do
		if note ~= nil then
			local noteTable = {
				tonumber(string.match(note, "%d+")), 
				string.match(note, "%a+"), 
				tonumber(string.sub(string.match(note, "%d+%-"), 0, -2))
			}
			result[#result + 1] = noteTable 
		end
	end
	return result
end

function parseTime()
	local startpos = _endtime
	local nextpos = string.find(currentSet, ";", startpos + 1, false)
	if nextpos == nil then
		nextpos = -1
	end
	local toPlayString = string.sub(currentSet, startpos, nextpos)
	local lineNumber = string.match(toPlayString, "%d+")
	if tonumber(lineNumber) ~=nil then
		if _nextNote == tonumber(lineNumber) then
			_endtime = nextpos + 1
			return lineNumber
		end
	end
	return nil
end

function pings.sendInstruments(list)
	instruments = list
end

function pings.sentCurrentSet(string)
	currentSet = string
end
