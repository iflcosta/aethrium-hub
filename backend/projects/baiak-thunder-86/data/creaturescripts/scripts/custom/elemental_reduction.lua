-- Elemental Reduction System (Dynamic)
-- Reads native absorb from ITEM_ABSORB table (auto-generated from items.xml)
-- Plus sealed element bonuses from storages (55000 + elementIdx)
-- No movements.xml registration needed for absorb to work!

-- Element name to craftingConfig index mapping
local ELEMENT_INDEX = {
    Fire = 2, Ice = 3, Earth = 4, Death = 5, Energy = 6, Holy = 7, Physical = 8
}

-- TFS combat type to element name mapping
local COMBAT_TO_ELEMENT = {
    [COMBAT_FIREDAMAGE] = "Fire",
    [COMBAT_ICEDAMAGE] = "Ice",
    [COMBAT_EARTHDAMAGE] = "Earth",
    [COMBAT_DEATHDAMAGE] = "Death",
    [COMBAT_ENERGYDAMAGE] = "Energy",
    [COMBAT_HOLYDAMAGE] = "Holy",
    [COMBAT_PHYSICALDAMAGE] = "Physical"
}

-- All equippable slots to scan
local EQUIP_SLOTS = {
    CONST_SLOT_HEAD,
    CONST_SLOT_NECKLACE,
    CONST_SLOT_ARMOR,
    CONST_SLOT_LEGS,
    CONST_SLOT_FEET,
    CONST_SLOT_RING,
    CONST_SLOT_LEFT,
    CONST_SLOT_RIGHT,
    CONST_SLOT_AMMO
}

-- Cache: playerGuid -> {checksum, reductions}
local reductionCache = {}

local function getEquipChecksum(player)
    local sum = 0
    for _, slot in ipairs(EQUIP_SLOTS) do
        local item = player:getSlotItem(slot)
        if item then
            sum = sum + item:getId() + slot * 100000
        end
    end
    -- Also include sealed element storages in checksum
    for i = 2, 8 do
        local val = player:getStorageValue(55000 + i)
        if val > 0 then
            sum = sum + val * (i * 1000)
        end
    end
    return sum
end

local function calculateReductions(player)
    local reductions = {}

    -- 1) Native absorb from ALL equipped items via lookup table
    if ITEM_ABSORB then
        for _, slot in ipairs(EQUIP_SLOTS) do
            local item = player:getSlotItem(slot)
            if item then
                local absorb = ITEM_ABSORB[item:getId()]
                if absorb then
                    for elName, value in pairs(absorb) do
                        reductions[elName] = (reductions[elName] or 0) + value
                    end
                end
            end
        end
    end

    -- 2) Sealed element bonuses from storages (set by elemental_set.lua)
    for elName, idx in pairs(ELEMENT_INDEX) do
        local sealBonus = player:getStorageValue(55000 + idx)
        if sealBonus > 0 then
            reductions[elName] = (reductions[elName] or 0) + sealBonus
        end
    end

    return reductions
end

function onHealthChange(player, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
    if not player:isPlayer() then 
        return primaryDamage, primaryType, secondaryDamage, secondaryType 
    end

    -- Get or recalculate cached reductions
    local guid = player:getGuid()
    local checksum = getEquipChecksum(player)
    local cached = reductionCache[guid]

    local reductions
    if cached and cached.checksum == checksum then
        reductions = cached.reductions
    else
        reductions = calculateReductions(player)
        reductionCache[guid] = {checksum = checksum, reductions = reductions}
    end

    -- Apply primary damage reduction
    local primaryEl = COMBAT_TO_ELEMENT[primaryType]
    if primaryEl and reductions[primaryEl] and reductions[primaryEl] ~= 0 then
        primaryDamage = primaryDamage * (1 - (reductions[primaryEl] / 100))
    end

    -- Apply secondary damage reduction
    local secondaryEl = COMBAT_TO_ELEMENT[secondaryType]
    if secondaryEl and reductions[secondaryEl] and reductions[secondaryEl] ~= 0 then
        secondaryDamage = secondaryDamage * (1 - (reductions[secondaryEl] / 100))
    end

    return primaryDamage, primaryType, secondaryDamage, secondaryType
end
