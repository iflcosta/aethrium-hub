--[[
    SKILL TRAINING BOOST SYSTEM - Styller Nexus (Fix Compat)
    Opção D: Tier System (Premium)
]]

local config = {
    -- Storages
    STORAGE_BOOST_TIER = 50900,        -- Tier atual (1/2/3)
    STORAGE_BOOST_END_TIME = 50901,    -- Timestamp quando expira
    
    -- Tiers
    tiers = {
        [1] = {
            name = "Basic Training",
            multiplier = 1.5,
            duration = 7 * 86400,
            effect = CONST_ME_MAGIC_GREEN
        },
        [2] = {
            name = "Advanced Training",
            multiplier = 2.0,
            duration = 7 * 86400,
            effect = CONST_ME_MAGIC_BLUE
        },
        [3] = {
            name = "Premium Training",
            multiplier = 3.0,
            duration = 7 * 86400,
            effect = CONST_ME_FIREWORK_YELLOW
        },
    },
    
    maxAccumulatedTime = 90 * 86400
}

-- ============================================================
-- FUNÇÕES GLOBAIS
-- ============================================================

function getTrainingBoostTier(player)
    local tier = player:getStorageValue(config.STORAGE_BOOST_TIER)
    if tier <= 0 then return nil end
    return tier
end

function getTrainingBoostMultiplier(player)
    local tier = getTrainingBoostTier(player)
    if not tier then return 1.0 end
    
    local endTime = player:getStorageValue(config.STORAGE_BOOST_END_TIME)
    if endTime <= os.time() then
        player:setStorageValue(config.STORAGE_BOOST_TIER, 0)
        return 1.0
    end
    
    local tierData = config.tiers[tier]
    return tierData and tierData.multiplier or 1.0
end

local function activateBoost(player, tier)
    local tierData = config.tiers[tier]
    if not tierData then return false end
    
    local currentEnd = player:getStorageValue(config.STORAGE_BOOST_END_TIME)
    local newEnd
    
    if currentEnd > os.time() then
        local timeToAdd = tierData.duration
        if (currentEnd - os.time()) + timeToAdd > config.maxAccumulatedTime then
            player:sendCancelMessage("Cannot accumulate more than 90 days!")
            return false
        end
        newEnd = currentEnd + timeToAdd
    else
        newEnd = os.time() + tierData.duration
    end
    
    player:setStorageValue(config.STORAGE_BOOST_TIER, tier)
    player:setStorageValue(config.STORAGE_BOOST_END_TIME, newEnd)
    
    player:getPosition():sendMagicEffect(tierData.effect)
    player:say(tierData.name .. " activated!", TALKTYPE_MONSTER_SAY)
    return true
end

-- ============================================================
-- MONK TRAINING BOOST (Usando onHealthChange para compatibilidade)
-- ============================================================

local monkBoost = CreatureEvent("TrainingBoostOnline")
monkBoost:type("healthchange") -- Força o registro do tipo correto

function monkBoost.onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
    if not attacker or not attacker:isPlayer() then
        return primaryDamage, primaryType, secondaryDamage, secondaryType
    end
    
    -- Verifica se é o Monk de treino
    if not creature:isMonster() or creature:getName():lower() ~= "training monk" then
        return primaryDamage, primaryType, secondaryDamage, secondaryType
    end
    
    -- Efeito visual ao bater (indica que está funcionando)
    -- O ganho real de skill está no events/player.lua
    if math.random(100) <= 5 then 
        local multiplier = getTrainingBoostMultiplier(attacker)
        if multiplier > 1.0 then
            attacker:getPosition():sendMagicEffect(CONST_ME_HITBYPOISON)
        end
    end
    
    return primaryDamage, primaryType, secondaryDamage, secondaryType
end

monkBoost:register()

-- ============================================================
-- LOGIN EVENT
-- ============================================================

local boostLogin = CreatureEvent("TrainingBoostLogin")
boostLogin:type("login")

function boostLogin.onLogin(player)
    player:registerEvent("TrainingBoostOnline") -- Registra o evento de dano
    
    local multiplier = getTrainingBoostMultiplier(player)
    if multiplier > 1.0 then
        local timeLeft = player:getStorageValue(config.STORAGE_BOOST_END_TIME) - os.time()
        local days = math.floor(timeLeft / 86400)
        local hours = math.floor((timeLeft % 86400) / 3600)
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, 
    	  string.format("Training Boost Active: %0.1fx skill rate (%dd %dh left).", multiplier, days, hours))
    end
    return true
end

boostLogin:register()

-- ============================================================
-- TALKACTIONS & ACTIONS
-- ============================================================

local boostCommand = TalkAction("!trainingboost", "!tb")
function boostCommand.onSay(player, words, param)
    local multiplier = getTrainingBoostMultiplier(player)
    
    if multiplier <= 1.0 then
        player:showTextDialog(1948, "TRAINING BOOST\n\nStatus: Inactive\n\nPurchase Items in Store:\nBasic: 1.5x\nAdvanced: 2.0x\nPremium: 3.0x")
    else
        local timeLeft = player:getStorageValue(config.STORAGE_BOOST_END_TIME) - os.time()
        local days = math.floor(timeLeft / 86400)
        local hours = math.floor((timeLeft % 86400) / 3600)
        
        -- ALTERAÇÃO AQUI: Mudamos %dx para %0.1fx para mostrar decimais (ex: 1.5x)
        player:showTextDialog(1948, string.format("TRAINING BOOST\n\nStatus: ACTIVE\nMultiplier: %0.1fx\nTime Left: %d days, %d hours.", multiplier, days, hours))
    end
    return false
end
boostCommand:separator(" ")
boostCommand:register()

-- Items de Ativação
local actions = {
    [7371] = 1, -- ID do item Basic
    [7370] = 2, -- ID do item Advanced
    [7369] = 3  -- ID do item Premium
}

for id, tier in pairs(actions) do
    local action = Action()
    function action.onUse(player, item, fromPosition, target, toPosition, isHotkey)
        if activateBoost(player, tier) then
            item:remove(1)
        end
        return true
    end
    action:id(id)
    action:register()
end