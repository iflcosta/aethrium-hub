--[[
    MARKET SYSTEM - Library
    Styller Nexus - Baiak Thunder
    
    Sistema completo de mercado player-to-player
    com Tibia Coins e Modal Window
]]

Market = {
    -- Configurações
    tibiaCoinsItemId = 2159,           -- ID Tibia Coin
    goldCoinId = 2148,                 -- ID Gold Coin
    platinumCoinId = 2152,             -- ID Platinum Coin
    crystalCoinId = 2160,              -- ID Crystal Coin
    
    -- Taxas
    taxPercent = 5,                    -- 5% tax padrão
    premiumTaxPercent = 2,             -- 2% tax VIP
    
    -- Limites
    maxOffers = 20,                    -- Max ofertas FREE
    premiumMaxOffers = 50,             -- Max ofertas VIP
    offerDuration = 7 * 86400,         -- 7 dias
    minPrice = 1,                      -- Preço mínimo
    maxPrice = 1000000,                -- Preço máximo
    
    -- Storages
    STORAGE_TIBIA_COINS = 93001,
    
    -- Modal Window IDs
    MODAL_MAIN = 10000,
    MODAL_SELL = 10001,
    MODAL_BUY = 10002,
    MODAL_MY_OFFERS = 10003,
    MODAL_SEARCH = 10004,
    MODAL_CONFIRM = 10005,
    
    -- Database
    offersTable = "market_offers",
    historyTable = "market_history",
}

-- ============================================================
-- TIBIA COINS FUNCTIONS
-- ============================================================

function Market.getTibiaCoins(player)
    return math.max(0, player:getStorageValue(Market.STORAGE_TIBIA_COINS))
end

function Market.setTibiaCoins(player, amount)
    player:setStorageValue(Market.STORAGE_TIBIA_COINS, math.max(0, amount))
end

function Market.addTibiaCoins(player, amount)
    local current = Market.getTibiaCoins(player)
    Market.setTibiaCoins(player, current + amount)
end

function Market.removeTibiaCoins(player, amount)
    local current = Market.getTibiaCoins(player)
    if current < amount then
        return false
    end
    Market.setTibiaCoins(player, current - amount)
    return true
end

-- ============================================================
-- GOLD FUNCTIONS
-- ============================================================

function Market.getPlayerGold(player)
    local gold = 0
    gold = gold + player:getItemCount(Market.goldCoinId)
    gold = gold + player:getItemCount(Market.platinumCoinId) * 100
    gold = gold + player:getItemCount(Market.crystalCoinId) * 10000
    return gold
end

function Market.removeGold(player, amount)
    if Market.getPlayerGold(player) < amount then
        return false
    end
    
    -- Remover crystal coins
    local crystals = math.floor(amount / 10000)
    if crystals > 0 then
        player:removeItem(Market.crystalCoinId, crystals)
        amount = amount - (crystals * 10000)
    end
    
    -- Remover platinum coins
    local platinums = math.floor(amount / 100)
    if platinums > 0 then
        player:removeItem(Market.platinumCoinId, platinums)
        amount = amount - (platinums * 100)
    end
    
    -- Remover gold coins
    if amount > 0 then
        player:removeItem(Market.goldCoinId, amount)
    end
    
    return true
end

function Market.addGold(player, amount)
    -- Adicionar em crystal coins (depot)
    local crystals = math.floor(amount / 10000)
    if crystals > 0 then
        player:addItem(Market.crystalCoinId, crystals, true)
        amount = amount - (crystals * 10000)
    end
    
    -- Adicionar em platinum coins
    local platinums = math.floor(amount / 100)
    if platinums > 0 then
        player:addItem(Market.platinumCoinId, platinums, true)
        amount = amount - (platinums * 100)
    end
    
    -- Adicionar gold coins restantes
    if amount > 0 then
        player:addItem(Market.goldCoinId, amount, true)
    end
    
    return true
end

-- ============================================================
-- PLAYER CHECKS
-- ============================================================

function Market.hasVipMarket(player)
    return player:getStorageValue(50200) >= 2  -- VIP Prata+
