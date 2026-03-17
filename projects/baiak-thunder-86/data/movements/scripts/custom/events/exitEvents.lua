function onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	-- Battlefield
	BATTLEFIELD:removePlayer(player:getId())

	-- SafeZone
	player:setStorageValue(SAFEZONE.storage, 0)
	SAFEZONE:removePlayer(player:getId())
	
	-- SnowBall
	if type(CACHE_GAMEPLAYERS) == "table" then
		for pos, players in ipairs(CACHE_GAMEPLAYERS) do
			if player:getId() == players then
				table.remove(CACHE_GAMEPLAYERS, pos)
				return true
			end
		end
	end

	-- General
	player:sendTextMessage(MESSAGE_INFO_DESCR, "You left the event.")
	player:setStorageValue(STORAGEVALUE_EVENTS, 0)
	
	-- Boss Room Cleanup on Exit
	-- Boss Room Cleanup on Exit
	if _G.BossRoom then
		BossRoom:checkAndCleanPlayer(player)
	end
	
	player:teleportTo(player:getTown():getTemplePosition())
	player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
end
