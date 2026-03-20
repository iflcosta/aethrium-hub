local config = {
    itemId = 12466,
    storage = 50404, -- Mesma storage usada no reset_modal.lua
    duration = 60 * 60, -- 1 hora em segundos
}

local skillScroll = Action()

function skillScroll.onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if player:getStorageValue(config.storage) > os.time() then
        player:sendTextMessage(MESSAGE_STATUS_SMALL, "Voce ja possui uma protecao de skill ativa. Aguarde ela expirar antes de usar outro scroll.")
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end

    player:setStorageValue(config.storage, os.time() + config.duration)
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Voce usou o Skill Preservation Scroll! Suas skills e magic level estao protegidos por 1 hora.")
    player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
    
    item:remove(1)
    return true
end

skillScroll:id(config.itemId)
skillScroll:register()
