--Simple Audio library made by Lsupergame :)

_G.simpleAudio = {} -- Make script a global table 
local self = _G.simpleAudio -- Make a local "copy" with the name "self" to type less shit


function self.init() -- an init function thats loaded at the start
require('simpleAudio.errorHandling') -- requires the error handling script
self.allSongs = {} -- this stores the songs
self.songCount = 0 -- this stores the number of songs, since adding songs with "self.allSongs[name] = love.audio.newSource( file, songType )" doesnt increase #self.allSongs

self.allsfx = {} -- all sfx
self.sfxCount = 0 -- the number of sfx (kinda obsolete)


local doTransition = false -- flags if to do a transition
local doManualLoop = false -- flags if to do a manual loop
end



local function add(name, file, songType) -- the local function to add a song.
    self.songCount = self.songCount + 1
    self.allSongs[name] = love.audio.newSource( file, songType ) -- stores song with name (a string) as index (i learned it :3)
    local song = self.allSongs[name] -- makes song a local variable bc its easier
    love.audio.play(song) -- plays the song
end



local function transition(newSong) -- the function that starts a transition
doTransition = true
newsong = newSong
end


local function transitionUpdate(dt) -- the function that actually does the transition
if doTransition then
    for i, song in pairs(self.allSongs) do -- im pretty sure (are you sure) that this need to be a loop, if there's multiple songs
        if i ~= newsong then 
            self.allSongs[i]:setVolume(self.allSongs[i]:getVolume() - (dt / 2))
                if self.allSongs[i]:getVolume() <= 0.01 then -- if the other songs's volume is less than 0.01, remove them
                    self.removeSong(i)
                end
            else
                self.allSongs[i]:setVolume(self.allSongs[i]:getVolume() + (dt / 2)) -- increase the new song's volume
            end
        end
    end
end



local function manualLoop(songName, loopStart, loopEnd) -- function that starts a manual loop
doManualLoop = true
loopsong = songName
loopstart = loopStart
loopend = loopEnd
end

 
local function manualLoopUpdate() -- function that does the manual loop
if doManualLoop then
    if self.allSongs[loopsong]:tell("seconds") >= loopend then 
        self.allSongs[loopsong]:seek(loopstart, "seconds")
    end
end

end



function self.addSong(name, file, songType, addType, startPoint) -- function to add a song
errorHandling.addSongError(name, file, songType, addType) -- function from error handling script, to check stuff

if self.songCount < 1 then 
    add(name, file, songType)
else
    if addType == 'replace' then -- replaces a song
        for i, song in pairs(self.allSongs) do
            self.removeSong(i)
        end
            add(name, file, songType)
                elseif addType == 'mesh' then -- makes multiple songs play at the same time (doesnt work with manual loops, meaning only the most recent song with manual loop will be looped)
                    add(name, file, songType)
                elseif addType == 'transition' then -- does a smooth transition (not really lol) and then replace the song
                    add(name, file, songType)
                    self.allSongs[name]:setVolume(0)
                    transition(name)
                end    
            end
if startPoint then -- starts song from specific time mark
    self.allSongs[name]:seek(startPoint)
end

end



function self.setSongLoop(name, loopType, loopStart, loopEnd) -- function to set a song's loop
errorHandling.setSongLoopError(name, loopType, loopStart, loopEnd) -- error handling

if loopType == 'auto' then -- if auto its the basic loop
    self.allSongs[name]:setLooping(true)
elseif loopType == 'manual' then -- if its manual, you can set start and end point
    manualLoop(name, loopStart, loopEnd)
end

end



function self.setSongEffects(songname, effects, pitch) -- sets effects to a song
errorHandling.setSongEffectsError(songname, effects, pitch) -- error handling

    for i, effect in pairs(effects) do 
        love.audio.setEffect(effect, {type = effect})
        self.allSongs[songname]:setEffect(effect) -- doesnt allow user to control settings of effect. should be fine.
    end

if pitch then
    self.allSongs[songname]:setPitch(pitch) -- pitch
end

end



function self.setSongVolume(songname, volume) -- sets the volume of a song
errorHandling.setSongVolumeError(songname, volume) -- error handling

self.allSongs[songname]:setVolume(volume)
end


function self.getSongPosition(songname) -- returns the position of the song
errorHandling.getSongPositionError(songname) -- error handling

return self.allSongs[songname]:tell("seconds")
end



function self.removeSong(name) -- removes a song
errorHandling.removeSongError(name) -- error handling

    if self.allSongs[name] then
        -- If the song is a manual loop song, disable manual loop
        if name == loopsong then
            doManualLoop = false
            loopsong = nil
        end

        -- Stop and remove song
        self.allSongs[name]:stop() -- if you dont stop, it just keeps playing somehow
        self.allSongs[name] = nil -- set it to nil to delete it
        self.songCount = self.songCount - 1 -- lower the song count
    end
end


function self.playsfx(name, file, volume, effects, pitch) -- plays a sound effect
errorHandling.playsfxError(name, file, volume, effects, pitch) -- error handling

-- add sfx
self.allsfx[name] = love.audio.newSource( file, "static" )
love.audio.play(self.allsfx[name])

-- Volume stuff
self.allsfx[name]:setVolume(volume)

-- Effects stuff
for i, effect in pairs(effects) do 
    love.audio.setEffect(effect, {type = effect})
    self.allsfx[name]:setEffect(effect) -- doesnt allow user to control settings of effect. should be fine.
end

-- set pitch
if pitch then
    self.allsfx[name]:setPitch(pitch)
else
    self.allsfx[name]:setPitch(1)
end

end

local function checkActiveSongs() -- checks if songs are active
if self.songCount > 0 then
    for i, song in pairs(self.allSongs) do --this is a loop incase there are multiple songs
        if not self.allSongs[i]:isPlaying() then -- if the song isnt playing, remove it
            self.removeSong(i)
        end
    end
end
end



function self.update(dt) -- update logic
checkActiveSongs()
transitionUpdate(dt)
manualLoopUpdate()
end


return simpleAudio -- returns the script