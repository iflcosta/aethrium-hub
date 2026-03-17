local config = {
    posFrom = Position(993, 922, 7),
    posTo = Position(1038, 967, 7)
}

function onSay(player, words, param)
    if not player:getGroup():getAccess() then
        return true
    end

    if param == "clean" then
        local count = 0
        for x = config.posFrom.x, config.posTo.x do
            for y = config.posFrom.y, config.posTo.y do
                local pos = Position(x, y, config.posFrom.z)
                local tile = Tile(pos)
                if tile then
                    local items = tile:getItems()
                    if items then
                        for _, item in ipairs(items) do
                            item:remove(-1)
                            count = count + 1
                        end
                    end
                end
                -- Creates or replaces the ground tile with id 424
                Game.createItem(424, 1, pos)
            end
        end
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Área limpa! Foram removidos " .. count .. " itens móveis.")
        return false
    end

    local startId = tonumber(param)
    if not startId then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Uso incorreto. Use: /searchitems <id inicial> ou /searchitems clean")
        return false
    end

    local currentId = startId
    local count = 0
    local maxItems = (config.posTo.x - config.posFrom.x + 1) * (config.posTo.y - config.posFrom.y + 1)
    
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Gerando até " .. maxItems .. " itens a partir do ID " .. startId .. "...")

    for y = config.posFrom.y, config.posTo.y do
        for x = config.posFrom.x, config.posTo.x do
            local pos = Position(x, y, config.posFrom.z)
            
            -- Pular IDs inválidos (tentamos até achar um válido na sequência)
            local it = ItemType(currentId)
            while currentId < 40000 and (not it or it:getId() == 0 or it:getName() == "" and it:getClientId() == 0) do
                currentId = currentId + 1
                it = ItemType(currentId)
            end

            -- Create the item
            local item = Game.createItem(currentId, 1, pos)
            if item then
                count = count + 1
            end
            
            currentId = currentId + 1
        end
    end

    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Foram gerados " .. count .. " itens. O último ID verificado foi " .. (currentId - 1) .. ".")
    return false
end
