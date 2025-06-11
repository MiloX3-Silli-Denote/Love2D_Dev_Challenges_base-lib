## SimpleAudio

The SimpleAudio library makes managing audio files easier.

# Songs
It keeps track of songs using names, that you use to access it.
To add a song you use SimpleAudio.addSong(name, file, songType, addType, startPoint), then you can use SimpleAudio.setSongLoop(name, loopType, loopStart, loopEnd) to manage
the song's loops, SimpleAudio.setSongEffects(songname, effects, pitch) to add effects and change pitch, SimpleAudio.setSongVolume(songname, volume) to set the song's volume, SimpleAudio.getSongPosition(songname) to get the song's
position, and SimpleAudio.removeSong(name) to remove the song

# SFX
SFX are managed the same way, but only bt the function SimpleAudio.playsfx(name, file, volume, effects, pitch), which does everything.

# Side Notes
SimpleAudio.update(dt) is required in love.update(dt) to make the library work.
There cant be multiple song with manual loops playing at the same time. 