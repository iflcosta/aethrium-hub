-- ============================================
-- BAIAK THUNDER - LOTTERY SYSTEM LIB (TRIPLE MATCH)
-- Core logic for multi-number tickets and jackpot
-- ============================================

Lottery = {
    config = {
        maxNumber = 50, -- Numbers from 1 to 50
        numbersPerTicket = 3,
        ticketCost = 100000,
        
        -- Storages
        storages = {
            jackpotBP = 28500,
            jackpotTP = 28501,
            tickets = 28502 -- JSON string: { [guid] = { {n1,n2,n3}, {n4,n5,n6} } }
        },
        
        -- Default rewards
        minJackpotBP = 100,
        minJackpotTP = 500
    }
}

function Lottery.getJackpot()
    local bp = math.max(Lottery.config.minJackpotBP, Game.getStorageValue(Lottery.config.storages.jackpotBP))
    local tp = math.max(Lottery.config.minJackpotTP, Game.getStorageValue(Lottery.config.storages.jackpotTP))
    return bp, tp
end

function Lottery.setJackpot(bp, tp)
    Game.setStorageValue(Lottery.config.storages.jackpotBP, bp)
    Game.setStorageValue(Lottery.config.storages.jackpotTP, tp)
end

function Lottery.addtoJackpot(bp, tp)
    local currentBP, currentTP = Lottery.getJackpot()
    Lottery.setJackpot(currentBP + (bp or 0), currentTP + (tp or 0))
end

function Lottery.getTickets()
    local data = Game.getStorageValue(Lottery.config.storages.tickets)
    if not data or data == "" or data == -1 then
        return {}
    end
    return json.decode(data)
end

function Lottery.saveTickets(tickets)
    Game.setStorageValue(Lottery.config.storages.tickets, json.encode(tickets))
end

function Lottery.buyTicket(player, numbers)
    if #numbers ~= Lottery.config.numbersPerTicket then
        return false, "Você precisa escolher exatamente " .. Lottery.config.numbersPerTicket .. " números."
    end
    
    -- Sort and validate numbers
    table.sort(numbers)
    for i, n in ipairs(numbers) do
        if n < 1 or n > Lottery.config.maxNumber then
            return false, "Os números devem estar entre 1 e " .. Lottery.config.maxNumber .. "."
        end
        if i > 1 and n == numbers[i-1] then
            return false, "Os números devem ser distintos."
        end
    end
    
    local tickets = Lottery.getTickets()
    local guid = tostring(player:getGuid())
    tickets[guid] = tickets[guid] or {}
    table.insert(tickets[guid], numbers)
    
    Lottery.saveTickets(tickets)
    
    -- Gold Sink Conversion: 100k adds 20 BP / 100 TP to global pool
    Lottery.addtoJackpot(20, 100)
    
    return true
end

function Lottery.draw()
    -- Generate 3 unique winning numbers
    local winning = {}
    while #winning < Lottery.config.numbersPerTicket do
        local n = math.random(1, Lottery.config.maxNumber)
        local found = false
        for _, v in ipairs(winning) do
            if v == n then found = true break end
        end
        if not found then table.insert(winning, n) end
    end
    table.sort(winning)
    
    local winningStr = table.concat(winning, ", ")
    Game.broadcastMessage("[Lottery] Números sorteados: [" .. winningStr .. "]!", MESSAGE_STATUS_WARNING)
    
    local tickets = Lottery.getTickets()
    local winners3 = {} -- Jackpot
    local winners2 = {} -- Partial
    local winners1 = {} -- Consolation
    
    for guid, playerTickets in pairs(tickets) do
        local pGuid = tonumber(guid)
        for _, ticket in ipairs(playerTickets) do
            local matches = 0
            for _, tn in ipairs(ticket) do
                for _, wn in ipairs(winning) do
                    if tn == wn then matches = matches + 1 break end
                end
            end
            
            if matches == 3 then table.insert(winners3, pGuid)
            elseif matches == 2 then table.insert(winners2, pGuid)
            elseif matches == 1 then table.insert(winners1, pGuid)
            end
        end
    end
    
    -- Process Prizes
    if #winners3 > 0 then
        local bp, tp = Lottery.getJackpot()
        local bpDiv = math.floor(bp / #winners3)
        local tpDiv = math.floor(tp / #winners3)
        for _, guid in ipairs(winners3) do
            local p = Player(guid)
            if p then
                p:addEventPoints("boss", bpDiv)
                p:addEventPoints("task", tpDiv)
                p:addItem(5957, 1) -- Jackpot Item
                p:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[Lottery] PARABÉNS! Você acertou os 3 números e ganhou o Jackpot!")
            end
        end
        Game.broadcastMessage("[Lottery] Tivemos " .. #winners3 .. " ganhador(es) do Jackpot! Próximo sorteio resetado.", MESSAGE_STATUS_WARNING)
        Lottery.setJackpot(Lottery.config.minJackpotBP, Lottery.config.minJackpotTP)
    else
        Game.broadcastMessage("[Lottery] Ninguém acertou os 3 números. O Jackpot acumulou!", MESSAGE_STATUS_WARNING)
    end
    
    -- Fixed rewards for 2 and 1 matches (to keep interest without inflating)
    for _, guid in ipairs(winners2) do
        local p = Player(guid)
        if p then p:addEventPoints("boss", 50) p:addEventPoints("task", 250) end
    end
    
    for _, guid in ipairs(winners1) do
        local p = Player(guid)
        if p then p:addItem(2160, 1) end -- 10k consolation
    end
    
    -- Clear tickets for next round
    Lottery.saveTickets({})
end
