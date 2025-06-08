local ConwaysGOLTile = Milos_Grid_Implementation.newTileBase();
ConwaysGOLTile.__index = ConwaysGOLTile;
ConwaysGOLTile.__name = "conwaysGOL"; -- name, for loading to the correct object properly

function ConwaysGOLTile.new()
    local instance = setmetatable({}, ConwaysGOLTile):init();

    instance:addSolver("conwaysGOL");

    instance.alive = false;

    return instance;
end

function ConwaysGOLTile:setLiving(alive)
    self.alive = alive;
end

function ConwaysGOLTile:draw()
    if self.alive then
        love.graphics.setColor(1,1,1); -- white
    else
        love.graphics.setColor(0,0,0); -- black
    end

    love.graphics.rectangle("fill", 0,0, 1,1); -- 1x1 (because of scaling)
end

return ConwaysGOLTile;