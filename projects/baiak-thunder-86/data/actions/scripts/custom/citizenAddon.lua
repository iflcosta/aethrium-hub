function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if player:getStorageValue(STORAGEVALUE_CITIZEN_FULL) >= 1 then
        player:sendCancelMessage("You have already received this prize.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
    else
        player:sendCancelMessage("You have won the complete Citizen outfit!")
        player:getPosition():sendMagicEffect(31)
        player:addOutfitAddon(136, 3)
        player:addOutfitAddon(128, 3)
        player:setStorageValue(STORAGEVALUE_CITIZEN_FULL, 1)
    end

    return true
end
