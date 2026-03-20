--[[
    ENHANCED DAILY REWARD SYSTEM - Baiak Thunder
    - ModalWindow UI
    - Dynamic XP (Base * Stage Multiplier)
    - 7-Day Streak
    - [WIP] Must consume online charges from storage 50802 to multiply output and then reset it to 0.
]]

local DAILY_CONFIG = {
    STORAGE_STREAK = 50800,
    STORAGE_LAST_CLAIM = 50801,
    STORAGE_ONLINE_CHARGES = 50802,
    
    MIN_LEVEL = 150, -- Level para coletar
    BASE_XP = 100000, -- XP Base (será multiplicada pelo stage)
    
    ACTION_ID = 50700,
    
    rewards = {
        [1] = {gold = 50000, items = {{2152, 5}}}, -- 5 Platinum Coins
        [2] = {gold = 100000, items = {{7618, 50}}}, -- 50 Health Potions
        [3] = {gold = 150000, items = {{7620, 50}}}, -- 50 Mana Potions
        [4] = {gold = 200000, items = {{2268, 50}}}, -- 50 SDs
        [5] = {gold = 250000, items = {{2273, 50}}}, -- 50 UHs
        [6] = {gold = 300000, items = {{2152, 30}}}, -- 30 Platinum Coins
        [7] = {gold = 1000000, items = {{2160, 10}, {9734, 1}}}, -- 10 CC + XP Potion (persistent!)
    }
}

local function getStreak(player) return math.max(1, player:getStorageValue(DAILY_CONFIG.STORAGE_STREAK)) end
local function setStreak(player, streak) player:setStorageValue(DAILY_CONFIG.STORAGE_STREAK, streak) end

local function canClaim(player)
    if player:getLevel() < DAILY_CONFIG.MIN_LEVEL then
        return false, "Você precisa de nível " .. DAILY_CONFIG.MIN_LEVEL .. " para coletar."
    end
    
    local today = tonumber(os.date("%Y%m%d"))
    if player:getStorageValue(DAILY_CONFIG.STORAGE_LAST_CLAIM) == today then
        return false, "Você já coletou sua recompensa hoje! Volte amanhã."
    end
    
    return true
end

local function applyStreak(player)
    local lastClaim = player:getStorageValue(DAILY_CONFIG.STORAGE_LAST_CLAIM)
    local yesterday = tonumber(os.date("%Y%m%d", os.time() - 86400))
    local today = tonumber(os.date("%Y%m%d"))
    
    local currentStreak = getStreak(player)
    
    if lastClaim == yesterday then
        -- Continuou streak
        currentStreak = (currentStreak >= 7) and 1 or (currentStreak + 1)
    elseif lastClaim ~= today then
        -- Quebrou streak ou faz tempo que não logo
        currentStreak = 1
    end
    
    setStreak(player, currentStreak)
    player:setStorageValue(DAILY_CONFIG.STORAGE_LAST_CLAIM, today)
    return currentStreak
end

local function getDynamicXP(player, multiplier)
    local stage = Game.getExperienceStage(player:getLevel())
    return math.floor(DAILY_CONFIG.BASE_XP * multiplier * stage)
end

local function claimReward(player)
    local can, err = canClaim(player)
    if not can then
        player:sendCancelMessage(err)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return
    end
    
    local streak = applyStreak(player)
    local reward = DAILY_CONFIG.rewards[streak]
    
    -- Leitura e Cálculo do Bônus (Storage 50802)
    local charges = math.max(0, player:getStorageValue(DAILY_CONFIG.STORAGE_ONLINE_CHARGES))
    charges = math.min(charges, 10)
    local bonusMultiplier = charges * 0.10
    
    -- XP (Dynamic)
    local xpMultiplier = (streak == 7) and 5 or 1
    local xp = getDynamicXP(player, xpMultiplier)
    player:addExperience(xp, true)
    
    -- Gold com Multiplicador
    local finalGold = math.floor(reward.gold + (reward.gold * bonusMultiplier))
    player:addMoney(finalGold)
    
    -- Items com Multiplicador
    for _, item in ipairs(reward.items) do
        local finalAmount = math.floor(item[2] + (item[2] * bonusMultiplier))
        player:addItem(item[1], finalAmount)
    end
    
    -- Entrega e Reset
    player:setStorageValue(DAILY_CONFIG.STORAGE_ONLINE_CHARGES, 0)
    
    local bonusMsg = charges > 0 and string.format(" Bônus de Tempo Online aplicado: +%d%%!", charges * 10) or ""
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("[Daily Reward] Dia %d coletado! Ganhos: %d XP, %d gold e itens.%s", streak, xp, finalGold, bonusMsg))
    player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_YELLOW)
end

-- ModalWindow Logic
local dailyRewardModal = ModalWindow({
    title = "Sistema de Recompensa Diária",
    message = "Pegue seu prêmio diário para manter seu streak e ganhar bônus!"
})

dailyRewardModal:addButton("Coletar", function(player, button, choice)
    claimReward(player)
end)

dailyRewardModal:addButton("Sair")
dailyRewardModal:setDefaultEnterButton("Coletar")
dailyRewardModal:setDefaultEscapeButton("Sair")

local function showDailyModal(player)
    local streak = getStreak(player)
    local today = tonumber(os.date("%Y%m%d"))
    local claimed = player:getStorageValue(DAILY_CONFIG.STORAGE_LAST_CLAIM) == today
    
    local currentCharges = math.max(0, player:getStorageValue(DAILY_CONFIG.STORAGE_ONLINE_CHARGES))
    currentCharges = math.min(currentCharges, 10)
    local bonusPct = currentCharges * 10
    
    local status = claimed and "COLETADO" or "DISPONÍVEL"
    local msg = string.format("Seu Streak Atual: %d dias\nStatus de Hoje: %s\nBônus Acumulado (Tempo Online): +%d%%\n\nRecompensa do próximo claim:\n- XP Escalável ao seu nível\n- Gold e Utilitários", streak, status, bonusPct)
    
    dailyRewardModal:setMessage(msg)
    dailyRewardModal:sendToPlayer(player)
end

-- Action Registration
local dailyAction = Action()
function dailyAction.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    showDailyModal(player)
    return true
end

dailyAction:aid(DAILY_CONFIG.ACTION_ID)
dailyAction:register()

-- Startup notification
print(">> Enhanced Daily Reward System loaded (Dynamic XP enabled)")