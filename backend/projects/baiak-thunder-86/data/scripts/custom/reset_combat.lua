--[[
    RESET COMBAT SYSTEM - NEXUS EDITION
    Aplica os bônus de reset (Dano, Crítico, Dodge) durante o combate.
]]

local config = {
    STORAGE_RESET_COUNT = 50400,
    benefits = {
        criticalChance = 1,     -- % por reset
        dodgeChance = 0.5,      -- % por reset
        damageBonus = 1,        -- % por reset
    }
}


-- Damage and Critical logic is handled in ResetHealth (onHealthChange) below.


local resetHealth = CreatureEvent("ResetHealth")

function resetHealth.onHealthChange(self, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
    if not self or not self:isPlayer() then
        return primaryDamage, primaryType, secondaryDamage, secondaryType
    end

    local resets = math.max(0, self:getStorageValue(config.STORAGE_RESET_COUNT))
    if resets <= 0 then
        return primaryDamage, primaryType, secondaryDamage, secondaryType
    end

    -- DODGE LOGIC
    local dodgeChance = resets * config.benefits.dodgeChance
    if math.random(1000) <= (dodgeChance * 10) then
        self:getPosition():sendMagicEffect(CONST_ME_POFF) -- Efeito de fumaça (esquivou)
        self:say("DODGE!", TALKTYPE_MONSTER_SAY)
        return 0, primaryType, 0, secondaryType
    end

    -- DAMAGE INCREASE LOGIC (If self is NOT the attacker, we apply reduction/increase if needed)
    -- Mas aqui queremos que o ATACANTE tenha bônus.
    if attacker and attacker:isPlayer() then
        local attackerResets = math.max(0, attacker:getStorageValue(config.STORAGE_RESET_COUNT))
        if attackerResets > 0 then
            local multiplier = 1 + (attackerResets * config.benefits.damageBonus / 100)
            primaryDamage = math.floor(primaryDamage * multiplier)
            secondaryDamage = math.floor(secondaryDamage * multiplier)
            
            -- CRITICAL LOGIC (Simulando bônus de dano extra 2x se critar)
            local critChance = attackerResets * config.benefits.criticalChance
            if math.random(100) <= critChance then
                primaryDamage = primaryDamage * 2
                secondaryDamage = secondaryDamage * 2
                self:getPosition():sendMagicEffect(CONST_ME_CRITICAL_DAMAGE)
                attacker:say("CRITICAL!", TALKTYPE_MONSTER_SAY)
            end
        end
    end

    return primaryDamage, primaryType, secondaryDamage, secondaryType
end

resetHealth:register()

local resetLogin = CreatureEvent("ResetCombatLogin")
function resetLogin.onLogin(player)
    player:registerEvent("ResetHealth")
    return true
end
resetLogin:register()
