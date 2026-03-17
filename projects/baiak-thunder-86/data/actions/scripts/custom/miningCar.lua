local CONFIG = {
    TELEPORT_POSITION = Position(1652, 1108, 8),
    TELEPORT_BACK_POSITION = Position(981, 1214, 7),
    MINING_POSITION = Position(980, 1215, 7),
    TELEPORT_EFFECT = CONST_ME_TELEPORT,
    CANCEL_EFFECT = CONST_ME_POFF,
}

function onUse(player, item, fromPosition, target, toPosition, isHotkey)
    if fromPosition == CONFIG.MINING_POSITION then
        player:getPosition():sendMagicEffect(CONFIG.CANCEL_EFFECT)
        player:sendCancelMessage("You have been teleported to the mining area.")
        player:teleportTo(CONFIG.TELEPORT_POSITION)
        player:getPosition():sendMagicEffect(CONFIG.TELEPORT_EFFECT)
    else
        player:getPosition():sendMagicEffect(CONFIG.CANCEL_EFFECT)
        player:sendCancelMessage("You were teleported back.")
        player:teleportTo(CONFIG.TELEPORT_BACK_POSITION)
        player:getPosition():sendMagicEffect(CONFIG.TELEPORT_EFFECT)
    end

    return true
end
