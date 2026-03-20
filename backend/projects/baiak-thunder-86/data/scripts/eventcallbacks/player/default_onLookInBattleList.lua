local ec = EventCallback

ec.onLookInBattleList = function(self, creature, distance, description)
	local prefix = "You see "
	local baseDescription = (description and description ~= "" and description or creature:getDescription(distance))
	
	if baseDescription:sub(1, #prefix) ~= prefix then
		description = prefix .. baseDescription
	else
		description = baseDescription
	end
	if self:getGroup():getAccess() then
		-- Health, Mana and Position for creatures are natively appended by the C++ engine.
		if creature:isPlayer() then
			description = string.format("%s\nIP: %s", description, Game.convertIpToString(creature:getIp()))
		end
	end
	return description
end

ec:register()
