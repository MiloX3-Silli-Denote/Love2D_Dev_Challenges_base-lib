local TileBase = {}; -- this IS a class

-- list of function names that are injected instead of overwriten
TileBase.injectWhitelist = {
    update       = 2; -- 2 : append code
    getSavedata  = 1; -- 1 : inject code
    loadSavedata = 2; -- 2 : append code
};

-- list of names that are not allowed to be used (for easily spotting errors with the whitelist)
TileBase.nameBlacklist = {
    getSave     = "getSavedata";
    save        = "getSavedata";
    getSaveData = "getSavedata";
    getData     = "getSavedata";
    saveData    = "getSavedata";
    SaveData    = "getSavedata";
    savedata    = "getSavedata";
    Savedata    = "getSavedata";

    loadSaveData = "loadSavedata";
    loadData     = "loadSavedata";
    loadSave     = "loadSavedata";
    load         = "loadSavedata";
};

function TileBase:__index(key)
    if TileBase[key] then
        return TileBase[key];
    end

    if self.injectWhitelist[key] then
        return self["_" .. key];
    end

    if self.components[key] then
        return self.components[key];
    end
end

function TileBase:__newindex(key, val)
    assert(not self.nameBlacklist[key], "tried to set value in TileBase of blacklisted key: " .. key .. " . you probably wanted: " .. (self.nameBlacklist[key] or ""));

    local injectType = self.injectWhitelist[key];

    -- just a normal variable
    if not injectType then
        rawset(self, key, val);
        return;
    end

    assert(type(val) == "function", "tried to inject non function into TileBase: " .. key);

    local prevFunc = self["_" .. key];

    local newFunc;

    if injectType == 1 then
        newFunc = function(...)
            local newArgs = {val(...)};

            if #newArgs > 0 then
                local calledObject = {...}; -- 'self'
                calledObject = calledObject[1];

                return prevFunc(calledObject, unpack(newArgs));
            else
                return prevFunc(...);
            end
        end
    elseif injectType == 2 then
        newFunc = function(...)
            local newArgs = {prevFunc(...)};

            if #newArgs > 0 then
                local calledObject = {...}; -- 'self'
                calledObject = calledObject[1];

                return val(calledObject, unpack(newArgs));
            else
                return val(...);
            end
        end
    else
        error("tried to have a unique inject type for TileBase.injeftWhitelist, only 1 and 2 allowed: " .. tostring(injectType));
    end

    if key == "getSavedata" then
        self.addedSave = true;
    elseif key == "loadSavedata" then
        self.addedLoad = true;
    end

    rawset(self, "_" .. key, newFunc);
end

function TileBase.new()
    local instance = setmetatable({}, TileBase);

    instance.addedSave = false;
    instance.addedLoad = false;

    return instance;
end

function TileBase:init()
    assert(self.__name, "cannot initialize tileBase if __name is not set");
    assert(self.addedSave, "cannot have a component that does not have a :getSavedata() function");
    assert(self.addedLoad, "cannot have a component that does not have a :loadSavedata(data) function");

    self.x = 0; -- position
    self.y = 0;

    -- whether this tile wants to update on the next update tick, gets set to false after every update tick
    self.queuedForUpdate = true;

    self.solvers = {}; -- list of injectable functions to be called on :update()

    --keyed with the components name and __index will index that component if indexing 'self' with that name
    self.components = {}; -- list of attached components

    self.setQueue = {}; -- queue of setting variables in this object

    return self; -- allow for instance = setmetatable({}, Tile):init();
end

function TileBase:wantsToUpdate()
    return self.queuedForUpdate;
end

function TileBase:updateSurroundingTiles(radius)
    radius = radius or 1; -- if no value given then only do surrounding tiles

    for x = -radius, radius do
        for y = -radius, radius do
            if x ~= 0 or y ~= 0 then
                -- tell it to update *next* tick since updating *this* tick isnt setup in the code yet
                local tile =  Milos_Grid_Implementation.getTileAt(self.x + x, self.y + y);

                if tile then
                    tile:queueValueChange("queuedForUpdate", true);
                end
            end
        end
    end
end

function TileBase:updatePosition(x, y)
    self.x = x;
    self.y = y;
end

function TileBase:addSolver(solver)
    -- if given the name to a solver then add that solver
    if type(solver) == "string" then
        self:addSolver(Milos_Grid_Implementation.getSolver(solver));

        return;
    end

    -- otherwise just add the solver given
    table.insert(self.solvers, solver);
end

