local ComponentBase = {}; -- this IS a class
ComponentBase.__index = ComponentBase;

function ComponentBase.new()
    local instance = setmetatable({}, ComponentBase);

    return instance;
end

function ComponentBase:init()
    assert(self.__name, "cannot initialize tileBase if __name is not set");
    assert(self.getSavedata, "cannot have a component that does not have a :getSavedata() function");
    assert(self.loadSavedata, "cannot have a component that does not have a :loadSavedata(data) function");

    self.tile = nil;

    return self; -- allow for instance = setmetatable({}, Tile):init();
end

function ComponentBase:setTile(tile)
    self.tile = tile;
end

function ComponentBase:getTile()
    return self.tile;
end

return ComponentBase;