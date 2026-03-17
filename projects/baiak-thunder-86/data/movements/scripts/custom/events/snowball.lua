function onStepIn(creature, item, position, fromPosition)
    local player = creature:getPlayer()

    if SNOWBALL.level.active and SNOWBALL.level.minLevel and player:getLevel() < SNOWBALL.level.minLevel then
        player:sendCancelMessage(SNOWBALL.prefix .. "You need to be level " .. SNOWBALL.level.minLevel .. " or higher to enter the event.")
        player:teleportTo(fromPosition, true)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end

    if player:getItemCount(2165) >= 1 then
        player:sendCancelMessage(SNOWBALL.prefix .. "You cannot enter the event with a stealth ring.")
        player:teleportTo(fromPosition, true)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end

    local ring = player:getSlotItem(CONST_SLOT_RING)
    if ring then
        if ring:getId() == 2202 then
            player:sendCancelMessage(SNOWBALL.prefix .. "You cannot enter the event using a stealth ring.")
            player:teleportTo(fromPosition, true)
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
            return true
        end
    end

    for _, check in ipairs(Game.getPlayers()) do
        if player:getIp() == check:getIp() and check:getStorageValue(STORAGEVALUE_EVENTS) > 0 then
            player:sendCancelMessage(SNOWBALL.prefix .. "You already have another player inside the event.")
            player:teleportTo(fromPosition, true)
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
            return true
        end
    end

    if #CACHE_GAMEPLAYERS >= SNOWBALL.maxPlayers then
        player:sendCancelMessage(SNOWBALL.prefix .. "The event has reached the maximum number of participants.")
        player:teleportTo(fromPosition, true)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end

    table.insert(CACHE_GAMEPLAYERS, player:getId())
    player:teleportTo(SNOWBALL.posWait)
    player:setStorageValue(STORAGEVALUE_EVENTS, 1)
    return true
end
