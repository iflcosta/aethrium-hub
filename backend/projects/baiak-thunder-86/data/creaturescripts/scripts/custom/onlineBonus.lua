local event = {}

local DAILY_CONFIG = {
    BATTLEPASS_XP_STORAGE = 30050,
    BATTLEPASS_XP_AMOUNT = 10,
    DAILY_REWARD_CHARGES_STORAGE = 50802,
    DAILY_REWARD_MAX_CHARGES = 10
}

local function addOnlineToken(playerId)
    local player = Player(playerId)
    if not player then
        return false
    end
    if player:getIp() == 0 then
        event[player:getId()] = nil       
        return false
    end
    
    player:addOnlineTime(1)
    
    -- Injeção 1: Battlepass XP
    local currentBpXp = math.max(0, player:getStorageValue(DAILY_CONFIG.BATTLEPASS_XP_STORAGE))
    player:setStorageValue(DAILY_CONFIG.BATTLEPASS_XP_STORAGE, currentBpXp + DAILY_CONFIG.BATTLEPASS_XP_AMOUNT)
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Você recebeu +" .. DAILY_CONFIG.BATTLEPASS_XP_AMOUNT .. " XP no seu Battlepass por jogar 1 hora!")
    
    -- Injeção 2: Cargas do Daily Reward
    local currentCharges = math.max(0, player:getStorageValue(DAILY_CONFIG.DAILY_REWARD_CHARGES_STORAGE))
    if currentCharges < DAILY_CONFIG.DAILY_REWARD_MAX_CHARGES then
        player:setStorageValue(DAILY_CONFIG.DAILY_REWARD_CHARGES_STORAGE, currentCharges + 1)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Seu baú de Recompensa Diária de amanhã foi turbinado! (+1 Carga)")
    end

    player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
    
    -- Agenda a próxima checagem em 60 minutos
    event[player:getId()] = addEvent(addOnlineToken, 60 * 60 * 1000, player:getId())
end

function onLogin(player)
    player:registerEvent("OnlineBonus")
    player:registerEvent("OnlineBonusLogout")
    if event[player:getId()] == nil then
        event[player:getId()] = addEvent(addOnlineToken, 60 * 60 * 1000, player:getId())    
    end
    return true
end

function onLogout(player)
    if event[player:getId()] then
        event[player:getId()] = nil
    end
    return true
end
