-- ============================================================
-- OFFLINE TRAINING REGEN (NexusOT) - Storage Based
-- ============================================================
-- Regenera o pool de treino enquanto o jogador está online
-- ============================================================

local OFF_TRAIN_CONFIG = {
    MAX_TIME = 43200,        -- 12 horas em segundos
    REGEN_AMOUNT = 60,       -- 1 segundo de treino por segundo online
    STORAGE_TIME = 54001,    -- Tempo restante de treino
    STORAGE_SKILL = 54002    -- Skill selecionada
}

function onThink(interval)
    -- Roda a cada minuto
    if interval < 60000 then
        return true
    end
    
    local players = Game.getPlayers()
    for _, player in ipairs(players) do
        local trainSkill = player:getStorageValue(OFF_TRAIN_CONFIG.STORAGE_SKILL)
        
        -- Se não tem treino ativo, regenera o pool
        if trainSkill == -1 then
            local currentTime = player:getStorageValue(OFF_TRAIN_CONFIG.STORAGE_TIME)
            if currentTime < 0 then currentTime = 0 end
            
            local newTime = math.min(OFF_TRAIN_CONFIG.MAX_TIME, currentTime + OFF_TRAIN_CONFIG.REGEN_AMOUNT)
            
            if newTime ~= currentTime then
                player:setStorageValue(OFF_TRAIN_CONFIG.STORAGE_TIME, newTime)
            end
        end
    end
    
    return true
end
