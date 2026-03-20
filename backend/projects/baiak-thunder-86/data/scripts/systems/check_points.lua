local checkPoints = TalkAction("!points", "!pontos", "!saldo")

-- Configuração (Mesma coluna usada no withdraw e deposit)
local config = {
    dbColumn = "premium_points"
}

function checkPoints.onSay(player, words, param)
    -- 1. Consulta o saldo no banco de dados
    local resultId = db.storeQuery("SELECT `" .. config.dbColumn .. "` FROM `accounts` WHERE `id` = " .. player:getAccountId())
    
    if not resultId then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Erro: Não foi possível acessar o saldo da conta.")
        return false
    end

    local balance = result.getDataInt(resultId, config.dbColumn)
    result.free(resultId)

    -- 2. Envia a resposta (Console e Centro da Tela)
    -- Usamos sendTextMessage porque é o método mais garantido em todas as distros 8.60
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, "Sua conta possui atualmente " .. balance .. " pontos.")
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Saldo: " .. balance .. " pontos.")
    
    return false
end

checkPoints:register()