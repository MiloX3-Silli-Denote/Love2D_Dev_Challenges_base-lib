local function conwaysGOLFunction(tile)
    local x = tile.x;
    local y = tile.y;

    local tile1 = Milos_Grid_Implementation.getTileAt(x - 1, y - 1);
    local tile2 = Milos_Grid_Implementation.getTileAt(x    , y - 1);
    local tile3 = Milos_Grid_Implementation.getTileAt(x + 1, y - 1);
    local tile4 = Milos_Grid_Implementation.getTileAt(x - 1, y    );
    local tile5 = Milos_Grid_Implementation.getTileAt(x + 1, y    );
    local tile6 = Milos_Grid_Implementation.getTileAt(x - 1, y + 1);
    local tile7 = Milos_Grid_Implementation.getTileAt(x    , y + 1);
    local tile8 = Milos_Grid_Implementation.getTileAt(x + 1, y + 1);

    local totalAlive = 0;
    -- make sure they are conwaysGOL tiles
    totalAlive = totalAlive + (tile1 and tile1.__name == "conwaysGOL" and tile1.alive and 1 or 0); -- ternary operation
    totalAlive = totalAlive + (tile2 and tile2.__name == "conwaysGOL" and tile2.alive and 1 or 0);
    totalAlive = totalAlive + (tile3 and tile3.__name == "conwaysGOL" and tile3.alive and 1 or 0);
    totalAlive = totalAlive + (tile4 and tile4.__name == "conwaysGOL" and tile4.alive and 1 or 0);
    totalAlive = totalAlive + (tile5 and tile5.__name == "conwaysGOL" and tile5.alive and 1 or 0);
    totalAlive = totalAlive + (tile6 and tile6.__name == "conwaysGOL" and tile6.alive and 1 or 0);
    totalAlive = totalAlive + (tile7 and tile7.__name == "conwaysGOL" and tile7.alive and 1 or 0);
    totalAlive = totalAlive + (tile8 and tile8.__name == "conwaysGOL" and tile8.alive and 1 or 0);

    if totalAlive < 2 then
        tile:setLiving(false); -- fewer than 2 then die
    elseif totalAlive > 3 then
        tile:setLiving(false); -- more than 3 then die
    elseif totalAlive == 3 then
        tile:setLiving(true); -- exactly 3 then become alive
    end -- if 2 then keep its state
end

local conwaysGOLSolver = Milos_Grid_Implementation.newSolver(conwaysGOLFunction);

return conwaysGOLSolver;