function onSay(player, words, param)
	local storIndex = player:getStorageValue(STORAGEVALUE_SUPERUP_INDEX)
	
	if storIndex <= 0 then
		player:sendCancelMessage("Voce nao possui uma cave ativa do SuperUP")
		return false
	end

	local superUpVariavel = SUPERUP.areas[storIndex]
	if superUpVariavel then
		local currencyType = superUpVariavel.currency or "coins"
		local price = superUpVariavel.price or SUPERUP.nexusCoinCost
		local currencyName = currencyType == "tasks" and "Task Points" or "Nexus Coins"

		-- Buscar o tempo que a hunt foi comprada
		local resultTime = db.storeQuery("SELECT `time` FROM `exclusive_hunts` WHERE `hunt_id` = " .. storIndex)
		local startTime = 0
		if resultTime then
			startTime = result.getDataInt(resultTime, "time")
			result.free(resultTime)
		end

		local timeElapsed = os.time() - startTime
		local refundPercent = 0.5 -- Inicial 50%
		
		if timeElapsed >= 7200 then -- 2 horas
			refundPercent = 0
		elseif timeElapsed >= 5400 then -- 1 hora e 30 min
			refundPercent = 0.25
		end

		local refundAmount = math.floor(price * refundPercent)

		if refundAmount > 0 then
			if currencyType == "tasks" then
				local currentTaskPoints = math.max(0, player:getStorageValue(20021))
				local newTaskPoints = currentTaskPoints + refundAmount
				player:setStorageValue(20021, newTaskPoints)
				
				local accCoins = 0
				local queryCoins = db.storeQuery("SELECT `premium_points` FROM `accounts` WHERE `id` = " .. player:getAccountId())
				if queryCoins then
					accCoins = result.getDataInt(queryCoins, "premium_points")
					result.free(queryCoins)
				end
				local bossPoints = math.max(0, player:getStorageValue(20022))
				player:sendExtendedOpcode(201, json.encode({action = "points", data = {points = accCoins, secondPoints = newTaskPoints, thirdPoints = bossPoints}}))
			else
				local getPoints = db.storeQuery("SELECT `premium_points` FROM `accounts` WHERE `id` = " .. player:getAccountId())
				local points = 0
				if getPoints then
					points = result.getDataInt(getPoints, "premium_points")
					result.free(getPoints)
				end
				
				local newPoints = points + refundAmount
				db.query("UPDATE `accounts` SET `premium_points` = " .. newPoints .. " WHERE `id` = " .. player:getAccountId())
				
				local currentTaskPoints = math.max(0, player:getStorageValue(20021))
				local bossPoints = math.max(0, player:getStorageValue(20022))
				player:sendExtendedOpcode(201, json.encode({action = "points", data = {points = newPoints, secondPoints = currentTaskPoints, thirdPoints = bossPoints}}))
			end
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format(SUPERUP.msg.refund, refundAmount, currencyName))
		else
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Voce desistiu da cave mas nao recebeu reembolso pois o tempo limite de refund expirou")
		end
	end

	-- Teleportar sempre para o lobby ao resetar
	player:teleportTo(Position(546, 1242, 7))
	player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)

	-- Resetar no banco de dados
	db.query(string.format("UPDATE exclusive_hunts SET `guid_player` = 0, `time` = 0, `to_time` = 0 WHERE `hunt_id` = %d", storIndex))
	
	-- Resetar as storages do player
	player:setStorageValue(STORAGEVALUE_SUPERUP_INDEX, -1)
	player:setStorageValue(STORAGEVALUE_SUPERUP_TEMPO, -1)
	player:setStorageValue(STORAGEVALUE_SUPERUP_REENTRY, -1)
	
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
	return false
end
