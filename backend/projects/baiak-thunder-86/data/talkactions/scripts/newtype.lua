function onSay(player, words, param)
	if not player:getGroup():getAccess() then
		return true
	end

	if player:getAccountType() < ACCOUNT_TYPE_GOD then
		return false
	end

	local lookType = tonumber(param)
	if not lookType then
		player:sendCancelMessage("Command param required. Example: /newtype 1373")
		return false
	end

	local outfit = player:getOutfit()
	outfit.lookType = lookType
	player:setOutfit(outfit)
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	return false
end
