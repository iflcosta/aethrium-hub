-- ============================================================
-- OFFLINE TRAINING LOGIN (NexusOT) - Storage Based
-- ============================================================
-- Processa os ganhos de treino offline ao fazer login
-- Regras: 12h pool, 50% eficiência, regenera 1:1
-- ============================================================

local OFF_TRAIN_CONFIG = {
    MAX_TIME = 43200,        -- 12 horas em segundos
    EFFICIENCY = 0.5,        -- 50% de eficiência
    STORAGE_TIME = 54001,    -- Tempo restante de treino
    STORAGE_SKILL = 54002,   -- Skill selecionada
    STORAGE_LAST_LOG = 54003,  -- Timestamp do logout
    STORAGE_BOOST = 54010    -- Boost percentage (from furniture)
}

function onLogin(player)
    -- Registrar eventos necessários
    player:registerEvent("OfflineTrainModal")
    
    local lastLogout = player:getLastLogout()
    if lastLogout == 0 then
        -- Primeira vez no servidor: dar 12h de treino offline
        player:setStorageValue(OFF_TRAIN_CONFIG.STORAGE_TIME, OFF_TRAIN_CONFIG.MAX_TIME)
        player:setStorageValue(OFF_TRAIN_CONFIG.STORAGE_SKILL, -1)
        player:setStorageValue(OFF_TRAIN_CONFIG.STORAGE_LAST_LOG, 0)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Voce recebeu 12 horas de treino offline gratuito! Use a estatua para treinar.")
        return true
    end
    
    local offlineTime = os.time() - lastLogout
    
    -- Sem tempo mínimo para testar
    local trainSkill = player:getStorageValue(OFF_TRAIN_CONFIG.STORAGE_SKILL)
    local trainTimeStored = player:getStorageValue(OFF_TRAIN_CONFIG.STORAGE_TIME)
    if trainTimeStored < 0 then trainTimeStored = 0 end
    
    -- Se não tem treino ativado, apenas regenera o pool
    if trainSkill == -1 then
        -- Regeneração: 1:1 do tempo offline
        local newTime = math.min(OFF_TRAIN_CONFIG.MAX_TIME, trainTimeStored + offlineTime)
        player:setStorageValue(OFF_TRAIN_CONFIG.STORAGE_TIME, newTime)
        
        -- Salvar (apenas storage)
        return true
    end
    
    -- Calcular tempo de treino (menor valor entre offlineTime e trainTimeStored)
    local effectiveTrainTime = math.min(offlineTime, trainTimeStored)
    local gained = false
    
    if effectiveTrainTime > 60 then -- Mínimo 1 minuto de treino
        -- Aplicar eficiência (50%)
        local tries = effectiveTrainTime * OFF_TRAIN_CONFIG.EFFICIENCY
        
        -- Verificar boost de furniture (20% bonus)
        local boost = player:getStorageValue(OFF_TRAIN_CONFIG.STORAGE_BOOST)
        if boost > 0 then
            tries = tries * (1 + (boost / 100))
        end
        
        -- Aplicar rateSkill do config
        local rateSkill = configManager.getNumber(configKeys.RATE_SKILL)
        
        tries = tries * rateSkill
        
        -- Aplicar gains baseados no skill
        local skillNames = {"Club", "Sword", "Axe", "Distance", "Magic"}
        
        if trainSkill >= 0 and trainSkill <= 3 then
            -- Skills de combate (Club=0, Sword=1, Axe=2, Distance=3)
            player:addSkillTries(trainSkill + 1, tries)  -- +1 porque Fist(0) foi removido
            -- Shielding também treina automaticamente
            player:addSkillTries(5, tries)
            gained = true
        elseif trainSkill == 4 then
            -- Magic Level (agora é button 5 = skill 4)
            local manaSpent = tries * 100
            player:addManaSpent(manaSpent)
            -- Shielding também treina automaticamente
            player:addSkillTries(5, tries)
            gained = true
        end
        
        -- Mostrar mensagem se ganhou algo
        if gained then
            local hours = math.floor(effectiveTrainTime / 3600)
            local minutes = math.floor((effectiveTrainTime % 3600) / 60)
            
            local timeStr = ""
            if hours > 0 then
                timeStr = hours .. " hora" .. (hours > 1 and "s" or "")
            end
            if minutes > 0 then
                if timeStr ~= "" then timeStr = timeStr .. " e " end
                timeStr = timeStr .. minutes .. " minuto" .. (minutes > 1 and "s" or "")
            end
            
            local skillName = skillNames[trainSkill + 1] or "Unknown"
            local boostMsg = ""
            if boost > 0 then
                boostMsg = " (+" .. boost .. "% boost!)"
            end
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Voce treinou " .. skillName .. " por " .. timeStr .. " offline! (Eficiencia: " .. (OFF_TRAIN_CONFIG.EFFICIENCY * 100) .. "%" .. boostMsg .. ")")
        end
    end
    
    -- Calcular regeneração e tempo restantes
    local newTrainTime = trainTimeStored
    
    -- Se houve gains, consumir o tempo de treino
    if gained then
        newTrainTime = trainTimeStored - effectiveTrainTime
        if newTrainTime < 0 then newTrainTime = 0 end
        
        -- Adicionar regeneração do tempo restante offline
        local remainingOfflineTime = offlineTime - effectiveTrainTime
        if remainingOfflineTime > 0 then
            newTrainTime = math.min(OFF_TRAIN_CONFIG.MAX_TIME, newTrainTime + remainingOfflineTime)
        end
    else
        -- Se não houve gains (tempo insuficiente), apenas regenera 1:1
        newTrainTime = math.min(OFF_TRAIN_CONFIG.MAX_TIME, trainTimeStored + offlineTime)
    end
    
    -- Armazenamento apenas em storage
    player:setStorageValue(OFF_TRAIN_CONFIG.STORAGE_TIME, newTrainTime)
    player:setStorageValue(OFF_TRAIN_CONFIG.STORAGE_SKILL, -1)
    player:setStorageValue(OFF_TRAIN_CONFIG.STORAGE_LAST_LOG, 0)
    player:setStorageValue(OFF_TRAIN_CONFIG.STORAGE_BOOST, -1)  -- Clear boost after training
    
    return true
end
