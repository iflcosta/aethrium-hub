function onSay(player, words, param)
    if not player:getGroup():getAccess() then
        return true
    end
    
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "--- Testando Sistema de Wings & Auras ---")
    for id, config in pairs(WingsAura.items) do
        local item = player:addItem(id, 1)
        if item then
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Recebido: " .. config.name .. " (Equipe para ver o efeito)")
        end
    end
    
    return true
end
