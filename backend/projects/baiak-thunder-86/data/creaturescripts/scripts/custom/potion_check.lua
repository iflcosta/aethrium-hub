function onThink(player, interval)
    -- Multi-second check to avoid high frequency processing
    -- interval is usually 1000ms, so we check every 30 iterations (30 seconds)
    local lastCheck = player:getStorageValue(99999) -- Temporary storage for throttle
    if lastCheck > os.time() then
        return true
    end
    player:setStorageValue(99999, os.time() + 30)

    player:updatePotionStatus()
    return true
end
