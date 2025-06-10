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

    if tile then
        tile:updatePosition((self.chunkX - 1) * self.chunkSize + x, (self.chunkY - 1) * self.chunkSize + y);
    end

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

            assert(objLoadInfo and string.len(objLoadInfo) > 0, "cannot save tile that does not contain objects name");
            assert(string.match(objLoadInfo, "[|\n]") == nil, "cannot save object whose name contains '|' or '\\n': " .. string.gsub(objLoadInfo, "\n", "\\n"));

            -- save the size of the savedata bcs if used an eof flag, then savedata may accidentally contain that flag
            file = file .. objLoadInfo .. "\n" .. tostring(string.len(saveData)) .. "\n" .. saveData .. "\n"; -- save the tile data to the file
        end
    end

    file = file .. "nonGridData\n"; -- begin writing the data not contained on the grid
    file = file .. tostring(#self.nonGridData) .. "\n"; -- describe the number of non grid objects (for quicker error recognition)

    for _, v in ipairs(self.nonGridData) do
        local savedata    = v:getSavedata(); -- get object data
        local objLoadInfo = v.__name;        -- what object to load this data with

        assert(objLoadInfo and string.len(objLoadInfo) > 0, "cannot save tile that does not contain objects name");
        assert(string.match(objLoadInfo, "[|\n]") == nil, "cannot save object whose name contains '|' or '\\n': " .. string.gsub(objLoadInfo, "\n", "\\n"));

        -- save the size of the savedata bcs if used an eof flag, then savedata may accidentally contain that flag
        file = file .. objLoadInfo .. "\n" .. tostring(string.len(savedata)) .. "\n" .. savedata .. "\n"; -- save the object data to the file
    end

    -- save the data to the file given by the chunk coordinates
    love.filesystem.write(self.fileLocation .. tostring(self.chunkX) .. "_" .. tonumber(self.chunkY) .. ".chu", file);
end

-- returns string containing fail msg if unsucessful; nil otherwise.
function Chunk:loadChunk() -- load the chunk from a file given the chunk coordinates
    local filename = self.fileLocation .. tostring(self.chunkX) .. "_" .. tostring(self.chunkY) .. ".chu";

    if not love.filesystem.getInfo(filename) then
        return "no file"; -- no file was found for that position
    end

    local file = love.filesystem.read(filename);

    local version, chunkSize, data = string.match(file, "^([^\n]*)\nchunkSize|(%d*)\ngridData\n(.*)$");
    assert(version and chunkSize and data, "tried to load invalid chunk: " .. filename);

    if version == "v0.1" then
        -- loading the 0.1 version of the chunk loader
    else
        error("tried to load chunk with an invalid version: " .. version);
    end

    self.chunkSize = tonumber(chunkSize);

    for tileX = 1, self.chunkSize do
        for tileY = 1, self.chunkSize do
            local objectName, dataSize, rem = string.match(data, "^([^\n]*)\n(%d*)\n(.*)$");
            assert(objectName and dataSize and rem, "tried to load a tile for a chunk with invalid contents");
            dataSize = tonumber(dataSize);

            data = string.sub(rem, dataSize + 2, -1); -- +2 because tile always ends with '\n'

            if objectName ~= "nil" then -- if tile is NOT empty
                local objectData = string.sub(rem, 0, dataSize);
                local tile = Milos_Grid_Implementation.getTile(objectName).new();
                tile:loadSavedata(objectData);

                self:setTileAt(tileX, tileY, tile);
            else
                self:setTileAt(tileX, tileY, nil);
            end
        end
    end

    -- empty the list of non grid data
    self.nonGridData = {};

    local nonGridDataObjectCount, nonGridData = string.match(data, "^\n?nonGridData\n(%d*)\n(.*)$");
    assert(nonGridDataObjectCount and nonGridData, "catastrophic error: non-grid data mis-aligned in chunk file");

    nonGridDataObjectCount = tonumber(nonGridDataObjectCount);

    -- go through and load all of the non grid objects
    for i = 1, nonGridDataObjectCount do
        local nonGridObjectName, nonGridObjectDataSize, rem = string.match(nonGridData, "^([^\n]*)\n(%d*)\n(.*)$");
        assert(nonGridObjectName and nonGridObjectDataSize and rem, "catastrophic error: non grid objects arent aligned properly in chunk file");
        nonGridObjectDataSize = tonumber(nonGridObjectDataSize);

        local objectData = string.sub(rem, 0, nonGridObjectDataSize);

        local nonTile = Milos_Grid_Implementation.getNonTile(nonGridObjectName).new();
        nonTile:loadSavedata(objectData);

        -- add non-grid object to the list of non grid objects
        table.insert(self.nonGridData, nonTile);

        -- +2 because non-grid object savedata always ends with '\n'
        nonGridData = string.sub(rem, nonGridObjectDataSize + 2, -1);
    end
end

return Chunk;