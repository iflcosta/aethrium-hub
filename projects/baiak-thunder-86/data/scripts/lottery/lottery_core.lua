-- ============================================
-- NEXUS GRAND LOTTERY - CORE LIBRARY
-- TFS 1.3 / 1.5 (Nekiro Downgrade)
-- ============================================

NexusLottery = {}

NexusLottery.Config = {
    NumbersRange = 60,
    NumbersPerTicket = 6,
    MaxTicketsPerPlayer = 20,
    CutoffTime = 600, -- 10 minutes before draw
    
    Prices = {
        ["simple"] = 10000,
        ["double"] = 18000,
        ["quintuple"] = 40000,
        ["mega"] = 75000
    },
    
    BetsPerType = {
        ["simple"] = 1,
        ["double"] = 2,
        ["quintuple"] = 5,
        ["mega"] = 10
    },
    
    Distribution = {
        Jackpot = 0.70, -- 6/6
        Match5 = 0.15,
        Match4 = 0.10,
        Match3 = 0.05
    }
}

function NexusLottery.formatNumber(n)
    if not n then return "0" end
    local left,num,right = string.match(tostring(n),'^([^%d]*%d+)(%d*)(.-)$')
    if not left then return tostring(n) end
    return left..(num:reverse():gsub('(%d%d%d)','%1.'):reverse())..right
end

-- -----------------------------------------------------------
-- DB UTILITIES
-- -----------------------------------------------------------

function NexusLottery.getCurrentDraw()
    local resultId = db.storeQuery("SELECT * FROM `lottery_draws` WHERE `status` = 'pending' ORDER BY `scheduled_time` ASC LIMIT 1")
    if resultId == false then
        return nil
    end
    
    local draw = {
        id = result.getDataInt(resultId, "id"),
        draw_number = result.getDataInt(resultId, "draw_number"),
        scheduled_time = result.getDataInt(resultId, "scheduled_time"),
        jackpot_accumulated = result.getDataInt(resultId, "jackpot_accumulated"),
        prize_pool = result.getDataInt(resultId, "prize_pool")
    }
    result.free(resultId)
    return draw
end

function NexusLottery.getPlayerTicketCount(playerId, drawId)
    local resultId = db.storeQuery(string.format("SELECT COUNT(*) as count FROM `lottery_tickets` WHERE `player_id` = %d AND `draw_id` = %d", playerId, drawId))
    if resultId == false then
        return 0
    end
    local count = result.getDataInt(resultId, "count")
    result.free(resultId)
    return count
end

function NexusLottery.getPlayerTickets(playerId, drawId)
    local resultId = db.storeQuery(string.format("SELECT `number_1`, `number_2`, `number_3`, `number_4`, `number_5`, `number_6` FROM `lottery_tickets` WHERE `player_id` = %d AND `draw_id` = %d", playerId, drawId))
    if resultId == false then
        return {}
    end
    
    local tickets = {}
    repeat
        local t = {
            result.getDataInt(resultId, "number_1"),
            result.getDataInt(resultId, "number_2"),
            result.getDataInt(resultId, "number_3"),
            result.getDataInt(resultId, "number_4"),
            result.getDataInt(resultId, "number_5"),
            result.getDataInt(resultId, "number_6")
        }
        table.insert(tickets, t)
    until not result.next(resultId)
    result.free(resultId)
    return tickets
end

-- -----------------------------------------------------------
-- CORE LOGIC
-- -----------------------------------------------------------

function NexusLottery.validateNumbers(numbers)
    if #numbers ~= NexusLottery.Config.NumbersPerTicket then return false end
    local used = {}
    for _, num in ipairs(numbers) do
        if num < 1 or num > NexusLottery.Config.NumbersRange then return false end
        if used[num] then return false end
        used[num] = true
    end
    return true
end

function NexusLottery.generateQuickPick()
    local numbers = {}
    while #numbers < NexusLottery.Config.NumbersPerTicket do
        local n = math.random(1, NexusLottery.Config.NumbersRange)
        local found = false
        for _, v in ipairs(numbers) do
            if v == n then found = true break end
        end
        if not found then table.insert(numbers, n) end
    end
    table.sort(numbers)
    return numbers
end

