local path = (...); -- what directory is this library in

_G.Milos_Grid_Implementation = {}; -- not a class (name a WIP ;3c)
local self = Milos_Grid_Implementation; -- for readability

function Milos_Grid_Implementation.init()
    self._Chunk    = require(path .. ".chunk");
    self._World    = require(path .. ".world");
    self._Solver   = require(path .. ".solver");
    self._TileBase = require(path .. ".tileBase");

    self.newChunk    = self._Chunk.new;
    self.newWorld    = self._World.new;
    self.newTileBase = self._TileBase.new;
    self.newSolver   = self._Solver.new;

    -- list of solvers that can be used by tiles (keyed)
    self.solvers = {};
    -- list of tiles that can be added to chunks
    self.tiles   = {};

    -- load all solvers in 'path .. /solvers'
    for _, filename in ipairs(love.filesystem.getDirectoryItems(path .. "/solvers")) do
        assert(string.sub(filename, -4,-1) == ".lua", "non lua file located in solvers file, must be removed");

        local name = string.sub(filename, 1, -5); -- remove '.lua'

        -- add solver to solver list
        self.addSolver(name, require(path .. "/solvers/" .. name));
    end

    -- load all tiles in 'path .. /tiles'
    for _, filename in ipairs(love.filesystem.getDirectoryItems(path .. "/tiles")) do
        assert(string.sub(filename, -4,-1) == ".lua", "non lua file located in tiles file, must be removed");

        local name = string.sub(filename, 1, -5); -- remove '.lua'

        -- add tile to tile list
        self.addTile(require(path .. "/tiles/" .. name));
    end

    -- currently active world
    self.world = self.newWorld();

    LoveAffix.appendCodeIntoLove(self.update, "update");
end

function Milos_Grid_Implementation.getWorld()
    return self.world;
end

function Milos_Grid_Implementation.getChunk(x, y)
    return self.world:getChunk(x, y);
end
function Milos_Grid_Implementation.getTileAt(x, y)
    return self.world:getTileAt(x, y);
end

function Milos_Grid_Implementation.addSolver(name, solver)
    assert(type(name) == "string", "tried to add solver at invalid name: " .. type(name));
    assert(string.match(name, "[|\n]") == nil, "tried to add a solver with '\\n' or '|' in its name: " .. string.gsub(name, "\n", "\\n"));
    assert(self.solvers[name] == nil, "tried to add a solver to the grid implementation at name that already exists");
    assert(solver.name == nil, "tried to add solver to grid implementation that has already been added with a different name");

    -- place solver in table at name
    self.solvers[name] = solver;
    solver.name = name; -- for easier OTF locating
end

function Milos_Grid_Implementation.getSolver(name)
    assert(type(name) == "string", "tried to get solver at invalid name: " .. type(name));
    assert(self.solvers[name], "tried to get nonexistent solver: " .. name);

    -- return the solver that we want
    return self.solvers[name];
end

function Milos_Grid_Implementation.addTile(tile)
    assert(type(tile.__name) == "string", "tried to add tile that doesnt have name");
    assert(self.tiles[tile.__name] == nil, "tried to add a tile to the grid implementation at name that already exists");
    assert(tile.getSavedata, "tried to create a tile object that does not contain the :getSavedata() function");

    -- place tile in table at its name in the tiles table
    self.tiles[tile.__name] = tile;
end
function Milos_Grid_Implementation.getTile(name)
    assert(type(name) == "string", "tried to get tile at invalid name: " .. type(name));
    assert(self.tiles[name], "tried to get nonexistent tile: " .. name);

    -- return the solver that we want
    return self.tiles[name];
end

function Milos_Grid_Implementation.update(dt)
    self.world:update(dt);
end

function Milos_Grid_Implementation.draw()
    self.world:draw();
end

return Milos_Grid_Implementation; -- doesnt do anything since its already global