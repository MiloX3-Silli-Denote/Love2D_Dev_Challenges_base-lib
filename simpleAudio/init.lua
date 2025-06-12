--Simple Audio library made by Lsupergame :)

_G.SimpleAudio = {} -- Make library global
local self = SimpleAudio -- for readability

function SimpleAudio.init() -- an init function thats loaded at the start
    self.loadedSongs = {}; -- keyed list of all song sources
    self.loadedSfx   = {}; -- keyed list of all loaded sfx sources

    self.activeSongs = {}; -- indexed list of keys to self.loadedSongs

    self.clonedSfx = {}; -- indexed list of sfx clones
end

function SimpleAudio.loadSong(name, filename)
    assert(type(name) == "string", "cannot load audio to an invalid name: " .. type(name));
    assert(type(filename) == "string", "tried to load an audio with an invalid type as the filename: " .. type(filename));
    assert(self.loadedSongs[name] == nil, "tried to load sound into a name that is already in use: " .. name);
    assert(string.match(filename, "^audio"), "tried to load an audio that is not contained in the 'audio' directory, this is bad practice: " .. filename);

    -- trying to make a source w/ an invalid filename will error anyways so i wont do an assert for it
    self.loadedSongs[name] = love.audio.newSource(filename, "stream");
end

function SimpleAudio.loadSfx(name, filename)
    assert(type(name) == "string", "cannot load audio to an invalid name: " .. type(name));
    assert(type(filename) == "string", "tried to load an audio with an invalid type as the filename: " .. type(filename));
    assert(self.loadedSfx[name] == nil, "tried to load sound into a name that is already in use: " .. name);
    assert(string.match(filename, "^audio"), "tried to load an audio that is not contained in the 'audio' directory, this is bad practice: " .. filename);

    -- trying to make a source w/ an invalid filename will error anyways so i wont do an assert for it
    self.loadedSfx[name] = love.audio.newSource(filename, "static");
end

function SimpleAudio.unloadSong(name)
    assert(type(name) == "string", "song name is not a string: " .. type(name));
    assert(self.loadedSongs[name], "tried to unload a song that does not exist: " .. name);

    for i = #self.activeSongs, 1, -1 do
        if self.activeSongs[i] == name then
            table.remove(self.activeSongs, i);
        end
    end

    self.loadedSongs[name]:stop(); -- just incase
    self.loadedSongs[name]:release(); -- destroy data
    self.loadedSongs[name] = nil; -- remove from table
end

function SimpleAudio.unloadSfx(name)
    assert(type(name) == "string", "sfx name is not a string: " .. type(name));
    assert(self.loadedSfx[name], "tried to unload an sfx that does not exist: " .. name);

    self.loadedSfx[name]:stop(); -- just incase
    self.loadedSfx[name]:release(); -- destroy data
    self.loadedSfx[name] = nil; -- remove from table
end

function SimpleAudio.playSong(name, addType, startPoint)
    addType = addType or "mesh"; -- default to replacing the song if no 'addType' is given
    startPoint = startPoint or 0; -- default to starting the song from the begining

    assert(type(name) == "string", "song name is not a string: " .. type(name));
    assert(self.loadedSongs[name], "tried to play a song that does not exist: " .. name);

    if #self.activeSongs > 0 then -- if there are othe rsongs playing
        if addType == "replace" then
            for i = #self.activeSongs, 1, -1 do -- loop through all active songs and stop them
                self.loadedSongs[self.activeSongs[i]]:stop();

                -- for loop goes through the table in reverse allowing for this to be kept inside the for loop
                table.remove(self.activeSongs, i);
            end
        elseif addType ~= "mesh" then
            error("tried to play a song with an invalid 'addType', only allowed: 'mesh' or 'replace' used: " .. addType);
        end
    end

    self.loadedSongs[name]:play(); -- play audio source
    self.loadedSongs[name]:seek(startPoint);

    table.insert(self.activeSongs, name); -- add to list of currently playing audios
end

function SimpleAudio.playSfx(name, volume, pitch, effects) -- plays a sound effect
    pitch = pitch or 1;
    volume = volume or 1;

    assert(type(name) == "string", "sfx name is not a string: " .. type(name));
    assert(self.loadedSfx[name], "tried to play sfx that does not exist: " .. name);

    local clone = self.loadedSfx[name]:clone(); -- clone of the sfx
    clone:setVolume(volume);
    clone:setPitch(pitch);

    if effects then
        for _, v in ipairs(effects) do
            clone:setEffect(v); -- apply all listed effect to the sfx source
        end
    end

    clone:play(); -- play sfx audio

    table.insert(self.clonedSfx, clone); -- add to list for later data management
end

function SimpleAudio.setSongLooping(name, looping)
    assert(type(name) == "string", "Song name is not a string: " .. type(name));
    assert(self.loadedSongs[name], "Song does not exist: " .. name);

    looping = (looping == nil) or looping;

    self.loadedSongs[name]:setLooping(looping);
end
function SimpleAudio.stopSongLooping(name)
    assert(type(name) == "string", "Song name is not a string: " .. type(name));
    assert(self.loadedSongs[name], "Song does not exist: " .. name);

    self.loadedSongs[name]:setLooping(false);
end

function SimpleAudio.createEffect(name, settings)
    love.audio.setEffect(name, settings);
end

function SimpleAudio.createEffects(effects)
    for k, v in pairs(effects) do
        love.audio.setEffect(k, v);
    end
end

function SimpleAudio.setSongEffects(name, effects, pitch) -- sets effects to a song
    assert(type(name) == 'string', "Song name is not a string");
    assert(self.loadedSongs[name], "Song does not exist");

    pitch = pitch or 1;
    self.loadedSongs[name]:setPitch(pitch);

    for _, v in ipairs(effects) do
        self.loadedSongs[name]:setEffect(v);
    end
end

function SimpleAudio.setSongVolume(name, volume) -- sets the volume of a song
    assert(type(name) == "string", "Song name is not a string: " .. type(name));
    assert(self.loadedSongs[name], "Song does not exist: " .. name);
    assert(type(volume) == "number", "volume is not a number: " .. type(volume));

    self.loadedSongs[name]:setVolume(volume);
end

function SimpleAudio.getSongPosition(name) -- returns the position of the song in seconds
    assert(type(name) == "string", "Song name is not a string: " .. type(name));
    assert(self.loadedSongs[name], "Song does not exist: " .. name);

    return self.loadedSongs[name]:tell("seconds");
end

function SimpleAudio.update()
    -- remove songs that have finished playing
    for i = #self.activeSongs, 1, -1 do
        if not self.loadedSongs[self.activeSongs[i]]:isPlaying() then
            self.loadedSongs[self.activeSongs[i]]:stop(); -- just in case

            -- allowed to do table.remove because for loop move in reverse through table
            table.remove(self.activeSongs, i);
        end
    end

    -- destroy sfx clones that have stopped playing
    for i = #self.clonedSfx, 1, -1 do
        if not self.clonedSfx[i]:isPlaying() then -- if sfx source stopped playing
            self.clonedSfx[i]:release(); -- destroy data
            table.remove(self.clonedSfx, i); -- remove from list
        end
    end
end

return SimpleAudio -- returns the script