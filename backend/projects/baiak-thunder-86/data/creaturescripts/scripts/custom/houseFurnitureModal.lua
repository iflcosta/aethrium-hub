-- ============================================================
-- HOUSE FURNITURE MODAL HANDLER
-- ============================================================
-- Handles modals for:
-- - Training System (Bamboo Drawer): 30200, 30201
-- - Supply Cabinet (Wooden Cabinet): 30300, 30301, 30302, 30303
-- - Furniture Shop: 9000
-- ============================================================

local OFF_TRAIN_TIME_STORAGE = 54001
local OFF_TRAIN_SKILL_STORAGE = 54002

-- Furniture Shop items (premium points)
local FURNITURE_SHOP = {
    [1] = {itemId = 16098, name = "Food Maker", price = 10},
    [2] = {itemId = 26075, name = "Supply Statue", price = 15},
    [3] = {itemId = 24682, name = "Training Statue (20% Boost)", price = 30},
}

-- Trainer dummies (premium points)
local TRAINERS = {
    {id = 31219, name = "Monk Trainer", bonus = 10, price = 50},
    {id = 31217, name = "Demon Trainer", bonus = 20, price = 100},
    {id = 31215, name = "Ferumbras Trainer", bonus = 30, price = 200},
}

-- Potion/Rune prices (gold)
local POTIONS = {
    {id = 7618, name = "Health Potion", price = 40},
    {id = 7620, name = "Mana Potion", price = 40},
    {id = 7588, name = "Strong Health", price = 80},
    {id = 7589, name = "Strong Mana", price = 80},
    {id = 7591, name = "Great Health", price = 120},
    {id = 7590, name = "Great Mana", price = 120},
    {id = 7643, name = "Ultimate Health", price = 200},
}

local RUNES = {
    {id = 2265, name = "Light Magic Missile", price = 12},
    {id = 2266, name = "Heavy Magic Missile", price = 24},
    {id = 2273, name = "Stalagmite", price = 20},
    {id = 2281, name = "Fireball", price = 60},
    {id = 2305, name = "Explosion", price = 52},
    {id = 2313, name = "Energy Field", price = 40},
    {id = 2268, name = "Cure Poison", price = 30},
    {id = 2269, name = "Intense Healing", price = 40},
}

