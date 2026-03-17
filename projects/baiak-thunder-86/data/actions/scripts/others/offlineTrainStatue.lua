-- ============================================================
-- OFFLINE TRAINING SYSTEM (NexusOT) - Storage Based
-- ============================================================
-- Sistema simplificado usando storages do TFS
-- Regras: 12h pool, 50% eficiência, regenera 1:1
-- ============================================================

local OFF_TRAIN_CONFIG = {
    MAX_TIME = 43200,        -- 12 horas em segundos
    EFFICIENCY = 0.5,        -- 50% de eficiência
    STORAGE_TIME = 54001,    -- Tempo restante de treino
    STORAGE_SKILL = 54002,   -- Skill selecionada
    STORAGE_LAST_LOG = 54003  -- Timestamp do logout
}

-- IDs das estátuas de treino (ajuste conforme seu servidor)
-- Uma única estátua para todos os skills (escolha via modal)
local STATUE_ID = 18491

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    -- Verificar se tem tempo de treino disponível
    local trainTime = player:getStorageValue(OFF_TRAIN_CONFIG.STORAGE_TIME)
    if trainTime < 0 then trainTime = 0 end
    
    if trainTime < 60 then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Voce precisa de pelo menos 60 segundos de treino offline disponivel.")
        return true
    end
    
    -- Criar modal para escolher skill
    local modal = ModalWindow(5400, "Escolha o Skill", "Qual skill voce deseja treinar? (Shielding treina automaticamente)")
    
    modal:addButton(1, "Club")
    modal:addButton(2, "Sword")
    modal:addButton(3, "Axe")
    modal:addButton(4, "Distance")
    modal:addButton(5, "Magic")
    modal:addButton(99, "Cancelar")
    
    -- Armazenar o item uid para uso posterior
    player:setStorageValue(54010, item:getUniqueId())
    
    modal:sendToPlayer(player)
    
    return true
end
