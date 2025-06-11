local function updateEveryTickFunc(tile)
    tile:queueValueChange("queuedForUpdate", true);
end


local conwaysGOLSolver = Milos_Grid_Implementation.newSolver(updateEveryTickFunc);

return conwaysGOLSolver;