function onModalWindow(player, modalWindowId, buttonId, choiceId)
    -- Furniture Shop Modal (9000)
    if modalWindowId == 9000 then
        local points = player:getPremiumPoints()
        
        if buttonId == 1 and choiceId > 0 and choiceId <= #FURNITURE_SHOP then
            local furn = FURNITURE_SHOP[choiceId]
            
            if points < furn.price then
                player:sendCancelMessage("Voce precisa de " .. furn.price .. " Premium Points! Voce tem: " .. points)
                player:getPosition():sendMagicEffect(CONST_ME_POFF)
                return true
            end
            
            player:removePremiumPoints(furn.price)
            local item = player:addItem(furn.itemId, 1)
            
            if item then
                player:sendTextMessage(MESSAGE_INFO_DESCR, "Voce comprou: " .. furn.name .. " por " .. furn.price .. " PP!")
                player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
            else
                player:addPremiumPoints(furn.price)
                player:sendCancelMessage("Inventario cheio!")
                player:getPosition():sendMagicEffect(CONST_ME_POFF)
            end
            return true
        end
    end
    


    -- Training Modal (30200) - Bamboo Drawer

    if modalWindowId == 30200 then
        local points = player:getPremiumPoints()
        
        if buttonId == 1 then -- Status
            local trainTime = player:getStorageValue(OFF_TRAIN_TIME_STORAGE)
            if trainTime < 0 then trainTime = 0 end
            local hours = math.floor(trainTime / 3600)
            local minutes = math.floor((trainTime % 3600) / 60)
            player:sendTextMessage(MESSAGE_INFO_DESCR, "Tempo offline: " .. hours .. "h " .. minutes .. "m")
            return true
        elseif buttonId == 2 then -- Activate offline training with boost
            local trainTime = player:getStorageValue(OFF_TRAIN_TIME_STORAGE)
            if trainTime < 0 then trainTime = 0 end
            
            if trainTime < 60 then
                player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Voce precisa de pelo menos 60 segundos de treino offline disponivel.")
                return true
            end
            
            player:setStorageValue(54010, 20)
            
            local modal = ModalWindow(5400, "Escolha o Skill", "Voce iniciou treino offline com 20% BONUS!")
            
            modal:addButton(1, "Club")
            modal:addButton(2, "Sword")
            modal:addButton(3, "Axe")
            modal:addButton(4, "Distance")
            modal:addButton(5, "Magic")
            modal:addButton(99, "Cancelar")
            
            modal:sendToPlayer(player)
            return true
        end
    end
    
    -- Trainer Dummies Modal (30201) - Premium Points
    if modalWindowId == 30201 then
        local points = player:getPremiumPoints()
        
        if buttonId ~= 99 and choiceId > 0 and choiceId <= #TRAINERS then
            local trainer = TRAINERS[choiceId]
            
            if points < trainer.price then
                player:sendCancelMessage("Voce precisa de " .. trainer.price .. " Premium Points! Voce tem: " .. points)
                player:getPosition():sendMagicEffect(CONST_ME_POFF)
                return true
            end
            
            player:removePremiumPoints(trainer.price)
            player:addItem(trainer.id, 1)
            player:sendTextMessage(MESSAGE_INFO_DESCR, "Comprado: " .. trainer.name .. " (-" .. trainer.price .. " PP)")
            player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
            return true
        end
    end
    
    -- Supply Cabinet Modal (30300)
    if modalWindowId == 30300 then
        if buttonId == 1 then
            local window = ModalWindow(30301, "Potions", "Escolha (max 1000):")
            window:addButton(99, "Sair")
            
            for i, pot in ipairs(POTIONS) do
                window:addChoice(i, pot.name .. " - " .. pot.price .. " gp cada")
            end
            
            window:sendToPlayer(player)
            return true
        elseif buttonId == 2 then
            local window = ModalWindow(30302, "Runes", "Escolha (max 1000):")
            window:addButton(99, "Sair")
            
            for i, rune in ipairs(RUNES) do
                window:addChoice(i, rune.name .. " - " .. rune.price .. " gp cada")
            end
            
            window:sendToPlayer(player)
            return true
        end
    end
    
    -- Potions Modal (30301) - Select Quantity
    if modalWindowId == 30301 then
        if buttonId ~= 99 and choiceId > 0 and choiceId <= #POTIONS then
            local pot = POTIONS[choiceId]
            
            -- Create quantity selection modal
            local window = ModalWindow(30303, "Quantidade", "Voce escolheu: " .. pot.name .. " (" .. pot.price .. " gp cada)")
            window:addButton(1, "1")
            window:addButton(2, "10")
            window:addButton(3, "50")
            window:addButton(4, "100")
            window:addButton(5, "500")
            window:addButton(6, "1000")
            window:addButton(99, "Cancelar")
            
            window:sendToPlayer(player)
            
            -- Store selected potion
            player:setStorageValue(95030, pot.id)
            player:setStorageValue(95031, pot.price)
            player:setStorageValue(95032, pot.name)
            return true
        end
    end
    
    -- Runes Modal (30302) - Select Quantity
    if modalWindowId == 30302 then
        if buttonId ~= 99 and choiceId > 0 and choiceId <= #RUNES then
            local rune = RUNES[choiceId]
            
            -- Create quantity selection modal
            local window = ModalWindow(30304, "Quantidade", "Voce escolheu: " .. rune.name .. " (" .. rune.price .. " gp cada)")
            window:addButton(1, "1")
            window:addButton(2, "10")
            window:addButton(3, "50")
            window:addButton(4, "100")
            window:addButton(5, "500")
            window:addButton(6, "1000")
            window:addButton(99, "Cancelar")
            
            window:sendToPlayer(player)
            
            -- Store selected rune
            player:setStorageValue(95033, rune.id)
            player:setStorageValue(95034, rune.price)
            player:setStorageValue(95035, rune.name)
            return true
        end
    end
    
    -- Potions Quantity Confirm (30303)
    if modalWindowId == 30303 then
        local itemId = player:getStorageValue(95030)
        local price = player:getStorageValue(95031)
        local name = player:getStorageValue(95032)
        
        if itemId < 0 or price < 0 then return true end
        
        local quantities = {1, 10, 50, 100, 500, 1000}
        local quantity = quantities[buttonId] or 1
        
        if quantity > 1000 then quantity = 1000 end
        
        local totalPrice = price * quantity
        
        if player:getMoney() >= totalPrice then
            player:removeMoney(totalPrice)
            
            local added = player:addItem(itemId, quantity)
            local delivered = 0
            
            -- Tentar adicionar item por item para contar exatamente
            if added then
                delivered = quantity
            else
                -- Se não conseguiu adicionar nada, tentar adicionar menos
                for i = quantity, 1, -1 do
                    added = player:addItem(itemId, i)
                    if added then
                        delivered = i
                        break
                    end
                end
            end
            
            -- Verificar se entregou tudo
            if delivered < quantity then
                -- Devolver parte do dinheiro
                local refund = price * (quantity - delivered)
                player:addMoney(refund)
                player:sendTextMessage(MESSAGE_INFO_DESCR, "Comprado: " .. delivered .. "x " .. name .. " (-" .. (totalPrice - refund) .. " gp) - Faltou espaco para " .. (quantity - delivered) .. " itens!")
            else
                player:sendTextMessage(MESSAGE_INFO_DESCR, "Comprado: " .. quantity .. "x " .. name .. " (-" .. totalPrice .. " gp)")
            end
            player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
        else
            player:sendCancelMessage("Voce precisa de " .. totalPrice .. " gp!")
        end
        
        -- Clear storage
        player:setStorageValue(95030, -1)
        player:setStorageValue(95031, -1)
        player:setStorageValue(95032, -1)
        return true
    end
    
    -- Runes Quantity Confirm (30304)
    if modalWindowId == 30304 then
        local itemId = player:getStorageValue(95033)
        local price = player:getStorageValue(95034)
        local name = player:getStorageValue(95035)
        
        if itemId < 0 or price < 0 then return true end
        
        local quantities = {1, 10, 50, 100, 500, 1000}
        local quantity = quantities[buttonId] or 1
        
        if quantity > 1000 then quantity = 1000 end
        
        local totalPrice = price * quantity
        
        if player:getMoney() >= totalPrice then
            player:removeMoney(totalPrice)
            
            local added = player:addItem(itemId, quantity)
            local delivered = 0
            
            -- Tentar adicionar item por item para contar exatamente
            if added then
                delivered = quantity
            else
                -- Se não conseguiu adicionar nada, tentar adicionar menos
                for i = quantity, 1, -1 do
                    added = player:addItem(itemId, i)
                    if added then
                        delivered = i
                        break
                    end
                end
            end
            
            -- Verificar se entregou tudo
            if delivered < quantity then
                -- Devolver parte do dinheiro
                local refund = price * (quantity - delivered)
                player:addMoney(refund)
                player:sendTextMessage(MESSAGE_INFO_DESCR, "Comprado: " .. delivered .. "x " .. name .. " (-" .. (totalPrice - refund) .. " gp) - Faltou espaco para " .. (quantity - delivered) .. " itens!")
            else
                player:sendTextMessage(MESSAGE_INFO_DESCR, "Comprado: " .. quantity .. "x " .. name .. " (-" .. totalPrice .. " gp)")
            end
            player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
        else
            player:sendCancelMessage("Voce precisa de " .. totalPrice .. " gp!")
        end
        
        -- Clear storage
        player:setStorageValue(95033, -1)
        player:setStorageValue(95034, -1)
        player:setStorageValue(95035, -1)
        return true
    end
    
    return true
end
