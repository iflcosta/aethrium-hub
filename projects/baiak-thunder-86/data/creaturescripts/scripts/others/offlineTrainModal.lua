-- ============================================================
-- OFFLINE TRAINING MODAL HANDLER (NexusOT)
-- ============================================================

local OFF_TRAIN_CONFIG = {
    STORAGE_TIME = 54001,
    STORAGE_SKILL = 54002,
    STORAGE_LAST_LOG = 54003
}

function onModalWindow(player, modalWindowId, buttonId)
    if modalWindowId ~= 5400 then
        return true
    end
    
    if buttonId == 99 then
        return true
    end
    
    local skillId = buttonId - 1
    local skillNames = {"Club", "Sword", "Axe", "Distance", "Magic"}
    
    -- Registrar skill e timestamp (apenas storage, não precisa de banco)
    player:setStorageValue(OFF_TRAIN_CONFIG.STORAGE_SKILL, skillId)
    player:setStorageValue(OFF_TRAIN_CONFIG.STORAGE_LAST_LOG, os.time())
    
    -- Mensagem
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Treino de " .. skillNames[skillId + 1] .. " ativado! Desconectando em 3 segundos...")
    
    -- Efeito visual
    player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
    
    -- Desconectar após 3 segundos
    addEvent(function()
        local p = Player(player:getGuid())
        if p then
            p:remove()
        end
    end, 3000)
    
    return true
end
