local combat = Combat()
combat:setParameter(COMBAT_PARAM_BLOCKARMOR, 1)
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_FIREDAMAGE)
combat:setParameter(COMBAT_PARAM_DISTANCEEFFECT, CONST_ANI_FIRE)

-- Min = (lvl/5) + (mlvl * 0.3) + 150
-- Max = (lvl/5) + (mlvl * 0.6) + 250
combat:setFormula(COMBAT_FORMULA_LEVELMAGIC, -0.3, -150, -0.6, -250)

function onUseWeapon(player, variant)
    return combat:execute(player, variant)
end
