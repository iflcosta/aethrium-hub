local exhaust = Condition(CONDITION_EXHAUST_HEAL)
exhaust:setParameter(CONDITION_PARAM_TICKS, getConfigInfo('timeBetweenActions'))

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if SPECIAL_FOODS[item.itemid] == nil then
        return false
    end

    local sound = SPECIAL_FOODS[item.itemid][1]

    if not player:addCondition(exhaust) then
        player:sendCancelMessage("You are exhausted.")
        return true
    end

    local playerMaxHealth = player:getMaxHealth()
    local playerHealth = player:getHealth()

    player:addHealth(playerMaxHealth - playerHealth)
    item:remove(1)
    player:say(sound, TALKTYPE_MONSTER_SAY)
    return true
end
