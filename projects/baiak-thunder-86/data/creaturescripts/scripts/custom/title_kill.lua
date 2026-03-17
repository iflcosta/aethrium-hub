-- TITLES - Kill Counter
function onKill(player, target)
    if not target:isPlayer() then return true end
    
    local kills = math.max(0, player:getStorageValue(49001))
    player:setStorageValue(49001, kills + 1)
    
    if kills + 1 >= 100 then
        player:checkTitleUnlocks()
    end
    return true
end
