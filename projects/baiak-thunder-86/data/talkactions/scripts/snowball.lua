function onSay(player, words, param)
    if not isInArena(player) then
        return false
    end

    if param == SNOWBALL.shootCommand then
        if player:getExhaustion(10107) > 1 then
            return true
        end

        if not SNOWBALL.infiniteAmmo then
            if player:getStorageValue(10108) > 0 then
                player:setStorageValue(10108, player:getStorageValue(10108) - 1)
                player:sendCancelMessage(SNOWBALL.prefix .. (SNOWBALL.messageAmmoLeft):format(player:getStorageValue(10108)))
            else
                player:sendCancelMessage(SNOWBALL.prefix .. SNOWBALL.messageNoAmmo)
                return true
            end
        end

        player:setExhaustion(10107, SNOWBALL.exhaustionTime)
        shootSnowball(player:getId(), player:getPosition(), SNOWBALL.shootDistance, player:getDirection())
        return false
    elseif param == "info" then
        local infoStr = "     ## -> Player Infos <- ##\n\nPoints: " .. player:getStorageValue(10109) .. "\nSnowballs: " .. player:getStorageValue(10108)
        infoStr = infoStr .. "\n\n          ## -> Ranking <- ##\n\n"
        
        for i = 1, 5 do
            if CACHE_GAMEPLAYERS[i] then
                infoStr = infoStr .. i .. ". " .. Player(CACHE_GAMEPLAYERS[i]):getName() .. "\n"
            end
        end

        for pos, playerId in ipairs(CACHE_GAMEPLAYERS) do
            if player:getId() == playerId then
                infoStr = infoStr .. "My position in the ranking: " .. pos
            end
        end

        player:showTextDialog(2111, infoStr)
        return false
    end
end
