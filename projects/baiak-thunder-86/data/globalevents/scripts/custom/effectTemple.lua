local positions = {
    [1] = Position(989, 1211, 7),
    [2] = Position(989, 1209, 7),
    [3] = Position(993, 1209, 7),
    [4] = Position(993, 1211, 7)
}
local shot = 4

function onThink(interval)
    -- Optimized: Only check if there are people in the Temple area (approx 15x15)
    local spectators = Game.getSpectators(Position(991, 1210, 7), false, true, 8, 8, 6, 6)
    if #spectators == 0 then
        return true
    end

    positions[1]:sendDistanceEffect(positions[4], shot)
    positions[3]:sendDistanceEffect(positions[2], shot)
    
    addEvent(function()
        positions[4]:sendDistanceEffect(positions[3], shot)
        positions[2]:sendDistanceEffect(positions[1], shot)
    end, 270)

    addEvent(function()
        positions[3]:sendDistanceEffect(positions[2], shot)
        positions[1]:sendDistanceEffect(positions[4], shot)
    end, 560)

    addEvent(function()
        positions[2]:sendDistanceEffect(positions[1], shot)
        positions[4]:sendDistanceEffect(positions[3], shot)
    end, 850)
    
    return true
end
