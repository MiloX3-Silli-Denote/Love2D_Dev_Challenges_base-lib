this file has every function in the "SimpleShaderLoading" library, along with what it does.


1: addShader(shaderName, shaderPath)
It adds a shader. 
It requires:
the name of the shader (string)
the path of the shader (string)


2: removeShader(shaderName, shaderPath)
It removes a shader.
It requires the same things as addShader


3: giveShaderExtern(shaderName, uniformName, uniformValue)
Gives an extern to a shader

4: drawShaders()
Draws all the shaders. Needed in love.draw

5: stopShaders() 
Stops drawing the shaders. To resume, call `drawShaders()` again.

6: resetShaders() 
resets all shaders.