function TileBase:addComponent(component)
    if type(component) == "string" then -- if given the name of the component then add the component through the name
        self:addComponent(Milos_Grid_Implementation.getComponent(component).new());

        return;
    end

    assert(component and component.__name, "tried to add invalid component to tile");
    assert(self.components[component.__name] == nil, "cannot add two of the same component to a tile");

    component:setTile(self);

    self.components[component.__name] = component; -- create a new component and add it to the associated key
end

function TileBase:queueValueChange(name, ...)
    local addToQueue = {...};
    addToQueue.name = name;

    table.insert(self.setQueue, addToQueue);
end

function TileBase:setValuesFromQueue()
    for i, v in ipairs(self.setQueue) do
        -- if you're 'changing' the value of a function and setting it to a non-function
        -- then instead of changing the value; call the function with 'newValue' as the argument
        if type(self[v.name]) == "function" and not type(v[1]) == "function" then
            self[v.name](self, unpack(v));
        else
            self[v.name] = v[1];
        end
    end

    self.setQueue = {}; -- empty the queue
end

function TileBase:_update(dt)
    self.queuedForUpdate = false; -- dont update next update tick unless given a reason to

    for i, v in ipairs(self.solvers) do
        v:solve(self);
    end
end

function TileBase:draw()
    if self.texture then
        love.graphics.draw(TextureSimplifier.getDrawable(self.texture), 0,0); -- wants to think its a 1x1 texture
    end
end

function TileBase:_getSavedata(append)
    --? I don't know if it should set values from the queue here or not
    --? (probably not because of possible moving between chunks and/or altering other tiles' values?)
    -- self:setValuesFromQueue();

    local ret = "v0.2\n"; -- version

    local data = "x|" .. tostring(self.x) .. "\n";
    data = data .. "y|" .. tostring(self.y) .. "\n";
    data = data .. "solvers\n";
    data = data .. tostring(#self.solvers) .. "\n";

    for _, v in ipairs(self.solvers) do
        data = data .. v.name .. "\n"; -- add the names of the solvers to the data
    end

    data = data .. "components\n";
    for k, v in pairs(self.components) do
        local componentData = v:getSavedata();

        data = data .. k .. "\n" .. tostring(string.len(componentData)) .. "\n" .. componentData .. "\n";
    end

    ret = ret .. tostring(string.len(data)) .. "\n" .. data .. "\n";

    return ret .. "|\n" .. append;
end

function TileBase:_loadSavedata(data) -- return remaining object save data because injectWhitelist type of 2
    local version, dataLen, allData = string.match(data, "^([^\n]*)\n(%d+)\n(.*)$");
    assert(version and dataLen and allData, "tried to load corrupted save data");

    if version == "v0.2" then
        -- loading the 0.1 version of the TileBase loader
    else
        error("tried loading TileBase with non-supported version (recomended to delete file as no parser for that format exists)");
    end

    -- seperate the data used in this function vs the data used inn the object specific function
    local myData = string.sub(allData, 0, dataLen);
    -- + 3 because: + 1 to get unique data, and guarenteed to contain '|\n'
    local retData = string.sub(allData, dataLen + 3, -1);

    -- seperate the x, y and solver data
    local x, y, solverCount, solverInfo = string.match(myData, "^x|([%d%-%.]+)\ny|([%d%-%.]+)\nsolvers\n(%d*)\n(.*)$");
    self.x = tonumber(x);
    self.y = tonumber(y);
    solverCount = tonumber(solverCount);

    self.solvers = {}; -- reset list of solvers

    for i = 1, solverCount do
        local nextSolverName, solverInfoRemaining = string.match(solverInfo, "^([^|\n]*)\n(.*)$");

        table.insert(self.solvers, Milos_Grid_Implementation.getSolver(nextSolverName));

        solverInfo = solverInfoRemaining;
    end

    solverInfo = string.match(solverInfo, "^\n?components\n(.*)$");
    assert(solverInfo, "catastrophic error: tile savedata aligned incorrectly");

    self.components = {}; -- reset list of components

    while string.len(solverInfo) > 1 do -- > 1 because all components finish with '\n'
        local componentName, componentDataLen, rem = string.match(solverInfo, "^([^\n]*)\n(%d*)\n(.*)$");
        assert(componentName and componentDataLen and rem, "catastrophic error: tile savedata component data aligned incorreectly");

        componentDataLen = tonumber(componentDataLen);

        local componentData = string.sub(rem, 0, componentDataLen);

        local component = Milos_Grid_Implementation.getComponent(componentName);
        component:loadSavedata(componentData);

        self:addComponent(component);

        solverInfo = string.sub(rem, componentDataLen + 2, -1); -- + 2 because all components finish with '\n'
    end

    return retData; -- return remaining object save data because injectWhitelist type of 2
end

return TileBase;