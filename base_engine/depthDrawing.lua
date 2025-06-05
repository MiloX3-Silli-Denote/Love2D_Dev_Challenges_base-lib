--? this script is for standardizing how the game is draw.
--? nobody likes having to ensure you're drawing your sprites in the correct order
--? so this script forces all draw calls to be made with it in mind.
--? dont just use love.graphics.draw(...) or anything else like that
--? instead use DepthDraing.draw(depth, ...) and let me take care of the draw ordering for you!

--? this script also solves a common problem with window size shananigans
--? instead of drawing to a pixel relative to the top left of the window
--? draw to to an abstract unit relative to the center of the window
--? the units scale in real time to the window if it is resized.
--? the units are in a 16:9 aspect ration that takes up as much of the
--? window as it can without accidentally hiding anything
--? so in any given 16:9 aspect ratio window the edges of the window
--? will be at: -960,-540   --   960,-540
--?                  |               |
--?                  |               |
--?             -960, 540   --   960, 540
--? just pretend youre always drawing to a 1920x1080 window with 0,0 in the center

--? dont worry about needing to alter anything in accordance to this; however,
--? because anything that relies on the window has been injected with code to fix it
--? this means that calling something like love.mouse.getX() will give you the x in unit coordinates

local path = string.match((...), "(.*)[./][^./]*") or ""; -- get the directory of this script

local DepthDrawing = {}; -- not a class
local self = DepthDrawing; -- for readability, does not affect anything outside of this script

function DepthDrawing.init()
    -- target dimmensions for screen
    self.targetWidth  = 1920;
    self.targetHeight = 1080;

    -- [0-1] of where 0,0 is on the screen
    self.centerXPerun = 0.5;
    self.centerYPerun = 0.5;

    self.enabled = true; -- whether to actually do things

    -- shader for drawing using depth
    self.shader = love.graphics.newShader("shaders/" .. path .. "/depthShader.glsl");

    -- width and height of the window
    self.w = love.graphics.getWidth();
    self.h = love.graphics.getHeight();

    -- minimum and maximum allowed depth
    self.maxDepth = 1000;
    self.minDepth = 0;

    -- canvases for drawing depth appropriately
    self.currentLayer = love.graphics.newCanvas(self.w, self.h); -- temporary at depth
    self.render       = love.graphics.newCanvas(self.w, self.h); -- final frame
    self.depth        = love.graphics.newCanvas(self.w, self.h, {format = "depth16", readable = true}); -- depth buffer

    -- how many times has startDrawingAtDepth() been called?
    self.startDrawCalls = 0;

    self.errorDrawCalls = false;  -- whether or not draw calls should error
    self.transformOrigin = false; -- whether or not to apply transformations whenever love.graphics.origin() is called

    local function drawCallErroring() -- cause dra calls to error when we want it to
        if not self.enabled then -- if not enabled then ignore everything related to it
            return;
        end

        assert(self.errorDrawCalls == false, "tried to call a draw call outside of a DepthDrawing use, call DepthDrawing.startDrawingAtDepth() or use the DepthDrawing. [draw callback] ()");
    end
    local function originAppend() -- cause love.graphics.origin() to be transformed when we want it to
        if not self.enabled then
            return;
        end

        if self.transformOrigin then
            self.applyTransformation();
        end
    end

    -- have the draw calls cause an error if not drawing to the depth buffer
    LoveAffix.makeFunctionInjectable("graphics", "arc");
    LoveAffix.makeFunctionInjectable("graphics", "circle");
    LoveAffix.makeFunctionInjectable("graphics", "draw");
    LoveAffix.makeFunctionInjectable("graphics", "drawInstanced");
    LoveAffix.makeFunctionInjectable("graphics", "drawLayer");
    LoveAffix.makeFunctionInjectable("graphics", "ellipse");
    LoveAffix.makeFunctionInjectable("graphics", "line");
    LoveAffix.makeFunctionInjectable("graphics", "points");
    LoveAffix.makeFunctionInjectable("graphics", "polygon");
    LoveAffix.makeFunctionInjectable("graphics", "print");
    LoveAffix.makeFunctionInjectable("graphics", "printf");
    LoveAffix.makeFunctionInjectable("graphics", "rectangle");
    LoveAffix.makeFunctionInjectable("graphics", "origin");

    LoveAffix.injectCodeIntoLove(drawCallErroring, "graphics", "arc");
    LoveAffix.injectCodeIntoLove(drawCallErroring, "graphics", "circle");
    LoveAffix.injectCodeIntoLove(drawCallErroring, "graphics", "draw");
    LoveAffix.injectCodeIntoLove(drawCallErroring, "graphics", "drawInstanced");
    LoveAffix.injectCodeIntoLove(drawCallErroring, "graphics", "drawLayer");
    LoveAffix.injectCodeIntoLove(drawCallErroring, "graphics", "ellipse");
    LoveAffix.injectCodeIntoLove(drawCallErroring, "graphics", "line");
    LoveAffix.injectCodeIntoLove(drawCallErroring, "graphics", "points");
    LoveAffix.injectCodeIntoLove(drawCallErroring, "graphics", "polygon");
    LoveAffix.injectCodeIntoLove(drawCallErroring, "graphics", "print");
    LoveAffix.injectCodeIntoLove(drawCallErroring, "graphics", "printf");
    LoveAffix.injectCodeIntoLove(drawCallErroring, "graphics", "rectangle");
    LoveAffix.appendCodeIntoLove(originAppend, "graphics", "origin");

    -- if an error occurs then dont cause a force quit for the entire application before the error screen can be drawn
    LoveAffix.makeFunctionInjectable("errorhandler");
    LoveAffix.injectCodeIntoLove(
       function()
           self.transformOrigin = false;
           self.errorDrawCalls = false;
       end,
       "errorhandler"
    );

    -- have this script be notified of whenever the window is resized
    LoveAffix.makeFunctionInjectable("resize");
    LoveAffix.injectCodeIntoLove(self.setDimensions, "resize");

    -- update transformations
    self.updateTransformations();

    self.errorDrawCalls = true;

    return self; -- allow: DepthDrawing = require("depthDrawing").init();