function NexusLottery.buyTicket(player, ticketType, betsList)
    -- This is the internal logic, called by NPC or Talkaction
    -- It assumes betsList is a nested table of numbers {{n1..n6}, {n..n}}
    
    local price = NexusLottery.Config.Prices[ticketType]
    local numBets = NexusLottery.Config.BetsPerType[ticketType]
    
    if player:getMoney() < price then return false, "Você não tem gold suficiente." end
    
    local draw = NexusLottery.getCurrentDraw()
    if not draw then return false, "Não há sorteio ativo no momento." end
    
    if draw.scheduled_time - os.time() < NexusLottery.Config.CutoffTime then
        return false, "O sorteio está prestes a começar. Aguarde o próximo ciclo."
    end
    
    local currentCount = NexusLottery.getPlayerTicketCount(player:getId(), draw.id)
    if currentCount + numBets > NexusLottery.Config.MaxTicketsPerPlayer then
        return false, "Você já atingiu o limite de 20 bilhetes para este sorteio."
    end
    
    -- Final Validation
    if #betsList ~= numBets then return false, "Erro na quantidade de apostas." end
    for _, numbers in ipairs(betsList) do
        if not NexusLottery.validateNumbers(numbers) then return false, "Números inválidos detectados." end
    end
    
    -- Transaction
    if not player:removeMoney(price) then return false, "Erro ao processar pagamento." end
    
    -- Economics
    local prizeAdd = math.floor(price * 0.70)
    local sinkAdd = math.floor(price * 0.20)
    local megaAdd = math.floor(price * 0.10)
    
    -- DB Insert
    for _, numbers in ipairs(betsList) do
        table.sort(numbers)
        db.query(string.format([[
            INSERT INTO `lottery_tickets` 
            (`draw_id`, `player_id`, `player_name`, `number_1`, `number_2`, `number_3`, `number_4`, `number_5`, `number_6`, `ticket_type`, `cost`, `purchased_at`)
            VALUES (%d, %d, %s, %d, %d, %d, %d, %d, %d, '%s', %d, %d)
        ]], draw.id, player:getId(), db.escapeString(player:getName()),
        numbers[1], numbers[2], numbers[3], numbers[4], numbers[5], numbers[6],
        ticketType, price, os.time()))
    end
    
    -- Update stats
    db.query(string.format([[
        UPDATE `lottery_draws` SET 
            `total_tickets_sold` = `total_tickets_sold` + %d,
            `total_gold_collected` = `total_gold_collected` + %d,
            `prize_pool` = `prize_pool` + %d,
            `gold_sinked` = `gold_sinked` + %d,
            `mega_pool_contribution` = `mega_pool_contribution` + %d
        WHERE `id` = %d
    ]], numBets, price, prizeAdd, sinkAdd, megaAdd, draw.id))
    
    return true
end

-- -----------------------------------------------------------
-- DRAW EXECUTION
-- -----------------------------------------------------------

function NexusLottery.executeDraw(drawId)
    local drawResult = db.storeQuery("SELECT * FROM `lottery_draws` WHERE `id` = " .. drawId)
    if drawResult == false then return end
    
    local status = result.getDataString(drawResult, "status")
    if status == "completed" then result.free(drawResult) return end
    
    local prizePool = result.getDataInt(drawResult, "prize_pool")
    local jackpotAcc = result.getDataInt(drawResult, "jackpot_accumulated")
    local drawNumber = result.getDataInt(drawResult, "draw_number")
    result.free(drawResult)
    
    -- Mark as completed
    db.query("UPDATE `lottery_draws` SET `status` = 'completed' WHERE `id` = " .. drawId)
    
    -- Winners Generation
    local winning = NexusLottery.generateQuickPick()
    local seed = string.format("%d-%d", os.time(), math.random(1000, 9999))
    
    db.query(string.format([[
        UPDATE `lottery_draws` SET
            `number_1` = %d, `number_2` = %d, `number_3` = %d,
            `number_4` = %d, `number_5` = %d, `number_6` = %d,
            `rng_seed` = %s, `executed_time` = %d
        WHERE `id` = %d
    ]], winning[1], winning[2], winning[3], winning[4], winning[5], winning[6],
    db.escapeString(seed), os.time(), drawId))
    
    -- Process Match Counts
    NexusLottery.processMatches(drawId, winning)
    
    -- Distribute
    NexusLottery.distribute(drawId, prizePool, jackpotAcc)
    
    -- Auto-create next
    NexusLottery.createNextDraw(drawNumber + 1)
    
    Game.broadcastMessage(string.format("[Nexus Lottery] Sorteio #%d realizado! Números: [%s]. Confira no NPC Aurelius!", drawNumber, table.concat(winning, ", ")), MESSAGE_STATUS_WARNING)
end

