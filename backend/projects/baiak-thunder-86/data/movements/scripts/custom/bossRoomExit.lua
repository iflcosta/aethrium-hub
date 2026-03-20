function onStepIn(creature, item, position, fromPosition)
    local player = creature:getPlayer()
    if not player then return true end

    if _G.BossRoom then
        local pAccId = player:getGuid()
        local foundRoom = false

        for actionid, bossData in pairs(BossRoom.monstros) do
            local query = db.storeQuery("SELECT `guid_player` FROM `boss_room` WHERE `room_id` = " .. actionid)
            if query then
                local roomGUID = result.getDataInt(query, "guid_player")
                result.free(query)

                if roomGUID == pAccId then
                    foundRoom = true
                    -- This is the room the player is exiting!
                    local spectators = Game.getSpectators(bossData.center, false, false, 0, bossData.x, 0, bossData.y)
                    if spectators then
                        for _, spec in ipairs(spectators) do
                            if spec:isMonster() then
                                spec:getPosition():sendMagicEffect(CONST_ME_POFF)
                                spec:remove()
                            elseif spec:isPlayer() and spec:getId() ~= player:getId() then
                                spec:teleportTo(Position(583, 1242, 7))
                                spec:sendTextMessage(MESSAGE_EVENT_ADVANCE, "O dono da sala saiu. O evento foi encerrado.")
                            end
                        end
                    end
                    
                    if bossData.bossId then bossData.bossId = nil end
                    BossRoom:setFreeRoom(actionid)
                    break 
                end
            end
        end

        if not foundRoom then
            -- Fallback: Just in case the DB didn't match, force wipe any boss on this center
            for actionid, bossData in pairs(BossRoom.monstros) do
                local spectators = Game.getSpectators(bossData.center, false, false, 0, bossData.x, 0, bossData.y)
                if spectators then
                    local playerHere = false
                    for _, spec in ipairs(spectators) do
                        if spec:isPlayer() and spec:getId() == player:getId() then
                            playerHere = true
                            break
                        end
                    end
                    
                    if playerHere then
                        for _, spec in ipairs(spectators) do
                            if spec:isMonster() then
                                spec:getPosition():sendMagicEffect(CONST_ME_POFF)
                                spec:remove()
                            end
                        end
                        BossRoom:setFreeRoom(actionid)
                        break
                    end
                end
            end
        end
    end

    player:teleportTo(Position(583, 1242, 7))
    player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
    player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Voce saiu da Boss Room. A sala esta livre para outros jogadores!")
    return true
end
