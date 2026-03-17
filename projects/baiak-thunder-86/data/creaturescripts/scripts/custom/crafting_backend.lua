if not json then dofile('data/lib/custom/json.lua') end
if not ModalWindow then dofile('data/lib/custom/modalwindow.lua') end

local OPCODE_CRAFTING = 204

-- Load existing config
-- Load existing config
if not craftingConfig then
    dofile('data/lib/custom/crafting.lua')
end

-- Fallback/Reference to the config if lib loader didn't work as expected
local cfg = craftingConfig 
if not cfg then
    --print(">> [Crafting Backend] CRITICAL: craftingConfig is nil!")
elseif not cfg.system then
    --print(">> [Crafting Backend] CRITICAL: craftingConfig.system is nil!")
else
    if not _G.CraftBackendPrinted then
        _G.CraftBackendPrinted = true
        --print(">> [Crafting Backend] Config loaded. Categories count: " .. #cfg.system)
        for i, cat in ipairs(cfg.system) do
            --print(">> [Crafting Backend] Category " .. i .. ": " .. cat.vocation .. " (" .. #cat.items .. " items)")
        end
    end
end

function sendCraftJSON(player, data)
    --print(">> Sending Crafting Data to " .. player:getName() .. " (Action: " .. (data.action or "unknown") .. ")")
    player:sendExtendedOpcode(OPCODE_CRAFTING, json.encode(data))
end

local function getCraftItemStats(id)
    local it = ItemType(id)
    if not it then return {} end

    local stats = {}
    
    local fullDesc = ""
    local dummyItem = Game.createItem(id, 1)
    if dummyItem then
        fullDesc = dummyItem:getDescription(1)
        dummyItem:remove()
    elseif it.getItemDescription then
        fullDesc = it:getItemDescription(1, -1)
    end
    
    if type(fullDesc) == "string" and fullDesc ~= "" then
        local prefix = "You see "
        if fullDesc:sub(1, #prefix) ~= prefix then
            fullDesc = prefix .. fullDesc
        end
        stats.description = fullDesc
    end
    
    -- Safe extraction of basic stats
    if it.getAttack then stats.attack = it:getAttack() end
    if it.getDefense then stats.defense = it:getDefense() end
    if it.getArmor then stats.armor = it:getArmor() end
    
    -- Range and HitChance are often missing in older TFS or named differently
    if it.getRange then stats.range = it:getRange() end
    if it.getHitChance then stats.hitchance = it:getHitChance() end
    if it.getShootRange then stats.range = it:getShootRange() end

    -- Magic Level and other attributes
    if it.getMagicLevelPoints then stats.magicPoints = it:getMagicLevelPoints() end
    
    -- Custom logic for Paladin Crossbows if needed (from user request)
    if id == 48935 or id == 41013 then
        stats.specialInfo = "Aceita Arrow e Bolt"
    end

    return stats
end

function sendInitData(player, categoryIndex)
    --print(">> [Crafting Backend] sendInitData starting for " .. player:getName() .. " (CatIdx: " .. (categoryIndex or "nil") .. ")")
    local status, err = pcall(function()
        if not cfg or not cfg.system then 
            --print(">> [Crafting Backend] Error: cfg or cfg.system is nil")
            return 
        end
        
        local payload = {
            action = "init",
            materials = {}
        }

        -- Always send materials
        payload.materialIDs = {}
        if cfg.materials then
            for k, v in pairs(cfg.materials) do
                payload.materials[k] = player:getItemCount(v)
                payload.materialIDs[k] = v
            end
        end

        -- Send elements list for the Sealing Tab
        payload.elements = cfg.elements

        local isCategoryRequest = false
        if categoryIndex then
            local cat = cfg.system[categoryIndex]
            if cat then
                isCategoryRequest = true
                local items = {}
                for j, itemCfg in ipairs(cat.items) do
                    local reqs = {}
                    for _, req in ipairs(itemCfg.reqItems) do
                        local itType = ItemType(req.item)
                        local displayReqId = (itType and itType.getClientId) and itType:getClientId() or req.item
                        table.insert(reqs, {
                            id = displayReqId,
                            name = itType and itType:getName() or "Item",
                            count = req.count,
                            playerHas = player:getItemCount(req.item)
                        })
                    end
                    
                    local it = ItemType(itemCfg.itemID)
                    local displayId = (it and it.getClientId) and it:getClientId() or itemCfg.itemID

                    table.insert(items, {
                        index = j,
                        name = itemCfg.item,
                        id = displayId, -- Use clientId for icon/preview
                        serverId = itemCfg.itemID, -- Keep serverId for crafting logic
                        stats = getCraftItemStats(itemCfg.itemID),
                        reqs = reqs
                    })
                end
                
                payload.action = "category"
                payload.categoryIndex = categoryIndex
                payload.items = items
            end
        end

        if not isCategoryRequest then
            -- Initial load or fallback: Send ONLY category names
            payload.categories = {}
            for i, cat in ipairs(cfg.system) do
                table.insert(payload.categories, {
                    index = i,
                    name = cat.vocation
                })
            end
        end

        --print(">> [Crafting Backend] Payload ready. Action: " .. payload.action)
        sendCraftJSON(player, payload)
    end)

    if not status then
        --print(">> [Crafting Backend] CRITICAL ERROR in sendInitData: " .. tostring(err))
    end
end

local function getItemTier(item)
    if not item then return "Other", 0 end
    local itType = ItemType(item:getId())
    local name = itType and itType:getName() or item:getName()
    name = name:lower()
    
    for tier, value in pairs(cfg.elementalTiers) do
        if name:find(tier:lower()) then
            return tier, value
        end
    end
    return "Other", 0
end

local function updateSealingDescription(item)
    if not item then return end
    local element = item:getCustomAttribute("sealedElement") or "None"
    local tier = item:getCustomAttribute("sealedTier") or "None"
    
    local lines = {}
    local currentDesc = item:getAttribute(ITEM_ATTRIBUTE_DESCRIPTION)
    if currentDesc and currentDesc ~= "" then
        for line in currentDesc:gmatch("([^\n]+)") do
            if not line:find("Sealed Element:") then
                table.insert(lines, line)
            end
        end
    end

    if element ~= "None" then
        local bonus = cfg.elementalTiers[tier] or 0
        table.insert(lines, string.format("Sealed Element: %s (+%d%%)", element, bonus))
    end

    if #lines > 0 then
        item:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, table.concat(lines, "\n"))
    else
        item:removeAttribute(ITEM_ATTRIBUTE_DESCRIPTION)
    end
end

-- isHighTier removed, replaced by getItemTier

local function isElementalItem(itemId)
    local itType = ItemType(itemId)
    if not itType then return false end
    local name = itType:getName():lower()
    
    -- Strict rule: Only armor and legs
    -- We can check by name keywords or by looking it up in the config categories
    local keywords = {"armor", "legs", "plate", "greaves", "gown", "robe", "pantaloons"}
    local isMatch = false
    for _, kw in ipairs(keywords) do
        if name:find(kw) then
            isMatch = true
            break
        end
    end
    
    if not isMatch then return false end

    -- Double check if it's in the crafting config under Armor or Legs categories
    for _, cat in ipairs(craftingConfig.system) do
        local catName = cat.vocation:lower()
        if catName:find("armor") or catName:find("legs") or catName:find("set") then
            for _, item in ipairs(cat.items) do
                if item.itemID == itemId then
                    return true
                end
            end
        end
    end
    return false
end

function processCraftingOpcode(player, data)
    local action = data.action

    if action == "init" then
        sendInitData(player)
        return true
    elseif action == "fetchCategory" then
        local catIdx = tonumber(data.index)
        if catIdx then
            sendInitData(player, catIdx)
        end
        return true
    elseif action == "fetchEquipped" then
        local equipped = {}
        local slots = {CONST_SLOT_ARMOR, CONST_SLOT_LEGS}
        for _, slotId in ipairs(slots) do
            local item = player:getSlotItem(slotId)
            if item then
                if isElementalItem(item:getId()) then
                    local tier = item:getCustomAttribute("sealedTier") or "None"
                    local bonus = cfg.elementalTiers[tier] or 0
                    if tier == "None" or bonus == 0 then
                        tier, bonus = getItemTier(item)
                    end
                    table.insert(equipped, {
                        slot = slotId,
                        id = item:getId(),
                        name = item:getName(),
                        currentElement = item:getCustomAttribute("sealedElement") or "None",
                        tier = tier,
                        bonus = bonus
                    })
                end
            end
        end

        local materials = {}
        for k, v in pairs(cfg.materials) do
            materials[k] = player:getItemCount(v)
        end

        sendCraftJSON(player, {action = "equipped", items = equipped, materials = materials})
        return true
    elseif action == "requestSeal" then
        local item = nil
        if data.position then
            item = player:getItemByPosition(data.position)
        elseif data.itemId then
            item = player:getItemById(data.itemId, true)
        end

        if item and isElementalItem(item:getId()) then
            local elName = item:getCustomAttribute("sealedElement") or "None"
            local tier = item:getCustomAttribute("sealedTier") or "None"
            local bonus = cfg.elementalTiers[tier] or 0
            if tier == "None" or bonus == 0 then
                tier, bonus = getItemTier(item)
            end

            local materials = {}
            for k, v in pairs(cfg.materials) do
                materials[k] = player:getItemCount(v)
            end

            sendCraftJSON(player, {
                action = "sealPreview",
                materials = materials,
                item = {
                    id = item:getId(),
                    name = item:getName(),
                    currentElement = elName,
                    tier = tier,
                    bonus = bonus,
                    position = data.position
                }
            })
        else
            player:sendTextMessage(MESSAGE_STATUS_SMALL, "Somente armaduras e legs podem ser seladas.")
        end
        return true
    elseif action == "sealEquipped" or action == "sealItem" then
        local item = nil
        if data.position then
            item = player:getItemByPosition(data.position)
        elseif data.slot then
            item = player:getSlotItem(data.slot)
        end

        if not item or not isElementalItem(item:getId()) then
            player:sendTextMessage(MESSAGE_STATUS_SMALL, "Item invalido para selamento. Somente Armaduras e Legs.")
            return true
        end

        local elementIdx = tonumber(data.elementIndex)
        local element = craftingConfig.elements[elementIdx]
        if not element then return true end

        local currentEl = item:getCustomAttribute("sealedElement") or "None"
        local isReSeal = (currentEl ~= "None" and element.name ~= "None")
        local fee = (element.name == "None") and 0 or (isReSeal and 5 or 10)
        local materialId = cfg.materials.sealingItem

        if fee > 0 and player:getItemCount(materialId) < fee then
            player:sendTextMessage(MESSAGE_STATUS_SMALL, "Voce nao possui Gold Tokens suficientes.")
            return true
        end

        if fee > 0 then
            player:removeItem(materialId, fee)
        end

        if element.name == "None" then
            item:removeCustomAttribute("sealedElement")
            item:removeCustomAttribute("sealedTier")
            updateSealingDescription(item)
        else
            local tier, bonus = getItemTier(item)
            item:setCustomAttribute("sealedElement", element.name)
            item:setCustomAttribute("sealedTier", tier)
            updateSealingDescription(item)
        end

        player:sendTextMessage(MESSAGE_INFO_DESCR, "Item selado com sucesso!")
        processCraftingOpcode(player, {action = "fetchEquipped"})
        return true
    elseif action == "craft" then
        local catIdx = tonumber(data.category)
        local itemIdx = tonumber(data.index)
        
        if not cfg.system[catIdx] or not cfg.system[catIdx].items[itemIdx] then
            sendCraftJSON(player, {action = "msg", type = "error", msg = "Item inválido."})
            return true
        end
        
        local itemCfg = cfg.system[catIdx].items[itemIdx]
        
        -- Validate base materials
        for _, req in ipairs(itemCfg.reqItems) do
            if player:getItemCount(req.item) < req.count then
                sendCraftJSON(player, {action = "msg", type = "error", msg = "Você não tem materiais suficientes."})
                return true
            end
        end
        
        -- Standard craft
        for _, req in ipairs(itemCfg.reqItems) do
            player:removeItem(req.item, req.count)
        end
        
        local item = player:addItem(itemCfg.itemID, 1)
        if item then
            player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have successfully crafted a " .. itemCfg.item .. "!")
            sendCraftJSON(player, {action = "msg", type = "info", msg = "Craft realizado com sucesso!"})
        end

        sendInitData(player)
        return true
    end
    return true
end
