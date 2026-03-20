function onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
    if not player then
        return false
    end

	local temple = player:getTown()
	local templePos = temple:getTemplePosition()
	local guild = player:getGuild()

    if not guild then
  	    player:getPosition():sendMagicEffect(CONST_ME_POFF)
		player:teleportTo(templePos)
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "".. CASTLE24H.castleName .." ".. CASTLE24H.messageNeedsGuild .."")
        return false
    end

	local guildId = guild:getId()
	local guildName = guild:getName()

	if guildId == Game.getStorageValue(STORAGEVALUE_CASTLE_DOMINADO) or guildId == CASTLE24H:getGuildIdFromCastle() then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "".. CASTLE24H.castleName .." ".. CASTLE24H.messageGuildDominant .."")
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		player:teleportTo(fromPosition, true)
	else
		Game.setStorageValue(STORAGEVALUE_CASTLE_DOMINADO, guildId)
		Game.broadcastMessage("".. CASTLE24H.castleName .." The castle has been dominated by player ".. player:getName() .." from guild ".. guildName ..".", MESSAGE_STATUS_WARNING)
		player:getPosition():sendMagicEffect(CONST_ME_HOLYAREA)
		db.query(('UPDATE `castle` SET `name` = "%s", `guild_id` = %d'):format(guildName, guildId))
		return true
	end
end
