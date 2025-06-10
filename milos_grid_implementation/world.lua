local World = {};
World.__index = World; -- this IS a class

World.chunkSize = 8; -- how many tiles wide and tall is each chunk?
World.loadedChunks = 1; -- how many chunks are loaded at once? width and height (# of chunks if this ^2)

World.tileSize = 32; -- how many units wide and tall is each tile?

World.tickrate = 0.5; -- number of seconds between update ticks

function World.new()
    local instance = setmetatable({}, World);

    -- what is the chunk position value of the top left chunk? (for keeping self.chunks an index table instead of keyed)
    instance.x = 0;
    instance.y = 0;

    instance.updateOverflow = 0; -- how much extra time was given to next tick

    instance.chunks = {}; -- 2d array, indexed with: chunks[x - self.x][y - self.y]

    -- make table 2d
    for i = 1, instance.loadedChunks do
        instance.chunks[i] = {};

        for j = 1, instance.loadedChunks do
            local newChunk = Milos_Grid_Implementation.newChunk(instance.chunkSize);
            newChunk:setChunkPosition(i + instance.x, j + instance.y);

            instance.chunks[i][j] = newChunk;
        end
    end

    return instance;
end

function World:dealWithChunk(x, y, moveX, moveY)
    local shiftX = x + moveX; -- location of the chunk that will be moved to this index
    local shiftY = y + moveY;

    -- if chunk will be moved out of loaded area, then unload it and load in new chunk
    if shiftX <= 0 or shiftY <= 0 or shiftX > self.loadedChunks or shiftY > self.loadedChunks then
        self.chunks[x][y]:saveChunk(); -- save chunk info to file

        -- create a new chunk and load its data from file
        local newChunk = Milos_Grid_Implementation.newChunk(self.chunkSize);
        newChunk:setChunkPosition(x + self.x, y + self.y);

        local errMsg = newChunk:loadChunk();

        if errMsg then
            if errMsg == "no file" then
                -- proc gen here
                -- just keep it filled w/ nothing for now though :3
            end
        end

        self.chunks[x][y] = newChunk;

        return; -- exit after loading new chunk into position
    end

    -- move chunk from future position to cur position in table
    self.chunks[x][y] = self.chunks[shiftX][shiftY];
end

function World:setPosition(x, y)
    if x == self.x and y == self.y then -- didnt actually move so dont do any modifications to the chunk data
        return;
    end

    local moveX = x - self.x; -- get the effective translation
    local moveY = y - self.y;

    self.x = x; -- set position to new position
    self.y = y;

    -- variables for modifying direction of for loop's x direction
    local xStart     = 1;
    local xEnd       = self.loadedChunks;
    local xDirection = 1;
    -- variables for modifying direction of for loop's y direction
    local yStart     = 1;
    local yEnd       = self.loadedChunks
    local yDirection = 1;

    -- if shift to the left then filter chunks right to left
    if moveX < 0 then
        xStart = self.loadedChunks;
        xEnd = 1;
        xDirection = -1;
    end

    -- if shift is upwards then filter chunks bottom to top
    if moveY < 0 then
        yStart = self.loadedChunks;
        yEnd = 1;
        yDirection = -1;
    end

    -- loop through all chunks and 'deal w/ them' :3
    for chunkX = xStart, xEnd, xDirection do
        for chunkY = yStart, yEnd, yDirection do
            self:dealWithChunk(chunkX, chunkY, moveX, moveY);
        end
    end
end

function World:getChunk(x, y)
    x = x - self.x; -- perform less operations in asserts
    y = y - self.y;

    assert(x > 0 and y > 0, "cannot get chunk below bounds of loaded chunks");
    assert(x <= self.loadedChunks and y <= self.loadedChunks, "cannot get chunk above bounds of loaded chunks");

    return self.chunks[x][y];
end

function World:getTileAt(x, y)
    x = x - self.x * self.chunkSize; -- perform less operations in asserts
    y = y - self.y * self.chunkSize;

    -- if out of bounds then return nil to show that we dont know what is there
    if x <= 0 or y <= 0 then
        return nil;
    end
    if x > self.loadedChunks * self.chunkSize or y > self.loadedChunks * self.chunkSize then
        return nil;
    end

    local chunkX = math.floor((x - 1) / self.chunkSize) + 1; -- which chunk is the tile in?
    local chunkY = math.floor((y - 1) / self.chunkSize) + 1;

    -- return the tile from the chosen chunk
    return self.chunks[chunkX][chunkY]:getTileAt((x - 1) % self.chunkSize + 1, (y - 1) % self.chunkSize + 1);
end

function World:update(dt)
    self.updateOverflow = self.updateOverflow + dt;

    -- if not enough time has passed then dont tick
    if self.updateOverflow < self.tickrate then
        return;
    end

    -- if a tick takes too long to process then just skip some ticks
    self.updateOverflow = self.updateOverflow % self.tickrate;

    for _, v in ipairs(self.chunks) do
        for _, w in ipairs(v) do
            w:update(dt);
        end
    end

    for _, v in ipairs(self.chunks) do
        for _, w in ipairs(v) do
            w:finishUpdate();
        end
    end
end

function World:draw()
    DepthDrawing.startDrawingAtDepth();

    for x, v in ipairs(self.chunks) do
        for y, w in ipairs(v) do
            love.graphics.push();

            love.graphics.scale(self.tileSize, self.tileSize);
            love.graphics.translate(
                (self.x + x - 1) * self.chunkSize,
                (self.y + y - 1) * self.chunkSize
            );

            w:draw();

            love.graphics.pop();
        end
    end

    DepthDrawing.stopDrawingAtDepth(0);
end

return World;