local loot = Action()

function loot.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local lootPot = lootPotion[item:getId()]
    if not lootPot then
        return false
    end

    if player:getStorageValue(STORAGEVALUE_LOOT_ID) >= 1 or player:getStorageValue(STORAGEVALUE_LOOT_TEMPO) > os.time() then
        player:sendCancelMessage("You already have a loot bonus active.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end

    if not item:remove() then
        player:sendCancelMessage("You do not have any loot bonus potion.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end

    player:sendCancelMessage("You activated a loot bonus of +".. lootPot.exp .."% for ".. lootPot.tempo .." hour".. (lootPot.tempo > 1 and "s" or "") ..".")
    player:getPosition():sendMagicEffect(31)
    player:setStorageValue(STORAGEVALUE_LOOT_ID, item:getId())
    player:setStorageValue(STORAGEVALUE_LOOT_TEMPO, os.time() + lootPot.tempo * 60 * 60)

    return true
end

loot:id(10089)
loot:register()
