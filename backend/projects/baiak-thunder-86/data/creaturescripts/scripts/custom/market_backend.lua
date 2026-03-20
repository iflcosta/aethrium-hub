local OPCODE_MARKET = 202

local marketCore = {
    tcId = 24774,
    taxFree = 5,
    taxVip = 2,
    maxOffers = 20,
    maxOffersVip = 50, -- This line was removed in the instruction's implied change, but not explicitly. Keeping it for now.
    duration = configManager.getNumber(configKeys.MARKET_OFFER_DURATION),
    ST_GOLD_BALANCE = 50000,
    ST_TC_BALANCE = 50001,
}

-- Helper function
local function getTableSize(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Global cache for mapping Client IDs back to Server IDs
if not MARKET_CLIENT_MAP then
    MARKET_CLIENT_MAP = {}

    for i = 100, 40000 do
        local it = ItemType(i)
        if it:getId() > 0 then
            local client_id = it:getClientId()
            if client_id and client_id > 0 then
                MARKET_CLIENT_MAP[client_id] = it:getId()
            end
        end
    end

end

function marketCore.getTC(player) return player:getItemCount(marketCore.tcId) end
function marketCore.removeTC(player, amount)
    if marketCore.getTC(player) < amount then return false end
    return player:removeItem(marketCore.tcId, amount)
end
function marketCore.getGold(p)
    return p:getItemCount(2148) + (p:getItemCount(2152) * 100) + (p:getItemCount(2160) * 10000) + p:getBankBalance()
end
function marketCore.removeGold(p, amt)
    if marketCore.getGold(p) < amt then return false end
    -- Try removing from inventory first
    local invGold = p:getItemCount(2148) + (p:getItemCount(2152) * 100) + (p:getItemCount(2160) * 10000)
    if invGold >= amt then
        if p:removeMoney(amt) then return true end
        -- Manual coin removal fallback
        local remaining = amt
        local crystal = math.min(math.floor(remaining / 10000), p:getItemCount(2160))
        if crystal > 0 then p:removeItem(2160, crystal) remaining = remaining - (crystal * 10000) end
        if remaining > 0 then
            local plat = math.min(math.floor(remaining / 100), p:getItemCount(2152))
            if plat > 0 then p:removeItem(2152, plat) remaining = remaining - (plat * 100) end
            local gold = math.min(remaining, p:getItemCount(2148))
            if gold > 0 then p:removeItem(2148, gold) remaining = remaining - gold end
        end
        return remaining <= 0
    else
        -- Remove all inventory coins first, then pull remainder from bank
        local remaining = amt
        if invGold > 0 then
            p:removeMoney(invGold)
            remaining = remaining - invGold
        end
        if remaining > 0 then
            local bankBal = p:getBankBalance()
            if bankBal >= remaining then
                p:setBankBalance(bankBal - remaining)
                return true
            end
        end
        return false
    end
end
function marketCore.addGold(p, amt) return p:addMoney(amt) end
function marketCore.addTC(p, amt) return p:addItem(marketCore.tcId, amt, true) end
function marketCore.getTax(p) return (p:getStorageValue(50200) >= 2) and marketCore.taxVip or marketCore.taxFree end
function marketCore.getMax(p) return (p:getStorageValue(50200) >= 2) and marketCore.maxOffersVip or marketCore.maxOffers end

local function sendMarketJSON(player, data)
    player:sendExtendedOpcode(OPCODE_MARKET, json.encode(data))
end

local function scanContainer(container, itemsMap)
    if not container then return end
    for i = 0, container:getSize() - 1 do
        local item = container:getItem(i)
        if item then
            if item:isContainer() then
                scanContainer(item, itemsMap)
            else
                local iid = item:getId()
                itemsMap[iid] = (itemsMap[iid] or 0) + item:getCount()
            end
        end
    end
end

local function getPlayerItems(player)
    local itemsMap = {}
    
    player:save()
    local pid = player:getGuid()
    local q = db.storeQuery("SELECT itemtype, count FROM player_depotitems WHERE player_id = " .. pid)
    
    if q then
        repeat
            local iid = result.getNumber(q, "itemtype")
            local count = result.getNumber(q, "count")
            itemsMap[iid] = (itemsMap[iid] or 0) + count
        until not result.next(q)
        result.free(q)
    end

    local resultData = {}
    for iid, count in pairs(itemsMap) do
        local it = ItemType(iid)
        local clientId = it:getClientId()
        
        -- Fallback to the Server ID if getClientId fails or there's none
        if not clientId or clientId == 0 then
            clientId = iid
        end
        
        table.insert(resultData, {clientId, 0, count})
    end
    return resultData
end

local function removePlayerItemDeep(player, itemId, amount)
    local toRemove = amount
    local foundItems = {}
    
    local function findInContainer(container)
        if not container then return end
        for i = 0, container:getSize() - 1 do
            local item = container:getItem(i)
            if item then
                if item:getId() == itemId then
                    table.insert(foundItems, item)
                elseif item:isContainer() then
                    findInContainer(item)
                end
            end
        end
    end
    
    for i = 1, 105 do
        local depotChest = player:getDepotChest(i, true)
        if depotChest then findInContainer(depotChest) end
    end
    
    local memoryCount = 0
    for _, item in ipairs(foundItems) do
        memoryCount = memoryCount + item:getCount()
    end
    
    if memoryCount >= toRemove then
        for _, item in ipairs(foundItems) do
            local c = item:getCount()
            if c >= toRemove then
                item:remove(toRemove)
                return true
            else
                item:remove()
                toRemove = toRemove - c
                if toRemove <= 0 then return true end
        end
        end
        return true
    end

    -- SQL Fallback logic (items are in depot but not loaded in memory yet)

    player:save()
    local pid = player:getGuid()
    
    local totalInDb = 0
    local dbRows = {}
    local q = db.storeQuery(string.format("SELECT sid, pid, count FROM player_depotitems WHERE player_id = %d AND itemtype = %d", pid, itemId))
    if q then

        repeat
            local sid = result.getNumber(q, "sid")
            local p_id = result.getNumber(q, "pid")
            local count = result.getNumber(q, "count")

            table.insert(dbRows, {sid = sid, pid = p_id, count = count})
            totalInDb = totalInDb + count
        until not result.next(q)
        result.free(q)
    else

    end
    

    if totalInDb < toRemove then 

        return false 
    end
    
    for _, row in ipairs(dbRows) do
        if row.count > toRemove then

            db.query(string.format("UPDATE player_depotitems SET count = %d WHERE player_id = %d AND sid = %d AND pid = %d AND itemtype = %d", row.count - toRemove, pid, row.sid, row.pid, itemId))
            toRemove = 0
            break
        else

            db.query(string.format("DELETE FROM player_depotitems WHERE player_id = %d AND sid = %d AND pid = %d AND itemtype = %d", pid, row.sid, row.pid, itemId))
            toRemove = toRemove - row.count
            if toRemove <= 0 then break end
        end
    end
    

    return true
end

function onMarketExtendedOpcode(player, opcode, buffer)
    if opcode ~= OPCODE_MARKET then return false end
    
    local status, data = pcall(function() return json.decode(buffer) end)
    if not status or not data then return false end

    -- PZ Restriction
    local tile = player:getTile()
    if not tile or not tile:hasFlag(TILESTATE_PROTECTIONZONE) then
        player:sendCancelMessage("You can only use the Market inside a Protection Zone (PZ).")
        return true
    end

    local action = data.action
    local pid = player:getGuid()
    
    if action == "init" then
        local gold = marketCore.getGold(player)
        local tc = marketCore.getTC(player)
        
        sendMarketJSON(player, {
            action = "enter",
            depotItems = getPlayerItems(player),
            offerCount = 0,
            gold = gold,
            tc = tc
        })
    elseif action == "browse" then
        if data.type == 1 then -- History
            sendMarketJSON(player, {action = "browseHistory", buyOffers = {}, sellOffers = {}})
        elseif data.type == 2 then -- My Offers
            local myBuyOffers = {}
            local mySellOffers = {}
            local q = db.storeQuery(string.format("SELECT * FROM market_offers WHERE player_id = %d", pid))
            if q then
                repeat
                    local s_id = result.getNumber(q, "item_id")
                    local c_id = ItemType(s_id):getClientId() or s_id
                    local otype = result.getNumber(q, "offer_type")
                    
                    local offer = {
                        timestamp = result.getNumber(q, "created_at"),
                        counter = result.getNumber(q, "id"),
                        action = otype,
                        itemId = c_id,
                        amount = result.getNumber(q, "item_count"),
                        price = result.getNumber(q, "price"),
                        holder = result.getString(q, "player_name"),
                        state = 0,
                        var = 2, -- My Offers
                        tier = 0
                    }
                    if otype == 0 then
                        table.insert(myBuyOffers, offer)
                    else
                        table.insert(mySellOffers, offer)
                    end
                until not result.next(q)
                result.free(q)
            end
            sendMarketJSON(player, {action = "browseMyOffers", buyOffers = myBuyOffers, sellOffers = mySellOffers})
        elseif data.type == 3 then -- Browse Category/Item
            local buyOffersList = {}
            local sellOffersList = {}
            local iid = data.itemId or 0
            
            -- Client sends Client ID 3370, we need to match it against Server ID 2476 in the DB
            local search_iid = MARKET_CLIENT_MAP[iid] or iid

            if search_iid > 0 then
                local q = db.storeQuery(string.format("SELECT * FROM market_offers WHERE item_id = %d AND expires_at > %d", search_iid, os.time()))
                if q then
                    repeat
                        local s_id = result.getNumber(q, "item_id")
                        local c_id = ItemType(s_id):getClientId() or s_id
                        local otype = result.getNumber(q, "offer_type")

                        local offer = {
                            timestamp = result.getNumber(q, "created_at"),
                            counter = result.getNumber(q, "id"),
                            action = otype,
                            itemId = c_id,
                            amount = result.getNumber(q, "item_count"),
                            price = result.getNumber(q, "price"),
                            holder = result.getString(q, "player_name"),
                            state = 0,
                            var = 0,
                            tier = 0
                        }
                        if otype == 0 then
                            table.insert(buyOffersList, offer)
                        else
                            table.insert(sellOffersList, offer)
                        end
                    until not result.next(q)
                    result.free(q)
                end
            end
            sendMarketJSON(player, {action = "browse", buyOffers = buyOffersList, sellOffers = sellOffersList})
        end
    elseif action == "create" then
        local clientId = data.itemId
        local amount = data.amount
        local price = data.price
        local offerType = data.type -- 0 = buy, 1 = sell

        -- Convert incoming Client ID to Server ID using global map
        local iid = MARKET_CLIENT_MAP[clientId] or clientId

        if offerType == 1 then -- Sell
            if not removePlayerItemDeep(player, iid, amount) then
                sendMarketJSON(player, {action = "msg", title = "Error", msg = "Você não tem os itens suficientes na mochila ou depot."})
                return true
            end
            
            -- Deduct creation tax
            local taxPercent = marketCore.getTax(player)
            local taxAmount = math.floor(price * taxPercent / 100)
            if taxAmount > 0 then
                if not marketCore.removeGold(player, taxAmount) then
                    sendMarketJSON(player, {action = "msg", title = "Error", msg = "Você não tem gold suficiente para pagar a taxa de " .. taxAmount .. " gold (" .. taxPercent .. "%)."})
                    -- Return the item since we already removed it
                    player:addItem(iid, amount, true)
                    return true
                end
            end
            
            db.asyncQuery(string.format(
                "INSERT INTO market_offers (player_id, player_name, item_id, offer_type, item_count, price, currency, category, created_at, expires_at) VALUES (%d, %s, %d, %d, %d, %d, %d, %d, %d, %d)",
                pid, db.escapeString(player:getName()), iid, 1, amount, price, 1, 6,
                os.time(), os.time() + marketCore.duration))

            sendMarketJSON(player, {action = "msg", title = "Market", msg = "Oferta criada! Taxa: " .. taxAmount .. " gold (" .. taxPercent .. "%)"})
            sendMarketJSON(player, {action = "close"})
        elseif offerType == 0 then -- Buy
            local totalCost = price * amount
            if not marketCore.removeGold(player, totalCost) then
                sendMarketJSON(player, {action = "msg", title = "Error", msg = "Você não tem ouro suficiente."})
                return true
            end
            
            db.asyncQuery(string.format(
                "INSERT INTO market_offers (player_id, player_name, item_id, offer_type, item_count, price, currency, category, created_at, expires_at) VALUES (%d, %s, %d, %d, %d, %d, %d, %d, %d, %d)",
                pid, db.escapeString(player:getName()), iid, 0, amount, price, 1, 6,
                os.time(), os.time() + marketCore.duration))

            sendMarketJSON(player, {action = "msg", title = "Market", msg = "Oferta de compra criada com sucesso!"})
            sendMarketJSON(player, {action = "close"})
        end
    elseif action == "accept" then
        local offerId = data.counter
        
        local q = db.storeQuery("SELECT * FROM market_offers WHERE id = " .. offerId)
        if not q then 
            sendMarketJSON(player, {action = "msg", title = "Error", msg = "Oferta não encontrada ou já comprada."})
            return true 
        end
        
        local sid = result.getNumber(q, "player_id")
        local offerType = result.getNumber(q, "offer_type")
        local prc = result.getNumber(q, "price")
        local cur = result.getNumber(q, "currency")
        local iid = result.getNumber(q, "item_id")
        local cnt = result.getNumber(q, "item_count")
        result.free(q)
        
        if sid == pid then 
            sendMarketJSON(player, {action = "msg", title = "Error", msg = "Você não pode aceitar sua própria oferta."})
            return true 
        end

        local taxVal = math.floor(prc * marketCore.getTax(player) / 100)
        local receive = prc - taxVal
        
        if offerType == 1 then -- Selling Offer (Acceptor is Buying)
            if cur == 1 then
                if not marketCore.removeGold(player, prc) then 
                    sendMarketJSON(player, {action = "msg", title = "Error", msg = "Gold insuficiente!"})
                    return true 
                end
            else
                if not marketCore.removeTC(player, prc) then 
                    sendMarketJSON(player, {action = "msg", title = "Error", msg = "Nexus Coins insuficientes!"})
                    return true 
                end
            end
            
            player:addItem(iid, cnt, true)
            db.asyncQuery("DELETE FROM market_offers WHERE id = " .. offerId)
            
            -- Pay seller by adding directly to bank balance
            local seller = Player(sid)
            if seller then
                seller:setBankBalance(seller:getBankBalance() + receive)
                seller:sendTextMessage(MESSAGE_INFO_DESCR, "[Market] Seus " .. cnt .. "x " .. ItemType(iid):getName() .. " foram vendidos! " .. receive .. " gold adicionados ao banco.")
            else
                -- Seller offline: queue gold delivery for next login (item_id=0 = gold)
                db.query(string.format(
                    "INSERT INTO market_deliveries (player_id, item_id, amount) VALUES (%d, 0, %d)",
                    sid, receive))
            end

            sendMarketJSON(player, {action = "msg", title = "Market", msg = "Você comprou o item com sucesso!"})

        elseif offerType == 0 then -- Buying Offer (Acceptor is Selling)
            -- Acceptor pays the item
            if not removePlayerItemDeep(player, iid, cnt) then
                sendMarketJSON(player, {action = "msg", title = "Error", msg = "Você não tem os itens suficientes na mochila ou depot."})
                return true
            end
            
            -- Acceptor receives the money (minus tax)
            if cur == 1 then
                marketCore.addGold(player, receive)
            else
                marketCore.addTC(player, receive)
            end
            
            db.asyncQuery("DELETE FROM market_offers WHERE id = " .. offerId)
            
            -- Creator of the Buy offer receives the item
            local creator = Player(sid)
            if creator then
                creator:addItem(iid, cnt, true)
                creator:sendTextMessage(MESSAGE_INFO_DESCR, "[Market] Sua oferta de compra foi concluída! " .. cnt .. "x " .. ItemType(iid):getName() .. " entregues.")
            else
                db.asyncQuery(string.format(
                    "INSERT INTO market_deliveries (player_id, item_id, amount) VALUES (%d, %d, %d)",
                    sid, iid, cnt))
            end
            
            sendMarketJSON(player, {action = "msg", title = "Market", msg = "Você vendeu o item com sucesso!"})
        end
        sendMarketJSON(player, {action = "close"})

    elseif action == "cancel" then
        local offerId = data.counter
        local q = db.storeQuery(string.format(
            "SELECT item_id, item_count FROM market_offers WHERE id = %d AND player_id = %d", offerId, pid))
        
        if q then
            local iid = result.getNumber(q, "item_id")
            local cnt = result.getNumber(q, "item_count")
            result.free(q)
            
            player:addItem(iid, cnt, true)
            db.asyncQuery("DELETE FROM market_offers WHERE id = " .. offerId)
            sendMarketJSON(player, {action = "msg", title = "Market", msg = "A oferta foi cancelada e os itens recuperados."})
            sendMarketJSON(player, {action = "close"})
        else
            sendMarketJSON(player, {action = "msg", title = "Error", msg = "Oferta não encontrada."})
        end

    elseif action == "leave" then
        local gBalance = math.max(0, player:getStorageValue(marketCore.ST_GOLD_BALANCE))
        local tBalance = math.max(0, player:getStorageValue(marketCore.ST_TC_BALANCE))
        
        if gBalance > 0 then
            marketCore.addGold(player, gBalance)
            player:setStorageValue(marketCore.ST_GOLD_BALANCE, 0)
            player:sendTextMessage(MESSAGE_INFO_DESCR, "Você resgatou " .. gBalance .. " gold do seu Saldo Market.")
        end
        
        if tBalance > 0 then
            marketCore.addTC(player, tBalance)
            player:setStorageValue(marketCore.ST_TC_BALANCE, 0)
            player:sendTextMessage(MESSAGE_INFO_DESCR, "Você resgatou " .. tBalance .. " NC do seu Saldo Market.")
        end
    end

    return true
end
