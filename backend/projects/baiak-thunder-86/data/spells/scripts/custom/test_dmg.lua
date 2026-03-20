local combatTypes = {
    ["testfire"] = COMBAT_FIREDAMAGE,
    ["testice"] = COMBAT_ICEDAMAGE,
    ["testearth"] = COMBAT_EARTHDAMAGE,
    ["testenergy"] = COMBAT_ENERGYDAMAGE,
    ["testdeath"] = COMBAT_DEATHDAMAGE,
    ["testholy"] = COMBAT_HOLYDAMAGE,
    ["testphysical"] = COMBAT_PHYSICALDAMAGE
}

local combatEffects = {
    [COMBAT_FIREDAMAGE] = CONST_ME_FIREATTACK,
    [COMBAT_ICEDAMAGE] = CONST_ME_ICEATTACK,
    [COMBAT_EARTHDAMAGE] = CONST_ME_EARTHATTACK,
    [COMBAT_ENERGYDAMAGE] = CONST_ME_ENERGYHIT,
    [COMBAT_DEATHDAMAGE] = CONST_ME_MORTAREA,
    [COMBAT_HOLYDAMAGE] = CONST_ME_HOLYDAMAGE,
    [COMBAT_PHYSICALDAMAGE] = CONST_ME_HITAREA
}

function onCastSpell(player, variant)
    local words = variant:getString():lower()
    local damageType = combatTypes[words] or COMBAT_ICEDAMAGE
    local effect = combatEffects[damageType] or CONST_ME_ICEATTACK
    
    local target = player:getTarget()
    if not target then
        player:sendCancelMessage("You need a target to use this test spell.")
        return false
    end
    
    -- Fixed 100 damage before any reductions
    doTargetCombatHealth(player, target, damageType, -100, -100, effect)
    return true
end
