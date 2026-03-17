local combat = Combat()
combat:setParameter(COMBAT_PARAM_BLOCKARMOR, 1)
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_ICEDAMAGE)
combat:setParameter(COMBAT_PARAM_DISTANCEEFFECT, CONST_ANI_ICE)

-- Min = (lvl/5) + (mlvl * 0.8) + 350
-- Max = (lvl/5) + (mlvl * 1.2) + 550
combat:setFormula(COMBAT_FORMULA_LEVELMAGIC, -0.8, -350, -1.2, -550)

function onUseWeapon(player, variant)
    return combat:execute(player, variant)
end
