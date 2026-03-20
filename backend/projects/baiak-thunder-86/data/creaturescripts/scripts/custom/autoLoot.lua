-- Emergency constants
if not AUTOLOOT_STORAGE_START then AUTOLOOT_STORAGE_START = 10000 end
if not AUTOLOOT_STORAGE_END then AUTOLOOT_STORAGE_END = 10050 end
if not AUTOLOOT_STORAGE_GOLD then AUTOLOOT_STORAGE_GOLD = 10100 end

local function collectItems(player, container, goldEnabled)
    if not container or not container:isContainer() then 
        return 
    end

    local size = container:getSize()
    if size == 0 then return end

    -- Optimization: Cache the player's autoloot list storages once per corpse scan
    local lootList = {}
    for s = AUTOLOOT_STORAGE_START, AUTOLOOT_STORAGE_END do
        local listId = player:getStorageValue(s)
        if listId > 0 then
            lootList[listId] = true
        end
    end

    for i = size - 1, 0, -1 do
        local item = container:getItem(i)
        if item then
            if item:isContainer() then
                -- Recursão para olhar dentro de bags/backpacks no corpo
                collectItems(player, item, goldEnabled)
            else
                local itemId = item:getId()
                
                -- Se for MOEDA (Gold: 2148, Platinum: 2152, Crystal: 2160)
                if itemId == 2148 or itemId == 2152 or itemId == 2160 then
                    if goldEnabled then
                        local multiplier = 1
                        if itemId == 2152 then multiplier = 100
                        elseif itemId == 2160 then multiplier = 10000 end
                        
                        local amount = item:getCount() * multiplier
                        player:setBankBalance(player:getBankBalance() + amount)
                        player:sendTextMessage(MESSAGE_STATUS_SMALL, "[Auto Loot] Depositado: ".. amount .." gold no banco.")
                        item:remove()
                    end
                else
                    -- Se não for moeda, checa a LISTA de autoloot do player (using local cache)
                    if lootList[itemId] then
                        if item:moveTo(player) then
                            player:sendTextMessage(MESSAGE_STATUS_SMALL, "[Auto Loot] Coletado: " .. item:getName())
                        end
                    end
                end
            end
        end
    end
end

local function scanContainer(cid, position)
    local player = Player(cid)
    if not player then return end

    local tile = Tile(position)
    if not tile then return end

    local corpse = nil
    local thingCount = tile:getThingCount()
    for i = 0, thingCount - 1 do
        local thing = tile:getThing(i)
        if thing and thing:isItem() and thing:getType():isCorpse() then
            corpse = thing
            break
        end
    end

    if not corpse or corpse:getAttribute(ITEM_ATTRIBUTE_CORPSEOWNER) ~= cid then
        return
    end

    local goldEnabled = player:getStorageValue(AUTOLOOT_STORAGE_GOLD) == 1
    collectItems(player, corpse, goldEnabled)
    
    -- Otimização Extrema de Lixo: Decomposição relâmpago nas salas VIP do SuperUP
    if SUPERUP and SUPERUP.areas then
        local pos = corpse:getPosition()
        for _, area in pairs(SUPERUP.areas) do
            if area.from and area.to then
                if pos.x >= area.from.x and pos.x <= area.to.x and
                   pos.y >= area.from.y and pos.y <= area.to.y and
                   pos.z == area.from.z then
                    
                    -- Adiciona um evento para remover o corpo 12 segundos apos ser "aberto" (looteado) pelo AutoLoot
                    addEvent(function(p, ownerId)
                        local tile = Tile(p)
                        if tile then
                            for i = 0, tile:getThingCount() - 1 do
                                local thing = tile:getThing(i)
                                if thing and thing:isItem() and thing:getType():isCorpse() then
                                    if thing:getAttribute(ITEM_ATTRIBUTE_CORPSEOWNER) == ownerId then
                                        thing:remove()
                                        break
                                    end
                                end
                            end
                        end
                    end, 12 * 1000, pos, cid)
                    break
                end
            end
        end
    end
end

function onKill(player, target)
    if not target:isMonster() then
        return true
    end

    addEvent(scanContainer, 100, player:getId(), target:getPosition())
    return true
end
