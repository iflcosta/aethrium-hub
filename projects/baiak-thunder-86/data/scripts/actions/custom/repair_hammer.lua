local repairHammer = Action()

function repairHammer.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if not target or type(target) ~= "userdata" or not target:isItem() then
        player:sendCancelMessage("Use isto em um equipamento trincado.")
        return true
    end
    
    local targetItem = target
    
    local slotPos = targetItem:getType() and targetItem:getType():getSlotPosition()
    if not slotPos or not UPGRADE_SYSTEM:canUpgradeItem(targetItem, slotPos) then
        player:sendCancelMessage("Este item não é um equipamento valido.")
        return true
    end
    
    if not UPGRADE_SYSTEM:isCracked(targetItem) then
        player:sendCancelMessage("Este item nao esta trincado.")
        return true
    end
    
    UPGRADE_SYSTEM:setCracked(targetItem, false)
    item:remove(1)
    
    player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "O item foi consertado! Todos os atributos foram restaurados e ele pode receber upgrades novamente.")
    return true
end

repairHammer:id(UPGRADE_SYSTEM.items.repairHammer)
repairHammer:register()

print("[Upgrade System] Action Repair Hammer carregada com sucesso!")
