function onKill(player, target)
    local playerPos = player:getPosition()
    local positions = {
        {x = playerPos.x - 7, y = playerPos.y - 5, z = playerPos.z},
        {x = playerPos.x + 7, y = playerPos.y + 5, z = playerPos.z},
    }
    local partyList = {}

    if target:isPlayer() or target:getMaster() then
        return true
    end

    local monsterName = target:getName():lower()
    local party = player:getParty()

    if party then
        local members = party:getMembers()
        local leader = party:getLeader()

        for _, member in ipairs(members) do
            if isInArea(member:getPosition(), positions[1], positions[2]) then
                partyList[#partyList + 1] = member
            end
        end

        if isInArea(leader:getPosition(), positions[1], positions[2]) then
            partyList[#partyList + 1] = leader
        end

        for _, partyMember in ipairs(partyList) do
            local player = Player(partyMember)
            local movie = getTaskInfos(partyMember)

            if movie then
                if monsterName == movie.name or isInArray(movie.mons_list, monsterName) then
                    local sto_value = player:getStorageValue(movie.storage)

                    if sto_value < movie.amount then
                        sto_value = sto_value + 1
                        player:setStorageValue(movie.storage, sto_value)

                        if sto_value < movie.amount then
                            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, '[Task System] Killed ['..(sto_value)..'/'..movie.amount..'] '..monsterName..'.')
                        else
                            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, '[Task System] You finished your task.')
                        end
                    end
                end
            end

            local tvr = getTaskDailyInfo(partyMember)

            if tvr then
                if monsterName == tvr.name or isInArray(tvr.mons_list, monsterName) then
                    local sto_value = player:getStorageValue(tvr.storage)

                    if sto_value < tvr.amount then
                        sto_value = sto_value + 1
                        player:setStorageValue(tvr.storage, sto_value)

                        if sto_value < tvr.amount then
                            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, '[Task System Daily] Killed ['..(sto_value)..'/'..tvr.amount..'] '..monsterName..'.')
                        else
                            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, '[Task System Daily] You finished your task.')
                        end
                    end
                end
            end
        end
    else
        local ret_t = getTaskInfos(player)

        if ret_t then
            if monsterName == ret_t.name or isInArray(ret_t.mons_list, monsterName) then
                local sto_value = player:getStorageValue(ret_t.storage)

                if sto_value < ret_t.amount then
                    sto_value = sto_value + 1
                    player:setStorageValue(ret_t.storage, sto_value)

                    if sto_value < ret_t.amount then
                        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, '[Task System] Killed ['..(sto_value)..'/'..ret_t.amount..'] '..monsterName..'.')
                    else
                        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, '[Task System] You finished your task.')
                    end
                end
            end
        end

        local ret_td = getTaskDailyInfo(player)

        if ret_td then
            if monsterName == ret_td.name or isInArray(ret_td.mons_list, monsterName) then
                local sto_value = player:getStorageValue(ret_td.storage)

                if sto_value < ret_td.amount then
                    sto_value = sto_value + 1
                    player:setStorageValue(ret_td.storage, sto_value)

                    if sto_value < ret_td.amount then
                        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, '[Task System Daily] Killed ['..(sto_value)..'/'..ret_td.amount..'] '..monsterName..'.')
                    else
                        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_ORANGE, '[Task System Daily] You finished your task.')
                    end
                end
            end
        end
    end

    return true
end
