function onStepIn(creature, item, position, fromPosition)

	local player = creature:getPlayer()
	
	if not player then
		return true
	end

	if BATTLEFIELD.level.active and player:getLevel() < BATTLEFIELD.level.levelMin then
		player:sendCancelMessage(BATTLEFIELD.messages.prefix .."You need to be at least level " .. BATTLEFIELD.level.levelMin .. " to enter the event.")
		player:teleportTo(fromPosition, true)
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return true
	end

	if player:getItemCount(2165) >= 1 then
		player:sendCancelMessage(BATTLEFIELD.messages.prefix .."You cannot enter the event while wearing a stealth ring.")
		player:teleportTo(fromPosition, true)
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return false
	end

	local ring = player:getSlotItem(CONST_SLOT_RING)
	if ring then
		if ring:getId() == 2202 then
			player:sendCancelMessage(BATTLEFIELD.messages.prefix .."You cannot enter the event while using a stealth ring.")
			player:teleportTo(fromPosition, true)
			player:getPosition():sendMagicEffect(CONST_ME_POFF)
			return false
		end
	end


	for a in pairs(BATTLEFIELD["red"].players) do
		local target = Player(a)
		if target and player:getIp() == target:getIp() then
			player:sendCancelMessage(BATTLEFIELD.messages.prefix .. "You already have another player inside the event.")
			player:teleportTo(fromPosition, true)
			player:getPosition():sendMagicEffect(CONST_ME_POFF)
			return true
		end
	end
	
	for b in pairs(BATTLEFIELD["blue"].players) do
		local target = Player(b)
		if target and player:getIp() == target:getIp() then
			player:sendCancelMessage(BATTLEFIELD.messages.prefix .. "You already have another player inside the event.")
			player:teleportTo(fromPosition, true)
			player:getPosition():sendMagicEffect(CONST_ME_POFF)
			return true
		end
    end

	if BATTLEFIELD:totalPlayers() >= BATTLEFIELD.maxPlayers then
		player:sendCancelMessage(BATTLEFIELD.messages.prefix .."The event has already reached the maximum participants.")
		player:teleportTo(fromPosition, true)
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		return false
	end

	BATTLEFIELD:insertPlayer(player:getId())

	return true
end
