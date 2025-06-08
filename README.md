# Base Engine for The Venus Project!!

In order to allow for any type of game to be made along with most types of libraries to be added, not a whole lot can be done without limiting the people.
So I've decided that a love injector and a depth drawing system were the best for the job.

## How To Use?
There are Two libraries that come with this, get familiar with 'DepthDrawing' as you'll be using it a lot.
'LoveAffix' is much more niche but not without it's uses, it mostly acts as a dependancy for DepthDrawing but you *are* allowed to use it!

### DepthDrawing
DepthDrawing gives you the ability to draw to the screen and not worry about the order in which you draw objects in; however, you **must** utilize it.
trying to draw without DepthDrawing and you will quickly be halted as all of the love.graphics draw functions will cause an error.
if you want to draw to your own canvas and not deal with the DepthDrawing stuff, then it can be toggled on and off with: ```DepthDrawing.disable();``` and ```DepthDrawing.enable();``` (make sure it is enabled in order to see the frame).

DepthDrawing transforms the screen to always be a 16:9 aspect ratio with the origin in the center of the screen.
Basically just pretend youre always drawing to a 1920x1080 window where 0,0 is the center.

To draw something to the screen you will utilize the functions: ```DepthDrawing.startDrawingAtDepth();``` and ```DepthDrawing.stopDrawingAtDepth(depth);``` like so:
```lua
local nickelBuddy  = love.graphics.newImage("textures/nickel_buddy.png");
local funnyMuffler = love.graphics.newImage("textures/funny_muffler.png");
local jerkyPal     = love.graphics.newImage("textures/jerky_pal.png");
local booBooKeys   = love.graphics.newImage("textures/boo_boo_keys.png");

-- will cause an error
love.graphics.draw(nickelBuddy, 0,0);
love.graphics.draw(funnyMuffler, 0,0);
love.graphics.draw(jerkyPal, 0,0);
love.graphics.draw(booBooKeys, 0,0);
--------------------------------------------------------

-- will NOT cause an error
DepthDrawing.startDrawingAtDepth();

love.graphics.draw(nickelBuddy, 0,0);
love.graphics.draw(funnyMuffler, 0,0);
love.graphics.draw(jerkyPal, 0,0);
love.graphics.draw(booBooKeys, 0,0);

DepthDrawing.stopDrawingAtDepth(15); -- depth of 15
```
Alternatively DepthDrawing will call *both* functions for you if you use the DepthDrawing version of the graphics function like so:
```lua
local nickelBuddy  = love.graphics.newImage("textures/nickel_buddy.png");
local funnyMuffler = love.graphics.newImage("textures/funny_muffler.png");
local jerkyPal     = love.graphics.newImage("textures/jerky_pal.png");
local booBooKeys   = love.graphics.newImage("textures/boo_boo_keys.png");

-- draws all images seperately at different depths
DepthDrawing.draw(15, nickelBuddy, 0,0);  -- depth of 15
DepthDrawing.draw(16, funnyMuffler, 0,0); -- depth of 16
DepthDrawing.draw(17, jerkyPal, 0,0);     -- depth of 17
DepthDrawing.draw(18, booBooKeys, 0,0);   -- depth of 18
```
**All** of the love.graphics draw calls are available in DepthDrawing

While DepthDrawing is enabled: love.mouse.getPosition(), love.mouse.getX(), love.mouse.getY(), and the mouse related callbacks like mousemoved, mousepressed, mousereleased .etc will give you the transformed point (so the center of the screen is 0,0)

### LoveAffix
LoveAffix allows you to inject code between official love calls, for example, DepthDrawing uses this to cause draw calls to create an error when not drawing with a DepthDrawing.startDrawingAtDepth()
you are also able to alter inputs to functions for example: if you want to have every love.graphics.translate() call translate the world by an additional 30 pixels than you could use ```LoveAffix.injectCodiIntoLove(function(x, y) return x + 30, y end, "graphics", "translate");```
If you inject code into a love function and return any number of values then those values will be used as the arguments for the next (injected or official)
Injecting code effectively places it into a queue: injecting will place the code at the begining of the queue and whenever the function is called it will call all items in order.
You can also use ```LoveAffix.appendCodeIntoLove(apendedCode, key, [key2]);``` to place code at the end of the queue.

#### IMPORTANT:
you are unable to inject or append code unless that function is prepped for it in love. you can do this by calling ```LoveAffix.makeCodeInjectable(key, [key2]);``` not all love items are valid for injection so be careful, but most things that you wold be using is.
there is no worry for calling ```LoveAffix.makeCodeInjectable(key, [key2]);``` on a function that is already prepped.

### SimpleShaderLoading
SimpleShaderLoading will keep track of, load, activate, send variables to, and unload shaders for you
call ```SimpleShaderLoading.addShader(shaderName, shaderFilename);``` to load a shader
if you want to unload a shader you can call ```SimpleShaderLoading.removeShader(shaderName);```
if you need to send a variable to a shader you can use ```SimpleShaderLoading.sendExternToShader(shaderName, externName, [externvalues ...]);```
to activate a shader simply call ```SimpleShaderLoading.activateShader(shaderName);```
and to deactivate shaders call ```SimpleShaderLoading.stopShaders();```
here is an example of using SimpleShaderLoading:
```lua
-- in love.load
SimpleShaderLoading.addShader("vhs", "shaders/SimpleShaderLoading/vhsFilter.frag");

-- in love.update
SimpleShaderLoading.sendExternToShader("vhs", "time", time);

-- in love.draw
SimpleShaderLoading.activateShader("vhs");
love.graphics.draw(curCanvas); -- canvas containing the frame wanted to be displayed on the screen
SimpleShaderLoading.stopShaders();
```

### TextureSimplifier
TextureSimplifier will keep track of, load, help draw, set filter, and resize for you
call ```TextureSimplifier.addTexture(textureName, textureFilename, [treatAsTextureOfWidth, treatAsTextureOfHeight]);``` to load a texture
the optional arguments "treatAsTextureOfWidth" and "treatAsTextureOfHeight" are for making it easier to draw if you plan on maybe changing the texture (if you define one of the args then you must define both)
so for example if you do something like:
```lua
-- textures/player.png is a 16x16 texture being treated as a 16x16 texture
TextureSimplifier.addTexture("player", "textures/player.png", 16,16);

-- love.draw
love.graphics.draw(TextureSimplifier.getDrawable("player", player.x, player.y)); -- draw player
```
then the "player" texture will draw in a 16x16 pixel area at player.x and player.y, but if you change "textures/player.png" to be a higher resolution
64x64 texture, then in normal love, you would have to scale it by 0.25 to get it to draw as it previously was, but TextureSimplifier will do this automatically, so nothing would change

remove a texture with ```TextureSimplifier.removeTexture(textureName);``` (this will unload it)
use ```TextureSimplifier.setFilter(textureName, nearFilter, farFilter);``` and ```TextureSimplifier.setDepthCompareMode(textureName, compareMode);``` to perform those funcitons on the given texture

to draw a texture you can get a drawable (that is already scaled as the texture waants to be treated as) with ```TextureSimplifier.getDrawable(textureName);```
which allows you to draw it using something like: ```love.graphics.draw(TextureSimplifier.getDrawable(texName), obj.x, obj.y, obj.rot, obj.scaleX, obj.scaleY);```

or to just get the unmodified texture 'image' object call ```TextureSimplifier.getTexture(textureName);```