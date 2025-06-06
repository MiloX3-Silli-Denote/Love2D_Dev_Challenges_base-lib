require("base_engine");
require("simpleShaderLoading").init();

local theVenusProject = {};

local function addLetter(filename, x, y, rot)
    local letter = {
        texture = love.graphics.newImage("textures/base_engine/" .. filename .. ".png");
        x     = x;
        y     = y;
        scale = 3;
        rot   = rot;

        rotOff   = love.math.random() * math.pi * 2;
        rotMag   = love.math.random() * math.pi / 8;
        rotSpeed = love.math.random() * math.pi / 6;

        xOff   = love.math.random() * math.pi * 2;
        xMag   = love.math.random() * 20 + 10;
        xSpeed = love.math.random() * 0.3;

        yOff   = love.math.random() * math.pi * 2;
        yMag   = love.math.random() * 15 + 20;
        ySpeed = love.math.random() * 0.3;
    };

    letter.texture:setFilter("nearest", "nearest");

    table.insert(theVenusProject, letter);
end

function love.load()
    -- LOVE
    addLetter("01", -700,-200, 0);
    addLetter("02", -500,-200, 0);
    addLetter("03", -300,-200, 0);
    addLetter("04", -100,-200, 0);
    -- <3
    addLetter("05",  100,-200, 0);
    -- 2D
    addLetter("06",  300,-200, 0);
    addLetter("07",  500,-200, 0);
    -- VENUS
    addLetter("08", -500, 100, 0);
    addLetter("09", -300, 100, 0);
    addLetter("10", -100, 100, 0);
    addLetter("11",  100, 100, 0);
    addLetter("12",  300, 100, 0);

    SimpleShaderLoading.addShader("vhs", "shaders/simpleShaderLoading/vhsFilter.frag");

    theVenusProject.time = 0;
end

function love.update(dt)
    theVenusProject.time = theVenusProject.time + dt; -- keep track of time
end

function love.mousemoved(x, y, dx, dy) --commented this since i think its not needed?
    -- to understand that mouse position is transformed a bit from normal!
    --print(x, y);
end

local function drawLetters()  --made the letters a function
    for i, v in ipairs(theVenusProject) do
        love.graphics.draw(
            v.texture,
            v.x + v.xMag * math.cos(v.xOff + v.xSpeed * theVenusProject.time) + 30,
            v.y + v.yMag * math.cos(v.yOff + v.ySpeed * theVenusProject.time) + 32,
            v.rot + v.rotMag * math.cos(v.rotOff + v.rotSpeed * theVenusProject.time),
            v.scale, v.scale,
            30,32
        );
    end
end

function love.draw()
    DepthDrawing.drawCallbackAtDepth(0, drawLetters);

    SimpleShaderLoading.activateShader("vhs"); -- apply vhs shader to the screen
    SimpleShaderLoading.giveShaderExtern("vhs", "time", theVenusProject.time);
    DepthDrawing.drawToSelf();
    SimpleShaderLoading.stopShaders(); -- stop applying inverting shader

    DepthDrawing.finalizeFrame(); -- draw frame to the window (always call last)
end

return theVenusProject