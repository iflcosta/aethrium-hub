--[[
    SISTEMA DE UPGRADE DE ITENS - Baiak Thunder (Refatorado - Fase 1)
    
    Trilha 1: Tiers +1 a +10 (Minor/Flawless Crystal)
    Trilha 2: Atributos Custom (Slots, Níveis, pedras Basic/Greater, RNG)
    Falhas: Punição de Tiers progresivos e item [Trincado] na Trilha 2.
]]

UPGRADE_SYSTEM = {
    -- ============================================================
    -- CONFIGURAÇÕES GERAIS
    -- ============================================================
    items = {
        minorCrystal = 22472,          -- Tier 0 a +5
        flawlessCrystal = 22473,       -- Tier +6 a +10
        basicAttributeStone = 8306,    -- Descobrir (Lv 1) ate Lv 3
        greaterAttributeStone = 8300,  -- Lv 3 ao Max (Lv 5)
        protectionScroll = 8301,       -- Previne Cracked (Falha Critica -> Falha Comum)
        cleansingStone = 8302,         -- Reroll (Limpa slots)
        repairHammer = 8303,           -- Remove tag cracked
    },
    
    -- ============================================================
    -- TRILHA 1: FORÇA BRUTA (Tiers)
    -- ============================================================
    tiers = {
        maxTier = 10,
        upgrades = {
            -- +1, +2, +3: Safe (-0)
            [1]  = {chance = 95, gold = 100000,   penalty = 0},
            [2]  = {chance = 90, gold = 250000,   penalty = 0},
            [3]  = {chance = 80, gold = 500000,   penalty = 0},
            -- +4, +5, +6: Lose 1 Tier (-1)
            [4]  = {chance = 60, gold = 1000000,  penalty = 1},
            [5]  = {chance = 50, gold = 2000000,  penalty = 1},
            [6]  = {chance = 40, gold = 4000000,  penalty = 1},
            -- +7, +8, +9, +10: Lose 2 Tiers (-2)
            [7]  = {chance = 25, gold = 8000000,  penalty = 2},
            [8]  = {chance = 15, gold = 10000000, penalty = 2},
            [9]  = {chance = 10, gold = 15000000, penalty = 2},
            [10] = {chance = 5,  gold = 20000000, penalty = 2},
        },
    },
    
    -- ============================================================
    -- TRILHA 2: ATRIBUTOS (Slots e Níveis)
    -- ============================================================
    attributes = {
        maxSlots = 2,
        maxLevel = 5,
        
        goldCost = 50000,
        
        -- Níveis com curas dinâmicas
        levels = {
            -- Para Level 1 (Descoberta): 100% Sucesso
            [1] = {success = 100, commonFail = 0, criticalFail = 0},
            -- Para Level 2
            [2] = {success = 70, commonFail = 25, criticalFail = 5},
            -- Para Level 3
            [3] = {success = 50, commonFail = 35, criticalFail = 15},
            -- Para Level 4
            [4] = {success = 30, commonFail = 40, criticalFail = 30},
            -- Para Level 5 (Max)
            [5] = {success = 15, commonFail = 40, criticalFail = 45},
        },
        
        list = {
            critical = {
                name = "Critical", description = "Chance de Dano Critico",
                multiplier = 3, -- 3% por Nível (Max 15%)
                slots = {"weapon"}, vocations = {1, 2, 3, 4, 5, 6, 7, 8}
            },
            hpLeech = {
                name = "HP Leech", description = "Roubo de vida",
                multiplier = 3, -- 3% por Nível (Max 15%)
                slots = {"weapon"}, vocations = {4, 8, 3, 7}
            },
            manaLeech = {
                name = "Mana Leech", description = "Roubo de mana",
                multiplier = 2, -- 2% por Nível (Max 10%)
                slots = {"weapon"}, vocations = {1, 5, 2, 6, 3, 7}
            },
            dodge = {
                name = "Dodge", description = "Chance de esquivar",
                multiplier = 3, -- 3% por Nível (Max 15%)
                slots = {"armor", "shield", "legs"}, vocations = {1, 2, 3, 4, 5, 6, 7, 8}
            },
            reflect = {
                name = "Reflect", description = "Reflete Dano",
                multiplier = 3, -- 3% por Nível (Max 15%)
                slots = {"shield"}, vocations = {1, 2, 3, 4, 5, 6, 7, 8}
            },
            bonusHpPercent = {
                name = "+HP%", description = "Bonus de vida maxima",
                multiplier = 4, -- 4% por Nível (Max 20%)
                slots = {"armor", "helmet", "legs"}, vocations = {1, 2, 3, 4, 5, 6, 7, 8}
            },
            bonusManaPercent = {
                name = "+Mana%", description = "Bonus de mana maxima",
                multiplier = 4, -- 4% por Nível (Max 20%)
                slots = {"armor", "helmet", "legs"}, vocations = {1, 2, 3, 4, 5, 6, 7, 8}
            },
            bonusSpeed = {
                name = "+Speed", description = "Bonus de velocidade",
                multiplier = 6, -- +6 Speed por Nível (Max 30)
                slots = {"boots"}, vocations = {1, 2, 3, 4, 5, 6, 7, 8}
            },
        },
    },
    
    slots = {
        [CONST_SLOT_HEAD] = "helmet",
        [CONST_SLOT_ARMOR] = "armor",
        [CONST_SLOT_LEGS] = "legs",
        [CONST_SLOT_FEET] = "boots",
        [CONST_SLOT_LEFT] = "weapon",
        [CONST_SLOT_RIGHT] = "weapon",
    },
    
    slotDisplayNames = {
        helmet = "Capacete", armor = "Armadura", legs = "Pernas",
        boots = "Botas", weapon = "Arma", shield = "Escudo",
    },
    
    messages = {
        noItem = "Voce nao possui um item equipado neste slot.",
        cantUpgrade = "Este item nao pode ser melhorado.",
        itemCracked = "Este item esta TRINCADO! Use um Repair Hammer.",
        maxTier = "Este item ja esta no tier maximo (+%d).",
        noGold = "Gold insuficiente: %s.",
        noMinor = "Voce precisa de %d Minor Crystal(s).",
        noFlawless = "Voce precisa de %d Flawless Crystal(s).",
        noBasic = "Voce precisa de Basic Attribute Stone(s).",
        noGreater = "Voce precisa de Greater Attribute Stone(s).",
        upgradeSuccess = "SUCESSO! Seu item agora esta +%d!",
        upgradeFail = "FALHA! Seu item voltou para +%d.",
        upgradeFailSafe = "FALHA! Porem nada aconteceu pois a falha era segura.",
        upgradeFailProtected = "FALHA! Porem nada aconteceu pois o protection scroll protegeu seu tier.",
        attrDiscover = "SUCESSO! Atributo [%s Lv. 1] descoberto no slot %d!",
        attrSuccess = "SUCESSO! O atributo %s upou para o Lv. %d!",
        attrFailCommon = "FALHA! A pedra quebrou, mas o item esta intacto.",
        attrFailCritical = "FALHA CRITICA! O item trincou!",
        attrFailProtected = "FALHA! A pedra quebrou, mas o protection scroll salvou o item de trincar.",
    },
}