function NexusLottery.processMatches(drawId, win)
    local query = db.storeQuery("SELECT `id`, `number_1`, `number_2`, `number_3`, `number_4`, `number_5`, `number_6` FROM `lottery_tickets` WHERE `draw_id` = " .. drawId)
    if query == false then return end
    
    local counts = {[6] = 0, [5] = 0, [4] = 0, [3] = 0}
    
    repeat
        local tid = result.getDataInt(query, "id")
        local t = {
            result.getDataInt(query, "number_1"),
            result.getDataInt(query, "number_2"),
            result.getDataInt(query, "number_3"),
            result.getDataInt(query, "number_4"),
            result.getDataInt(query, "number_5"),
            result.getDataInt(query, "number_6")
        }
        
        local matches = 0
        for _, num in ipairs(t) do
            for _, w in ipairs(win) do
                if num == w then matches = matches + 1 break end
            end
        end
        
        db.query("UPDATE `lottery_tickets` SET `matches` = " .. matches .. " WHERE `id` = " .. tid)
        if matches >= 3 then counts[matches] = (counts[matches] or 0) + 1 end
    until not result.next(query)
    result.free(query)
    
    db.query(string.format("UPDATE `lottery_draws` SET `winners_6` = %d, `winners_5` = %d, `winners_4` = %d, `winners_3` = %d WHERE `id` = %d", 
        counts[6], counts[5], counts[4], counts[3], drawId))
end

function NexusLottery.distribute(drawId, prizePool, jackpotAcc)
    local totalPrize = prizePool + jackpotAcc
    local shares = NexusLottery.Config.Distribution
    
    local drawRes = db.storeQuery("SELECT `winners_6`, `winners_5`, `winners_4`, `winners_3` FROM `lottery_draws` WHERE `id` = " .. drawId)
    if drawRes == false then return end
    local winners = {
        [6] = result.getDataInt(drawRes, "winners_6"),
        [5] = result.getDataInt(drawRes, "winners_5"),
        [4] = result.getDataInt(drawRes, "winners_4"),
        [3] = result.getDataInt(drawRes, "winners_3")
    }
    result.free(drawRes)
    
    -- Handle Jackpot Rollover
    local accToCarry = 0
    if winners[6] == 0 then
        accToCarry = math.floor(totalPrize * shares.Jackpot)
    end
    NexusLottery._accToCarry = accToCarry -- temporary storage for next draw
    
    for match = 6, 3, -1 do
        local count = winners[match]
        if count > 0 then
            local share = (match == 6) and shares.Jackpot or (match == 5 and shares.Match5 or (match == 4 and shares.Match4 or shares.Match3))
            local totalForCategory = math.floor(totalPrize * share)
            local each = math.floor(totalForCategory / count)
            
            local ticketsRes = db.storeQuery(string.format("SELECT `id`, `player_id` FROM `lottery_tickets` WHERE `draw_id` = %d AND `matches` = %d", drawId, match))
            if ticketsRes ~= false then
                repeat
                    local tid = result.getDataInt(ticketsRes, "id")
                    local pid = result.getDataInt(ticketsRes, "player_id")
                    
                    db.query(string.format("UPDATE `lottery_tickets` SET `prize_gold` = %d, `prize_claimed` = 1 WHERE `id` = %d", each, tid))
                    
                    local player = Player(pid)
                    if player then
                        player:setBankBalance(player:getBankBalance() + each)
                        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("[Nexus Lottery] Você ganhou %d gold com %d acertos!", each, match))
                    else
                        -- In a real TFS, we'd add to inbox/depot or a custom mailbox table
                        -- For simplicity in Baiak Thunder:
                        db.query(string.format("UPDATE `players` SET `balance` = `balance` + %d WHERE `id` = %d", each, pid))
                    end
                until not result.next(ticketsRes)
                result.free(ticketsRes)
            end
        end
    end
end

function NexusLottery.getNextSaturday20h()
    local now = os.date("*t")
    -- wday: 1=Sun, 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri, 7=Sat
    local daysNeeded = (7 - now.wday) % 7
    
    local drawTime = os.time({
        year = now.year, day = now.day, month = now.month,
        hour = 20, min = 0, sec = 0
    }) + (daysNeeded * 24 * 3600)
    
    if drawTime <= os.time() then
        drawTime = drawTime + (7 * 24 * 3600)
    end
    
    return drawTime
end

function NexusLottery.createNextDraw(nextNum)
    local scheduled = NexusLottery.getNextSaturday20h()
    
    local acc = NexusLottery._accToCarry or 0
    NexusLottery._accToCarry = 0
    
    db.query(string.format([[
        INSERT INTO `lottery_draws` (`draw_number`, `scheduled_time`, `status`, `jackpot_accumulated`, `created_at`)
        VALUES (%d, %d, 'pending', %d, %d)
    ]], nextNum, scheduled, acc, os.time()))
end

-- One-time fix for Draw #1 scheduled incorrectly by previous bug
local currentDrawFix = NexusLottery.getCurrentDraw()
if currentDrawFix and currentDrawFix.draw_number == 1 then
    local correctTime = NexusLottery.getNextSaturday20h()
    if currentDrawFix.scheduled_time ~= correctTime then
        print("[Nexus Lottery] Correcting scheduled time for Draw #1...")
        db.query("UPDATE `lottery_draws` SET `scheduled_time` = " .. correctTime .. " WHERE `id` = " .. currentDrawFix.id)
    end
end
