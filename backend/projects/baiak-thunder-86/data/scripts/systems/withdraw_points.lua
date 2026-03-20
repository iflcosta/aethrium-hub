local withdraw = TalkAction("!withdraw")

-- Configuração
local config = {
    coinId = 24774, -- ID do Tibia Coin (item roxo)
    dbColumn = "premium_points" -- Nome da coluna no banco de dados (confirme se é premium_points ou coins)
}

local function sendShopUpdate(player)
    local resultId = db.storeQuery("SELECT `premium_points` FROM `accounts` WHERE `id` = " .. player:getAccountId())
    local points = 0
    if resultId then
        points = result.getDataInt(resultId, "premium_points")
        result.free(resultId)
    end
    local taskPoints = math.max(0, player:getStorageValue(20021))
    local bossPoints = math.max(0, player:getStorageValue(20022))
    player:sendExtendedOpcode(201, json.encode({action = "points", data = {points = points, secondPoints = taskPoints, thirdPoints = bossPoints}}))
end

function withdraw.onSay(player, words, param)
    -- Exhaustion (200ms)
    local STORAGE_EXHAUST = 49996
    if player:getStorageValue(STORAGE_EXHAUST) > os.mtime() then
        return false
    end
    player:setStorageValue(STORAGE_EXHAUST, os.mtime() + 200)

    -- Tenta converter o parâmetro para número
    local amount = tonumber(param)
    
    -- Se não for número ou for menor/igual a 0
    if not amount or amount <= 0 then
        player:sendCancelMessage("Comando incorreto. Use: !withdraw 10")
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Exemplo: Para sacar 50 pontos, digite !withdraw 50")
        return false
    end
    
    -- Consulta o saldo
    local resultId = db.storeQuery("SELECT `" .. config.dbColumn .. "` FROM `accounts` WHERE `id` = " .. player:getAccountId())
    
    if not resultId then
        return false
    end

    local balance = result.getDataInt(resultId, config.dbColumn)
    result.free(resultId)

    -- Verifica saldo
    if balance < amount then
        player:sendCancelMessage("Saldo insuficiente. Voce tem " .. balance .. " pontos.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    -- Executa a transação
    -- 1. Remove pontos
    db.query("UPDATE `accounts` SET `" .. config.dbColumn .. "` = `" .. config.dbColumn .. "` - " .. amount .. " WHERE `id` = " .. player:getAccountId())
    
    -- 2. Entrega o item
    player:addItem(config.coinId, amount)
    
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Sucesso! Voce converteu " .. amount .. " pontos em Tibia Coins.")
    player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
    
    -- Sincronizar Shop UI
    sendShopUpdate(player)
    
    return false
end

-- AQUI ESTÁ A CORREÇÃO MÁGICA:
withdraw:separator(" ") -- Avisa o servidor que existe um espaço separando o comando do número
withdraw:register()