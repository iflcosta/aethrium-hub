--[[
═══════════════════════════════════════════════════════════════
    VIP SYSTEM - CLEAN VERSION
    Styller Nexus - Baiak Thunder 8.6
    
    Comandos:
    !vip        -> Abre janela com status, dias e benefícios
    !gohome     -> Teleporta para templo VIP (Sem PK/Battle)
    !vipadmin   -> Adicionar VIP (Gods apenas)
═══════════════════════════════════════════════════════════════
]]

VIP_CONFIG = {
    tiers = {
        [1] = { name = "VIP Bronze", xpBonus = 10, lootChance = 10, color = "bronze" },
        [2] = { name = "VIP Prata", xpBonus = 15, lootChance = 20, color = "silver" },
        [3] = { name = "VIP Ouro", xpBonus = 30, lootChance = 35, color = "gold" }
    },
    
    STORAGE_VIP_TIER = 50200,
    STORAGE_VIP_END = 50201,
    EXTRA_LOOT_ITEM = 2160, -- Crystal Coin
    
    vipTemple = {x = 950, y = 950, z = 7},
    
    effects = {
        bronze = CONST_ME_YELLOWENERGY,
        silver = CONST_ME_PURPLEENERGY,
        gold = CONST_ME_HOLYDAMAGE
    }
}

-- ============================================================
-- FUNÇÕES GLOBAIS
-- ============================================================
function getVipTier(player) return player:getStorageValue(VIP_CONFIG.STORAGE_VIP_TIER) or 0 end
function setVipTier(player, tier) player:setStorageValue(VIP_CONFIG.STORAGE_VIP_TIER, tier) end
function getVipEndTime(player) return player:getStorageValue(VIP_CONFIG.STORAGE_VIP_END) or 0 end
function setVipEndTime(player, timestamp) player:setStorageValue(VIP_CONFIG.STORAGE_VIP_END, timestamp) end

function hasVip(player)
    local tier = getVipTier(player)
    if tier <= 0 then return false end
    if getVipEndTime(player) <= os.time() then
        setVipTier(player, 0)
        setVipEndTime(player, 0)
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "Sua VIP expirou.")
        return false
    end
    return true
end

function getVipDaysRemaining(player)
    if not hasVip(player) then return 0 end
    return math.max(0, math.ceil((getVipEndTime(player) - os.time()) / 86400))
end

function addVip(player, tier, days)
    local currentTier = getVipTier(player)
    local currentEnd = getVipEndTime(player)
    if currentTier == tier and currentEnd > os.time() then
        setVipEndTime(player, currentEnd + (days * 86400))
    else
        setVipTier(player, tier)
        setVipEndTime(player, os.time() + (days * 86400))
    end
    player:getPosition():sendMagicEffect(VIP_CONFIG.effects[VIP_CONFIG.tiers[tier].color])
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Recebido: %d dias de %s!", days, VIP_CONFIG.tiers[tier].name))
end

-- print only once using a global flag
if not VIP_SYSTEM_LOADED then
    VIP_SYSTEM_LOADED = true
    print(">>> [VIP System] Carregado com sucesso!")
    print(">>> Tier Bronze: 10% XP / 10% Loot")
    print(">>> Tier Silver: 15% XP / 20% Loot")
    print(">>> Tier Gold: 30% XP / 35% Loot")
end