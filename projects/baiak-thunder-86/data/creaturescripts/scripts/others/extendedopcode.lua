-- ============================================================
-- NEXUS STORE - Extended Opcode Handler
-- ============================================================

local OPCODE_LANGUAGE = 1
local OPCODE_GAME_SHOP = 201 -- Must match GAME_SHOP_CODE in client
local OPCODE_MARKET = 202
local OPCODE_BANK = 203
local OPCODE_CRAFTING = 204

-- Ensure shopConfig is loaded (fallback if not auto-loaded by lib)
if not shopConfig then
    dofile('data/lib/custom/shop_config.lua')
end

dofile('data/creaturescripts/scripts/custom/market_backend.lua')
dofile('data/creaturescripts/scripts/custom/bank_backend.lua')
dofile('data/creaturescripts/scripts/custom/autoloot_client.lua')
dofile('data/creaturescripts/scripts/custom/furniture_client.lua')
dofile('data/creaturescripts/scripts/custom/crafting_backend.lua')

-- Rate Limiting Storage
local STORAGE_OPCODE_EXHAUSTION = 49995

local function sendShopJSON(player, data)
    player:sendExtendedOpcode(OPCODE_GAME_SHOP, json.encode(data))
end

local function getAccountPoints(player)
    local resultId = db.storeQuery("SELECT `premium_points` FROM `accounts` WHERE `id` = " .. player:getAccountId())
    if resultId then
        local points = result.getDataInt(resultId, "premium_points")
        result.free(resultId)
        return points
    end
    return 0
end

local function removeAccountPoints(player, amount)
    local points = getAccountPoints(player)
    if points >= amount then
        db.query("UPDATE `accounts` SET `premium_points` = `premium_points` - " .. amount .. " WHERE `id` = " .. player:getAccountId())
        return true
    end
    return false
end

local function addAccountPoints(player, amount)
    db.query("UPDATE `accounts` SET `premium_points` = `premium_points` + " .. amount .. " WHERE `id` = " .. player:getAccountId())
    return true
end

