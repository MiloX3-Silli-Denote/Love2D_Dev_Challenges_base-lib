local Chunk = {};
Chunk.__index = Chunk; -- this IS a class

Chunk.fileLocation = "milos_grid_implementation/chunks/"; -- location of files containing chunk data
love.filesystem.createDirectory(Chunk.fileLocation); -- create file directory (if it doesnt exist already)

-- 'layers' not implemented yet :3
function Chunk.new(chunkSize)--, layers)
    local instance = setmetatable({}, Chunk);

    --instance.layers = layers or 1; -- number of layers to the grid
    instance.chunkSize = chunkSize;

    instance.chunkX = 0; -- chunk position
    instance.chunkY = 0;

    -- single dimension array: index with x + (y - 1) * chunkSize (for efficiency)
    instance.gridData = {};
    -- single dimension array: true or false, of whether to skip a tile in update

    -- indexed table, dont look up w/ index, use pointers
    instance.nonGridData = {};

    return instance;
end

function Chunk:setChunkPosition(x, y)
    self.chunkX = x;
    self.chunkY = y;
end

function Chunk:update(dt)
    for x = 1, self.chunkSize do
        for y = 1, self.chunkSize do
            local index = x + (y - 1) * self.chunkSize;

            if self.gridData[index] then
                self.gridData[index]:updatePosition((self.chunkX - 1) * self.chunkSize + x, (self.chunkY - 1) * self.chunkSize + y);
                self.gridData[index]:update(dt); -- update tile
            end
        end
    end

    -- update tthe non grid objects
    for _, v in ipairs(self.nonGridData) do
        v:update(dt);
    end
end

function Chunk:finishUpdate()
    for x = 1, self.chunkSize do
        for y = 1, self.chunkSize do
            local index = x + (y - 1) * self.chunkSize;

            if self.gridData[index] then
                self.gridData[index]:setValuesFromQueue(); -- update values in tiles
            end
        end
    end
end

function Chunk:getTileAt(x, y)
    local index = x + (y - 1) * self.chunkSize;

    assert(index > 0, "cannot get tile lower than bounds of chunk");
    assert(index <= self.chunkSize * self.chunkSize, "cannot get tile higher than bounds of chunk");

    return self.gridData[index];
end

function Chunk:setTileAt(x, y, tile)
    -- if given the name to a tile then add that tile
    if type(tile) == "string" then
        self:setTileAt(x, y, Milos_Grid_Implementation.getTile(tile).new());
        return;
    end

    local index = x + (y - 1) * self.chunkSize;

    assert(index > 0, "cannot set tile lower than bounds of chunk");
    assert(index <= self.chunkSize * self.chunkSize, "cannot set tile higher than bounds of chunk");

    tile:updatePosition((self.chunkX - 1) * self.chunkSize + x, (self.chunkY - 1) * self.chunkSize + y);
    self.gridData[index] = tile;
end

function Chunk:fillWithTile(tile)
    -- if given the name to a tile then fill with that tile
    if type(tile) == "string" then
        self:fillWithTile(Milos_Grid_Implementation.getTile(tile));
        return;
    end

    for x = 1, self.chunkSize do
        for y = 1, self.chunkSize do
            local index = x + (y - 1) * self.chunkSize;

            local newTile = tile.new();
            newTile:updatePosition((self.chunkX - 1) * self.chunkSize + x, (self.chunkY - 1) * self.chunkSize + y);
            self.gridData[index] = newTile;
        end
    end
end

function Chunk:draw()
    -- draw grid lines
    love.graphics.setLineWidth(0.01);
    for x = 0, self.chunkSize do -- vertical grid lines
        love.graphics.line(x, 0, x, self.chunkSize);
    end
    for y = 0, self.chunkSize do -- horizontal grid lines
        love.graphics.line(0, y, self.chunkSize, y);
    end

    for x = 1, self.chunkSize do
        for y = 1, self.chunkSize do
            local index = x + (y - 1) * self.chunkSize;

            love.graphics.push();
            love.graphics.translate(x - 1, y - 1);

            if self.gridData[index] then
                self.gridData[index]:draw();
            end

            love.graphics.pop();
        end
    end
end

function Chunk:saveChunk() -- save the chunk data to a file given the chunk coords
    local file = "v0.1\n"; -- version of save/load data

    file = file .. "chunkSize|" .. tostring(self.chunkSize) .. "\n"; -- prevent chunk size mismatch (maybe allow OTF resizing using side by side chunks)
    file = file .. "gridData\n"; -- begin writing data for the grid

    -- go though all tiles this chunk has and save them
    for tileX = 1, self.chunkSize do
        for tileY = 1, self.chunkSize do
            local tile = self:getTileAt(tileX, tileY);

            local saveData;
            local objLoadInfo;

            if tile then
                saveData    = tile:getSavedata(); -- get tile data
                objLoadInfo = tile.__name;        -- what object to load this data with
            else -- if the tile is empty
                saveData    = "nil"; -- show that there was no tile present
                objLoadInfo = "nil"; -- nil so no object to load it with
            end

            assert(string.match(objLoadInfo, "|") == nil, "cannot save object whose name contains '|': " .. objLoadInfo);
            assert(string.len(objLoadInfo) > 0, "cannot save tile that does not contain objects name");

            -- save the size of the savedata bcs if used an eof flag, then savedata may accidentally contain that flag
            file = file .. objLoadInfo .. "\n" .. tostring(string.len(saveData)) .. "\n" .. saveData .. "\n"; -- save the tile data to the file
        end
    end

    file = file .. "nonGridData\n"; -- begin writing the data not contained on the grid
    file = file .. tostring(#self.nonGridData) .. "\n"; -- describe the number of non grid objects (for quicker error recognition)

    for _, v in ipairs(self.nonGridData) do
        local savedata    = v:getSavedata(); -- get object data
        local objLoadInfo = v.__name;        -- what object to load this data with

        assert(string.match(objLoadInfo, "|") == nil, "cannot save object whose name contains '|': " .. objLoadInfo);
        assert(string.len(objLoadInfo) > 0, "cannot save tile that does not contain objects name");

        -- save the size of the savedata bcs if used an eof flag, then savedata may accidentally contain that flag
        file = file .. objLoadInfo .. "|" .. tostring(string.len(savedata)) .. "|" .. savedata .. "\n"; -- save the object data to the file
    end

    -- save data to file given the chunk coords
    print(love.filesystem.write(self.fileLocation .. tostring(self.chunkX) .. "_" .. tonumber(self.chunkY) .. ".chu", file));
end

-- returns string containing fail msg if unsucessful; nil otherwise.
function Chunk:loadChunk() -- load the chunk from a file given the chunk coords
    if not love.filesystem.getInfo(self.fileLocation .. tostring(self.chunkX) .. "_" .. tostring(self.chunkY) .. ".chu") then
        return "no file"; -- no file was found for that position
    end

    -- not implemented yet (I took a break to have sex (am I the only comp sci girl to get bitches? probably :3c) /srs)
    error("loading chunk not implemented yet");
end

return Chunk;