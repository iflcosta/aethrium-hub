function onStepIn(creature, item, position, fromPosition)
    local player = creature:getPlayer()
    if not player then
        return true
    end

    if player:getGroup():getAccess() then
        player:teleportTo(SAFEZONE.positionEnterEvent)
        return true
    end

    if player:getLevel() < SAFEZONE.levelMin then
        player:sendCancelMessage(SAFEZONE.messages.prefix .."You need to be level " .. SAFEZONE.levelMin .. " or higher to enter the event.")
        player:teleportTo(fromPosition, true)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end

    if player:getItemCount(2165) >= 1 then
        player:sendCancelMessage(SAFEZONE.messages.prefix .."You cannot enter the event with a stealth ring.")
        player:teleportTo(fromPosition, true)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end

    local ring = player:getSlotItem(CONST_SLOT_RING)
    if ring then
        if ring:getId() == 2202 then
            player:sendCancelMessage(SAFEZONE.messages.prefix .." You cannot enter the event with a stealth ring.")
            player:teleportTo(fromPosition, true)
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
            return true
        end
    end

    for a in pairs(SAFEZONE.players) do
        target = Player(a)
        if player:getIp() == target:getIp() then
            player:sendCancelMessage(SAFEZONE.messages.prefix .. "You already have another player inside the event.")
            player:teleportTo(fromPosition, true)
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
            return true
        end
    end

    if safezoneTotalPlayers() >= SAFEZONE.maxPlayers then
        player:sendCancelMessage(SAFEZONE.messages.prefix .. "The event has reached the maximum number of participants.")
        player:teleportTo(fromPosition, true)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end

    local outfit = player:getSex() == 0 and 136 or 128
    local treeLifeColor = SAFEZONE.lifeColor[3]
    player:setOutfit({lookType = outfit, lookHead = treeLifeColor, lookBody = treeLifeColor, lookLegs = treeLifeColor, lookFeet = treeLifeColor})

    player:sendTextMessage(MESSAGE_INFO_DESCR, SAFEZONE.messages.prefix .."You entered the event. Good luck!")
    player:teleportTo(SAFEZONE.positionEnterEvent)
    player:setStorageValue(STORAGEVALUE_EVENTS, 1)
    player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
    player:setStorageValue(SAFEZONE.storage, 3)
    SAFEZONE:insertPlayer(player:getId())

    return true
end
