function onDeath(creature, corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)
    local target = creature
    if not target:isMonster() then
        return true
    end

    local bossName = target:getName()
    local bossData = nil
    
    -- Find which boss room this monster belongs to by matching name inside the room
    for id, data in pairs(BossRoom.monstros) do
        if data.bossName:lower() == bossName:lower() then
            -- Verify if the boss was killed near its supposed center
            if target:getPosition():getDistance(data.center) <= math.max(data.x, data.y) then
                bossData = data
                break
            end
        end
    end

    if not bossData or not bossData.pointsReward then
        return true
    end

    -- Setup damage map threshold
    local damageMap = target:getDamageMap()
    local totalHealth = target:getMaxHealth()
    local threshold = totalHealth * 0.03 -- 3% of boss total health required
    
    if not damageMap then
        return true
    end

    -- Process rewards
    for playerId, damageStats in pairs(damageMap) do
        local player = Player(playerId)
        local totalDamage = (type(damageStats) == "table") and damageStats.total or damageStats
        if player and totalDamage >= threshold then
            -- Verify if the player is still inside the room
            if player:getPosition():getDistance(bossData.center) <= math.max(bossData.x, bossData.y) then
                -- Give Boss Points (Storage 20022 will be our Boss Points storage)
                local currentPoints = math.max(0, player:getStorageValue(20022))
                player:setStorageValue(20022, currentPoints + bossData.pointsReward)
                
                player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You received %d Boss Points for helping defeat %s!", bossData.pointsReward, bossName))
                player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_YELLOW)
                
                -- Update OTClient Store UI (opcode 201)
                local currentTaskPoints = math.max(0, player:getStorageValue(20021))
                local accCoins = 0
                local queryCoins = db.storeQuery("SELECT `premium_points` FROM `accounts` WHERE `id` = " .. player:getAccountId())
                if queryCoins then
                    accCoins = result.getDataInt(queryCoins, "premium_points")
                    result.free(queryCoins)
                end
                
                local newBossPoints = currentPoints + bossData.pointsReward
                -- We send Boss Points as thirdPoints
                player:sendExtendedOpcode(201, json.encode({action = "points", data = {points = accCoins, secondPoints = currentTaskPoints, thirdPoints = newBossPoints}}))
            end
        end
    end

    return true
end