end

function DepthDrawing.setDimensions(w, h) -- update canvases and transformations
    self.w = w;
    self.h = h;

    self.currentLayer = love.graphics.newCanvas(w, h);
    self.render       = love.graphics.newCanvas(w, h);
    self.depth        = love.graphics.newCanvas(w, h, {format =  "depth16", readable = true});

    self.updateTransformations();
end

function DepthDrawing.updateTransformations()
    -- where the center of the screen is, relative to the windows top left corner
    self.translateX = self.w * self.centerXPerun;
    self.translateY = self.h * self.centerYPerun;

    -- wants to draw to a 1920x1080 screen
    local ratioX = self.w / self.targetWidth;
    local ratioY = self.h / self.targetHeight;

    self.scale = math.min(ratioX, ratioY);
end

function DepthDrawing.clear(r, g, b)
    love.graphics.setCanvas({self.currentLayer, self.render, depthstencil = self.depth});
    love.graphics.clear({r or 0, g or 0, b or 0, 1}, {r or 0, g or 0, b or 0, 1}, true, 1); -- clear all colours and depths
    love.graphics.setCanvas();
end

function DepthDrawing.drawAtDepth(depth, ...)
    self.drawCallbackAtDepth(depth, love.graphics.draw, ...);
end

function DepthDrawing.drawCallbackAtDepth(depth, callback, ...)
    self.startDrawingAtDepth();

    callback(...);

    self.stopDrawingAtDepth(depth);
end

function DepthDrawing.applyTransformation()
    love.graphics.translate(self.translateX, self.translateY);
    love.graphics.scale(self.scale);
