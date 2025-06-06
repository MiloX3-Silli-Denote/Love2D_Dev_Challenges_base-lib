mainGame = {}

--object used for testing
object1 = { 
texture = love.graphics.newImage('textures/game/Square.png'),
x = -960,
y = -540,
scale = 10,
rot = 0,
}

function mainGame.load() --load for game
--addShader("grayScale", 'shaders/game/grayScale.frag')  --added these for testing shaders
--removeShader('grayScale')
--addShader("grayScale", 'shaders/game/grayScale.frag')
end



function mainGame.update(dt) --update for game
--giveShaderExtern("grayScale", "test", 1) --also for testing shaders
end


function mainGame.draw() --draw for game
 if false then
    stopShaders()
     love.graphics.draw( --test for shaders and image loading
            object1.texture,
            object1.x,
            object1.y,
            object1.rot,
            object1.scale, object1.scale, 30, 32)
    drawShaders()
    end


    
end


return mainGame