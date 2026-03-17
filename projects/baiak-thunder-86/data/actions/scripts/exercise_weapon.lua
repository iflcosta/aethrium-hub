-- ============================================================
-- EXERCISE WEAPONS SYSTEM (Tibia Global Style)
-- Protocolo 8.6 - TFS 1.5
-- ============================================================
-- Configurações baseadas no Tibia Global:
-- Intervalo: 2 segundos (2000ms) por hit
-- ============================================================

local TRAIN_INTERVAL = 750 -- 0.75 segundos por hit

-- Valores base por hit (Tibia Global)
local VALUES = {
    [SKILL_SWORD] = 7.2,      -- Melee
    [SKILL_AXE] = 7.2,       -- Melee
    [SKILL_CLUB] = 7.2,      -- Melee
    [SKILL_DISTANCE] = 4.32,  -- Distance (mais difícil)
    [SKILL_MAGLEVEL] = 600,   -- Mana Spent
}

-- Bônus para trainers especiais
local TRAINER_BONUS = {
    [31215] = 1.3,  -- Ferumbras: 30%
    [31216] = 1.3,  -- Ferumbras: 30%
    [31217] = 1.2,  -- Demon: 20%
    [31218] = 1.2,  -- Demon: 20%
    [31219] = 1.1,  -- Monk: 10%
    [31220] = 1.1,  -- Monk: 10%
}

local function doExerciseTraining(playerId, itemId, skillType, bonus, targetPos)
    local player = Player(playerId)
    if not player then return end
    
    -- Verifica se o player está online
    local item = player:getItemById(itemId, true)
    if not item then return end
    
    -- Verifica cargas
    local charges = item:getAttribute(ITEM_ATTRIBUTE_CHARGES)
    if charges <= 0 then
        item:remove()
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your exercise weapon broke.")
        return
    end
    
    -- Verifica PZ Lock (não pode treinar em combate)
    if player:isPzLocked() then
        player:sendCancelMessage("You cannot train while in a protection zone.")
        return
    end
    
    -- Verifica se ainda está no mesmo tile
    local currentPos = player:getPosition()
    if currentPos.z ~= targetPos.z or currentPos.x ~= targetPos.x or currentPos.y ~= targetPos.y then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Training stopped. You moved.")
        return
    end
    
    -- Consome 1 carga
    item:setAttribute(ITEM_ATTRIBUTE_CHARGES, charges - 1)
    
    -- Obtém rateSkill do config
    local rateSkill = configManager.getNumber(configKeys.RATE_SKILL)
    
    -- Aplica gains com bônus e rateSkill
    if skillType == SKILL_MAGLEVEL then
        -- Magic Level: usa manaSpent
        local manaSpent = VALUES[skillType] * bonus * rateSkill
        player:addManaSpent(manaSpent)
    else
        -- Skills: usa addSkillTries
        local tries = VALUES[skillType] * bonus * rateSkill
        player:addSkillTries(skillType, tries)
    end
    
    -- Shield sempre treina junto (mesmo bônus)
    local shieldTries = VALUES[SKILL_SWORD] * bonus * rateSkill
    player:addSkillTries(SKILL_SHIELD, shieldTries)
    
    -- Efeito visual
    player:getPosition():sendMagicEffect(CONST_ME_HITAREA)
    
    -- Continua o treino se ainda houver charges
    if charges - 1 > 0 then
        addEvent(doExerciseTraining, TRAIN_INTERVAL, playerId, itemId, skillType, bonus, targetPos)
    else
        item:remove()
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your exercise weapon broke.")
    end
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    -- Verifica se tem alvo
    if not target or not target:isItem() then
        player:sendCancelMessage("Use this on a trainer.")
        return true
    end
    
    -- IDs de trainers (com bônus 20%)
    local trainerBonusIds = {
        [31215] = true, -- Ferumbras
        [31216] = true,
        [31217] = true, -- Demon
        [31218] = true,
        [31219] = true, -- Monk
        [31220] = true,
    }
    
    -- IDs de trainers normais (sem bônus)
    local trainerNormalIds = {
        [31214] = true, -- Normal
        [31221] = true,
    }
    
    local targetId = target:getId()
    local bonus = 1.0
    
    -- Verifica bônus específico por trainer
    if TRAINER_BONUS[targetId] then
        bonus = TRAINER_BONUS[targetId]
    elseif targetId ~= 31214 and targetId ~= 31221 then
        -- Se não é nenhum trainer válido, mostra mensagem
        player:sendCancelMessage("Use this on a trainer.")
        return true
    end
    
    -- Mapeamento de item para skill
    local weaponSkills = {
        [31208] = SKILL_SWORD,
        [37935] = SKILL_SWORD,
        [37941] = SKILL_SWORD,
        [31209] = SKILL_AXE,
        [37936] = SKILL_AXE,
        [37942] = SKILL_AXE,
        [31210] = SKILL_CLUB,
        [37937] = SKILL_CLUB,
        [37943] = SKILL_CLUB,
        [31211] = SKILL_DISTANCE,
        [37938] = SKILL_DISTANCE,
        [37944] = SKILL_DISTANCE,
        [31212] = SKILL_MAGLEVEL,
        [37939] = SKILL_MAGLEVEL,
        [37945] = SKILL_MAGLEVEL,
        [31213] = SKILL_MAGLEVEL,
        [37940] = SKILL_MAGLEVEL,
        [37946] = SKILL_MAGLEVEL,
    }
    
    local skillType = weaponSkills[item:getId()]
    if not skillType then
        player:sendCancelMessage("This item is not a valid exercise weapon.")
        return true
    end
    
    -- Verifica cargas
    local charges = item:getAttribute(ITEM_ATTRIBUTE_CHARGES)
    if charges <= 0 then
        item:remove()
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your exercise weapon broke.")
        return true
    end
    
    -- Verifica PZ Lock
    if player:isPzLocked() then
        player:sendCancelMessage("You cannot train while in a protection zone.")
        return true
    end
    
    -- Salva posição inicial para verificar se moveu
    local startPos = player:getPosition()
    
    -- Mensagem de início
    local bonusPercent = math.floor((bonus - 1) * 100 + 0.5)
    if bonusPercent > 0 then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Training started! (Bonus: " .. bonusPercent .. "% extra)")
    else
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Training started!")
    end
    
    -- Inicia o treino com bônus e posição
    doExerciseTraining(player:getId(), item:getId(), skillType, bonus, startPos)
    
    return false -- Permite uso à distância como runas
end
