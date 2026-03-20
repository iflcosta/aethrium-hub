local elements = {
    {type = COMBAT_HOLYDAMAGE, distanceeffect = CONST_ANI_HOLY},
    {type = COMBAT_ICEDAMAGE, distanceeffect = CONST_ANI_ICE},
    {type = COMBAT_FIREDAMAGE, distanceeffect = CONST_ANI_FIRE},
    {type = COMBAT_ENERGYDAMAGE, distanceeffect = CONST_ANI_ENERGYBALL},
    {type = COMBAT_EARTHDAMAGE, distanceeffect = CONST_ANI_EARTH}
}

local combats = {}
for i = 1, #elements do
    local combat = Combat()
    combat:setParameter(COMBAT_PARAM_BLOCKARMOR, 1)
    combat:setParameter(COMBAT_PARAM_TYPE, elements[i].type)
    combat:setParameter(COMBAT_PARAM_DISTANCEEFFECT, elements[i].distanceeffect)
    -- Scaling formula: min = (lvl/5) + (mlvl * 1.0) + 300; max = (lvl/5) + (mlvl * 1.5) + 400
    combat:setFormula(COMBAT_FORMULA_LEVELMAGIC, -1.0, -300, -1.5, -400)
    table.insert(combats, combat)
end

function onUseWeapon(player, variant)
    local combat = combats[math.max(1, player:getStorageValue(STORAGEVALUE_THUNDER_WAND))]
    if not combat then
        return false
    end
    return combat:execute(player, variant)
end