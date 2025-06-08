local LoveAffix = {}; -- not a class
local self = LoveAffix; -- for readability

function LoveAffix.init()
    local loveMeta = {};

    -- __index function for love and its tables
    function loveMeta.__index(_love, key)
        return rawget(_love, "F_" .. key);
    end

    -- __newindex function for love and its tables
    function loveMeta.__newindex(_love, key, value)
        if rawget(_love, "F_" .. key) then
            if _love == love then
                self.appendCodeIntoLove(value, key);

                return;
            else
                for k, v in pairs(love) do
                    if v == _love then
                        self.appendCodeIntoLove(value, k, key);

                        return;
                    end
                end
            end

            -- bad practice to do this type of wording, but as only love and its tables are able to contain
            -- this metatable then this is (probably) impossible to reach, but error just in case ;3
            error("cosmic ray detected");
        else
            rawset(_love, key, value);
        end
    end

    -- may need to make a whitelist for this
    for k, v in pairs(love) do
        if type(v) == "table" and not getmetatable(v) then
            setmetatable(v, loveMeta);
        end
    end

    -- errhand is supposed to be depracated but it does have this singular niche use
    love.errorhandler = love.errhand;
    love.errhand = nil;

    setmetatable(love, loveMeta);

    return self; -- allow: LoveAffix = require("loveAffix").init();
end

-- only certain love functions are actuall injectable, so know what youre doing
function LoveAffix.makeFunctionInjectable(key, key2)
    local _love = love;

    local errorMsg = "love." .. key .. (key2 and "." .. key2 or "");

    -- just keep it consistent
    if key2 then
        _love = _love[key];
        key = key2;
    end

    if rawget(_love, key) then
        assert(type(rawget(_love, key)) == "function", "tried to make a non function injectable: " .. errorMsg);

        rawset(_love, "F_" .. key, rawget(_love, key));
        rawset(_love, key, nil);
    else
        if rawget(_love, "F_" .. key) then -- function is already prepped
            return;
        end
        -- already injectable but make it permanent by placing a function there
        rawset(_love, "F_" .. key, function() end);
    end
end

function LoveAffix.injectCodeIntoLove(inject, key, key2)
    local errorInfo = "love." .. key .. (key2 and "." .. key2 or "");

    assert(type(inject) == "function", "tried to inject a non function into love: " .. errorInfo);

    local _love = love;

    -- just keep it consistent
    if key2 then
        _love = _love[key];
        key = key2;
    end

    -- if the item exists in the 'real' position than its not an injectable function
    assert(rawget(_love, key) == nil, "tried to inject code into an un-injectable love2d function: " .. errorInfo);

    -- there was no function here already
    if not _love[key] then
        rawset(_love, "F_" .. key, inject); -- rawset to avoid recursion with __newindex

        return;
    end

    local previousFunction = _love[key];

    assert(type(previousFunction) == "function", "tried to inject code into a non function: " .. errorInfo);

    -- call the inject function before the old function optionally with the return values as arguments
    rawset(_love, "F_" .. key,
        function(...)
            local args = {...};

            local newArgs = {inject(...)};

            if #newArgs > 0 then
                args = newArgs;
            end

            local ret = {previousFunction(unpack(args))};

            if #ret > 0 then
                return unpack(ret);
            else
                return unpack(args);
            end
        end
    );
end

function LoveAffix.appendCodeIntoLove(append, key, key2)
    local errorInfo = "love." .. key .. (key2 and "." .. key2 or "");

    assert(type(append) == "function", "tried to append a non function into lov: " .. errorInfo);

    local _love = love;

    -- just keep it consistent
    if key2 then
        _love = love[key];
        key = key2;
    end

    -- if the item exists in the 'real' position than its not an injectable function
    assert(rawget(_love, key) == nil, "tried to append code into an un-appendable love2d function: " .. errorInfo);

    -- there was no function here already
    if not _love[key] then
        rawset(_love, "F_" .. key, append); -- rawset to avoid recursion with __newindex

        return;
    end

    local previousFunction = _love[key];

    assert(type(previousFunction) == "function", "tried to append code into a non function: " .. errorInfo);

    -- call the old function before the appended function optionally with the return values as arguments
    rawset(_love, "F_" .. key,
        function(...)
            local args = {...};

            local newArgs = {previousFunction(...)};

            if #newArgs > 0 then
                args = newArgs;
            end

            local ret = {append(unpack(args))};

            if #ret > 0 then
                return unpack(ret);
            else
                return unpack(args);
            end
        end
    );
end

return LoveAffix;