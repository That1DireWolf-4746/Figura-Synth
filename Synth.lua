json = require("json")

local instruments = {}
local currentLine = {}
local line = 1
local songName = ""
local song = nil
local endsong = false
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
	if string.len(songName) > 0 and endsong == false then
		nextLine()
	end
end

function play(sn)
	endsong = false
	if host:isHost() then
		songName = sn
		song = json.decode(file:readString("music/" .. songName .. ".json"))
		instruments = song["instruments"]
		line = 1
	end
end

function stop()
	endsong = true
end

local function nextLine()
	if host:isHost() then
		currentLine = song["song"][line]
		pings.playline(instruments, currentLine)
		line = line + 1
		if song["song"][line] == nil then
			stop()
		end
	end
end

local function pings.playline(list, currentline)
	local instruments = list
	for _, note in ipairs(currentline) do
			sounds:playSound("block.note_block." .. instruments[note[1]], player:getPos() + vec(0, 0.1, 0), 1, (pitch[note[2]] * 2^(note[3] - 4)), false)
	end
end