end

function DepthDrawing.getWorldPointFromScreenPoint(x, y)
    love.graphics.push();

    -- check if our transformation will already get applied or not
    if self.transformOrigin then
        love.graphics.origin();
    else
        love.graphics.origin();
        self.applyTransformation();
    end

    local retX, retY = love.graphics.inverseTransformPoint(x, y);

    love.graphics.pop();

    return retX, retY;
end
function DepthDrawing.getWorldDeltaFromScreenDelta(dx, dy)
    return self.getWorldPointFromScreenPoint(dx + self.translateX, dy + self.translateY);
end

function DepthDrawing.disable()
    assert(self.startDrawCalls == 0, "cannot disable DepthDrawing when a startDrawingAtDepth() is active");
    self.enabled = false;
end

function DepthDrawing.enable()
    self.enabled = true;
end

function DepthDrawing.startDrawingAtDepth()
    assert(self.enabled == true, "tried to start drawing at depth whan DepthDrawing is not active");

    self.startDrawCalls = self.startDrawCalls + 1; -- increment the counter of startDrawingAtDepth() calls

    if self.startDrawCalls > 1 then
        return;
    end

    love.graphics.push();

    -- make calling love.graphics.origin() not mess up the desired centering and scaling of the universe
    self.transformOrigin = true;

    -- the previously mentioned centering and scaling of the universe
    love.graphics.origin(); -- origin because any previous transformations would get messed up by just calling self.applyTransformation()

    love.graphics.setDepthMode("always", false);
    love.graphics.setCanvas(self.currentLayer);
    love.graphics.clear();

    self.errorDrawCalls = false; -- dont error when drawing in here
end

function DepthDrawing.stopDrawingAtDepth(depth)
    assert(self.enabled == true, "tried to start drawing at depth whan DepthDrawing is not active");

    assert(self.startDrawCalls > 0, "tried to stop drawing at a depth before starting a draw at depth");
    assert(depth ~= nil, "tried to start and stop a draw at depth without setting the depth");
    assert(depth >= self.minDepth and depth <= self.maxDepth, "can only draw item at a depth of: " .. tostring(self.minDepth) .. " <= depth <= " .. tostring(self.maxDepth));

    self.startDrawCalls = self.startDrawCalls - 1; -- decrement additional draws
    if self.startDrawCalls > 0 then -- if there are more than one depth draw remaining then wait until its the last one
        return;
    end

    -- make calling love.graphics.origin() ignore the previous centering and scaling of the universe
    self.transformOrigin = false;

    -- draw the currentLayer canvas to the final render target with depth
    love.graphics.setCanvas({self.render, depthstencil = self.depth});
    love.graphics.setShader(self.shader);
    love.graphics.setDepthMode("lequal", true);

    self.shader:send("z", (depth - self.minDepth) / (self.maxDepth + self.minDepth)); -- depth of the current layer (perun)

    love.graphics.origin();
    love.graphics.setColor(1,1,1,1);
    love.graphics.draw(self.currentLayer);

    love.graphics.setDepthMode("always", false);
    love.graphics.setShader();
    love.graphics.setCanvas();

    love.graphics.pop();

    self.errorDrawCalls = true; -- error draw calls since theyre not done in the DepthDrawing
end

function DepthDrawing.finalizeFrame()
    assert(self.startDrawCalls == 0, "tried to finalize the depth buffers frame while a startDrawingAtDepth is still active still active");

    self.errorDrawCalls = false; -- dont error on drawing to the screen

    -- ensure that no modifications are made so they mess up the final drawing of the fram
    love.graphics.origin();
    love.graphics.setCanvas();
    love.graphics.setShader();
    love.graphics.setColor(1,1,1,1);
    love.graphics.draw(self.render); -- draw the final frame

    self.clear(); -- clear the canvases in preparation for the next frame

    self.errorDrawCalls = true;
end

return DepthDrawing;