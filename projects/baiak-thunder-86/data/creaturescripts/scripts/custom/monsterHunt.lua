function onKill(player, target)

	if Game.getStorageValue(MONSTER_HUNT.storages.monster) == nil then
		return true
	end

	if not player or not target then
		return true
	end

	if player:getStorageValue(MONSTER_HUNT.storages.player) == -1 then
		player:setStorageValue(MONSTER_HUNT.storages.player, 0)
	end

	if target:isMonster() and target:getName():lower() == (MONSTER_HUNT.list[Game.getStorageValue(MONSTER_HUNT.storages.monster)]):lower() then
		local kills = player:getStorageValue(MONSTER_HUNT.storages.player) + 1
		player:setStorageValue(MONSTER_HUNT.storages.player, kills)
		player:sendTextMessage(MESSAGE_STATUS_BLUE_LIGHT, MONSTER_HUNT.messages.prefix .. MONSTER_HUNT.messages.kill:format(kills, target:getName()))
		
		local found = false
		for i = 1, #MONSTER_HUNT.players do
			if MONSTER_HUNT.players[i][1] == player:getId() then
				MONSTER_HUNT.players[i][2] = kills
				found = true
				break
			end
		end
		
		if not found then
			table.insert(MONSTER_HUNT.players, {player:getId(), kills})
		end
	end

	return true
end