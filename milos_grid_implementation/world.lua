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
            love.graphics.origin();
            love.graphics.scale(self.tileSize, self.tileSize);
            love.graphics.translate(
                self.x + x - 1,
                self.y + y - 1
            );

            w:draw();
        end
    end

    DepthDrawing.stopDrawingAtDepth(0);
end

return World;