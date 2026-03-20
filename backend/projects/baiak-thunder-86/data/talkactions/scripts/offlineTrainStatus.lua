-- ============================================================
-- OFFLINE TRAINING STATUS (NexusOT) - Storage Based
-- ============================================================
-- Comando !offtrain para ver o tempo disponível
-- ============================================================

local OFF_TRAIN_CONFIG = {
    STORAGE_TIME = 54001,    -- Tempo restante de treino
    STORAGE_SKILL = 54002   -- Skill selecionada
}

function onSay(player, words, param)
    local trainTime = player:getStorageValue(OFF_TRAIN_CONFIG.STORAGE_TIME)
    if trainTime < 0 then trainTime = 0 end
    
    local trainSkill = player:getStorageValue(OFF_TRAIN_CONFIG.STORAGE_SKILL)
    
    local hours = math.floor(trainTime / 3600)
    local minutes = math.floor((trainTime % 3600) / 60)
    local seconds = trainTime % 60
    
    local timeStr = string.format("%02d:%02d:%02d", hours, minutes, seconds)
    
    local skillName = "Nenhum"
    if trainSkill == 0 then skillName = "Club"
    elseif trainSkill == 1 then skillName = "Sword"
    elseif trainSkill == 2 then skillName = "Axe"
    elseif trainSkill == 3 then skillName = "Distance"
    elseif trainSkill == 4 then skillName = "Magic Level"
    end
    
    local status = "Inativo"
    if trainSkill ~= -1 then
        status = "Ativo (" .. skillName .. ")"
    end
    
    local text = "=== OFFLINE TRAINING ===\n\n"
    text = text .. "Tempo disponivel: " .. timeStr .. "\n"
    text = text .. "Status: " .. status .. "\n\n"
    text = text .. "Eficiencia: 50% - Shielding automatico\n"
    text = text .. "Maximo: 12 horas\n"
    text = text .. "Regenera online e offline"
    
    player:popupFYI(text)
    
    return false
end