-- ============================================================
-- CONSTANTS & STORAGES
-- ============================================================
STORAGE_BONUS_HP = 50501
STORAGE_BONUS_MANA = 50502
STORAGE_BONUS_SPEED = 50503

GLOBAL_LIMITS = {
    dodge = 15,
    critical = 15,
    reflect = 15,
    hpLeechEKRP = 15,
    manaLeechMSED = 10,
    maxHpPercent = 20,
    maxManaPercent = 20
}


-- ============================================================
-- CORE FUNCTIONS
-- ============================================================
function UPGRADE_SYSTEM:getItemAttribute(item, key)
    if not item or not item.getCustomAttribute then return 0 end
    local val = item:getCustomAttribute(key)
    return tonumber(val) or 0
end

function UPGRADE_SYSTEM:setItemAttribute(item, key, value)
    if not item or not item.setCustomAttribute then return false end
    item:setCustomAttribute(key, value)
    return true
end

function UPGRADE_SYSTEM:isCracked(item)
    return self:getItemAttribute(item, "cracked") == 1
end

function UPGRADE_SYSTEM:setCracked(item, state)
    self:setItemAttribute(item, "cracked", state and 1 or 0)
    self:updateItemNameDesc(item)
end

function UPGRADE_SYSTEM:getItemTier(item)
    return self:getItemAttribute(item, "upgradeTier")
end

