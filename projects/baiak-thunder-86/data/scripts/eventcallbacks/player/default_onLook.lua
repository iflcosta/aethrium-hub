local ec = EventCallback

ec.onLook = function(self, thing, position, distance, description)
	-- Debug: verify if engine already provides metadata
	if description and description ~= "" then
		-- print(">> Look Debug: description already has content: '" .. description .. "'")
	end

	local prefix = "You see "
	local baseDescription = (description and description ~= "" and description or thing:getDescription(distance))
	
	if baseDescription:sub(1, #prefix) ~= prefix then
		description = prefix .. baseDescription
	else
		description = baseDescription
	end
	if self:getGroup():getAccess() then
		if thing:isItem() then
			if not description:find("Item ID:") then
				description = string.format("%s\nItem ID: %d", description, thing:getId())

				local actionId = thing:getActionId()
				if actionId ~= 0 then
					description = string.format("%s, Action ID: %d", description, actionId)
				end

				local uniqueId = thing:getAttribute(ITEM_ATTRIBUTE_UNIQUEID)
				if uniqueId > 0 and uniqueId < 65536 then
					description = string.format("%s, Unique ID: %d", description, uniqueId)
				end
			end

			local itemType = thing:getType()

			local transformEquipId = itemType:getTransformEquipId()
			local transformDeEquipId = itemType:getTransformDeEquipId()
			if transformEquipId ~= 0 then
				description = string.format("%s\nTransforms to: %d (onEquip)", description, transformEquipId)
			elseif transformDeEquipId ~= 0 then
				description = string.format("%s\nTransforms to: %d (onDeEquip)", description, transformDeEquipId)
			end

			local decayId = itemType:getDecayId()
			if decayId ~= -1 then
				description = string.format("%s\nDecays to: %d", description, decayId)
			end
		elseif thing:isCreature() then
			-- Health, Mana and Position for creatures are natively appended by the C++ engine.
		end

		if thing:isCreature() then
			if thing:isPlayer() then
				description = string.format("%s\nIP: %s.", description, Game.convertIpToString(thing:getIp()))
			end
		end
	end

	if thing:isItem() then
		local item = thing
		local element = item:getAttribute("sealedElement")
		local value = tonumber(item:getAttribute("sealedValue")) or 0

		if value > 0 and element ~= "" then
			local displayValue = value
			local isArmorOrLegs = false
			local slot = item:getType():getSlot()

			-- Check for 18% cap if Armor and Legs are the same element
			if (slot == 4 or slot == 8) and value >= 12 then -- 4 is body, 8 is legs
				local player = self
				local otherSlot = (slot == 4) and 8 or 4
				local otherItem = player:getSlotItem(otherSlot)
				if otherItem then
					local oElement = otherItem:getAttribute("sealedElement")
					local oValue = tonumber(otherItem:getAttribute("sealedValue")) or 0
					if oElement == element and oValue >= 12 then
						displayValue = 18 -- Cap at 18% for the pair (Set Cap)
					end
				end
			elseif (slot == 4 or slot == 8) and value >= 5 and element == "Physical" then
				local player = self
				local otherSlot = (slot == 4) and 8 or 4
				local otherItem = player:getSlotItem(otherSlot)
				if otherItem then
					local oElement = otherItem:getAttribute("sealedElement")
					local oValue = tonumber(otherItem:getAttribute("sealedValue")) or 0
					if oElement == "Physical" and oValue >= 5 then
						displayValue = 8 -- Cap at 8% for Physical set
					end
				end
			end

			description = string.format("%s\n%s Guarded %d%%.", description, element, displayValue)
		end
	end

	return description
end

ec:register()
