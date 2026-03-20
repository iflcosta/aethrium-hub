local cfg = craftingConfig

local function finalizeReset(player, item, elementIndex)
    local element = cfg.elements[elementIndex]
    
    if player:getItemCount(cfg.materials.goldToken) < cfg.materials.resetFee then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Você precisa de " .. cfg.materials.resetFee .. " Gold Tokens para trocar o elemento.")
        return false
    end

    -- Remove old element attributes
    local oldElementName = item:getAttribute("sealedElement")
    if oldElementName ~= "" then
        for _, el in ipairs(cfg.elements) do
            if el.name == oldElementName and el.attr then
                item:removeAttribute(el.attr)
            end
        end
    end

    if element.name ~= "None" then
        -- Find tier for bonus
        local itemName = item:getName()
        local tierBonus = 0
        for tier, bonus in pairs(cfg.elementalTiers) do
            if itemName:find(tier) then
                tierBonus = bonus
                break
            end
        end
        
        if element.name == "Physical" then tierBonus = 5 end
        
        item:setAttribute("sealedElement", element.name)
        item:setAttribute("sealedValue", tierBonus)
        if element.attr then
            item:setAttribute(element.attr, tierBonus)
        end
        
        -- Clean and update description
        local desc = item:getAttribute(ITEM_ATTRIBUTE_DESCRIPTION) or ""
        desc = desc:gsub(" %([^%)]*Sealed:[^%)]*%)", "") -- Remove old sealed string if present
        item:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, desc .. " (Sealed: " .. element.name .. ")")
        
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Elemento alterado para " .. element.name .. " com sucesso!")
        player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
        player:removeItem(cfg.materials.goldToken, cfg.materials.resetFee)
    else
        -- Remove sealing
        item:removeAttribute("sealedElement")
        item:removeAttribute("sealedValue")
        local desc = item:getAttribute(ITEM_ATTRIBUTE_DESCRIPTION) or ""
        desc = desc:gsub(" %([^%)]*Sealed:[^%)]*%)", "")
        item:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, desc)
        
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "O selamento elemental foi removido.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        player:removeItem(cfg.materials.goldToken, cfg.materials.resetFee)
    end
    
    return true
end

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    -- Target must be an anvil
    local targetId = target:getId()
    if targetId ~= 2555 and targetId ~= 8671 and targetId ~= 37841 and targetId ~= 37842 then
        return false
    end

    -- Check items in Armor/Legs slots
    local armor = player:getSlotItem(CONST_SLOT_ARMOR)
    local legs = player:getSlotItem(CONST_SLOT_LEGS)
    
    local itemToReset = nil
    if armor and (armor:getAttribute("sealedElement") ~= "" or armor:getName():find("Aethrium") or armor:getName():find("Ancient") or armor:getName():find("Celestial") or armor:getName():find("Ethereal")) then
        itemToReset = armor
    elseif legs and (legs:getAttribute("sealedElement") ~= "" or legs:getName():find("Aethrium") or legs:getName():find("Ancient") or legs:getName():find("Celestial") or legs:getName():find("Ethereal")) then
        itemToReset = legs
    end

    if not itemToReset then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Equipe o item craftado (Armor ou Legs) para trocar o elemento na Anvil.")
        return true
    end

    if player:getItemCount(cfg.materials.goldToken) < cfg.materials.resetFee then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Você precisa de " .. cfg.materials.resetFee .. " Gold Tokens para resetar o elemento.")
        return true
    end

    local modal = ModalWindow({
        title = "Elemental Reset",
        message = "Deseja alterar o elemento do seu " .. itemToReset:getName() .. "?\nCusto: " .. cfg.materials.resetFee .. " Gold Tokens."
    })

    for i, el in ipairs(cfg.elements) do
        modal:addChoice(el.name)
    end

    modal:addButton("Reset", function(p, button, choice)
        finalizeReset(p, itemToReset, choice.id)
    end)
    modal:addButton("Cancel")
    modal:setDefaultEnterButton("Reset")
    modal:setDefaultEscapeButton("Cancel")
    modal:sendToPlayer(player)

    return true
end