local function processShopOpcode(player, json_data)
    local action = json_data.action
    local data = json_data.data

    if action == "fetch" then
        -- Send Categories & Balance
        local categoriesPayload = {}
        for i, cat in ipairs(shopConfig.categories) do
            table.insert(categoriesPayload, {title = cat.name, iconId = i - 1})
        end

        sendShopJSON(player, {action = "fetchBase", data = {categories = categoriesPayload, url = "http://nexus-global.com"}})
        
        -- Push Offers for every category
        for _, cat in ipairs(shopConfig.categories) do
            local offersPayload = {}
            for _, item in ipairs(cat.items) do
                local it = ItemType(item.itemId)
                local clientId = it and it:getClientId() or item.itemId
                table.insert(offersPayload, {
                    id = clientId,
                    name = item.name,
                    price = item.price,
                    count = item.count,
                    categoryId = 1,
                    isSecondPrice = item.isSecondPrice or false,
                    isThirdPrice = item.isThirdPrice or false
                })
            end
            sendShopJSON(player, {action = "fetchOffers", data = {category = cat.name, offers = offersPayload}})
        end
        
        local taskPoints = math.max(0, player:getStorageValue(20021))
        local bossPoints = math.max(0, player:getStorageValue(20022))
        sendShopJSON(player, {action = "points", data = {points = getAccountPoints(player), secondPoints = taskPoints, thirdPoints = bossPoints}})

        -- Fetch History
        local historyPayload = {}
        local resultId = db.storeQuery("SELECT `title`, `price`, `costSecond`, `costThird`, DATE_FORMAT(`date`, '%d %b %Y %H:%i') as `date_str` FROM `shop_history` WHERE `account` = " .. player:getAccountId() .. " ORDER BY `date` DESC LIMIT 50")
        if resultId then
            repeat
                local pCoin = result.getDataInt(resultId, "price")
                local pTask = result.getDataInt(resultId, "costSecond")
                local pBoss = result.getDataInt(resultId, "costThird")
                
                -- As compras devem ser exibidas como saldo negativo (vermelho)
                local finalCost = pCoin
                if pBoss > 0 then finalCost = pBoss
                elseif pTask > 0 then finalCost = pTask end
                
                table.insert(historyPayload, {
                    name = result.getString(resultId, "title"),
                    price = -finalCost,
                    isSecondPrice = pTask > 0,
                    isThirdPrice = pBoss > 0,
                    date = result.getString(resultId, "date_str")
                })
            until not result.next(resultId)
            result.free(resultId)
        end
        sendShopJSON(player, {action = "history", data = historyPayload})

    elseif action == "getDescription" then
        local categoryName = data.category
        local descriptionData = ""

        for _, cat in ipairs(shopConfig.categories) do
            if cat.name == categoryName then
                for _, item in ipairs(cat.items) do
                    if data.name == item.name then
                        local currencyName = "Nexus Coins"
                        if item.isThirdPrice then currencyName = "Boss Points"
                        elseif item.isSecondPrice then currencyName = "Task Points" end
                        descriptionData = "Voce esta comprando " .. item.count .. "x " .. item.name .. " por " .. item.price .. " " .. currencyName .. "."
                        break
                    end
                end
                break
            end
        end

        sendShopJSON(player, {action = "fetchDescription", data = {name = data.name, description = descriptionData}})

    elseif action == "purchase" then
        local targetId = data.id
        local requestedCount = tonumber(data.count) or 1
        
        if not targetId or requestedCount <= 0 then
            sendShopJSON(player, {action = "msg", data = {type = "error", msg = "Item inválido ou quantidade insuficiente."}})
            return true
        end

        local foundItem = nil
        local foundCategory = nil
        for _, category in ipairs(shopConfig.categories) do
            for _, item in ipairs(category.items) do
                local it = ItemType(item.itemId)
                if it and it:getClientId() == targetId then
                    foundItem = item
                    foundCategory = category
                    break
                end
            end
            if foundItem then break end
        end

        if not foundItem then
            sendShopJSON(player, {action = "msg", data = {type = "error", msg = "Produto não encontrado na Store."}})
            return true
        end

        if foundItem.requireHouse then
            local house = Tile(player:getPosition()):getHouse()
            if not house or house:getOwnerGuid() ~= player:getGuid() then
                sendShopJSON(player, {action = "msg", data = {type = "error", msg = "Você precisa ser o dono da casa para comprar mobília aqui."}})
                return true
            end
        end

        local unitPrice = foundItem.price
        local baseCount = foundItem.count or 1
        
        -- Force requestedCount to 1 as per user request (buy only what is shown in the sample)
        local requestedCount = 1

        local totalItems = baseCount
        local totalPrice = unitPrice

        -- Check if we should force a backpack (Consumables: Runes & Potions)
        local forceBackpack = false
        if foundCategory and (foundCategory.name == "Consumiveis" or foundCategory.name == "Supplies") then
            forceBackpack = true
        end

        local isSecondPrice = foundItem.isSecondPrice or false
        local isThirdPrice = foundItem.isThirdPrice or false
        local playerTaskPoints = math.max(0, player:getStorageValue(20021))
        local playerBossPoints = math.max(0, player:getStorageValue(20022))

        if isThirdPrice then
            if playerBossPoints < totalPrice then
                sendShopJSON(player, {action = "msg", data = {type = "error", msg = "Você não possui Boss Points suficientes."}})
                return true
            end
        elseif isSecondPrice then
            if playerTaskPoints < totalPrice then
                sendShopJSON(player, {action = "msg", data = {type = "error", msg = "Você não possui Task Points suficientes."}})
                return true
            end
        else
            if getAccountPoints(player) < totalPrice then
                sendShopJSON(player, {action = "msg", data = {type = "error", msg = "Você não possui Nexus Coins suficientes."}})
                return true
            end
        end

        -- Purchase Execution
        local paymentSuccess = false
        if isThirdPrice then
            player:setStorageValue(20022, playerBossPoints - totalPrice)
            paymentSuccess = true
        elseif isSecondPrice then
            player:setStorageValue(20021, playerTaskPoints - totalPrice)
            paymentSuccess = true
        else
            paymentSuccess = removeAccountPoints(player, totalPrice)
        end

        if paymentSuccess then
            local remaining = totalItems
            local backpackCount = 0
            local currentTarget = player -- Start by adding directly to player
            
            -- If forcing a backpack, we start by creating one
            if forceBackpack then
                local firstBP = player:addItem(1988, 1)
                if firstBP then
                    currentTarget = firstBP
                    backpackCount = 1
                end
            end

            while remaining > 0 do
                local addCount = math.min(remaining, 100)
                local item = currentTarget:addItem(foundItem.itemId, foundItem.charges or addCount)
                
                if item then
                    local itType = item:getType()
                    local added = (itType and itType:isStackable() and item:getCount()) or 1
                    remaining = remaining - added
                else
                    -- If adding to player (or current BP) failed, create a new backpack
                    if backpackCount >= 20 then -- Limit to 20 extra backpacks for safety
                        break
                    end
                    
                    local newBP = player:addItem(1988, 1)
                    if not newBP then
                        break -- Player truly has no slots at all
                    end
                    
                    backpackCount = backpackCount + 1
                    currentTarget = newBP -- Now try adding to this new backpack
                    
                    -- Try adding the same amount to the new backpack
                    local newItem = currentTarget:addItem(foundItem.itemId, foundItem.charges or addCount)
                    if newItem then
                        local itType = newItem:getType()
                        local added = (itType and itType:isStackable() and newItem:getCount()) or 1
                        remaining = remaining - added
                    else
                        break -- Should not happen with fresh BP
                    end
                end
            end

            -- SQL Fix: Removed single quotes around %s because db.escapeString includes them
            local priceCoin = not (isSecondPrice or isThirdPrice) and totalPrice or 0
            local priceTask = isSecondPrice and totalPrice or 0
            local priceBoss = isThirdPrice and totalPrice or 0
            db.asyncQuery(string.format("INSERT INTO `shop_history` (`account`, `player`, `date`, `title`, `price`, `costSecond`, `costThird`, `count`) VALUES (%d, %d, NOW(), %s, %d, %d, %d, %d)", 
                player:getAccountId(), 
                player:getGuid(), 
                db.escapeString(foundItem.name .. " (x" .. requestedCount .. ")"), 
                priceCoin, 
                priceTask,
                priceBoss,
                totalItems))
            
            sendShopJSON(player, {action = "msg", data = {type = "info", msg = "Voce comprou " .. foundItem.name .. " com sucesso!", close = true}})
            
            local taskPoints = math.max(0, player:getStorageValue(20021))
            local bossPoints = math.max(0, player:getStorageValue(20022))
            sendShopJSON(player, {action = "points", data = {points = getAccountPoints(player), secondPoints = taskPoints, thirdPoints = bossPoints}})
            player:getPosition():sendMagicEffect(CONST_ME_GIFT_WRAPS)
        else
            sendShopJSON(player, {action = "msg", data = {type = "error", msg = "Erro ao processar o pagamento."}})
        end

    elseif action == "transfer" then
        local amountSecond = tonumber(data.amountSecond) or 0
        local amount = tonumber(data.amount) or 0
        local targetName = tostring(data.target) or ""
        local totalAmountDesc = ""
        
        if (amount <= 0 and amountSecond <= 0) or targetName == "" then
            sendShopJSON(player, {action = "msg", data = {type = "error", msg = "Dados vazios ou quantidade zero."}})
            return true
        end

        local resultId = db.storeQuery("SELECT `id`, `account_id` FROM `players` WHERE `name` = " .. db.escapeString(targetName))
        if not resultId then
            sendShopJSON(player, {action = "msg", data = {type = "error", msg = "Personagem não encontrado."}})
            return true
        end

        local targetAccountId = result.getDataInt(resultId, "account_id")
        result.free(resultId)

        if targetAccountId == player:getAccountId() then
            sendShopJSON(player, {action = "msg", data = {type = "error", msg = "Voce nao pode transferir para si mesmo."}})
            return true
        end
        
        local playerTaskPoints = math.max(0, player:getStorageValue(20021))
        local successCoins = false
        local successTask = false
        
        if amount > 0 then
            if removeAccountPoints(player, amount) then
                db.query("UPDATE `accounts` SET `premium_points` = `premium_points` + " .. amount .. " WHERE `id` = " .. targetAccountId)
                successCoins = true
                totalAmountDesc = totalAmountDesc .. amount .. " Nexus Coins"
            else
                sendShopJSON(player, {action = "msg", data = {type = "error", msg = "Saldo insuficiente de Nexus Coins."}})
                return true
            end
        end
        
        if amountSecond > 0 then
            if playerTaskPoints >= amountSecond then
                player:setStorageValue(20021, playerTaskPoints - amountSecond)
                -- We need to add task points to the target. However, OTClient target is an account ID here, but Task Points are character bound (Storage).
                -- Wait! Task points (storage 20021) are PLAYER BOUND, not ACCOUNT bound.
                -- We need to update the player_storage table for the target character.
                local targetPlayerResult = db.storeQuery("SELECT `id` FROM `players` WHERE `name` = " .. db.escapeString(targetName))
                if targetPlayerResult then
                    local targetPlayerId = result.getDataInt(targetPlayerResult, "id")
                    result.free(targetPlayerResult)
                    
                    -- Check if target is online to update storage directly, else update DB
                    local targetPlayerInstance = Player(targetName)
                    if targetPlayerInstance then
                        local currentTP = math.max(0, targetPlayerInstance:getStorageValue(20021))
                        targetPlayerInstance:setStorageValue(20021, currentTP + amountSecond)
                    else
                        -- Need to update player_storage in database
                        local storageCheck = db.storeQuery("SELECT `value` FROM `player_storage` WHERE `player_id` = " .. targetPlayerId .. " AND `key` = 20021")
                        if storageCheck then
                            local currentTargetTP = math.max(0, result.getDataInt(storageCheck, "value"))
                            result.free(storageCheck)
                            db.query("UPDATE `player_storage` SET `value` = " .. (currentTargetTP + amountSecond) .. " WHERE `player_id` = " .. targetPlayerId .. " AND `key` = 20021")
                        else
                            db.query("INSERT INTO `player_storage` (`player_id`, `key`, `value`) VALUES (" .. targetPlayerId .. ", 20021, " .. amountSecond .. ")")
                        end
                    end
                    
                    successTask = true
                    if totalAmountDesc ~= "" then totalAmountDesc = totalAmountDesc .. " e " end
                    totalAmountDesc = totalAmountDesc .. amountSecond .. " Task Points"
                end
            else
                sendShopJSON(player, {action = "msg", data = {type = "error", msg = "Saldo insuficiente de Task Points."}})
                return true
            end
        end

        if successCoins or successTask then
            -- Histórico para o pagador (Negativo na view = valor normal no db)
            db.asyncQuery(string.format("INSERT INTO `shop_history` (`account`, `player`, `date`, `title`, `price`, `costSecond`, `costThird`, `count`) VALUES (%d, %d, NOW(), %s, %d, %d, %d, %d)", 
                player:getAccountId(), 
                player:getGuid(), 
                db.escapeString("Transfer to " .. targetName), 
                amount > 0 and amount or 0, 
                amountSecond > 0 and amountSecond or 0, 
                0,
                1))

            -- Histórico para o recebedor (Positivo na view = valor negativo no db)
            db.asyncQuery(string.format("INSERT INTO `shop_history` (`account`, `player`, `date`, `title`, `price`, `costSecond`, `costThird`, `count`) VALUES (%d, %d, NOW(), %s, %d, %d, %d, %d)", 
                targetAccountId, 
                targetPlayerId or 0, 
                db.escapeString("Gift from " .. player:getName()), 
                amount > 0 and -amount or 0, 
                amountSecond > 0 and -amountSecond or 0, 
                0,
                1))

            sendShopJSON(player, {action = "msg", data = {type = "info", msg = "Voce transferiu " .. totalAmountDesc .. " para " .. targetName .. "!", close = true}})
            local taskPoints = math.max(0, player:getStorageValue(20021))
            local bossPoints = math.max(0, player:getStorageValue(20022))
            sendShopJSON(player, {action = "points", data = {points = getAccountPoints(player), secondPoints = taskPoints, thirdPoints = bossPoints}})
            
            -- Se o target estiver online, atualizar a view dele
            local targetPlayerInstance = Player(targetName)
            if targetPlayerInstance then
                local tTaskPoints = math.max(0, targetPlayerInstance:getStorageValue(20021))
                local tBossPoints = math.max(0, targetPlayerInstance:getStorageValue(20022))
                sendShopJSON(targetPlayerInstance, {action = "points", data = {points = getAccountPoints(targetPlayerInstance), secondPoints = tTaskPoints, thirdPoints = tBossPoints}})
            end
        end
    end
    return true
