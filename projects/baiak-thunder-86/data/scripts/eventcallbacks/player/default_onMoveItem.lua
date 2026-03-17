local ec = EventCallback

ec.onMoveItem = function(self, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if toPosition.x ~= CONTAINER_POSITION then
		return true
	end

	if item:getTopParent() == self and bit.band(toPosition.y, 0x40) == 0 then
		local itemType, moveItem = ItemType(item:getId())
		
		local isDistanceBlock = (itemType:getWeaponType() == WEAPON_DISTANCE) and (itemType:getAmmoType() ~= 0)
		local name = item:getName():lower()
		local isShield = (itemType:getWeaponType() == WEAPON_SHIELD) and not name:find("quiver")
		local isTwoHanded = (bit.band(itemType:getSlotPosition(), SLOTP_TWO_HAND) ~= 0)

		if (toPosition.y == CONST_SLOT_LEFT or toPosition.y == CONST_SLOT_RIGHT) then
			local otherSlot = (toPosition.y == CONST_SLOT_LEFT) and CONST_SLOT_RIGHT or CONST_SLOT_LEFT

			print("[MoveItem Debug] Item: " .. item:getName() .. " | isShield=" .. tostring(isShield) .. " | isDistanceBlock=" .. tostring(isDistanceBlock) .. " | isTwoHanded=" .. tostring(isTwoHanded))
			local otherItem = self:getSlotItem(otherSlot)
			if otherItem then
				print("[MoveItem Debug] Other slot item: " .. otherItem:getName() .. " | isQuiver=" .. tostring(otherItem:getName():lower():find("quiver") ~= nil))
			end

			if isTwoHanded or isDistanceBlock then
				moveItem = self:getSlotItem(otherSlot)
				-- Quivers are immune to Distance weapons
				if moveItem and isDistanceBlock and moveItem:getName():lower():find("quiver") then
					print("[MoveItem Debug] Quiver detected in other slot, allowing combo!")
					moveItem = nil
				end
			elseif isShield then
				moveItem = self:getSlotItem(otherSlot)
				if moveItem then
					local moveItemType = ItemType(moveItem:getId())
					local moveIsTwoHanded = bit.band(moveItemType:getSlotPosition(), SLOTP_TWO_HAND) ~= 0
					local moveIsDistanceBlock = (moveItemType:getWeaponType() == WEAPON_DISTANCE) and (moveItemType:getAmmoType() ~= 0)
					print("[MoveItem Debug] Shield check: other item=" .. moveItem:getName() .. " | moveIsTwoHanded=" .. tostring(moveIsTwoHanded) .. " | moveIsDistanceBlock=" .. tostring(moveIsDistanceBlock))
					if not moveIsTwoHanded and not moveIsDistanceBlock then
						moveItem = nil
					end
				end
			end
		end

		if moveItem then
			local parent = item:getParent()
			if parent:isContainer() and parent:getSize() == parent:getCapacity() then
				self:sendTextMessage(MESSAGE_STATUS_SMALL, Game.getReturnMessage(RETURNVALUE_CONTAINERNOTENOUGHROOM))
				return false
			else
				return moveItem:moveTo(parent)
			end
		end
	end

	return true
end

ec:register()
