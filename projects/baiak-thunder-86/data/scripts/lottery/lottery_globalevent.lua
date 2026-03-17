-- ============================================
-- NEXUS GRAND LOTTERY - AUTOMATION
-- Saturday 20h Draw & Reminders
-- ============================================

local lotteryAuto = GlobalEvent("NexusLotteryAuto")

function lotteryAuto.onTime(interval)
    local draw = NexusLottery.getCurrentDraw()
    if draw then
        NexusLottery.executeDraw(draw.id)
    end
    return true
end

lotteryAuto:time("20:00:00")
-- Note: Days are handled by checking which day it is if the server runs this every day, 
-- but in TFS 1.3/1.5 XML-style format we'd specify Saturday. 
-- In the new script system, we check the day in the function.

local function isSaturday()
    return os.date("*t").wday == 7
end

-- Wrapper to only run on Saturdays
local originalOnTime = lotteryAuto.onTime
function lotteryAuto.onTime(interval)
    if isSaturday() then
        return originalOnTime(interval)
    end
    return true
end

lotteryAuto:register()

-- -----------------------------------------------------------
-- REMINDER (19:50h)
-- -----------------------------------------------------------

local lotteryReminder = GlobalEvent("NexusLotteryReminder")
function lotteryReminder.onTime(interval)
    if isSaturday() then
        local draw = NexusLottery.getCurrentDraw()
        if draw then
            local total = draw.prize_pool + draw.jackpot_accumulated
            Game.broadcastMessage("[Nexus Lottery] Sorteio em 10 minutos! Jackpot: " .. total .. " gold. Última chance de comprar seu bilhete no NPC Aurelius!", MESSAGE_STATUS_WARNING)
        end
    end
    return true
end
lotteryReminder:time("19:50:00")
lotteryReminder:register()

-- -----------------------------------------------------------
-- STARTUP FAILSAFE
-- -----------------------------------------------------------

local lotteryStartup = GlobalEvent("NexusLotteryStartup")
function lotteryStartup.onStartup()
    local draw = NexusLottery.getCurrentDraw()
    if not draw then
        print("[Nexus Lottery] No pending draw found. Creating initial draw #1...")
        local scheduled = NexusLottery.getNextSaturday20h()
        db.query(string.format("INSERT INTO `lottery_draws` (`draw_number`, `scheduled_time`, `status`, `jackpot_accumulated`, `created_at`) VALUES (1, %d, 'pending', 0, %d)", scheduled, os.time()))
    else
        print("[Nexus Lottery] Active draw found: #" .. draw.draw_number)
        if draw.scheduled_time < os.time() then
            print("[Nexus Lottery] Draw #" .. draw.draw_number .. " is overdue. Executing now.")
            NexusLottery.executeDraw(draw.id)
        end
    end
    return true
end
lotteryStartup:register()