-- ============================================================
-- TRILHA 1 LOGIC (STATS NATIVOS)
-- ============================================================
function UPGRADE_SYSTEM:applyTierStats(item, tier)
    if not item then return end
    local itemType = ItemType(item:getId())
    if not itemType then return end
    
    local isCracked = self:isCracked(item)
    local weaponType = itemType:getWeaponType()
    local slotPos = itemType:getSlotPosition()
    
    if tier <= 0 or isCracked then
        item:removeAttribute(ITEM_ATTRIBUTE_ATTACK)
        item:removeAttribute(ITEM_ATTRIBUTE_DEFENSE)
        item:removeAttribute(ITEM_ATTRIBUTE_ARMOR)
        return
    end
    
    local multiplier = 1.0
    local itemNameAttr = item:getAttribute(ITEM_ATTRIBUTE_NAME)
    if itemNameAttr:lower():find("aethrium") then
        multiplier = 1.3
    end

    -- Weapons (+1 attack per tier)
    if weaponType ~= WEAPON_NONE and weaponType ~= WEAPON_SHIELD and weaponType ~= WEAPON_AMMO then
        local baseAttack = itemType:getAttack()
        if baseAttack > 0 then
            item:setAttribute(ITEM_ATTRIBUTE_ATTACK, math.floor(baseAttack * multiplier) + tier)
        end
    end
    
    -- Shields (+1 defense per 2 tiers)
    if weaponType == WEAPON_SHIELD then
        local baseDefense = itemType:getDefense()
        if baseDefense > 0 then
            local bonus = math.floor(tier / 2)
            item:setAttribute(ITEM_ATTRIBUTE_DEFENSE, math.floor(baseDefense * multiplier) + bonus)
        end
    end
    
    -- Armors, Helmets, Legs, Boots (+1 armor per 2 tiers)
    if bit.band(slotPos, SLOTP_HEAD) ~= 0 or bit.band(slotPos, SLOTP_ARMOR) ~= 0 or bit.band(slotPos, SLOTP_LEGS) ~= 0 or bit.band(slotPos, SLOTP_FEET) ~= 0 then
        local baseArmor = itemType:getArmor()
        if baseArmor > 0 then
            local bonus = math.floor(tier / 2)
            item:setAttribute(ITEM_ATTRIBUTE_ARMOR, math.floor(baseArmor * multiplier) + bonus)
        end
    end
end

function UPGRADE_SYSTEM:setItemTier(item, tier)
    local success = self:setItemAttribute(item, "upgradeTier", tier)
    if success then
        self:applyTierStats(item, tier)
        self:updateItemNameDesc(item)
    end
    return success
end

-- ============================================================
-- TRILHA 2 LOGIC (SLOTS & ATRIBUTOS)
-- ============================================================

-- Recupera o nome do atributo salvo num determinado slot (1 ou 2)
function UPGRADE_SYSTEM:getSlotAttribute(item, slotIdx)
    local attrKeyStr = item:getCustomAttribute("attr_slot_" .. slotIdx .. "_key")
    if not attrKeyStr or attrKeyStr == "" then return nil end
    local level = self:getItemAttribute(item, "attr_slot_" .. slotIdx .. "_level")
    return {key = tostring(attrKeyStr), level = level}
end

function UPGRADE_SYSTEM:setSlotAttribute(item, slotIdx, attrKey, level)
    if not item.setCustomAttribute then return false end
    item:setCustomAttribute("attr_slot_" .. slotIdx .. "_key", attrKey)
    self:setItemAttribute(item, "attr_slot_" .. slotIdx .. "_level", level)
    self:updateItemNameDesc(item)
    return true
end

function UPGRADE_SYSTEM:clearSlot(item, slotIdx)
    if not item.removeCustomAttribute then return false end
    item:removeCustomAttribute("attr_slot_" .. slotIdx .. "_key")
    item:removeCustomAttribute("attr_slot_" .. slotIdx .. "_level")
    self:updateItemNameDesc(item)
    return true
end

function UPGRADE_SYSTEM:clearAllSlots(item)
    if not item.removeCustomAttribute then return false end
    for i = 1, self.attributes.maxSlots do
        item:removeCustomAttribute("attr_slot_" .. i .. "_key")
        item:removeCustomAttribute("attr_slot_" .. i .. "_level")
    end
    self:updateItemNameDesc(item)
    return true
end

function UPGRADE_SYSTEM:getValidAttributesForItem(item, vocationId)
    local validAttrs = {}
    local itemType = item and item:getType()
    if not itemType then return validAttrs end
    local slotPos = itemType:getSlotPosition()
    local slotType = self:getItemSlotType(item, slotPos)
    if not slotType then return validAttrs end

    for attrKey, attrData in pairs(self.attributes.list) do
        local isValidSlot = false
        for _, vSlot in ipairs(attrData.slots) do
            if vSlot == slotType then isValidSlot = true break end
        end
        
        local isValidVoc = false
        for _, vVoc in ipairs(attrData.vocations) do
            if vVoc == vocationId then isValidVoc = true break end
        end
        
        if isValidSlot and isValidVoc then
            table.insert(validAttrs, attrKey)
        end
    end
    return validAttrs
