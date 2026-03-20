local combat = Combat()
combat:setParameter(COMBAT_PARAM_AGGRESSIVE, false)

local condition = Condition(CONDITION_ATTRIBUTES)
condition:setParameter(CONDITION_PARAM_SUBID, 5)
condition:setParameter(CONDITION_PARAM_TICKS, 3600000)
condition:setParameter(CONDITION_PARAM_STAT_MAGICPOINTSPERCENT, 105)
condition:setParameter(CONDITION_PARAM_BUFF_SPELL, true)
combat:addCondition(condition)

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

    if not player:addCondition(condition) then
        player:sendCancelMessage("You already have this effect active.")
        return true
    end

    combat:execute(player, Variant(player:getId()))
    item:remove(1)
    player:say(sound, TALKTYPE_MONSTER_SAY)
    return true
end
