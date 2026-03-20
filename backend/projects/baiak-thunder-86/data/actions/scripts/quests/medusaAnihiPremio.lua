local config = {
    quests = {
        [34589] = {itemId = 2493, storage = 34589}, -- demon helmet
        [34590] = {itemId = 2400, storage = 34590}, -- magic sword
        [34591] = {itemId = 2431, storage = 34591}, -- stonecutter axe
        [34592] = {itemId = 2520, storage = 34592}  -- demon shield
    }
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local questConfig = config.quests[item.actionid]

    if not questConfig then
        return false
    end

    -- Verifica se já pegou o prêmio
    if player:getStorageValue(questConfig.storage) ~= -1 then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The chest is empty.")
        return true
    end

    -- Verifica se tem espaço no inventário
    if player:getFreeCapacity() < ItemType(questConfig.itemId):getWeight() then
        player:sendCancelMessage("You don't have enough capacity.")
        return true
    end

    -- Dá o prêmio
    player:addItem(questConfig.itemId, 1)
    player:setStorageValue(questConfig.storage, 1)
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a " .. ItemType(questConfig.itemId):getName() .. ".")
    player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_YELLOW)

    return true
end
