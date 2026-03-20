function onSay(player, words, param)
    -- Verifica se o player é um administrador (Acesso 3+)
    if player:getGroup():getId() < 3 then 
        return false 
    end
    
    -- Verifica se o parâmetro foi enviado
    if param == "" then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[Erro] Use: !setattr criticalPercent, 50")
        return false
    end

    local split = param:split(",")
    if #split < 2 then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[Erro] Use: !setattr NomeAtributo, Valor")
        return false
    end

    local attrName = split[1]:trim()
    local value = tonumber(split[2]:trim())

    if not value then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[Erro] O valor deve ser um numero.")
        return false
    end

    -- Tenta pegar o item na mão ou na armadura
    local item = player:getSlotItem(CONST_SLOT_LEFT) or player:getSlotItem(CONST_SLOT_RIGHT) or player:getSlotItem(CONST_SLOT_ARMOR)
    
    if not item then
        player:sendCancelMessage("Equipe o item para definir o atributo.")
        return false
    end

    item:setCustomAttribute(attrName, value)
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Atributo '" .. attrName .. "' definido para " .. value .. " no item: " .. item:getName())
    return false
end