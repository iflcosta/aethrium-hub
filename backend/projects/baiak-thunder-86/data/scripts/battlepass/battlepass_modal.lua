local function giveRewards(player, rewards, rewardType)
    if not rewards then return end
    
    local vipBonus = 1.0
    if player:getStorageValue(50200) == 3 then  -- VIP Ouro
        vipBonus = 1.2
    elseif player:getStorageValue(50200) == 2 then  -- VIP Prata
        vipBonus = 1.1
    end
    
    if rewards.gold then
        local gold = math.floor(rewards.gold * vipBonus)
        player:addMoney(gold)
        player:sendTextMessage(MESSAGE_LOOT,
            string.format("+%d gold (Aethrium Pass %s)", gold, rewardType))
    end
    
    if rewards.items then
        for _, it in ipairs(rewards.items) do
            local itemId = it[1]
            local count = math.floor(it[2] * vipBonus)
            player:addItem(itemId, count, true)
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE,
                string.format("Recebeu %dx %s!", count, ItemType(itemId):getName()))
        end
    end
    
    if rewards.taskPoints then
        local currentTaskPoints = math.max(0, player:getStorageValue(20021))
        local tp = math.floor(rewards.taskPoints * vipBonus)
        player:setStorageValue(20021, currentTaskPoints + tp)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Recebeu %d Task Points (Aethrium Pass %s)!", tp, rewardType))
    end
    
    if rewards.nexusCoins then
        local nc = math.floor(rewards.nexusCoins * vipBonus)
        db.query("UPDATE `accounts` SET `premium_points` = `premium_points` + " .. nc .. " WHERE `id` = " .. player:getAccountId())
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Recebeu %d Nexus Coins (Aethrium Pass %s)!", nc, rewardType))
    end
end

local battlepassModal = CreatureEvent("BattlePassModal")

function battlepassModal.onModalWindow(player, modalWindowId, buttonId, choiceId)
    if modalWindowId == 1001 then
        -- Botao 3: Fechar
        if buttonId == 3 or buttonId == 255 then
            return true
        end
        
        local level = player:getStorageValue(BATTLEPASS_CONFIG.storageLevel)
        if level < 0 then level = 1 end
        
        local data = BATTLEPASS_CONFIG.levels[level]
        if not data then return true end
        
        local currentXp = math.max(0, player:getStorageValue(BATTLEPASS_CONFIG.storageXp))
        local passType = player:getStorageValue(BATTLEPASS_CONFIG.storagePremium)
        local isPremium = (passType == 2)
        
        if buttonId == 1 then
            -- Resgatar nivel
            if currentXp < data.requiredXP then
                player:sendCancelMessage("Voce ainda nao tem XP suficiente para este nivel.")
                player:getPosition():sendMagicEffect(CONST_ME_POFF)
                return true
            end
            
            -- Dar rewards
            giveRewards(player, data.rewardFree, "[FREE]")
            
            -- Se for premium, dar os extras
            if isPremium then
                giveRewards(player, data.rewardPremium, "[PREMIUM]")
            end
            
            -- Avancar level
            player:setStorageValue(BATTLEPASS_CONFIG.storageLevel, level + 1)
            
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, 
                string.format("Aethrium Pass nivel %d completo! Avancou para nivel %d.", level, level + 1))
            player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_YELLOW)
            
        elseif buttonId == 2 then
            -- Comprar premium (Abre Confirmação)
            if isPremium then
                player:sendCancelMessage("Voce ja possui o Aethrium Pass Premium!")
                player:getPosition():sendMagicEffect(CONST_ME_POFF)
                return true
            end
            
            -- Cálculo de Preço (Revalidação do VIP Tier)
            local vipTier = math.max(0, player:getStorageValue(50200))
            local finalPrice = BATTLEPASS_CONFIG.pricing[vipTier] or BATTLEPASS_CONFIG.pricing[0]
            
            local confirmMsg = string.format("Voce esta prestes a adquirir o Aethrium Pass PREMIUM.\n\nCusto: %d Nexus Coins\nStatus VIP: %s\n\nDeseja confirmar a compra?", finalPrice, vipTier > 0 and "Desconto VIP Aplicado!" or "Sem Desconto")
            local confirmWindow = ModalWindow(1002, "Confirmar Compra", confirmMsg)
            
            confirmWindow:addButton(1, "Sim")
            confirmWindow:addButton(2, "Nao")
            confirmWindow:setDefaultEnterButton(1)
            confirmWindow:setDefaultEscapeButton(2)
            confirmWindow:sendToPlayer(player)
            return true
        end
        return true

    elseif modalWindowId == 1002 then
        if buttonId == 2 or buttonId == 255 then
            player:say("!bp", TALKTYPE_SAY) -- Reabre a janela original se cancelar
            return true
        end
        
        if buttonId == 1 then
            local passType = player:getStorageValue(BATTLEPASS_CONFIG.storagePremium)
            if passType == 2 then
                player:sendCancelMessage("Voce ja possui o Aethrium Pass Premium!")
                return true
            end
            
            -- Cálculo de Preço
            local vipTier = math.max(0, player:getStorageValue(50200))
            local finalPrice = BATTLEPASS_CONFIG.pricing[vipTier] or BATTLEPASS_CONFIG.pricing[0]
            
            -- Checar e Remover usando db update + updateClientStore
            -- Tentamos remover tanto no banco quanto usar a função de sincronizar
            local getPoints = db.storeQuery("SELECT `premium_points` FROM `accounts` WHERE `id` = " .. player:getAccountId())
            local points = 0
            if getPoints then
                points = result.getDataInt(getPoints, "premium_points")
                result.free(getPoints)
            end
            
            if points < finalPrice then
                player:sendCancelMessage("Voce nao possui Nexus Coins suficientes para esta compra. (Necessario: " .. finalPrice .. ")")
                player:getPosition():sendMagicEffect(CONST_ME_POFF)
                return true
            end
            
            -- Para o banco (fallback): removemos no DB
            db.query("UPDATE `accounts` SET `premium_points` = `premium_points` - " .. finalPrice .. " WHERE `id` = " .. player:getAccountId())
            
            -- Atualiza interface in-game para sincronizar store UI (- value) se a engine suportar
            if player.removeTibiaCoins then
                player:removeTibiaCoins(0) -- só dar um update na interface
            elseif player.addCoinsBalance then
                player:addCoinsBalance(0)
            end
            
            -- Ativar o Passe Premium
            player:setStorageValue(BATTLEPASS_CONFIG.storagePremium, 2)
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Parabéns! Você agora é um membro PREMIUM do Aethrium Pass!")
            player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_YELLOW)
            
            -- Atualização da Interface (Reabrir Modal Original)
            player:say("!bp", TALKTYPE_SAY)
        end
        return true
    end
end

battlepassModal:register()
