local berserk = Condition(CONDITION_ATTRIBUTES)
berserk:setParameter(CONDITION_PARAM_TICKS, 10 * 60 * 1000)
berserk:setParameter(CONDITION_PARAM_SKILL_MELEE, 5)
berserk:setParameter(CONDITION_PARAM_SKILL_SHIELD, -10)
berserk:setParameter(CONDITION_PARAM_BUFF_SPELL, true)

local mastermind = Condition(CONDITION_ATTRIBUTES)
mastermind:setParameter(CONDITION_PARAM_TICKS, 10 * 60 * 1000)
mastermind:setParameter(CONDITION_PARAM_STAT_MAGICPOINTS, 3)
mastermind:setParameter(CONDITION_PARAM_BUFF_SPELL, true)

local bullseye = Condition(CONDITION_ATTRIBUTES)
bullseye:setParameter(CONDITION_PARAM_TICKS, 10 * 60 * 1000)
bullseye:setParameter(CONDITION_PARAM_SKILL_DISTANCE, 5)
bullseye:setParameter(CONDITION_PARAM_SKILL_SHIELD, -10)
bullseye:setParameter(CONDITION_PARAM_BUFF_SPELL, true)

local potions = {
    [6558] = {transform = {7588, 7589}, effect = CONST_ME_DRAWBLOOD},
    [7439] = {condition = berserk, vocations = {4, 8}, effect = CONST_ME_MAGIC_RED, description = "Only knights can drink this potion.", text = "You feel stronger."},
    [7440] = {condition = mastermind, vocations = {1, 2, 5, 6}, effect = CONST_ME_MAGIC_BLUE, description = "Only sorcerers and druids can drink this potion.", text = "You feel smarter."},
    [7443] = {condition = bullseye, vocations = {3, 7}, effect = CONST_ME_MAGIC_GREEN, description = "Only paladins can drink this potion.", text = "You feel more accurate."},
    [7588] = {health = {250, 350}, vocations = {3, 4, 7, 8}, level = 50, flask = 7634, description = "Only knights and paladins of level 50 or higher can drink this potion."},
    [7589] = {mana = {115, 185}, vocations = {1, 2, 3, 5, 6, 7}, level = 50, flask = 7634, description = "Only sorcerers, druids, and paladins of level 50 or higher can drink this potion."},
    [7590] = {mana = {150, 250}, vocations = {1, 2, 5, 6}, level = 80, flask = 7635, description = "Only druids and sorcerers of level 80 or higher can drink this liquid."},
    [26029] = {mana = {430, 520}, vocations = {1, 2, 5, 6}, level = 130, flask = 7635, description = "Only druids and sorcerers of level 130 or higher can drink this liquid."},
    [26030] = {health = {450, 550}, mana = {150, 250}, vocations = {3, 7}, level = 130, flask = 7635, description = "Only paladins of level 130 or higher can drink this liquid."},
    [26031] = {health = {850, 950}, vocations = {4, 8}, level = 130, flask = 7635, description = "Only knights of level 130 or higher can drink this liquid."},
    [7591] = {health = {425, 575}, vocations = {4, 8}, level = 80, flask = 7635, description = "Only knights of level 80 or higher can drink this liquid."},
    [7618] = {health = {125, 175}, flask = 7636},
    [7620] = {mana = {75, 125}, flask = 7636},
    [8472] = {health = {250, 350}, mana = {100, 200}, vocations = {3, 7}, level = 80, flask = 7635, description = "Only paladins of level 80 or higher can drink this liquid."},
    [8473] = {health = {650, 850}, vocations = {4, 8}, level = 130, flask = 7635, description = "Only knights of level 130 or higher can drink this liquid."},
    [8474] = {antidote = true, flask = 7636},
    [8704] = {health = {60, 90}, flask = 7636},
}

local EXHAUST_STORAGE = 45001
local EXHAUST_TIME = 1 -- 1 segundo (os.time() é em segundos)

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    -- Manual Exhaustion Check (Non-engine blocking)
    if player:getStorageValue(EXHAUST_STORAGE) > os.time() then
        player:sendCancelMessage("You are exhausted.")
        return true
    end

    if type(target) == "userdata" and not target:isPlayer() then
        return false
    end

    local potion = potions[item:getId()]
    if not potion then
        return false
    end

    if potion.level and player:getLevel() < potion.level or potion.vocations and not table.contains(potion.vocations, player:getVocation():getId()) then
        player:say(potion.description, TALKTYPE_MONSTER_SAY)
        return true
    end

    if potion.condition then
        player:addCondition(potion.condition)
        player:say(potion.text, TALKTYPE_MONSTER_SAY)
        player:getPosition():sendMagicEffect(potion.effect)
    elseif potion.transform then
        item:transform(potion.transform[math.random(#potion.transform)])
        item:getPosition():sendMagicEffect(potion.effect)
        -- Set Exhaustion for transform too
        player:setStorageValue(EXHAUST_STORAGE, os.time() + EXHAUST_TIME)
        return true
    else
        if potion.health then
            doTargetCombat(player, target, COMBAT_HEALING, potion.health[1], potion.health[2])
        end

        if potion.mana then
            doTargetCombat(player, target, COMBAT_MANADRAIN, potion.mana[1], potion.mana[2])
        end

        if potion.antidote then
            target:removeCondition(CONDITION_POISON)
        end

        target:say("Aaaah...", TALKTYPE_MONSTER_SAY)
        target:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
    end
    
    -- Set Manual Exhaustion
    player:setStorageValue(EXHAUST_STORAGE, os.time() + EXHAUST_TIME)

    if not configManager.getBoolean(configKeys.REMOVE_POTION_CHARGES) then
        return true
    end

    item:remove(1)
    return true
end
