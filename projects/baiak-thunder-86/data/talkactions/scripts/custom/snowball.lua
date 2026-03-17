-- ============================================================
-- SnowBall Event Start Command
-- Usage: !snowball
-- ============================================================

function onSay(player, words, param)
    -- Check if player has permission
    if not player:getGroup():getAccess() then
        return true
    end
    
    -- Load the SNOWBALL configuration
    dofile("data/lib/events/snowball.lua")
    
    -- Initialize CACHE_GAMEPLAYERS if not exists
    if not CACHE_GAMEPLAYERS then
        CACHE_GAMEPLAYERS = {}
    end
    
    -- Get all players in the waiting area
    local waitingPos = SNOWBALL.waitingPos
    local tile = Tile(waitingPos)
    if tile then
        local creatures = tile:getCreatures()
        for _, creature in ipairs(creatures) do
            if creature:isPlayer() then
                table.insert(CACHE_GAMEPLAYERS, creature:getId())
            end
        end
    end
    
    -- Start the event with waiting time instead of immediately
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Starting SnowBall event with waiting time...")
    
    -- Call the startGame function with rounds = duracaoEspera to start waiting period
    startGame(SNOWBALL.duracaoEspera)
    
    return true
end
