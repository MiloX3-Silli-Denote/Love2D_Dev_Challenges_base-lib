--Simple Audio library made by Lsupergame :)

-- TODO: ensure structure functions appropriately without unecessary actions
-- TODO: correct system info and song accounting
-- TODO: correct song playing time and direction of values

local path = (...); -- what directory is this library in?

_G.SimpleAudio = {} -- Make library global
local self = SimpleAudio -- for readability

local errorHandling = require(path .. ".errorHandling") -- requires the error handling script

function SimpleAudio.init() -- an init function thats loaded at the start
    self.allSongs = {} -- stores the songs
    self.songCount = 0 -- stores the number of songs since the len of a table isnt affected by the num of keys it has

    self.allsfx = {} -- all sfx

    self.doTransition = false -- flags if trying to do a transition
    self.doManualLoop = false -- flags if trying to do a manual loop

    -- keep all self. vars in .init()
    self.newSong   = nil;
    self.loopsong  = nil;
    self.loopstart = nil;
    self.loopend   = nil;

    self.lowestVolume = 0.01; -- lowest allowed volume
end

function SimpleAudio.insertSong(name, file, songType)
    self.songCount = self.songCount + 1;

    local song = love.audio.newSource(file, songType);

    self.allSongs[name] = song; -- stores song with a key (i learned it :3)

    --! do we rly want to play it immediately?
    love.audio.play(song); -- plays the song
end

function SimpleAudio.transitionUpdate(dt) -- the function that actually does the transition
    if not self.doTransition then -- never nester ;3
        return;
    end

    local halfDT = dt / 2;

    for k, song in pairs(self.allSongs) do -- im pretty sure (are you sure) that this need to be a loop, if there's multiple songs
        if k ~= self.newsong then
            song:setVolume(song:getVolume() - halfDT);

            -- if the other songs's volume is less than the lowest allowed volume, remove them
            if song:getVolume() <= self.lowestVolume then
                self.removeSong(k);
            end
        else
            song:setVolume(song:getVolume() + halfDT); -- increase the new song's volume
        end
    end
end
 
function SimpleAudio.manualLoopUpdate() -- function that does the manual loop
    if not self.doManualLoop then -- never nester ;3
        return;
    end

    if self.allSongs[self.loopsong]:tell("seconds") >= self.loopend then
        self.allSongs[self.loopsong]:seek(self.loopstart, "seconds")
    end
end

function SimpleAudio.addSong(name, file, songType, addType, startPoint) -- function to add a song
    errorHandling.addSongError(name, file, songType, addType) -- function from error handling script, to check stuff

    if self.songCount < 1 then
        self.insertSong(name, file, songType)
    else
        if addType == 'replace' then -- replaces a song
            for k, song in pairs(self.allSongs) do
                self.removeSong(k);
            end

            self.insertSong(name, file, songType)
        elseif addType == 'mesh' then -- makes multiple songs play at the same time (doesnt work with manual loops, meaning only the most recent song with manual loop will be looped)
            self.insertSong(name, file, songType)
        elseif addType == 'transition' then -- does a smooth transition (not really lol) and then replace the song
            self.insertSong(name, file, songType)

            self.allSongs[name]:setVolume(0)

            -- transition between songs
            self.doTransition = true;
            self.newsong = name;
        end
    end

    if startPoint then -- starts song from specific time mark
        self.allSongs[name]:seek(startPoint)
    end
end

function SimpleAudio.setSongLoop(name, loopType, loopStart, loopEnd) -- function to set a song's loop
    errorHandling.setSongLoopError(name, loopType, loopStart, loopEnd) -- error handling

    if loopType == 'auto' then -- if auto its the basic loop
        self.allSongs[name]:setLooping(true)
    elseif loopType == 'manual' then -- if its manual, you can set start and end point
        -- manually loop song
        self.doManualLoop = true
        self.loopsong = name
        self.loopstart = loopStart
        self.loopend = loopEnd
    end
end

function SimpleAudio.setSongEffects(songname, effects, pitch) -- sets effects to a song
    errorHandling.setSongEffectsError(songname, effects, pitch) -- error handling

    for _, effect in pairs(effects) do
        love.audio.setEffect(effect, {type = effect})
        self.allSongs[songname]:setEffect(effect) -- doesnt allow user to control settings of effect. should be fine.
    end

    if pitch then
        self.allSongs[songname]:setPitch(pitch) -- pitch
    end
end

function SimpleAudio.setSongVolume(songname, volume) -- sets the volume of a song
    errorHandling.setSongVolumeError(songname, volume) -- error handling

    self.allSongs[songname]:setVolume(volume)
end

function SimpleAudio.getSongPosition(songname) -- returns the position of the song
    errorHandling.getSongPositionError(songname) -- error handling

    return self.allSongs[songname]:tell("seconds")
end

function SimpleAudio.removeSong(name) -- removes a song
    errorHandling.removeSongError(name) -- error handling

    if not self.allSongs[name] then -- never nester
        return;
    end

    -- If the song is a manual loop song, disable manual loop
    if name == self.loopsong then
        self.doManualLoop = false
        self.loopsong = nil
    end

    -- Stop and remove song
    self.allSongs[name]:stop() -- if you dont stop, it just keeps playing somehow
    self.allSongs[name] = nil -- set it to nil to delete it
    self.songCount = self.songCount - 1 -- lower the song count
end

function SimpleAudio.playsfx(name, file, volume, effects, pitch) -- plays a sound effect
    pitch = pitch or 1;
    volume = volume or 1;

    errorHandling.playsfxError(name, file, volume, effects, pitch) -- error handling

    -- add sfx
    self.allsfx[name] = love.audio.newSource(file, "static");
    love.audio.play(self.allsfx[name])

    -- Volume stuff
    self.allsfx[name]:setVolume(volume)

    -- Effects stuff
    for k, effect in pairs(effects) do
        effect.type = effect.type or k;

        love.audio.setEffect(k, effect);
        self.allsfx[name]:setEffect(k);
    end

    -- set pitch
    self.allsfx[name]:setPitch(pitch);
end

function SimpleAudio.checkActiveSongs() -- checks if songs are active
    if self.songCount <= 0 then -- never nester ;3
        return;
    end

    for k, song in pairs(self.allSongs) do --this is a loop incase there are multiple songs
        if not song:isPlaying() then -- if the song isnt playing, remove it
            self.removeSong(k);
        end
    end
end

function SimpleAudio.update(dt) -- update logic
    self.checkActiveSongs()
    self.transitionUpdate(dt)
    self.manualLoopUpdate()
end

return SimpleAudio -- returns the script