function onStepIn(creature, item, position, fromPosition)
    local player = creature:getPlayer()
    if not player then return false end

    local superUpVariavel = SUPERUP.areas[item.actionid]
    local tempo = superUpVariavel and (superUpVariavel.time + 60) or (SUPERUP.setTime * 3600 + 60)
    if not superUpVariavel then
        player:teleportTo(fromPosition, true)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return true
    end

    if player:getStorageValue(STORAGEVALUE_SUPERUP_INDEX) == item.actionid then
        local reentryCount = player:getStorageValue(STORAGEVALUE_SUPERUP_REENTRY)
        local currencyType = superUpVariavel.currency or "coins"
        local price = superUpVariavel.price or SUPERUP.nexusCoinCost
        local reentryPrice = math.ceil(price * 0.25)
        local currencyName = currencyType == "tasks" and "Task Points" or "Nexus Coins"

        -- Primeira re-entrada é grátis (count se torna 1)
        if reentryCount <= 0 then
            player:setStorageValue(STORAGEVALUE_SUPERUP_REENTRY, 1)
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, SUPERUP.msg.reentradaFree)
            player:teleportTo(superUpVariavel.destination or superUpVariavel.entrada, true)
            player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
            return true
        end

        -- A partir da segunda, cobra 25%
        local hasBalance = false
        if currencyType == "tasks" then
            local taskPoints = math.max(0, player:getStorageValue(20021))
            if taskPoints >= reentryPrice then
                local newTaskPoints = taskPoints - reentryPrice
                player:setStorageValue(20021, newTaskPoints)
                
                local accCoins = 0
                local queryCoins = db.storeQuery("SELECT `premium_points` FROM `accounts` WHERE `id` = " .. player:getAccountId())
                if queryCoins then
                    accCoins = result.getDataInt(queryCoins, "premium_points")
                    result.free(queryCoins)
                end
                local bossPoints = math.max(0, player:getStorageValue(20022))
                player:sendExtendedOpcode(201, json.encode({action = "points", data = {points = accCoins, secondPoints = newTaskPoints, thirdPoints = bossPoints}}))
                
                hasBalance = true
            end
        else
            local queryCoins = db.storeQuery("SELECT `premium_points` FROM `accounts` WHERE `id` = " .. player:getAccountId())
            if queryCoins then
                local points = result.getDataInt(queryCoins, "premium_points")
                result.free(queryCoins)
                if points >= reentryPrice then
                    local newPoints = points - reentryPrice
                    db.query("UPDATE `accounts` SET `premium_points` = " .. newPoints .. " WHERE `id` = " .. player:getAccountId())
                    
                    local currentTaskPoints = math.max(0, player:getStorageValue(20021))
                    local bossPoints = math.max(0, player:getStorageValue(20022))
                    player:sendExtendedOpcode(201, json.encode({action = "points", data = {points = newPoints, secondPoints = currentTaskPoints, thirdPoints = bossPoints}}))
                    
                    hasBalance = true
                end
            end
        end

        if hasBalance then
            player:setStorageValue(STORAGEVALUE_SUPERUP_REENTRY, reentryCount + 1)
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format(SUPERUP.msg.reentradaPaga, reentryPrice .. " " .. currencyName))
            player:teleportTo(superUpVariavel.destination or superUpVariavel.entrada, true)
            player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
        else
            player:sendCancelMessage("Voce nao tem " .. reentryPrice .. " " .. currencyName .. " para re-entrar")
            player:teleportTo(fromPosition, true)
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
        end
        return true
    end

    local value = SUPERUP:getCave(item.actionid) or {dono = 0, tempo = 0}
    if value.dono > 0 and value.tempo > 0 then
        player:sendCancelMessage(string.format(SUPERUP.msg.naoDisponivel, os.date("%H:%M", value.tempo)))
        player:teleportTo(fromPosition, true)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
    elseif player:getStorageValue(STORAGEVALUE_SUPERUP_INDEX) >= 1 then
        player:sendCancelMessage(SUPERUP.msg.possuiCave)
        player:teleportTo(fromPosition, true)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
    else
        local currencyType = superUpVariavel.currency or "coins"
        local price = superUpVariavel.price or SUPERUP.nexusCoinCost
        local hasBalance = false

        if currencyType == "tasks" then
            local taskPoints = math.max(0, player:getStorageValue(20021))
            if taskPoints >= price then
                player:setStorageValue(20021, taskPoints - price)
                
                local accCoins = 0
                local queryCoins = db.storeQuery("SELECT `premium_points` FROM `accounts` WHERE `id` = " .. player:getAccountId())
                if queryCoins then
                    accCoins = result.getDataInt(queryCoins, "premium_points")
                    result.free(queryCoins)
                end
                local bossPoints = math.max(0, player:getStorageValue(20022))
                player:sendExtendedOpcode(201, json.encode({action = "points", data = {points = accCoins, secondPoints = taskPoints - price, thirdPoints = bossPoints}}))
                
                hasBalance = true
            end
        else
            local getPoints = db.storeQuery("SELECT `premium_points` FROM `accounts` WHERE `id` = " .. player:getAccountId())
            local points = 0
            if getPoints then
                points = result.getDataInt(getPoints, "premium_points")
                result.free(getPoints)
            end

            if points >= price then
                if price > 0 then
                    db.query("UPDATE `accounts` SET `premium_points` = `premium_points` - " .. price .. " WHERE `id` = " .. player:getAccountId())
                end
                
                -- Envia a atualização em tempo real para a interface (Store / UI do Client)
                local updatePoints = points - price
                local currentTaskPoints = math.max(0, player:getStorageValue(20021))
                local bossPoints = math.max(0, player:getStorageValue(20022))
                player:sendExtendedOpcode(201, json.encode({action = "points", data = {points = updatePoints, secondPoints = currentTaskPoints, thirdPoints = bossPoints}}))
                
                hasBalance = true
            end
        end

        if hasBalance then
            player:sendCancelMessage(string.format(SUPERUP.msg.disponivel, tempo / 3600, (tempo / 3600) > 1 and "horas" or "hora"))
            player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
            player:setStorageValue(STORAGEVALUE_SUPERUP_TEMPO, (os.time() + tempo))
            player:setStorageValue(STORAGEVALUE_SUPERUP_INDEX, item.actionid)
            db.query(string.format("UPDATE exclusive_hunts SET `guid_player` = %d, `time` = %d, `to_time` = %d WHERE `hunt_id` = %d",
                player:getGuid(), os.time(), (os.time() + tempo), item.actionid))
            -- Teleportar para a entrada da cave
            player:teleportTo(superUpVariavel.destination or superUpVariavel.entrada, true)
        else
            local currencyName = currencyType == "tasks" and "Task Points" or "Nexus Coins"
            player:sendCancelMessage(string.format(SUPERUP.msg.naoMoeda, price .. " " .. currencyName))
            player:teleportTo(fromPosition, true)
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
        end
    end
    return true
end
