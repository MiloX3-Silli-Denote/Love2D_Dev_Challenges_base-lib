--Error Handling script for the Simple Audio library made by Lsupergame :)

_G.errorHandling = {} -- Make script a global table 
local self = _G.errorHandling -- Make a local "copy" with the name "self" to type less shit

function self.addSongError(name, file, songType, addType) -- the error handling for the "addSong" function
assert(type(name) == 'string', "Song name is not a string") -- checks name
assert(type(file) == 'string', "file path is not a string") -- checks file
assert(love.filesystem.getInfo(file), "file path is not a valid path") -- checks file path
assert(type(songType) == 'string', "song type is not a string") -- checks song type
assert(type(addType) == 'string', "add type is is not a string") -- checks add type
assert(addType == "replace" or addType == "mesh" or addType == "transition" , "add type is neither replace, mesh, or transition") -- checks add type
assert(simpleAudio.allSongs[name] == nil, "Song is already added. Song name: " .. name) -- checks if song is a clone
end



function self.removeSongError(name) -- the error handling for the "removeSong" function
assert(type(name) == 'string', "Song name is not a string")
end


function self.setSongLoopError(name, loopType, loopStart, loopEnd) -- the error handling for the "setSongLoop" function
assert(type(name) == 'string', "Song name is not a string")
assert(simpleAudio.allSongs[name], "Song does not exist") -- checks if song exists
assert(loopType and type(loopType) == 'string', "loop type is is not a string") -- checks the loop variables
assert(loopType == "auto" or loopType == "manual", "loop type is neither auto or manual")
assert(loopType ~= 'manual' or type(loopStart) == 'number', "loop start is not a number")
assert(loopType ~= 'manual' or type(loopEnd) == 'number', "loop end is not a number")
assert(loopType ~= 'manual' or loopStart > 0, "loop start is less than 0")
assert(loopType ~= 'manual' or loopEnd > 0, "loop end is less than 0")
end



function self.setSongEffectsError(songname, effects, pitch) -- the error handling for the "setSongEffects" function
assert(type(songname) == 'string', "Song name is not a string")
assert(simpleAudio.allSongs[songname], "Song does not exist")
assert(not pitch or type(pitch) == 'number', "pitch is not a number")
end

function self.setSongVolumeError(songname, volume) -- the error handling for the "setSongVolume" function
assert(type(songname) == 'string', "Song name is not a string")
assert(simpleAudio.allSongs[songname], "Song does not exist")
assert(type(volume) == 'number', "volume is not a number")
end

function self.getSongPositionError(songname) -- the error handling for the "getSongPosition" function
assert(type(songname) == 'string', "Song name is not a string")
assert(simpleAudio.allSongs[songname], "Song does not exist")
end




function self.playsfxError(name, file, volume, effects, pitch) -- the error handling for the "playsfx" function
assert(type(name) == 'string', "sfx name is not a string")
assert(love.filesystem.getInfo(file), "file path is not a valid path")
assert(type(volume) == 'number', "volume is not a number")
assert(not pitch or type(pitch) == 'number', "pitch is not a number")
end



return errorHandling -- returns the script