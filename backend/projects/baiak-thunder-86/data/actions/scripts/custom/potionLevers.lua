local potions = {
    [1517] = {id = 7588, charges = 1, value = 100}, -- Strong Health Potion
    [1518] = {id = 7589, charges = 1, value = 80}, -- Strong Mana Potion
    [1519] = {id = 7591, charges = 1, value = 190}, -- Great Health Potion
    [1520] = {id = 7590, charges = 1, value = 120}, -- Great Mana Potion
    [1521] = {id = 8473, charges = 1, value = 310}, -- Ultimate Health Potion
    [1522] = {id = 8472, charges = 1, value = 190},-- Great Spirit Potion
    [1515] = {id = 26029, charges = 1, value = 400},-- Ultimate Mana Potion
    [1516] = {id = 26031, charges = 1, value = 400},-- Supreme Health Potion
    [1514] = {id = 26030, charges = 1, value = 400},-- Ultimate Spirit Potion
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local potion = potions[item.actionid]
    if not potion then
        return false
    end

    if player:getStorageValue(77124) >= os.time() then
        player:sendCancelMessage("You need to wait 2 seconds between purchases.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end

    local potionId = ItemType(potion.id)
    local itemWeight = potionId:getWeight() * potion.charges
    if player:getFreeCapacity() >= itemWeight then
        if not player:removeMoney(potion.value) then
            player:sendCancelMessage("You don't have enough gold coins to buy ".. potion.charges .." ".. potionId:getName() ..".")
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
        elseif not player:addItem(potion.id, potion.charges) then
            print("[ERROR] ACTION: potions_lever, FUNCTION: addItem, PLAYER: "..player:getName())
        else
            player:sendCancelMessage("You bought ".. potion.charges .."x ".. potionId:getName() ..".")
            player:setStorageValue(77124, os.time() + 2)
            player:getPosition():sendMagicEffect(29)
        end
    else
        player:sendCancelMessage("You don't have enough cap to buy.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
    end

    item:transform(item.itemid == 1945 and 1946 or 1945)
    return true
end
