function onCastSpell(player, variant)
    local target = player:getTarget()
    if not target then
        player:sendCancelMessage("You need a target to use this test spell.")
        return false
    end
    doTargetCombatHealth(player, target, COMBAT_ENERGYDAMAGE, -100, -100, CONST_ME_ENERGYHIT)
    return true
end
