local deposit = TalkAction("!deposit")

-- Configuração (Mantendo o padrão do seu withdraw)
local config = {
    coinId = 24774, -- ID do Tibia Coin (item roxo)
    dbColumn = "premium_points" -- Nome da coluna no banco de dados
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

function deposit.onSay(player, words, param)
    -- Exhaustion (200ms)
    local STORAGE_EXHAUST = 49996
    if player:getStorageValue(STORAGE_EXHAUST) > os.mtime() then
        return false
    end
    player:setStorageValue(STORAGE_EXHAUST, os.mtime() + 200)

    -- Tenta converter o parâmetro para número (removendo espaços extras)
    local amount = tonumber(param)
    
    -- Se não for um número válido ou for menor/igual a 0
    if not amount or amount <= 0 then
        player:sendCancelMessage("Comando incorreto. Use: !deposit 10")
        return false
    end
    
    -- 1. Verifica se o player tem os itens na mochila
    local playerCount = player:getItemCount(config.coinId)
    
    if playerCount < amount then
        player:sendCancelMessage("Voce nao tem Tibia Coins suficientes. Voce possui: " .. playerCount)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    -- 2. Tenta remover os itens
    if player:removeItem(config.coinId, amount) then
        -- 3. Adiciona os pontos no banco de dados (tabela accounts)
        db.query("UPDATE `accounts` SET `" .. config.dbColumn .. "` = `" .. config.dbColumn .. "` + " .. amount .. " WHERE `id` = " .. player:getAccountId())
        
        -- Feedback visual e mensagem de sucesso
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Sucesso! Voce depositou " .. amount .. " Tibia Coins na sua conta.")
        player:getPosition():sendMagicEffect(CONST_ME_GIFT_WRAPS)
        
        -- Sincronizar Shop UI
        sendShopUpdate(player)
    else
        player:sendCancelMessage("Erro ao processar o deposito. Tente novamente.")
    end
    
    return false
end

-- A MESMA ALTERAÇÃO QUE CORRIGIU O WITHDRAW:
deposit:separator(" ") 
deposit:register()