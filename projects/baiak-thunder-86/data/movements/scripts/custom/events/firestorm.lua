function onStepIn(creature, item, position, fromPosition)
    local player = creature:getPlayer()
    if not player then
        return true
    end

    if player:getGroup():getAccess() then
        player:teleportTo(FSE.teleport.destination)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You are participating only as a spectator.")
        return true
    end

    if player:getLevel() < FSE.players.levelMin then
        player:sendCancelMessage(FSE.msg.prefix .. "You need to be level " .. FSE.players.levelMin .. " or higher to enter the event.")
        player:teleportTo(fromPosition, true)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end

    if player:getItemCount(2165) >= 1 then
        player:sendCancelMessage(FSE.msg.prefix .. "You cannot enter with a stealth ring in the event.")
        player:teleportTo(fromPosition, true)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end

    local ring = player:getSlotItem(CONST_SLOT_RING)
    if ring then
        if ring:getId() == 2202 then
            player:sendCancelMessage(FSE.msg.prefix .. " You cannot enter the event with a stealth ring.")
            player:teleportTo(fromPosition, true)
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
            return true
        end
    end

    for _, check in ipairs(Game.getPlayers()) do
        if player:getIp() == check:getIp() and check:getStorageValue(STORAGEVALUE_EVENTS) > 0 then
            player:sendCancelMessage(FSE.msg.prefix .. "You already have another player inside the event.")
            player:teleportTo(fromPosition, true)
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
            return true
        end
    end

    if #FSE:GetPlayers() >= FSE.players.max then
        player:sendCancelMessage(FSE.msg.prefix .. "The event has reached the maximum number of participants.")
        player:teleportTo(fromPosition, true)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end

    player:sendTextMessage(MESSAGE_INFO_DESCR, FSE.msg.prefix .. "You entered the event. Good luck!")
    player:teleportTo(FSE.teleport.destination)
    player:setStorageValue(STORAGEVALUE_EVENTS, 1)
    player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)

    return true
end