end

function Market.getMaxOffers(player)
    return Market.hasVipMarket(player) and Market.premiumMaxOffers or Market.maxOffers
end

function Market.getTaxPercent(player)
    return Market.hasVipMarket(player) and Market.premiumTaxPercent or Market.taxPercent
end

function Market.calculateTax(price, player)
    local taxPercent = Market.getTaxPercent(player)
    return math.floor(price * taxPercent / 100)
end

function Market.isInPZ(player)
    local tile = player:getTile()
    return tile and tile:hasFlag(TILESTATE_PROTECTIONZONE)
end

-- ============================================================
-- DATABASE FUNCTIONS
-- ============================================================

function Market.initDatabase()
    -- Tabela de ofertas
    db.query([[
        CREATE TABLE IF NOT EXISTS `market_offers` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `player_id` INT NOT NULL,
            `player_name` VARCHAR(255) NOT NULL,
            `item_id` INT NOT NULL,
            `item_count` INT DEFAULT 1,
            `price` INT NOT NULL,
            `currency` TINYINT DEFAULT 1 COMMENT '1=Gold, 2=TibiaCoin',
            `created_at` BIGINT NOT NULL,
            `expires_at` BIGINT NOT NULL,
            INDEX (`player_id`),
            INDEX (`item_id`),
            INDEX (`expires_at`),
            INDEX (`currency`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    -- Tabela de histórico
    db.query([[
        CREATE TABLE IF NOT EXISTS `market_history` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `seller_id` INT NOT NULL,
            `seller_name` VARCHAR(255) NOT NULL,
            `buyer_id` INT NOT NULL,
            `buyer_name` VARCHAR(255) NOT NULL,
            `item_id` INT NOT NULL,
            `item_count` INT DEFAULT 1,
            `price` INT NOT NULL,
            `currency` TINYINT DEFAULT 1,
            `tax` INT NOT NULL,
            `sold_at` BIGINT NOT NULL,
            INDEX (`seller_id`),
            INDEX (`buyer_id`),
            INDEX (`sold_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    print(">> [Market] Database tables initialized")
end

function Market.getPlayerOfferCount(playerId)
    local query = db.storeQuery(string.format(
        "SELECT COUNT(*) as total FROM %s WHERE player_id = %d",
        Market.offersTable, playerId))
    
    if not query then
        return 0
    end
    
    local count = result.getNumber(query, "total")
    result.free(query)
    return count
end

function Market.createOffer(player, itemId, itemCount, price, currency)
    -- Verificar limite ofertas
    if Market.getPlayerOfferCount(player:getGuid()) >= Market.getMaxOffers(player) then
        return false, "Limite de ofertas atingido!"
    end
    
    -- Validar preço
    if price < Market.minPrice or price > Market.maxPrice then
        return false, "Preço inválido!"
    end
    
    -- Remover item do player (vai pro depot automático na venda)
    local item = player:getItemById(itemId, true)
    if not item or item:getCount() < itemCount then
        return false, "Você não possui este item!"
    end
    
    item:remove(itemCount)
    
    -- Criar oferta
    local now = os.time()
    local expiresAt = now + Market.offerDuration
    
    db.asyncQuery(string.format([[
        INSERT INTO %s (player_id, player_name, item_id, item_count, price, currency, created_at, expires_at)
        VALUES (%d, %s, %d, %d, %d, %d, %d, %d)
    ]],
        Market.offersTable,
        player:getGuid(),
        db.escapeString(player:getName()),
        itemId,
        itemCount,
        price,
        currency,
        now,
        expiresAt
    ))
    
    return true, "Oferta criada com sucesso!"
end

function Market.buyOffer(player, offerId)
    -- Buscar oferta
    local query = db.storeQuery(string.format(
        "SELECT * FROM %s WHERE id = %d",
        Market.offersTable, offerId))
    
    if not query then
        return false, "Oferta não encontrada!"
    end
    
    local sellerId = result.getNumber(query, "player_id")
    local sellerName = result.getString(query, "player_name")
    local itemId = result.getNumber(query, "item_id")
    local itemCount = result.getNumber(query, "item_count")
    local price = result.getNumber(query, "price")
    local currency = result.getNumber(query, "currency")
    local expiresAt = result.getNumber(query, "expires_at")
    
    result.free(query)
    
    -- Verificar expiração
    if expiresAt <= os.time() then
        db.asyncQuery(string.format("DELETE FROM %s WHERE id = %d", Market.offersTable, offerId))
        return false, "Oferta expirada!"
    end
    
    -- Não pode comprar própria oferta
    if sellerId == player:getGuid() then
        return false, "Você não pode comprar sua própria oferta!"
    end
    
    -- Remover moeda do comprador
    if currency == 1 then  -- Gold
        if not Market.removeGold(player, price) then
            return false, "Você não tem " .. price .. " gold!"
        end
    else  -- Tibia Coin
        if not Market.removeTibiaCoins(player, price) then
            return false, "Você não tem " .. price .. " Tibia Coins!"
        end
    end
    
    -- Calcular tax
    local seller = Player(sellerName)
    local tax = Market.calculateTax(price, seller or player)
    local sellerReceives = price - tax
    
    -- Adicionar moeda ao vendedor (depot)
    if seller then
        if currency == 1 then
            Market.addGold(seller, sellerReceives)
        else
            Market.addTibiaCoins(seller, sellerReceives)
        end
        
        seller:sendTextMessage(MESSAGE_EVENT_ADVANCE,
            string.format("Sua oferta foi vendida! Recebeu %d %s (-% d%% tax)",
            sellerReceives, currency == 1 and "gold" or "TC", Market.getTaxPercent(seller)))
    else
        -- Seller offline, adicionar via storage
        if currency == 2 then
            db.asyncQuery(string.format(
                "UPDATE player_storage SET value = value + %d WHERE player_id = %d AND `key` = %d",
                sellerReceives, sellerId, Market.STORAGE_TIBIA_COINS))
        end
        -- Gold será adicionado ao depot quando logar (TODO: implementar inbox)
    end
    
    -- Dar item ao comprador (depot)
    player:addItem(itemId, itemCount, true)
    
    -- Remover oferta
    db.asyncQuery(string.format("DELETE FROM %s WHERE id = %d", Market.offersTable, offerId))
    
    -- Histórico
    db.asyncQuery(string.format([[
        INSERT INTO %s (seller_id, seller_name, buyer_id, buyer_name, item_id, item_count, price, currency, tax, sold_at)
        VALUES (%d, %s, %d, %s, %d, %d, %d, %d, %d, %d)
    ]],
        Market.historyTable,
        sellerId, db.escapeString(sellerName),
        player:getGuid(), db.escapeString(player:getName()),
        itemId, itemCount, price, currency, tax, os.time()
    ))
    
    return true, string.format("Comprou %dx %s por %d %s!",
        itemCount, ItemType(itemId):getName(), price, currency == 1 and "gold" or "TC")
end

function Market.cancelOffer(player, offerId)
    -- Verificar se oferta existe e pertence ao player
    local query = db.storeQuery(string.format(
        "SELECT item_id, item_count FROM %s WHERE id = %d AND player_id = %d",
        Market.offersTable, offerId, player:getGuid()))
    
    if not query then
        return false, "Oferta não encontrada!"
    end
    
    local itemId = result.getNumber(query, "item_id")
    local itemCount = result.getNumber(query, "item_count")
    result.free(query)
    
    -- Devolver item (depot)
    player:addItem(itemId, itemCount, true)
    
    -- Remover oferta
    db.asyncQuery(string.format("DELETE FROM %s WHERE id = %d", Market.offersTable, offerId))
    
    return true, "Oferta cancelada! Item devolvido ao depot."
end

-- ============================================================
-- FORMAT HELPERS
-- ============================================================

function Market.formatGold(amount)
    if amount >= 10000 then
        return string.format("%.1fk", amount / 1000)
    end
    return tostring(amount)
end

function Market.getCurrencyName(currency)
    return currency == 1 and "gold" or "TC"
end

print(">> [Market Library] Loaded successfully!")
