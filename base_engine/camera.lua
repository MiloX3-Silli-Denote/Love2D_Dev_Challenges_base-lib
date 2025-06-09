local Camera = {}; -- not a class
local self = Camera; -- for readability

function Camera.init()
    self.x = 0; -- camera position
    self.y = 0;

    -- 1 for normal camera movement, 0 for infinite distance (no movement) 1 < X for closer to the camera
    -- double the value to double the speed of movement
    self.paralax = 0;

    self.scale = 1; -- how many 1920x1080 screens fit in the screen

    self.rotation = 0; -- radians

    -- whether or not to immedietely alter graphics coordinates when altering a value
    self.applied = false;

    self.pushes = {}; -- list of pushes of the camera transformations

    return self; -- allow for Camera = require("camera").init();
end

function Camera.setPosition(x, y)
    assert(type(x) == "number", "tried to give non-number as x position for camera " .. type(x));
    assert(type(x) == "number", "tried to give non-number as y position for camera " .. type(y));

    self.x = x;
    self.y = y;

    self.tryToApplyTransform(); -- if the camera is active then apply its transform
end

function Camera.translate(x, y)
    assert(type(x) == "number", "tried to translate x position of camera by non-number " .. type(x));
    assert(type(x) == "number", "tried to translate y position of camera by non-number " .. type(y));

    self.x = self.x + x;
    self.y = self.y + y;

    self.tryToApplyTransform(); -- if the camera is active then apply its transform
end

function Camera.setParalax(paralax)
    assert(type(paralax) == "number", "tried to set paralax of camera to non-number " .. type(paralax));

    self.paralax = paralax;

    self.tryToApplyTransform(); -- if the camera is active then apply its transform
end

function Camera.resetParalax() -- normal distance from camera
    self.paralax = 1;

    self.tryToApplyTransform(); -- if the camera is active then apply its transform
end

function Camera.setScale(scale)
    assert(type(scale) == "number", "tried to set scale of camera to non-number " .. type(scale));

    self.scale = scale;

    self.tryToApplyTransform(); -- if the camera is active then apply its transform
end

function Camera.resetScale() -- normal scale
    self.scale = 1;

    self.tryToApplyTransform(); -- if the camera is active then apply its transform
end

function Camera.setRotation(rot)
    assert(type(rot) == "number", "tried to set rotation of camera to non-number " .. type(rot));

    self.rotation = rot;

    self.tryToApplyTransform(); -- if the camera is active then apply its transform
end

function Camera.rotate(rot)
    assert(type(rot) == "number", "tried to rotate camera by a non-number " .. type(rot));

    self.rotation = self.rotation + rot;

    self.tryToApplyTransform(); -- if the camera is active then apply its transform
end

function Camera.resetRotation()
    self.rotation = 0;

    self.tryToApplyTransform(); -- if the camera is active then apply its transform
end

function Camera.push()
    local cam = {
        x        = self.x;
        y        = self.y;
        scale    = self.scale;
        rotation = self.rotation;
        paralax  = self.paralax;
    };

    table.insert(self.pushes, cam);
end

function Camera.pop()
    assert(#self.pushes > 0, "tried to pop camera more times then camera was pushed");

    local cam = table.remove(self.pushes, #self.pushes);

    self.x        = cam.x;
    self.y        = cam.y;
    self.scale    = cam.y;
    self.rotation = cam.rotation;
    self.paralax  = cam.paralax;
end

function Camera.reset()
    self.x        = 0;
    self.y        = 0;
    self.scale    = 1;
    self.rotation = 0;
    self.paralax  = 1;
end
Camera.origin = Camera.reset; -- allow either to be called (for aesthetic choice)

function Camera.applyCamera()
    self.applied = true;

    love.graphics.push();

    self.tryToApplyTransform();
end

function Camera.tryToApplyTransform()
    if not self.applied then
        return;
    end

    love.graphics.origin();
    love.graphics.scale(self.scale);
    love.graphics.rotate(-self.rotation); -- negative because the camera is rotating
    love.graphics.translate(-self.x * self.paralax, -self.y * self.paralax);
end

function Camera.unapplyCamera()
    self.applied = false;
    love.graphics.pop();
end

return Camera;