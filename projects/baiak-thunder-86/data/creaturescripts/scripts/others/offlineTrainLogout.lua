-- ============================================================
-- OFFLINE TRAINING LOGOUT (NexusOT) - Storage Based
-- ============================================================
-- Regenera o pool de treino quando o jogador desloga sem usar
-- ============================================================

local OFF_TRAIN_CONFIG = {
    MAX_TIME = 43200,        -- 12 horas em segundos
    STORAGE_TIME = 54001,    -- Tempo restante de treino
    STORAGE_SKILL = 54002,   -- Skill selecionada
    STORAGE_LAST_LOG = 54003  -- Timestamp do logout
}

function onLogout(player)
    local trainSkill = player:getStorageValue(OFF_TRAIN_CONFIG.STORAGE_SKILL)
    
    -- Se tem treino ativo, não faz nada (o login que processa)
    if trainSkill ~= -1 then
        return true
    end
    
    -- Se não tem treino ativo, regenera o pool 1:1
    local currentTime = player:getStorageValue(OFF_TRAIN_CONFIG.STORAGE_TIME)
    if currentTime < 0 then currentTime = 0 end
    
    local lastLog = player:getStorageValue(OFF_TRAIN_CONFIG.STORAGE_LAST_LOG)
    
    if lastLog and lastLog > 0 then
        local offlineTime = os.time() - lastLog
        local newTime = math.min(OFF_TRAIN_CONFIG.MAX_TIME, currentTime + offlineTime)
        player:setStorageValue(OFF_TRAIN_CONFIG.STORAGE_TIME, newTime)
    end
    
    -- Limpar storage
    player:setStorageValue(OFF_TRAIN_CONFIG.STORAGE_LAST_LOG, 0)
    
    return true
end
