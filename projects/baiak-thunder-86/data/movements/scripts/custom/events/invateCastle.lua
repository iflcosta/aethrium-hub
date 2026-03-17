function onStepIn(creature, item, position, fromPosition)
    local player = creature:getPlayer()
    if not player then
        return false
    end

    local guild = player:getGuild()
    if not guild then
        player:teleportTo(fromPosition, true)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "".. CASTLE24H.castleName .." ".. CASTLE24H.messageNeedGuild .."")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    local guildId = guild:getId()
    local guildName = guild:getName()
    local warningTime = CASTLE24H.warningTime

    if CASTLE24H.levelToConquer == true and player:getLevel() < CASTLE24H.level then
        player:teleportTo(fromPosition, true)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "".. CASTLE24H.castleName .." ".. CASTLE24H.messageMinimumLevel .." (".. CASTLE24H.level .."+)")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    if player:getStorageValue(STORAGEVALUE_CASTLE_SPAM) > os.time() and guild then
        return true
    end

    if (guild) and (guildId == CASTLE24H:getGuildIdFromCastle()) then
        if Game.getStorageValue(STORAGEVALUE_CASTLE_DOMINADO) == nil or not Game.getStorageValue(STORAGEVALUE_CASTLE_DOMINADO) then
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "".. CASTLE24H.castleName .." ".. CASTLE24H.messageWelcome .."")
            return true
        end
    end

    if guildId ~= Game.getStorageValue(STORAGEVALUE_CASTLE_DOMINADO) or guildId ~= CASTLE24H:getGuildIdFromCastle() then
        Game.broadcastMessage("".. CASTLE24H.castleName .." The castle is being invaded by player ".. player:getName() .." from guild ".. guildName ..".", MESSAGE_STATUS_WARNING)
        player:setStorageValue(STORAGEVALUE_CASTLE_SPAM, (os.time() + warningTime))
    else
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "".. CASTLE24H.castleName .." ".. CASTLE24H.messageWelcome .."")
    end

    return true
end
