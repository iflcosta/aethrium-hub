function onEquip(player, item, slot)
    local itemId = item:getId()
    local config = WingsAura.items[itemId]
    
    if config then
        -- Inicia o loop de efeitos
        WingsAura.showEffect(player:getId(), itemId)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Voce equipou " .. config.name .. "!")
    end
    return true
end

function onDeEquip(player, item, slot)
    -- Ao desequipar, chamamos a função para que ela envie o opcode de desativação (shader "none")
    WingsAura.showEffect(player:getId(), item:getId())
    return true
end
