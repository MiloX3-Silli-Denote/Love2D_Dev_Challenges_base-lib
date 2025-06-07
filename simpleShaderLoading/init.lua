--this was made by: Lsupergame :D

--the point of this library is to make loading shaders simpler.

-- globalize
_G.SimpleShaderLoading = {}; -- not a class
local self = SimpleShaderLoading; -- for readability

function SimpleShaderLoading.init()
    -- allShaders was being used as an array of shader
    -- but given that every time a shader was needed it would use a key and locate it
    -- I have changed it into a pairs (keyed) table for O(1) lookup time
    self.allShaders = {};

    -- removed 'crashFailsafeEnabled' because catastrophic errors were able to occur when not erroring
end

function SimpleShaderLoading.addShader(shaderName, shaderPath)
    assert(type(shaderName) == "string", "Cannot add shader with invalid name data type: " .. type(shaderName));
    assert(self.allShaders[shaderName] == nil, "Shader is already added " .. shaderName); -- if its a clone
    assert(type(shaderPath) == "string", "shader path must be a string: " .. type(shaderPath));
    assert(love.filesystem.getInfo(shaderPath), "Shader path not valid: " .. shaderPath);

    self.allShaders[shaderName] = love.graphics.newShader(shaderPath);
    -- previous shader item contained more info than needed, better to not make a table
end

function SimpleShaderLoading.removeShader(shaderName)
    assert(self.allShaders[shaderName], "Cannot remove shader that does not exist: " .. shaderName);

    -- accidentally called invalid: 'destroy' instead of 'release'
    self.allShaders[shaderName].shader:release(); -- tell love to remove it from gpu memory
    self.allShaders[shaderName] = nil; -- remove it from the list of shaders
end

function SimpleShaderLoading.giveShaderExtern(shaderName, uniformName, ...) -- gives an extern to a shader
    assert(self.allShaders[shaderName], "Cannot send value to shader that does not exist: " .. (shaderName or type(shaderName)));
    assert(self.allShaders[shaderName]:hasUniform(uniformName), "tried to send value to suniform '" .. uniformName .."' that does not exist in shader " .. shaderName);

    self.allShaders[shaderName]:send(uniformName, ...); -- ... to allow for sending vectors and matrices with individual elements
end

function SimpleShaderLoading.activateShader(shaderName)
    assert(self.allShaders[shaderName], "Cannot activate shader that does not exist: " .. (shaderName or type(shaderName)));

    love.graphics.setShader(self.allShaders[shaderName]);
end

function SimpleShaderLoading.stopShaders() --stops drawing the shaders
    love.graphics.setShader()
end

-- removed SimpleShaderLoading.startShaders() because it didnt do anything useful

-- remove SimpleShaderLoading.resetShaders() because it removed all shaders which isnt useful

return SimpleShaderLoading;