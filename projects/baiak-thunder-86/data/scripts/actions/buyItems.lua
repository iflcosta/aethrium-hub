local items = Action()

local levers = {
    [2655] = {id = 9693, count = 1, value = 45},
    [2656] = {id = 12411, count = 1, value = 50},
    [2657] = {id = 12640, count = 1, value = 100},
    [2658] = {id = 8978, count = 1, value = 0},
    [2659] = {id = 12544, count = 1, value = 190},
}

function items.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local choose = levers[item.actionid]

    if not choose then
        return false
    end

    if player:getStorageValue(77124) >= os.time() then
        player:sendCancelMessage("You need to wait 2 seconds between purchases.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end

    local userItem = ItemType(choose.id)
    local itemWeight = userItem:getWeight() * choose.count

    if player:getFreeCapacity() < itemWeight then
        player:sendCancelMessage("You don't have enough space.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end

    if not player:removeMoney(choose.value) then
        player:sendCancelMessage("You don't have enough money.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end
    
    local buy = Game.createItem(choose.id, choose.count)
    if player:addItemEx(buy) == RETURNVALUE_CONTAINERNOTENOUGHROOM then
        sendMailbox(player:getId(), choose.id, choose.count)
        player:sendTextMessage(MESSAGE_STATUS_BLUE_LIGHT, "You don't have enough space in your backpack, and your item has been sent to the mailbox.")
    end

    player:sendCancelMessage("You bought ".. choose.count .."x ".. userItem:getName() ..".")
    player:getPosition():sendMagicEffect(29)
    player:setStorageValue(77124, os.time() + 2)

    item:transform(item.itemid == 1945 and 1946 or 1945)

    return true
end

items:aid(2655, 2656, 2657, 2658, 2659)
items:register()
