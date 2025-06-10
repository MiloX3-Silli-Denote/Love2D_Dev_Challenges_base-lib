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

    rawset(self, "_" .. key, newFunc);
end

function TileBase.new()
    local instance = setmetatable({}, TileBase);

    return instance;
end

function TileBase:init()
    assert(self.__name, "cannot initialize tileBase if __name is not set");

    self.x = 0; -- position
    self.y = 0;

    self.solvers = {}; -- list of injectable functions to be called on :update()

    self.setQueue = {}; -- queue of setting variables in this object

    return self; -- allow for instance = setmetatable({}, Tile):init();
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

function TileBase:queueValueChange(name, newVal)
    table.insert(self.setQueue, {name = name, newVal = newVal});
end

function TileBase:setValuesFromQueue()
    for i, v in ipairs(self.setQueue) do
        self[v.name] = v.newVal;
    end

    self.setQueue = {}; -- empty the queue
end

function TileBase:_update(dt)
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

    local ret = "v0.1\n"; -- version

    local data = "x|" .. tostring(self.x) .. "\n";
    data = data .. "y|" .. tostring(self.y) .. "\n";
    data = data .. "solvers\n";

    for _, v in ipairs(self.solvers) do
        data = data .. v.name .. "\n"; -- add the names of the solvers to the data
    end

    ret = ret .. tostring(string.len(data)) .. "\n" .. data;

    return ret .. "|\n" .. append;
end

function TileBase:_loadSavedata(data) -- return remaining object save data because injectWhitelist type of 2
    local version, dataLen, allData = string.match(data, "^([^\n]*)\n(%d+)\n(.*)$");
    assert(version and dataLen and allData, "tried to load corrupted save data");

    if version == "v0.1" then
        -- loading the 0.1 version of the TileBase loader
    else
        error("tried loading TileBase with non-supported version");
    end

    -- seperate the data used in this function vs the data used inn the object specific function
    local myData = string.sub(allData, 1, dataLen);
    -- + 3 because: + 1 to get unique data, and guarenteed to contain '|\n'
    local retData = string.sub(allData, dataLen + 3, -1);

    -- seperate the x, y and solver data
    local x, y, solverInfo = string.match(myData, "^x|([%d%-%.]+)\ny|([%d%-%.]+)\nsolvers\n(.*)$");
    self.x = tonumber(x);
    self.y = tonumber(y);

    self.solvers = {}; -- reset list of solvers
    while string.len(solverInfo) > 1 do -- 1 because solver is guarenteed to finish with a '\n'
        local nextSolverName, solverInfoRemaining = string.match(solverInfo, "^([^|\n]*)\n(.*)$");

        table.insert(self.solvers, Milos_Grid_Implementation.getSolver(nextSolverName));

        solverInfo = solverInfoRemaining;
    end

    return retData; -- return remaining object save data because injectWhitelist type of 2
end

return TileBase;