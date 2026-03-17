local VIP_CONFIG = {
    tiers = {
        [1] = { name = "VIP Bronze", xpBonus = 10, lootChance = 10, color = "bronze" },
        [2] = { name = "VIP Prata", xpBonus = 15, lootChance = 20, color = "silver" },
        [3] = { name = "VIP Ouro", xpBonus = 30, lootChance = 35, color = "gold" }
    },
    
    STORAGE_VIP_TIER = 50200,
    STORAGE_VIP_END = 50201,
    
    vipTemple = {x = 950, y = 950, z = 7},
    
    effects = {
        bronze = CONST_ME_YELLOWENERGY,
        silver = CONST_ME_PURPLEENERGY,
        gold = CONST_ME_HOLYDAMAGE
    }
}

local function getVipTier(player) return player:getStorageValue(VIP_CONFIG.STORAGE_VIP_TIER) or 0 end
local function getVipEndTime(player) return player:getStorageValue(VIP_CONFIG.STORAGE_VIP_END) or 0 end

local function hasVip(player)
    local tier = getVipTier(player)
    if tier <= 0 then return false end
    if getVipEndTime(player) <= os.time() then
        player:setStorageValue(VIP_CONFIG.STORAGE_VIP_TIER, 0)
        player:setStorageValue(VIP_CONFIG.STORAGE_VIP_END, 0)
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "Sua VIP expirou.")
        return false
    end
    return true
end

local function getVipDaysRemaining(player)
    if not hasVip(player) then return 0 end
    return math.max(0, math.ceil((getVipEndTime(player) - os.time()) / 86400))
end

function onSay(player, words, param)
    if words == "!vip" then
        if not hasVip(player) then
            player:sendTextMessage(MESSAGE_STATUS_WARNING, "Voce nao possui VIP ativa.")
            return false
        end
        
        local tier = getVipTier(player)
        if not VIP_CONFIG.tiers[tier] then 
            player:sendTextMessage(MESSAGE_STATUS_SMALL, "Erro de configuração VIP.")
            return false 
        end

        local tierName = VIP_CONFIG.tiers[tier].name
        local days = getVipDaysRemaining(player)
        local xp = VIP_CONFIG.tiers[tier].xpBonus
        local loot = VIP_CONFIG.tiers[tier].lootChance
        
        -- Formatação da Modal Window usando a LIB custom
        local title = "VIP STATUS"
        local message = string.format(
            "Rank: %s\nDias Restantes: %d\n\nBeneficios Ativos:\n- XP Bonus: +%d%%\n- Loot Boost: +%d%%",
            tierName, days, xp, loot
        )
        
        local window = ModalWindow({title = title, message = message})
        window:addButton("Fechar")
        window:setDefaultEnterButton("Fechar")
        window:setDefaultEscapeButton("Fechar")
        
        window:sendToPlayer(player)
        return false
    end
    
    if words == "!vipadmin" or words == "/vipadd" then
        -- (Mantive a lógica do vipadmin inalterada)
        if player:getGroup():getId() < 3 then return true end

        local split = param:split(",")
        if #split < 3 then
            player:sendCancelMessage("Use: !vipadmin Nome, Tier(1-3), Dias")
            return false
        end

        local targetName = split[1]:trim()
        local tier = tonumber(split[2])
        local days = tonumber(split[3])
        local target = Player(targetName)

        if target and tier and days then
            local currentTier = target:getStorageValue(VIP_CONFIG.STORAGE_VIP_TIER) or 0
            local currentEnd = target:getStorageValue(VIP_CONFIG.STORAGE_VIP_END) or 0
            
            if currentTier == tier and currentEnd > os.time() then
                target:setStorageValue(VIP_CONFIG.STORAGE_VIP_END, currentEnd + (days * 86400))
            else
                target:setStorageValue(VIP_CONFIG.STORAGE_VIP_TIER, tier)
                target:setStorageValue(VIP_CONFIG.STORAGE_VIP_END, os.time() + (days * 86400))
            end
            
            target:getPosition():sendMagicEffect(VIP_CONFIG.effects[VIP_CONFIG.tiers[tier].color])
            target:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Recebido: %d dias de %s!", days, VIP_CONFIG.tiers[tier].name))
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "VIP adicionada com sucesso.")
        else
            player:sendCancelMessage("Erro nos parametros ou player offline.")
        end
        return false
    end
    
    return true
end
