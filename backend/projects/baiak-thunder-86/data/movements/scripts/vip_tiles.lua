--[[
═══════════════════════════════════════════════════════════════
    VIP TILES - MOVEMENT SYSTEM
    Styller Nexus - Baiak Thunder 8.6
    
    Tiles que só VIPs podem passar.
    Configurar Action IDs no RME para cada tier.
══════════════════════════════════════════════════════════════
]]

-- ============================================================
-- CONFIGURAÇÃO DE ACTION IDs
-- ============================================================

local vipTiles = {
    -- Action IDs que você vai colocar nos tiles no RME
    [50001] = {tier = 1, name = "VIP Bronze"},  -- Bronze ou superior
    [50002] = {tier = 2, name = "VIP Silver"},  -- Silver ou superior
    [50003] = {tier = 3, name = "VIP Gold"},    -- Gold apenas
}

-- ============================================================
-- FUNÇÃO AUXILIAR (Mesma do vip_system.lua)
-- ============================================================

local STORAGE_VIP_TIER = 50200
local STORAGE_VIP_END = 50201

local function getVipTier(player)
    return player:getStorageValue(STORAGE_VIP_TIER) or 0
end

local function getVipEndTime(player)
    return player:getStorageValue(STORAGE_VIP_END) or 0
end

local function hasVip(player)
    local tier = getVipTier(player)
    if tier <= 0 then
        return false
    end
    
    local endTime = getVipEndTime(player)
    if endTime <= os.time() then
        return false
    end
    
    return true
end

-- ============================================================
-- MOVEMENT - TILES RESTRITOS
-- ============================================================

function onStepIn(creature, item, position, fromPosition)
    local player = creature:getPlayer()
    if not player then
        return true
    end
    
    local actionId = item:getActionId()
    local tileConfig = vipTiles[actionId]
    
    if not tileConfig then
        return true
    end
    
    -- Verificar se tem VIP
    if not hasVip(player) then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, 
            string.format("You need %s or higher to access this area!", tileConfig.name))
        player:teleportTo(fromPosition, true)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end
    
    -- Verificar tier
    local playerTier = getVipTier(player)
    if playerTier < tileConfig.tier then
        player:sendTextMessage(MESSAGE_STATUS_SMALL,
            string.format("You need %s or higher to access this area!", tileConfig.name))
        player:teleportTo(fromPosition, true)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end
    
    -- Passou! Efeito visual de sucesso
    position:sendMagicEffect(CONST_ME_TELEPORT)
    return true
end
