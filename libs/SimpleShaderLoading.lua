--this was made by: Lsupergame :D

--the point of this library is to make loading shaders simpler.
local Allshaders = {}
crashFailsafeEnabled = false --if true it will just continue without executing, better for users. If false, it makes the game crash when a shader is not valid, better for debugging. 

function addShader(shaderName, shaderPath)
local isClone = false
for i, shader in ipairs(Allshaders) do
    if shader.name == shaderName then
        isClone = true
    end
end


if not isClone and shaderName and shaderPath and love.filesystem.getInfo(shaderPath) then
    table.insert(Allshaders, {name = shaderName, path = shaderPath, shader = love.graphics.newShader(shaderPath)})
end


if not shaderName then
        if not crashFailsafeEnabled then
            error("Shader name not valid in function 'addShader'") -- Crashes for debugging
        else
            print("Shader name not valid in function 'addShader'") --prevents crash, just doesnt use the shader and prints the error
        end
    return
end

    if not shaderPath or not love.filesystem.getInfo(shaderPath) then
        if not crashFailsafeEnabled then
            error("Shader path not valid in function 'addShader'") -- Crashes for debugging
        else
           print("Shader path not valid in function 'addShader'") --prevents crash, just doesnt use the shader and prints the error
        end
    return
end


if isClone then
        if not crashFailsafeEnabled then
            error("Shader is already added") -- Crashes for debugging
        else
            print("Shader is already added") --prevents crash, just doesnt use the shader and prints the error
        end
        return
    end

end



function removeShader(shaderName)
    local foundShader = false
    for i, shader in ipairs(Allshaders) do
        if shader.name == shaderName then
    table.remove(Allshaders, i)
    foundShader = true
        end
    end
 if not shaderName or not foundShader then
        if not crashFailsafeEnabled then
            error("Shader name not valid in function 'removeShader'") -- Crashes for debugging
        else
            print("Shader name not valid in function 'removeShader'") --prevents crash, just doesnt use the shader and prints the error
        end
        return
    end
end



function giveShaderExtern(shaderName, uniformName, uniformValue) --gives an extern to a shader
    local foundShader = false
    local foundShaderUniformName = false
    if shaderName and uniformName and uniformValue then
    for _, shaderData in ipairs(Allshaders) do
        if shaderData.name == shaderName and shaderData.shader:hasUniform(uniformName) then
       shaderData.shader:send(uniformName, uniformValue)
       foundShaderUniformName = true
    end
end


 if not shaderName then
        if not crashFailsafeEnabled then
            error("Shader name not valid in function 'giveShaderExtern'") -- Crashes for debugging
        else
            print("Shader name not valid in function 'giveShaderExtern'") --prevents crash, just doesnt use the shader and prints the error
        end
        return
    end


    if not uniformName or not uniformValue or not foundShaderUniformName then
        if not crashFailsafeEnabled then
            error("Shader uniform name or uniform value not valid in function 'giveShaderExtern'") -- Crashes for debugging
        else
            print("Shader uniform name or uniform value not valid in function 'giveShaderExtern'") --prevents crash, just doesnt use the shader and prints the error
        end
        return
    end
end

end



function drawShaders() --draws the shaders
    if #Allshaders > 0 then
        love.graphics.setShader(Allshaders[#Allshaders].shader)
    end
end


function stopShaders() --stops drawing the shaders
love.graphics.setShader(nil)
end



function resetShaders() --resets all shaders
    for i, shader in ipairs(Allshaders) do
        shader.shader = love.graphics.setShader()
    end
end