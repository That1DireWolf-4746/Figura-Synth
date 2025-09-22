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

function events.chat_send_message(msg)
	local playCommand = (string.find(msg, ".play ", 1))
	local localPlayCommand = (string.find(msg, ".localplay ", 1))
	if playCommand ~= nil then
		if playCommand == 1 then
			play(string.sub(msg, 7, -1))
			return nil
		end
	end
	if localPlayCommand ~= nil then
		if localPlayCommand == 1 then
			playLocal(string.sub(msg, 12, -1))
			return nil
		end
	end
	local stopCommand = (string.find(msg, ".stop", 1))
	if stopCommand ~= nil then
		if stopCommand == 1 then
			stop()
			clear()
			return nil
		end
	end
	return msg
end

function try( err )
	if host:isHost() then
   		print( "Invalid JSON file:", err )
   	end
	stop()
	clear()
	return nil
end

function readFile()
	song = json.decode(file:readString("music/" .. songName .. ".json"))
end

function play(sn)
	endsong = false
	line = 1
	if host:isHost() then
		if file:isFile("music/" .. sn .. ".json") then
			songName = sn
			xpcall(readFile, try)
			if song == nil then
				return nil
			end
			instruments = song["instruments"]
			pings.sendInstruments(instruments)
			nextSet(true)
		else
			print("File Not Found!")
			stop()
		end
	end
end


function playLocal(sn)
	endsong = false
	line = 1
	if host:isHost() then
		if file:isFile("music/" .. sn .. ".json") then
			songName = sn
			xpcall(readFile, try)
			if song == nil then
				return nil
			end
			instruments = song["instruments"]
			if song ~= nil then
				nextSet(false)
			end
		else
			print("File Not Found!")
			stop()
		end
	end
end

function stop()
	endsong = true
	song = nil
	songName = ""
	line = 1
	currentLine = {}
end

function clear()
	currentSet = ""
	_nextNote = 0
end

function nextSet(localplay)
	local ticker = 0
	local toSend = ""
	while ticker < PACKETTIME do
		local currentLine = song["song"][line]
		line = line + 1
		ticker = ticker + 1
		if currentLine ~= nil and not endsong then
			if currentLine[1] == "END" then
				toSend = toSend .. "|"
				break
			end
			toSend = toSend .. ";" .. tostring(ticker - 1) .. "-"
			for _, note in ipairs(currentLine) do
				toSend = toSend .. tostring(note[1]) .. note[2] .. note[3] .. "-"
			end
		end
		
	end
	if not localplay then
		pings.sentCurrentSet(toSend)
	else
		if host:isHost() then
			currentSet = toSend
		end
	end
end

function playLine()
	local toPlay = parse()
	if toPlay ~= nil then
		for _, note in ipairs(toPlay) do
			sounds["block.note_block." .. instruments[note[1]]]:play()
					:setPos(player:getPos() + vec(0, 1, 0))
					:setPitch((pitch[note[2]] * 2^(note[3] - 4)))
		end
	end
	_nextNote = _nextNote + 1
	if _nextNote >= PACKETTIME then
		if setLengthBelowLimit() and not endsong then
			nextSet()
		end
		_nextNote = 0
	end
end

function setLengthBelowLimit()
	local count = 0
	if currentSet == nil then
		return false
	end
	for note in string.gmatch(currentSet, "[;|]") do
		count = count + 1
	end
	return count < 45
end

function parse()
	if currentSet == nil then
		return nil
	end
	local endOfFileLocation = string.find(currentSet, "|", 1)
	if  endOfFileLocation ~= nil then
		if endOfFileLocation <= 3 then
			if host:isHost() then
				print("End of playback")
				stop()
				clear()
			end
			return nil
		end
	end
	local nextpos = string.find(currentSet, ";", 2)
	if nextpos == nil then
		nextpos = -1
	end
	local endOfIndex = string.find(currentSet, "%-", 2)
	if endOfIndex == nil then
		endOfIndex = 0
	end
	local lineNumber = string.sub(currentSet, 2, endOfIndex - 1)
	if lineNumber == nil then
		lineNumber = "0"
	end
	if _nextNote == tonumber(lineNumber) then
		local toPlayString = string.sub(currentSet, 1, nextpos)
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
		currentSet = string.sub(currentSet, nextpos, -1)
		return result
	end
	return nil
end

function pings.sendInstruments(list)
	instruments = list
end

function pings.sentCurrentSet(string)
	if currentSet == nil then
		currentSet = ""
	end
	if string ~= nil then
		currentSet = currentSet .. string
	end
	currentSet = string.match(currentSet, ";.*")
end
