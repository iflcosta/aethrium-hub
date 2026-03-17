-- ============================================
-- NEXUS GRAND LOTTERY - TALKACTION
-- TFS 1.3 / 1.5 (RevScript)
-- ============================================

local lotteryTalk = TalkAction("!lottery")

local function getTimeRemaining(seconds)
    local days = math.floor(seconds / (24 * 3600))
    local hours = math.floor((seconds % (24 * 3600)) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    
    local text = ""
    if days > 0 then text = text .. days .. "d " end
    if hours > 0 or days > 0 then text = text .. hours .. "h " end
    text = text .. minutes .. "m"
    return text
end

function lotteryTalk.onSay(player, words, param)
    local draw = NexusLottery.getCurrentDraw()
    if not draw then 
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[Nexus Lottery] Nao ha sorteio ativo.")
        return false 
    end

    local totalPool = draw.prize_pool + draw.jackpot_accumulated
    local tickets = NexusLottery.getPlayerTickets(player:getId(), draw.id)
    
    local timeLeft = draw.scheduled_time - os.time()
    local dateStr = os.date("%A, %d/%m/%Y as %H:%M", draw.scheduled_time)
    
    -- Tradução básica de dia da semana para PT-BR
    local daysMap = {
        ["Monday"] = "Segunda", ["Tuesday"] = "Terca", ["Wednesday"] = "Quarta",
        ["Thursday"] = "Quinta", ["Friday"] = "Sexta", ["Saturday"] = "Sabado", ["Sunday"] = "Domingo"
    }
    for en, pt in pairs(daysMap) do
        dateStr = dateStr:gsub(en, pt)
    end
    
    local title = "NEXUS GRAND LOTTERY"
    local message = string.format("Sorteio Atual: #%d\nProximo Sorteio: %s\nFaltam: %s\n\nJackpot Acumulado: %s gold\nPremio Estimado: %s gold\n\n", 
        draw.draw_number, dateStr, getTimeRemaining(timeLeft),
        NexusLottery.formatNumber(draw.jackpot_accumulated), NexusLottery.formatNumber(totalPool))
    
    if #tickets > 0 then
        message = message .. "SEUS BILHETES ATIVOS (" .. #tickets .. "/20):\n"
        for i, t in ipairs(tickets) do
            message = message .. string.format("- [%02d %02d %02d %02d %02d %02d]\n", t[1], t[2], t[3], t[4], t[5], t[6])
        end
    else
        message = message .. "Voce nao possui bilhetes ativos.\nCompre no NPC Aurelius no Templo!"
    end

    local window = ModalWindow({
        title = title,
        message = message
    })

    window:addButton("Fechar", function(button, choice) end)
    
    window:setDefaultEnterButton("Fechar")
    window:setDefaultEscapeButton("Fechar")
    window:sendToPlayer(player)
    
    return false
end

lotteryTalk:separator(" ")
lotteryTalk:register()
