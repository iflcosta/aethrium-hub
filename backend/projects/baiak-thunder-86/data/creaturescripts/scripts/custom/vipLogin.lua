local VIP_CONFIG = {
    tiers = {
        [1] = { name = "VIP Bronze", xpBonus = 10, lootChance = 10, color = "bronze" },
        [2] = { name = "VIP Prata", xpBonus = 15, lootChance = 20, color = "silver" },
        [3] = { name = "VIP Ouro", xpBonus = 30, lootChance = 35, color = "gold" }
    },
    
    STORAGE_VIP_TIER = 50200,
    STORAGE_VIP_END = 50201,
}

local function getVipTier(player) return player:getStorageValue(VIP_CONFIG.STORAGE_VIP_TIER) or 0 end
local function getVipEndTime(player) return player:getStorageValue(VIP_CONFIG.STORAGE_VIP_END) or 0 end

local function hasVip(player)
    local tier = getVipTier(player)
    if tier <= 0 then return false end
    if getVipEndTime(player) <= os.time() then
        player:setStorageValue(VIP_CONFIG.STORAGE_VIP_TIER, 0)
        player:setStorageValue(VIP_CONFIG.STORAGE_VIP_END, 0)
        return false
    end
    return true
end

function onLogin(player)
    player:registerEvent("VipLootBonus")
    player:registerEvent("AutoLootClient")
    if hasVip(player) then
        local tier = getVipTier(player)
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, 
            string.format("[VIP SYSTEM] Bem-vindo! %s ativa. (XP: +%d%%)", VIP_CONFIG.tiers[tier].name, VIP_CONFIG.tiers[tier].xpBonus))
    end
    return true
end
