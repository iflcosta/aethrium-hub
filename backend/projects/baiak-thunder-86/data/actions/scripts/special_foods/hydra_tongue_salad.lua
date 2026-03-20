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

    local conditions = {
        CONDITION_POISON, CONDITION_FIRE, CONDITION_ENERGY, CONDITION_BLEEDING,
        CONDITION_PARALYZE, CONDITION_DROWN, CONDITION_FREEZING, CONDITION_DAZZLED,
        CONDITION_CURSED
    }

    for _, condition in ipairs(conditions) do
        if player:getCondition(condition) then
            player:removeCondition(condition)
        end
    end

    item:remove(1)
    player:say(sound, TALKTYPE_MONSTER_SAY)
    return true
end