end

-- Calcula bônus real de um atributo na arma. Se o item estiver cracked, retorna 0!
function UPGRADE_SYSTEM:getItemAttributeBonus(item, attrKey)
    if self:isCracked(item) then return 0 end
    
    local totalBonus = 0
    for i = 1, self.attributes.maxSlots do
        local slotData = self:getSlotAttribute(item, i)
        if slotData and slotData.key == attrKey then
            local attrDef = self.attributes.list[attrKey]
            if attrDef then
                totalBonus = totalBonus + (slotData.level * attrDef.multiplier)
            end
        end
    end
    return totalBonus
end

function UPGRADE_SYSTEM:getTotalAttributeBonus(player, attrKey)
    local total = 0
    local slots = {
        CONST_SLOT_HEAD, CONST_SLOT_ARMOR, CONST_SLOT_LEGS, CONST_SLOT_FEET, 
        CONST_SLOT_LEFT, CONST_SLOT_RIGHT, CONST_SLOT_NECK, CONST_SLOT_RING, CONST_SLOT_AMMO
    }
    for _, slot in ipairs(slots) do
        local item = player:getSlotItem(slot)
        if item then
            total = total + self:getItemAttributeBonus(item, attrKey)
        end
    end
    return total
end

-- Recalcula HP, Mana e Speed em tempo real
function UPGRADE_SYSTEM:recalculateStats(player)
    if not player then return end
    
    -- 1. Recuperar bônus antigos aplicados (nas storages)
    local oldBonusHp = math.max(0, player:getStorageValue(STORAGE_BONUS_HP))
    local oldBonusMana = math.max(0, player:getStorageValue(STORAGE_BONUS_MANA))
    local oldBonusSpeed = math.max(0, player:getStorageValue(STORAGE_BONUS_SPEED))
    
    -- 2. Remover bônus antigos do máximo atual
    -- (O motor do OTServ soma bônus/punições ao valor base. 
    -- Para evitar drift, removemos o que nós mesmos adicionamos antes)
    if oldBonusHp > 0 then
        player:setMaxHealth(player:getMaxHealth() - oldBonusHp)
        if player:getHealth() > player:getMaxHealth() then
            player:addHealth(player:getMaxHealth() - player:getHealth())
        end
    end
    
    if oldBonusMana > 0 then
        player:setMaxMana(player:getMaxMana() - oldBonusMana)
        if player:getMana() > player:getMaxMana() then
            player:addMana(player:getMaxMana() - player:getMana())
        end
    end
    
    if oldBonusSpeed > 0 then
        player:changeSpeed(-oldBonusSpeed)
    end
    
    -- 3. Calcular novos bônus baseados nos itens equipados
    local rawHpPercent = self:getTotalAttributeBonus(player, "bonusHpPercent")
    local rawManaPercent = self:getTotalAttributeBonus(player, "bonusManaPercent")
    local bonusSpeed = self:getTotalAttributeBonus(player, "bonusSpeed")
    
    local bonusHpPercent = math.min(rawHpPercent, GLOBAL_LIMITS.maxHpPercent)
    local bonusManaPercent = math.min(rawManaPercent, GLOBAL_LIMITS.maxManaPercent)
    
    -- 4. Verificar caps e avisar o jogador
    local warnings = {}
    if rawHpPercent > GLOBAL_LIMITS.maxHpPercent then table.insert(warnings, "Max HP (20%)") end
    if rawManaPercent > GLOBAL_LIMITS.maxManaPercent then table.insert(warnings, "Max Mana (20%)") end
    
    -- Adicionando alertas para outros atributos também
    local dodge = self:getTotalAttributeBonus(player, "dodge")
    local critical = self:getTotalAttributeBonus(player, "critical")
    local reflect = self:getTotalAttributeBonus(player, "reflect")
    
    if dodge > GLOBAL_LIMITS.dodge then table.insert(warnings, "Dodge (15%)") end
    if critical > GLOBAL_LIMITS.critical then table.insert(warnings, "Critical (15%)") end
    if reflect > GLOBAL_LIMITS.reflect then table.insert(warnings, "Reflect (15%)") end
    
    if #warnings > 0 then
        player:sendTextMessage(MESSAGE_STATUS_WARNING, "[Upgrade System] Limite excedido: " .. table.concat(warnings, ", ") .. ". O excesso foi ignorado.")
    end
    
    -- 5. Aplicar novos bônus
    local baseHp = player:getMaxHealth()
    local baseMana = player:getMaxMana()
    
    local newBonusHp = math.floor(baseHp * (bonusHpPercent / 100))
    local newBonusMana = math.floor(baseMana * (bonusManaPercent / 100))
    local newBonusSpeed = bonusSpeed
    
    if newBonusHp > 0 then
        player:setMaxHealth(player:getMaxHealth() + newBonusHp)
    end
    
    if newBonusMana > 0 then
        player:setMaxMana(player:getMaxMana() + newBonusMana)
    end
    
    if newBonusSpeed > 0 then
        player:changeSpeed(newBonusSpeed)
    end
    
    -- 6. Salvar novos valores nas storages
    player:setStorageValue(STORAGE_BONUS_HP, newBonusHp)
    player:setStorageValue(STORAGE_BONUS_MANA, newBonusMana)
    player:setStorageValue(STORAGE_BONUS_SPEED, newBonusSpeed)
