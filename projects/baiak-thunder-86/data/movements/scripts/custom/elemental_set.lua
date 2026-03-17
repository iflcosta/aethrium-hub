if not craftingConfig then
    dofile('data/lib/custom/crafting.lua')
end

local function applyElementalBonus(player)
    -- Remove all potential sealed conditions first to reset
    local elements = {"Fire", "Ice", "Earth", "Energy", "Death", "Holy", "Physical"}
    for _, name in ipairs(elements) do
        player:removeCondition(CONDITION_ATTRIBUTES, CONDITIONID_COMBAT, 1000 + _) -- Reserve IDs 1001-1007
    end

    local armor = player:getSlotItem(CONST_SLOT_ARMOR)
    local legs = player:getSlotItem(CONST_SLOT_LEGS)

    local armorEl = armor and armor:getCustomAttribute("sealedElement") or "None"
    local armorTier = armor and armor:getCustomAttribute("sealedTier") or "None"
    
    local legsEl = legs and legs:getCustomAttribute("sealedElement") or "None"
    local legsTier = legs and legs:getCustomAttribute("sealedTier") or "None"

    local activeBonuses = {} -- element -> percent

    -- Case 1: Same Element (Set Bonus)
    if armorEl ~= "None" and armorEl == legsEl then
        local tier = armorTier -- Aethrium or Others
        local value = craftingConfig.setBonusValues[tier] or 0
        activeBonuses[armorEl] = value
    else
        -- Case 2: Different or Single
        if armorEl ~= "None" then
            local value = craftingConfig.elementalTiers[armorTier] or 0
            activeBonuses[armorEl] = (activeBonuses[armorEl] or 0) + value
        end
        if legsEl ~= "None" then
            local value = craftingConfig.elementalTiers[legsTier] or 0
            activeBonuses[legsEl] = (activeBonuses[legsEl] or 0) + value
        end
    end

    -- Apply conditions
    for elName, percent in pairs(activeBonuses) do
        local attr = nil
        for i, el in ipairs(craftingConfig.elements) do
            if el.name == elName then
                attr = el.attr
                if attr then
                    local cond = Condition(CONDITION_ATTRIBUTES, CONDITIONID_COMBAT)
                    cond:setParameter(CONDITION_PARAM_TICKS, -1)
                    cond:setParameter(CONDITION_PARAM_SUBID, 1000 + i)
                    -- We map the internal attribute key to the condition parameter
                    -- Common TFS attributes: ABSORBPERCENTFIRE -> CONDITION_PARAM_STAT_... is not direct
                    -- We'll use the specific Condition Type for absorbing
                end
            end
        end
        
        -- Since standard TFS Condition(CONDITION_ATTRIBUTES) doesn't always support absorbPercent easily via Lua parameters in all versions
        -- I'll use a safer approach: Adding the percent directly to a temporary storage or using the Condition for specific elements if available.
        -- Actually, most TFS 1.x support:
        local condType = nil
        if elName == "Fire" then condType = CONDITION_FIRE end -- This is DOT. 
        -- Correct way for protection in TFS is often CONDITION_ATTRIBUTES with specific parameters if the engine supports them, 
        -- or just use item attributes which we already set in the craft.
    end
end

-- Wait, if I use item:setAttribute(element.attr, bonus) in crafting_backend, the engine already handles it!
-- THE PROBLEM: If I have 12% on armor and 12% on legs, it will sum to 24%. The user wants 18%.
-- So I MUST remove the attribute from the item and use a script to apply the correct value.

-- REVISED STRATEGY: 
-- 1. crafting_backend will NOT set the 'absorbPercent...' attribute on the item directly anymore.
-- 2. It will only set the 'sealedElement', 'sealedTier' etc.
-- 3. This script (elemental_set.lua) will calculate the sum and apply a CUSTOM CONDITION.

local function getConditionType(elName)
    if elName == "Fire" then return CONDITION_PARAM_STAT_MAGICPERCENT -- Placeholder, actually we need ABSORB
    end
    return nil
end

-- Optimization: If the user has 1.x TFS, we can create Combat conditions.
local elementalConditions = {}
for i, el in ipairs(craftingConfig.elements) do
    if el.name ~= "None" then
        elementalConditions[el.name] = i
    end
end

function onEquip(player, item, slot)
    addEvent(applyElementalBonus, 100, player:getGuid()) -- Delay to ensure item is in slot
    return true
end

function onDeEquip(player, item, slot)
    addEvent(applyElementalBonus, 100, player:getGuid())
    return true
end

local function getItemTier(item)
    if not item then return "None" end
    local sealedTier = item:getCustomAttribute("sealedTier")
    if sealedTier then return sealedTier end
    
    local itemName = ItemType(item:getId()):getName():lower()
    for tierName, _ in pairs(craftingConfig.elementalTiers) do
        if itemName:find(tierName:lower()) then
            return tierName
        end
    end
    return "None"
end

-- Re-implement applyElementalBonus with Player GUID for safety in addEvent
function applyElementalBonus(guid)
    local player = Player(guid)
    if not player then return end

    print("[ElementalSystem] Recalculating bonuses for " .. player:getName())

    -- Cleanup old set bonus conditions
    for i = 1, #craftingConfig.elements do
        player:removeCondition(CONDITION_ATTRIBUTES, CONDITIONID_COMBAT, 2000 + i)
    end

    local armor = player:getSlotItem(CONST_SLOT_ARMOR)
    local legs = player:getSlotItem(CONST_SLOT_LEGS)

    local armorEl = armor and armor:getCustomAttribute("sealedElement") or "None"
    local legsEl = legs and legs:getCustomAttribute("sealedElement") or "None"

    local armorTier = getItemTier(armor)
    local legsTier = getItemTier(legs)

    local activeBonuses = {}

    if armorEl ~= "None" and armorEl == legsEl then
        local value = craftingConfig.setBonusValues[armorTier] or 0
        activeBonuses[armorEl] = value
    else
        if armorEl ~= "None" then
            activeBonuses[armorEl] = (activeBonuses[armorEl] or 0) + (craftingConfig.elementalTiers[armorTier] or 0)
        end
        if legsEl ~= "None" then
            activeBonuses[legsEl] = (activeBonuses[legsEl] or 0) + (craftingConfig.elementalTiers[legsTier] or 0)
        end
    end

    for elName, value in pairs(activeBonuses) do
        local elementIdx = elementalConditions[elName]
        if elementIdx then
            local elCfg = craftingConfig.elements[elementIdx]
            -- Unfortunately, adding absorption via Condition in Lua is very engine-dependent.
            -- Most TFS 1.3+ use CONDITION_PARAM_SPECIAL_SKILL_... or similar.
            -- A safer way for "Baiak" (usually 1.2/1.3) is using a storage and a revscript onHealthChange.
            -- BUT, let's try the Condition approach first if the user has the 'absorb' attributes registered.
            
            -- If the engine doesn't support it, we'll use player:setStorageValue and a global event.
            -- However, let's check if we can just update the item attributes dynamically? 
            -- No, that's messier.
            
            -- Let's use a hidden storage per element to store the "Set Bonus" value
            -- and let a 'onHealthChange' creaturescript do the final reduction.
            player:setStorageValue(55000 + elementIdx, value)
        end
    end
    
    -- Reset storages for elements not active
    for i = 1, #craftingConfig.elements do
        if not activeBonuses[craftingConfig.elements[i].name] then
            player:setStorageValue(55000 + i, 0)
        end
    end
end
