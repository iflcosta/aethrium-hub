function onSay(player, words, param)
    if param == "" or param:lower() == "help" then
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Use: !lottery buy <n1> <n2> <n3> (Custa 100k) ou !lottery info")
        return false
    end

    local split = param:split(" ")
    local command = split[1]:lower()

    if command == "info" then
        local bp, tp = Lottery.getJackpot()
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("[Lottery] Jackpot para 3 acertos: %d Boss Points e %d Task Points. Números 1 a %d.", bp, tp, Lottery.config.maxNumber))
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Prêmios: 2 acertos (50 BP / 250 TP), 1 acerto (1 Crystal Coin).")
        return false
    end

    if command == "buy" then
        if #split < 4 then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Você precisa especificar 3 números. Ex: !lottery buy 10 25 42")
            return false
        end

        local n1, n2, n3 = tonumber(split[2]), tonumber(split[3]), tonumber(split[4])
        if not n1 or not n2 or not n3 then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Números inválidos.")
            return false
        end

        if not player:removeMoney(Lottery.config.ticketCost) then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Você precisa de 100k para comprar um bilhete.")
            return false
        end

        local success, msg = Lottery.buyTicket(player, {n1, n2, n3})
        if success then
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Você comprou o bilhete [%d, %d, %d]. Boa sorte!", n1, n2, n3))
        else
            player:addMoney(Lottery.config.ticketCost) -- Refund
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, msg)
        end
        return false
    end

    return false
end
