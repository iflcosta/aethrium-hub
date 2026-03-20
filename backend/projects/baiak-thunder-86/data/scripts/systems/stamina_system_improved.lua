--[[
═══════════════════════════════════════════════════════════════
    STAMINA REFILL SYSTEM - VERSÃO MELHORADA
    Styller Nexus - Baiak Thunder 8.6
    
    Baseado no seu script original, com 3 tiers de produtos.
═══════════════════════════════════════════════════════════════
]]

-- ============================================================
-- CONFIGURAÇÕES
-- ============================================================

local config = {
    stamina_full = 42,  -- 42 horas máximo
    
    -- Item IDs (AJUSTAR PARA IDs LIVRES NO SEU SERVIDOR)
    items = {
        potion_3h = 39381,      -- Stamina Potion (3h) - R$ 10
        full_42h = 39380,       -- Full Stamina (42h) - R$ 25
        infinite_7d = 39391     -- Infinite 7 days - R$ 50
    },
    
    -- Valores em horas
    values = {
        potion = 3,      -- 3 horas
        full = 42,       -- 42 horas (máximo)
        infinite = 7     -- 7 dias de infinite
    },
    
    -- Storage para infinite stamina
    STORAGE_INFINITE = 50300
}

-- ============================================================
-- 1. STAMINA POTION (3 HORAS) - R$ 10
-- ============================================================

local staminaPotion = Action()

function staminaPotion.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local current = player:getStamina()
    local max = config.stamina_full * 60
    
    -- Verificar se já está cheio
    if current >= max then
        player:sendCancelMessage("Your stamina is already full.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end
    
    -- Adicionar 3 horas (180 minutos)
    local newStamina = math.min(current + (config.values.potion * 60), max)
    player:setStamina(newStamina)
    
    -- Mensagem
    local hours = math.floor(newStamina / 60)
    local minutes = newStamina % 60
    player:sendCancelMessage(string.format("You recharged 3 hours! Total: %dh %dm", hours, minutes))
    player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
    
    item:remove(1)
    return true
end

staminaPotion:id(config.items.potion_3h)
staminaPotion:register()

-- ============================================================
-- 2. FULL STAMINA (42 HORAS) - R$ 25
-- ============================================================

local fullStamina = Action()

function fullStamina.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if player:getStamina() >= (config.stamina_full * 60) then
        player:sendCancelMessage("Your stamina is already full.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
    else
        player:setStamina(config.stamina_full * 60)
        player:sendCancelMessage("Your stamina has been fully replenished (42h)!")
        player:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)
        player:say("FULL STAMINA!", TALKTYPE_MONSTER_SAY)
    end
    
    item:remove(1)
    return true
end

fullStamina:id(config.items.full_42h)
fullStamina:register()

-- ============================================================
-- 3. INFINITE STAMINA (7 DIAS) - R$ 50
-- ============================================================

local infiniteStamina = Action()

function infiniteStamina.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    local currentEnd = player:getStorageValue(config.STORAGE_INFINITE)
    local now = os.time()
    local days = config.values.infinite
    
    -- Se já tem infinite ativo, adicionar tempo
    if currentEnd > now then
        player:setStorageValue(config.STORAGE_INFINITE, currentEnd + (days * 86400))
        local totalDays = math.ceil((player:getStorageValue(config.STORAGE_INFINITE) - now) / 86400)
        player:sendCancelMessage(string.format("Infinite Stamina extended! Total: %d days", totalDays))
    else
        -- Ativar novo infinite
        player:setStorageValue(config.STORAGE_INFINITE, now + (days * 86400))
        player:sendCancelMessage(string.format("Infinite Stamina activated for %d days!", days))
    end
    
    -- Efeito visual especial
    player:getPosition():sendMagicEffect(CONST_ME_HOLYDAMAGE)
    player:say("INFINITE STAMINA!", TALKTYPE_MONSTER_SAY)
    
    item:remove(1)
    return true
end

infiniteStamina:id(config.items.infinite_7d)
infiniteStamina:register()

-- ============================================================
-- SISTEMA DE AUTO-REGENERAÇÃO (INFINITE STAMINA)
-- ============================================================

local infiniteStaminaRegen = GlobalEvent("InfiniteStaminaRegen")

function infiniteStaminaRegen.onThink(interval)
    -- Executar a cada 1 minuto
    for _, player in ipairs(Game.getPlayers()) do
        local endTime = player:getStorageValue(config.STORAGE_INFINITE)
        
        if endTime > os.time() then
            -- Tem infinite ativo, manter stamina sempre cheia
            local current = player:getStamina()
            local max = config.stamina_full * 60
            
            if current < max then
                player:setStamina(max)
            end
        end
    end
    
    return true
end

infiniteStaminaRegen:interval(60000) -- 1 minuto
infiniteStaminaRegen:register()

-- ============================================================
-- COMANDO: !stamina (ver status)
-- ============================================================

local staminaCommand = TalkAction("!stamina")

function staminaCommand.onSay(player, words, param)
    local current = player:getStamina()
    local hours = math.floor(current / 60)
    local minutes = current % 60
    local max = config.stamina_full * 60
    
    local message = string.format(" -------- STAMINA STATUS -------- ", 
        hours, minutes, config.stamina_full)
    
    -- Verificar infinite
    local endTime = player:getStorageValue(config.STORAGE_INFINITE)
    if endTime > os.time() then
        local daysLeft = math.ceil((endTime - os.time()) / 86400)
        message = message .. string.format("Infinite Stamina: %d days remaining\n", daysLeft)
    else
        message = message .. "Infinite Stamina: Not active\n"
    end
    
    message = message .. "-------------------------------------"
    
    player:showTextDialog(1948, message)
    return false
end

staminaCommand:separator(" ")
staminaCommand:register()

-- ============================================================
-- LOGIN EVENT (Avisar infinite stamina)
-- ============================================================

local staminaLogin = CreatureEvent("StaminaSystemLogin")

function staminaLogin.onLogin(player)
    local endTime = player:getStorageValue(config.STORAGE_INFINITE)
    
    if endTime > os.time() then
        local daysLeft = math.ceil((endTime - os.time()) / 86400)
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE,
            string.format("Your Infinite Stamina is active for %d more days!", daysLeft))
    end
    
    return true
end

staminaLogin:register()

print(">> [Stamina Refill System] Loaded successfully!")
print(">> Products: Potion (3h), Full (42h), Infinite (7d)")
print(">> Command: !stamina")
