local premiumPass = Action()

function premiumPass.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if player:getStorageValue(BattlePass.storagePassType) == 2 then
        player:sendCancelMessage("Você já tem Premium!")
        return true
    end
    
    player:setStorageValue(BattlePass.storagePassType, 2)
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "BattlePass Premium ativado!")
    player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_RED)
    item:remove(1)
    return true
end

premiumPass:id(12050)
premiumPass:register()