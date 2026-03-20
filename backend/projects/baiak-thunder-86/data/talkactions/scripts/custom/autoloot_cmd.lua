-- Emergency constants
local STORAGE_START = 10000
local STORAGE_END = 10050
local STORAGE_GOLD = 10100

function onSay(player, words, param)
    -- Se não tem parâmetro, abre a janela
    if not param or param == "" then
        player:sendExtendedOpcode(152, '{"action":"open"}')
        return false
    end

    local action = tostring(param):lower():trim()

    if action == "gold" then
        local current = player:getStorageValue(STORAGE_GOLD)
        if current == 1 then
            player:setStorageValue(STORAGE_GOLD, -1)
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[AutoLoot] Coleta de moedas DESATIVADA.")
        else
            player:setStorageValue(STORAGE_GOLD, 1)
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[AutoLoot] Coleta de moedas ATIVADA.")
        end
        return false
    end

    if action == "list" then
        local text = "-- Auto Loot List --\n"
        local count = 0
        for i = STORAGE_START, STORAGE_END do
            local storage = player:getStorageValue(i)
            if storage > 0 then
                local it = ItemType(storage)
                text = text .. (count + 1) .. ". " .. (it and it:getName() or ("ID:" .. storage)) .. "\n"
                count = count + 1
            end
        end
        if count == 0 then text = text .. "Lista vazia." end
        player:showTextDialog(1950, text, false)
        return false
    end

    if action == "clear" then
        for i = STORAGE_START, STORAGE_END do
            player:setStorageValue(i, 0)
        end
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[AutoLoot] Lista de itens limpa.")
        return false
    end

    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Comandos: !autoloot gold, !autoloot list, !autoloot clear")
    return false
end
