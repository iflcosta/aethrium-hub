local cleansingStone = Action()

local function sendCleansingMenu(player, targetItem, stoneItem)
    local function buttonCallback(player, button, choice)
        if not choice then return end
        if button.text == "Limpar" then
            if player:getItemCount(UPGRADE_SYSTEM.items.cleansingStone) < 1 then
                return player:sendTextMessage(MESSAGE_STATUS_SMALL, "Voce nao possui mais a Cleansing Stone.")
            end
            
            if choice.id == 99 then
                UPGRADE_SYSTEM:clearAllSlots(targetItem)
                player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Todos os slots de atributos do item foram completamente resetados! O Tier foi mantido.")
            else
                UPGRADE_SYSTEM:clearSlot(targetItem, choice.id)
                player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "O atributo do Slot " .. choice.id .. " foi resetado com sucesso!")
            end
            
            player:removeItem(UPGRADE_SYSTEM.items.cleansingStone, 1)
            player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
        end
    end

    local window = ModalWindow { title = "Cleansing Stone", message = "Escolha quais atributos deseja resetar deste item:\nObs: O Tier e mantido intacto.\n\nAviso: O item e consumido instantaneamente ao Limpar." }
    window:addButton("Fechar")
    window:addButton("Limpar", buttonCallback)
    
    for i = 1, UPGRADE_SYSTEM.attributes.maxSlots do
        local attrData = UPGRADE_SYSTEM:getSlotAttribute(targetItem, i)
        if attrData then
            local def = UPGRADE_SYSTEM.attributes.list[attrData.key]
            local name = def and def.name or attrData.key
            local choice = window:addChoice("Limpar Slot " .. i .. " (" .. name .. " Lv." .. attrData.level .. ")")
            choice.id = i
        end
    end
    
    local choiceAll = window:addChoice("Limpar TODOS os Slots de Atributo")
    choiceAll.id = 99
    
    window:setDefaultEnterButton("Limpar")
    window:setDefaultEscapeButton("Fechar")
    window:sendToPlayer(player)
end

function cleansingStone.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if not target or type(target) ~= "userdata" or not target:isItem() then
        player:sendCancelMessage("Use isto em um equipamento.")
        return true
    end
    
    local targetItem = target
    
    local slotPos = targetItem:getType() and targetItem:getType():getSlotPosition()
    if not slotPos or not UPGRADE_SYSTEM:canUpgradeItem(targetItem, slotPos) then
        player:sendCancelMessage("Este item nao pode receber upgrades.")
        return true
    end
    
    if UPGRADE_SYSTEM:isCracked(targetItem) then
        player:sendCancelMessage("Voce nao pode resetar atributos de um item trincado. Conserte-o primeiro.")
        return true
    end
    
    local hasAttrs = false
    for i = 1, UPGRADE_SYSTEM.attributes.maxSlots do
        if UPGRADE_SYSTEM:getSlotAttribute(targetItem, i) then
            hasAttrs = true
            break
        end
    end
    
    if not hasAttrs then
        player:sendCancelMessage("Este item nao possui atributos para serem limpos.")
        return true
    end
    
    sendCleansingMenu(player, targetItem, item)
    return true
end

cleansingStone:id(UPGRADE_SYSTEM.items.cleansingStone)
cleansingStone:register()

print("[Upgrade System] Action Cleansing Stone carregada com sucesso!")
