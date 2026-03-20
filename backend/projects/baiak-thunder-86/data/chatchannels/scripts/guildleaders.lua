function canJoin(player)
	return player:getGuildLevel() == 3 or player:getGroup():getAccess()
end

function onSpeak(player, type, message)
	local staff = player:getGroup():getAccess()
	local guild = player:getGuild()
	local info = "STAFF"
	type = TALKTYPE_CHANNEL_Y
	
	if staff then
		if guild then
			info =  info .. "][" .. guild:getName()
		end
		for _, target in ipairs(Game.getPlayers()) do
			if target:getGuild() and target:getGuild():getId() == player:getGuild():getId() then
				target:sendChannelMessage(player:getName(), message, type, 10)
			end
		end
		return false
	else
		info = guild:getName()
	end
	
	sendChannelMessage(10, type, player:getName() .. " [" .. info .. "]: " .. message)
	return false
end