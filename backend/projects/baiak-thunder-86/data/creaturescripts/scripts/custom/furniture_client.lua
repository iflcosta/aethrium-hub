local OPCODE_FURNITURE = 153

-- Mesmas tabelas do houseFurnitureModal para consistência
local FURNITURE_SHOP = {
    [16098] = {name = "Food Maker", price = 10, currency = "PP"},
    [26075] = {name = "Supply Statue", price = 15, currency = "PP"},
    [26076] = {name = "Rune Statue 2", price = 15, currency = "PP"},
    [24682] = {name = "Training Statue (20% Boost)", price = 30, currency = "PP"},
}

local TRAINERS = {
    [31219] = {name = "Monk Trainer", price = 50, currency = "PP"},
    [31217] = {name = "Demon Trainer", price = 100, currency = "PP"},
    [31215] = {name = "Ferumbras Trainer", price = 200, currency = "PP"},
}

local POTIONS = {
    [7618] = {name = "Health Potion", price = 40, currency = "GP"},
    [7620] = {name = "Mana Potion", price = 40, currency = "GP"},
    [7588] = {name = "Strong Health", price = 80, currency = "GP"},
    [7589] = {name = "Strong Mana", price = 80, currency = "GP"},
    [7591] = {name = "Great Health", price = 120, currency = "GP"},
    [7590] = {name = "Great Mana", price = 120, currency = "GP"},
    [8473] = {name = "Ultimate Health", price = 250, currency = "GP"},
}

local RUNES = {
    [2268] = {name = "Sudden Death", price = 150, currency = "GP"},
    [2313] = {name = "Explosion", price = 52, currency = "GP"},
    [2304] = {name = "Great Fireball", price = 60, currency = "GP"},
    [2311] = {name = "Heavy Magic Missile", price = 24, currency = "GP"},
    [2287] = {name = "Light Magic Missile", price = 12, currency = "GP"},
    [2265] = {name = "Intense Healing", price = 40, currency = "GP"},
    [2292] = {name = "Stalagmite", price = 20, currency = "GP"}
}

local function getServerIdFromClientId(clientId)
    -- Iteramos as tabelas para encontrar qual Server ID tem esse Client ID
    local tables = {FURNITURE_SHOP, TRAINERS, POTIONS, RUNES}
    for _, t in ipairs(tables) do
        for serverId, data in pairs(t) do
            if ItemType(serverId):getClientId() == clientId then
                return serverId
            end
        end
    end
    return nil
end

local function getBuyableItem(serverId)
    return FURNITURE_SHOP[serverId] or TRAINERS[serverId] or POTIONS[serverId] or RUNES[serverId]
end

function onFurnitureExtendedOpcode(player, opcode, buffer)
    if opcode ~= OPCODE_FURNITURE then return true end
    

    
    local split = buffer:split(":")
    local clientId = tonumber(split[1])
    local quantity = tonumber(split[2]) or 1
    
    if not clientId then 

        return true 
    end
    
    local itemId = getServerIdFromClientId(clientId)
    if not itemId then
        -- Fallback: Se não encontrou pelo Client ID, tenta ver se foi enviado o Server ID direto
        if getBuyableItem(clientId) then
            itemId = clientId
        else
            player:sendCancelMessage("Item não encontrado na loja.")

            return true
        end
    end
    
    -- Limite de segurança
    quantity = math.min(1000, math.max(1, quantity))
    
    local itemData = getBuyableItem(itemId)
    if not itemData then
        player:sendCancelMessage("Item não encontrado na loja.")

        return true
    end
    
    local totalPrice = itemData.price * quantity
    local currency = itemData.currency
    
    if currency == "PP" then
        local points = player:getPremiumPoints()
        if points < totalPrice then
            player:sendCancelMessage("Você precisa de " .. totalPrice .. " Premium Points!")
            return true
        end
        player:removePremiumPoints(totalPrice)
    else
        if player:getMoney() < totalPrice then
            player:sendCancelMessage("Você precisa de " .. totalPrice .. " gold coins!")
            return true
        end
        player:removeMoney(totalPrice)
    end
    
    local successCount = 0
    -- Adiciona os itens conforme a quantidade
    -- Para itens agrupáveis ou runas/poções, podemos usar o parâmetro count se o servidor suportar
    -- Caso contrário, fazemos um loop
    for i = 1, quantity do
        local item = player:addItem(itemId, 1)
        if item then
            successCount = successCount + 1
        else
            break
        end
    end

    if successCount > 0 then
        player:sendTextMessage(MESSAGE_INFO_DESCR, "Você comprou: " .. successCount .. "x " .. itemData.name .. " por " .. (itemData.price * successCount) .. " " .. currency .. "!")
        player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
        
        -- Reembolso parcial se não coube tudo
        if successCount < quantity then
            local refund = (quantity - successCount) * itemData.price
            if currency == "PP" then player:addPremiumPoints(refund) else player:addMoney(refund) end
            player:sendCancelMessage("Inventário cheio! Extorno de " .. refund .. " aplicado.")
        end
    else
        -- Reembolso total se não coube nada
        if currency == "PP" then player:addPremiumPoints(totalPrice) else player:addMoney(totalPrice) end
        player:sendCancelMessage("Inventário cheio! Compra cancelada.")
    end
    
    return true
end
