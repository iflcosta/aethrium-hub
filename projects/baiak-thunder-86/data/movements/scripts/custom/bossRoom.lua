function onStepIn(creature, item, position, fromPosition)
    local player = creature:getPlayer()
    if not player then
        return false
    end

    local bossVariavel = BossRoom.monstros[item.actionid]
    if not bossVariavel then
        player:teleportTo(fromPosition, true)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end

    -- 1. Check if room is occupied
    local spectators = Game.getSpectators(bossVariavel.center, false, false, 0, bossVariavel.x, 0, bossVariavel.y)
    if spectators then
        local isOcupado = false
        for _, spec in ipairs(spectators) do
            if spec:isPlayer() then
                isOcupado = true
                break
            end
        end

        if isOcupado then
            player:teleportTo(fromPosition, true)
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, BossRoom.msg.notAvailable)
            return true
        end
    end

    -- 2. Identify Team (Party or Solo)
    local team = {}
    local party = player:getParty()
    if party then
        if party:getLeader() ~= player then
            player:sendCancelMessage("Only the party leader can initiate the boss fight.")
            player:teleportTo(fromPosition, true)
            return true
        end
        
        local members = party:getMembers()
        table.insert(team, player)
        for _, member in ipairs(members) do
            if member:getPosition():getDistance(player:getPosition()) <= 3 then
                table.insert(team, member)
            end
        end
    else
        table.insert(team, player)
    end

    -- 3. Check Balance for everyone in team
    local currencyType = bossVariavel.currencyType or "coins"
    local price = bossVariavel.price or 10
    local currencyName = currencyType == "tasks" and "Task Points" or "Nexus Coins"

    for _, member in ipairs(team) do
        local hasBalance = false
        if currencyType == "tasks" then
            local taskPoints = math.max(0, member:getStorageValue(20021))
            if taskPoints >= price then
                hasBalance = true
            end
        else
            local getPoints = db.storeQuery("SELECT `premium_points` FROM `accounts` WHERE `id` = " .. member:getAccountId())
            if getPoints then
                local points = result.getDataInt(getPoints, "premium_points")
                result.free(getPoints)
                if points >= price then
                    hasBalance = true
                end
            end
        end

        if not hasBalance then
            local msg = (member == player) and BossRoom.msg.notItem:format(price, currencyName) or BossRoom.msg.notItemTeam:format(member:getName(), price, currencyName)
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, msg)
            if member ~= player then
                member:sendTextMessage(MESSAGE_EVENT_ADVANCE, BossRoom.msg.notItem:format(price, currencyName))
            end
            player:teleportTo(fromPosition, true)
            return true
        end
    end

    -- 4. Deduct Balance and Teleport everyone
    for _, member in ipairs(team) do
        local currentTaskPoints = math.max(0, member:getStorageValue(20021))
        local currentAccPoints = 0
        
        if currencyType == "tasks" then
            member:setStorageValue(20021, currentTaskPoints - price)
            currentTaskPoints = currentTaskPoints - price
            
            local queryCoins = db.storeQuery("SELECT `premium_points` FROM `accounts` WHERE `id` = " .. member:getAccountId())
            if queryCoins then
                currentAccPoints = result.getDataInt(queryCoins, "premium_points")
                result.free(queryCoins)
            end
        else
            db.query("UPDATE `accounts` SET `premium_points` = `premium_points` - " .. price .. " WHERE `id` = " .. member:getAccountId())
            
            local queryCoins = db.storeQuery("SELECT `premium_points` FROM `accounts` WHERE `id` = " .. member:getAccountId())
            if queryCoins then
                currentAccPoints = result.getDataInt(queryCoins, "premium_points")
                result.free(queryCoins)
            end
        end
        
        -- Update UI
        local currentBossPoints = math.max(0, member:getStorageValue(20022))
        member:sendExtendedOpcode(201, json.encode({action = "points", data = {points = currentAccPoints, secondPoints = currentTaskPoints, thirdPoints = currentBossPoints}}))
        
        -- Teleport
        member:teleportTo(bossVariavel.center, true)
        member:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
        member:sendTextMessage(MESSAGE_EVENT_ADVANCE, BossRoom.msg.enterRoom:format(3, bossVariavel.killTime))
    end

    -- 5. Spawn Boss
    addEvent(function()
        local monster = Game.createMonster(bossVariavel.bossName, bossVariavel.center)
        if monster then
            BossRoom.monstros[item.actionid].bossId = monster:getId()
        end
    end, 3 * 1000)

    -- 6. Setup Room Occupancy and Kick Event
    local playerGUID = player:getGuid()
    local toTime = os.time() + bossVariavel.killTime * 60
    db.query("UPDATE `boss_room` SET `guid_player` = " .. playerGUID .. ", `time` = " .. os.time() .. ", `to_time` = " .. toTime .. " WHERE room_id = " .. item.actionid)

    addEvent(function(roomId, expTime, bossVar)
        local query = db.storeQuery("SELECT `to_time` FROM `boss_room` WHERE `room_id` = " .. roomId)
        if query then
            local currentToTime = result.getDataInt(query, "to_time")
            result.free(query)
            if currentToTime == expTime then
                local spectators = Game.getSpectators(bossVar.center, false, false, 0, bossVar.x, 0, bossVar.y)
                if spectators then
                    for _, spec in ipairs(spectators) do
                        if spec:isPlayer() then
                            spec:teleportTo(spec:getTown():getTemplePosition())
                            spec:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
                            spec:sendTextMessage(MESSAGE_EVENT_ADVANCE, BossRoom.msg.timeOver)
                        elseif spec:isMonster() then
                            spec:getPosition():sendMagicEffect(CONST_ME_POFF)
                            spec:remove()
                        end
                    end
                end
                BossRoom:setFreeRoom(roomId)
            end
        end
    end, bossVariavel.killTime * 60 * 1000, item.actionid, toTime, bossVariavel)

    return true
end
