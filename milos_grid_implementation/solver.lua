local Solver = {};
Solver.__index = Solver; -- this IS a class

function Solver.new(func)
    assert(type(func) == "function", "tried to create a solver with non function given as argument");

    local instance = setmetatable({}, Solver);

    instance.func = func;

    return instance;
end

function Solver:solve(tile)
    local prevX = tile.x;
    local prevY = tile.y;

    self.func(tile);

    -- if the tile didnt move then finish this solve
    if tile.x == prevX and tile.y == prevY then
        return;
    end

    -- if the tile did move then move it in the chunk and world
    -- not implemented yet
    error("not implemented solvers moving tile in chunk and world yet");
end

return Solver;