-- library made By Milo:3 Silli Denote
-- MIT License applied here

_G.TextureSimplifier = {}; -- not a class
local self = TextureSimplifier; -- for readability

function TextureSimplifier.init()
    self.textures = {}; -- keyed table of textures
end

function TextureSimplifier.addTexture(name, filename, treatAsWide, treatAsTall)
    assert(type(name) == "string", "tried to load a texture to an invalid name: " .. type(name));
    assert(self.textures[name] == nil, "tried to load a texture to a name that already exists: " .. name);
    assert(type(filename) == "string", "tried to load texture with an invalid filename: " .. type(filename));
    assert(love.filesystem.getInfo(filename), "tried to load a texture with an invalid texture name: " .. filename);
    assert(type(treatAsWide) == type(treatAsTall), "tried to set width of texture but not height: " .. name);
    assert(not treatAsWide or type(treatAsWide) == "number", "tried to set width of texture as non number: " .. name);

    local tex = love.graphics.newImage(filename);

    -- use texture dimensions if no size given
    treatAsWide = treatAsWide or tex:getWidth();
    treatAsTall = treatAsTall or tex:getHeight();

    -- add texture, dimmensions, and mesh for drawing to list of textures
    self.textures[name] = {
        img = tex;
        width = treatAsWide;
        height = treatAsTall;
        mesh = love.graphics.newMesh(
            {
                {0          ,0          , 0,0};
                {treatAsWide,0          , 1,0};
                {treatAsWide,treatAsTall, 1,1};
                {0          ,treatAsTall, 0,1};
            },
            "fan", "static"
        );
    };

    self.textures[name].mesh:setTexture(tex);
end

function TextureSimplifier.setFilter(name, near, far)
    assert(type(name) == "string", "tried to change filter of an invalid name from textures: " .. type(name));
    assert(self.textures[name], "tried to change filter of a texture that does not exist: " .. name);

    self.textures[name].img:setFilter(near, far); -- set filter given
end

function TextureSimplifier.setDepthSampleMode(name, depthSampleMode)
    assert(type(name) == "string", "tried to set depth sample mode of an invalid name from textures: " .. type(name));
    assert(self.textures[name], "tried to set depth sample mode of a texture that does not exist: " .. name);

    self.textures[name].img:setDepthSampleMode(depthSampleMode); -- set filter given
end

function TextureSimplifier.removeTexture(name)
    assert(type(name) == "string", "tried to remove an invalid name from textures: " .. type(name));
    assert(self.textures[name], "tried to remove a texture that does not exist: " .. name);

    self.textures[name].mesh:release(); -- unload mesh and img from gpu
    self.textures[name].img:release();
    self.textures[name] = nil; -- remove texture from list
end

function TextureSimplifier.getTexture(name)
    assert(type(name) == "string", "tried to get texture of an invalid name from textures: " .. type(name));
    assert(self.textures[name], "tried to get texture of a texture that does not exist: " .. name);

    return self.textures[name].img;
end

function TextureSimplifier.getDrawable(name)
    assert(type(name) == "string", "tried to get drawable of an invalid name from textures: " .. type(name));
    assert(self.textures[name], "tried to get drawable of a texture that does not exist: " .. name);

    return self.textures[name].mesh;
end

return TextureSimplifier;