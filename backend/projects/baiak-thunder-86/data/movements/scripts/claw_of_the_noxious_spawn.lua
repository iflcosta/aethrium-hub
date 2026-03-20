function onStepIn(creature, item, position, fromPosition)
    local player = creature:getPlayer()
    if not player then return true end
    
    if not Tile(player:getPosition()):hasFlag(TILESTATE_PROTECTIONZONE) then
        doTargetCombat(0, player, COMBAT_PHYSICALDAMAGE, -150, -200, CONST_ME_DRAWBLOOD)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Ouch! The serpent claw stabbed you.")
    end
    return true
end