end

function onExtendedOpcode(player, opcode, buffer)
    if player:getStorageValue(STORAGE_OPCODE_EXHAUSTION) > os.mtime() then
        return true
    end
    player:setStorageValue(STORAGE_OPCODE_EXHAUSTION, os.mtime() + 200)

    if opcode == OPCODE_GAME_SHOP then
        local status, json_data = pcall(function() return json.decode(buffer) end)
        if status and type(json_data) == "table" then
            processShopOpcode(player, json_data)
        end
        return true
    end

    if opcode == OPCODE_BANK then
        local status, json_data = pcall(function() return json.decode(buffer) end)
        if status and type(json_data) == "table" then
            processBankOpcode(player, json_data)
        end
        return true
    end

    if opcode == OPCODE_CRAFTING then
        local status, json_data = pcall(function() return json.decode(buffer) end)
        if status and type(json_data) == "table" then
            processCraftingOpcode(player, json_data)
        end
        return true
    end

    if opcode == OPCODE_MARKET then
        if onMarketExtendedOpcode then
            onMarketExtendedOpcode(player, opcode, buffer)
        end
        return true
    end

    if opcode == 152 then -- AutoLoot
        if onAutoLootExtendedOpcode then
            onAutoLootExtendedOpcode(player, opcode, buffer)
        end
        return true
    end

    if opcode == 153 then -- Furniture
        if onFurnitureExtendedOpcode then
            onFurnitureExtendedOpcode(player, opcode, buffer)
        end
        return true
    end

    if opcode == 155 then
        local status, data = pcall(function() return json.decode(buffer) end)
        if status and type(data) == "table" and data.action == "request" then
            local target = data.cid and Player(data.cid) or Player(data.name)
            if target then target:syncTitle(player) end
        end
        return true
    end
    return true
end
