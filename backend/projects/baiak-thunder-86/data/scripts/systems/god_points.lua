local godPoints = TalkAction("/addpoints")

function godPoints.onSay(player, words, param)
    -- Verifica se é GOD
    if not player:getGroup():getAccess() then
        return true
    end

    local split = param:split(",")
    if #split < 2 then
        player:sendCancelMessage("Uso correto: /addpoints Nome do Player, Quantidade")
        return false
    end

    local targetName = split[1]:trim()
    local amount = tonumber(split[2]:trim())

    if not amount then
        player:sendCancelMessage("A quantidade deve ser um numero.")
        return false
    end

    local target = Player(targetName)
    if not target then
        player:sendCancelMessage("O jogador " .. targetName .. " deve estar online.")
        return false
    end

    -- Atualiza o Banco de Dados
    -- NOTA: Verifique se sua tabela chama 'accounts' e a coluna 'premium_points'
    db.query("UPDATE `accounts` SET `premium_points` = `premium_points` + " .. amount .. " WHERE `id` = " .. target:getAccountId())
    
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Voce adicionou " .. amount .. " Premium Points para " .. targetName .. ".")
    target:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Voce recebeu " .. amount .. " Premium Points!")
    target:getPosition():sendMagicEffect(CONST_ME_GIFT_WRAPS)
    
    return false
end

godPoints:separator(" ")
godPoints:register()