local combat = Combat()
combat:setParameter(COMBAT_PARAM_BLOCKARMOR, 1)
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_FIREDAMAGE)
combat:setParameter(COMBAT_PARAM_DISTANCEEFFECT, CONST_ANI_FIRE)

-- Min = (lvl/5) + (mlvl * 0.5) + 200
-- Max = (lvl/5) + (mlvl * 0.8) + 350
combat:setFormula(COMBAT_FORMULA_LEVELMAGIC, -0.5, -200, -0.8, -350)

function onUseWeapon(player, variant)
    return combat:execute(player, variant)
end