end


-- ============================================================
-- HELPERS
-- ============================================================
function UPGRADE_SYSTEM:getItemSlotType(item, slotPosition)
    if not item then return nil end
    local itemType = item:getType()
    if not itemType then return nil end
    
    if item:isContainer() or itemType:isContainer() then return nil end

    if itemType:getWeaponType() == WEAPON_SHIELD then return "shield" end
    if itemType:getWeaponType() ~= WEAPON_NONE then return "weapon" end
    
    local slotPos = itemType:getSlotPosition()
    if bit.band(slotPos, SLOTP_HEAD) ~= 0 then return "helmet"
    elseif bit.band(slotPos, SLOTP_ARMOR) ~= 0 then return "armor"
    elseif bit.band(slotPos, SLOTP_LEGS) ~= 0 then return "legs"
    elseif bit.band(slotPos, SLOTP_FEET) ~= 0 then return "boots" end
    
    return nil
end

function UPGRADE_SYSTEM:canUpgradeItem(item, slotPosition)
    local itemType = item and item:getType()
    if not itemType then return false end
    local slotPos = slotPosition or itemType:getSlotPosition()
    return self:getItemSlotType(item, slotPos) ~= nil
end

function UPGRADE_SYSTEM:formatNumber(num)
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1.%2')
        if k == 0 then break end
    end
    return formatted
end

function UPGRADE_SYSTEM:updateItemNameDesc(item)
    if not item then return end
    local itemType = ItemType(item:getId())
    local name = itemType:getName()
    
    local tier = self:getItemTier(item)
    local isCracked = self:isCracked(item)
    
    local parts = {}
    if isCracked then
        table.insert(parts, "[Trincado]")
    end
    
    if tier > 0 then
        table.insert(parts, "[+" .. tier .. "]")
    end

    local itemNameAttr = item:getAttribute(ITEM_ATTRIBUTE_NAME)
    if itemNameAttr:lower():find("aethrium") then
        table.insert(parts, "Aethrium")
    end
    
    table.insert(parts, name)
    local finalName = table.concat(parts, " ")
    
    -- Aplicar custom name
    item:setAttribute(ITEM_ATTRIBUTE_NAME, finalName)

    -- Aplicar descricao extra p/ niveis
    local descLines = {}
    for i = 1, self.attributes.maxSlots do
        local sAttr = self:getSlotAttribute(item, i)
        if sAttr then
            local def = self.attributes.list[sAttr.key]
            if def then
                local value = sAttr.level * def.multiplier
                local formatVal = tostring(value) .. (sAttr.key == "bonusSpeed" and "" or "%")
                table.insert(descLines, string.format("Slot %d: %s Lv.%d (+%s)", i, def.name, sAttr.level, formatVal))
            end
        else
            table.insert(descLines, string.format("Slot %d: Vazio", i))
        end
    end
    item:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, table.concat(descLines, "\n"))
end

function UPGRADE_SYSTEM:formatItemName(item)
    if not item then return "Vazio" end
    if item:getAttribute(ITEM_ATTRIBUTE_NAME) ~= "" then
        return item:getAttribute(ITEM_ATTRIBUTE_NAME)
    end
    return item:getName()
end

function UPGRADE_SYSTEM:hasProtection(player)
    return player:getStorageValue(50500) == 1
end

function UPGRADE_SYSTEM:setProtection(player, active)
    player:setStorageValue(50500, active and 1 or 0)
end

print("[Upgrade System] Biblioteca Fase 1 carregada com sucesso!")
