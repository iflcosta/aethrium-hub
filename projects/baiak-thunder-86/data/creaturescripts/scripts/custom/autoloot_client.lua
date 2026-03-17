local OPCODE_AUTOLOOT = 152

-- Configuração de Limites por VIP
local VIP_LIMITS = {
    [0] = 5,  -- Free
    [1] = 15, -- Bronze
    [2] = 25, -- Prata
    [3] = 50  -- Ouro
}

local function getLimit(player)
    local tier = getVipTier(player) -- Função global do vip_system.lua
    return VIP_LIMITS[tier] or 5
end

local function getAutoLootList(player)
    local list = {}
    for i = AUTOLOOT_STORAGE_START, AUTOLOOT_STORAGE_END do
        local itemId = player:getStorageValue(i)
        if itemId > 0 then
            table.insert(list, itemId)
        end
    end
    return list
end

local function sendState(player)
    local list = getAutoLootList(player)
    local limit = getLimit(player)
    
    -- Monta array de objetos {"id":X,"name":"Y"}
    local itemsJson = {}
    for _, itemId in ipairs(list) do
        local it = ItemType(itemId)
        local name = it and it:getName() or ('ID:' .. itemId)
        table.insert(itemsJson, string.format('{"id":%d,"name":"%s"}', itemId, name))
    end
    
    local json = string.format('{"limit":%d,"items":[%s]}', limit, table.concat(itemsJson, ","))
    player:sendExtendedOpcode(OPCODE_AUTOLOOT, json)
end

function onAutoLootExtendedOpcode(player, opcode, buffer)
    if opcode ~= OPCODE_AUTOLOOT then return false end
    
    -- Parser manual melhorado para JSON
    local function getJsonField(str, field)
        -- Tenta pegar valor com aspas: "field":"value"
        local res = str:match('"' .. field .. '":%s*"([^"]+)"')
        if not res then
            -- Tenta pegar valor sem aspas (números): "field":123
            res = str:match('"' .. field .. '":%s*([^,%s}]+)')
        end
        return res
    end

    local action = getJsonField(buffer, "action")
    local data = getJsonField(buffer, "data")
    

    
    if action == "fetch" then
        sendState(player)
        
    elseif action == "add" then
        if not data then return end
        
        local itemId = tonumber(data)
        if not itemId then
            local it = ItemType(data)
            if it and it:getId() > 0 then
                itemId = it:getId()
            end
        end
        

        
        if not itemId or itemId <= 0 then 
            player:sendTextMessage(MESSAGE_STATUS_SMALL, "Item '"..tostring(data).."' nao encontrado.")
            return 
        end
        
        local list = getAutoLootList(player)
        local limit = getLimit(player)
        
        if #list >= limit then
            player:sendTextMessage(MESSAGE_STATUS_SMALL, "Seu limite de Auto-Loot ("..limit..") foi atingido. Vire VIP para aumentar!")
            return
        end
        
        -- Verificar duplicatas
        for _, id in ipairs(list) do
            if id == itemId then
                player:sendTextMessage(MESSAGE_STATUS_SMALL, "Este item ja esta na lista.")
                return 
            end
        end
        
        -- Adicionar na primeira storage vazia
        for i = AUTOLOOT_STORAGE_START, AUTOLOOT_STORAGE_END do
            if player:getStorageValue(i) <= 0 then
                player:setStorageValue(i, itemId)
                player:sendTextMessage(MESSAGE_STATUS_SMALL, ItemType(itemId):getName() .. " adicionado ao Auto-Loot.")
                break
            end
        end
        sendState(player)
        
    elseif action == "remove" then
        local itemId = tonumber(data)
        for i = AUTOLOOT_STORAGE_START, AUTOLOOT_STORAGE_END do
            if player:getStorageValue(i) == itemId then
                player:setStorageValue(i, 0)
                player:sendTextMessage(MESSAGE_STATUS_SMALL, ItemType(itemId):getName() .. " removido.")
                break
            end
        end
        sendState(player)
        
    elseif action == "clear" then
        for i = AUTOLOOT_STORAGE_START, AUTOLOOT_STORAGE_END do
            player:setStorageValue(i, 0)
        end
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "Lista de Auto-Loot limpa.")
        sendState(player)
    end
    
    return true
end
