function onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	if not configManager.getBoolean(configKeys.PVP_BALANCE) then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end
	
	if not creature or not attacker or creature == attacker then
	  return primaryDamage, primaryType, secondaryDamage, secondaryType
	end
   
	if creature:isPlayer() and creature:getParty() and attacker:isPlayer() and attacker:getParty() then
	  if creature:getParty() == attacker:getParty() then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	  end
	end
	if creature:isPlayer() and attacker:isPlayer() then
		primaryDamage = math.floor(primaryDamage - (primaryDamage * 20 / 100))
		secondaryDamage = math.floor(secondaryDamage - (secondaryDamage * 20 / 100))

		-- Stacking Balancing (Armor + Legs Same Element)
		local armor = creature:getSlotItem(CONST_SLOT_ARMOR)
		local legs = creature:getSlotItem(CONST_SLOT_LEGS)
		if armor and legs then
			local aElement = armor:getAttribute("sealedElement")
			local lElement = legs:getAttribute("sealedElement")
			if aElement ~= "" and aElement == lElement then
				local aValue = tonumber(armor:getAttribute("sealedValue")) or 0
				local lValue = tonumber(legs:getAttribute("sealedValue")) or 0

				local multiplier = 1.0
				if aElement == "Physical" then
					-- Target: 8% (0.92). Engine (5+5): 0.95 * 0.95 = 0.9025
					multiplier = 0.92 / 0.9025
				elseif aValue >= 12 and lValue >= 12 then
					-- Tier 1 (Ancient/Celestial/Ethereal). Target: 18% (0.82). Engine (12+12): 0.88 * 0.88 = 0.7744
					multiplier = 0.82 / 0.7744
				elseif aValue >= 6 and lValue >= 6 then
					-- Tier 2 (Aethrium). Target: 8% (0.92). Engine (6+6): 0.94 * 0.94 = 0.8836
					multiplier = 0.92 / 0.8836
				end

				if multiplier ~= 1.0 then
					primaryDamage = math.floor(primaryDamage * multiplier)
					secondaryDamage = math.floor(secondaryDamage * multiplier)
				end
			end
		end

		local damage = (primaryDamage + secondaryDamage)
		if damage < 0 then
			damage = damage * -1
		end
	end
	return primaryDamage, primaryType, secondaryDamage, secondaryType
  end
  
  function onManaChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	if not configManager.getBoolean(configKeys.PVP_BALANCE) then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end

	if not creature or not attacker or creature == attacker then
	  return primaryDamage, primaryType, secondaryDamage, secondaryType
	end
  
	if creature:isPlayer() and creature:getParty() and attacker:isPlayer() and attacker:getParty() then
	  if creature:getParty() == attacker:getParty() then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	  end
	end
	  if creature:isPlayer() and attacker:isPlayer() then
	  if creature:getVocation():getId() == 3 or creature:getVocation():getId() == 7 or creature:getVocation():getId() == 11 then
		   primaryDamage = math.floor(primaryDamage - (primaryDamage * 12 / 100))
		   secondaryDamage = math.floor(secondaryDamage - (secondaryDamage * 12 / 100))
		 else
		  primaryDamage = math.floor(primaryDamage - (primaryDamage * 65 / 100))
		  secondaryDamage = math.floor(secondaryDamage - (secondaryDamage * 65 / 100))
		 end
	  local damage = (primaryDamage + secondaryDamage)
	  if damage < 0 then
		damage = damage * -1
	  end
	end
	return primaryDamage, primaryType, secondaryDamage, secondaryType
  end