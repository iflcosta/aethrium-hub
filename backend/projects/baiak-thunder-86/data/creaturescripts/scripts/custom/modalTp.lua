function onModalWindow(player, modalWindowId, buttonId, choiceId)
 


    if modalWindowId >= firstid and modalWindowId <= lastid and buttonId == 100 then
        local levelReq = tplist[modalWindowId].level[choiceId]
        
        if levelReq > 0 and player:getLevel() < levelReq then
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Você não tem o nível necessário de " .. levelReq .. ".")
            return true
        end
        
        local position = tplist[modalWindowId].positions[choiceId]
        local subarea = tplist[modalWindowId].subareas[choiceId] or tplist[modalWindowId].name
        
        player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
        player:teleportTo(position)
        player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Teleportado para " .. subarea .. ".")
    end
    
    return true
end
