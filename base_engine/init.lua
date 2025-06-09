local path = (...); -- get the directory of this library

-- globalize these because they are necessary for all users
_G.LoveAffix    = require(path .. ".loveAffix"   ).init();
_G.DepthDrawing = require(path .. ".depthDrawing").init();
_G.Camera       = require(path .. ".camera"      ).init();