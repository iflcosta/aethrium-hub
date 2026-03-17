--[[
    !hunted add, Player, item, item name or id
    !hunted add, Player, points, 10
    !hunted add, Player, gold, 10000000
    !hunted delete, Player
    !hunted check, Player
--]]

local HuntedSystem = {
    messages = {
        prefix = "[Hunted System] ",
        notParam = "Learn the system commands on our website.",
        levelMin = "You need to be at least level %d to use this system.",
        enoughParam = "Missing parameters.",
        noComand = "This command does not exist.",
        noTarget = "This player does not exist or is not online.",
        noType = "You need to inform the type of payment (gold, points, or item).",
        noQnt = "You need to inform %s.",
        notNumber = "You need to inform only numbers.",
        noItem = "This item does not exist.",
        hunted = "The player %s is now hunted.",
        isHunted = "The player is on the hunted list.",
        notHunted = "The player is not on the hunted list.",
        noGold = "You do not have enough money.",
        target = "Your death has been put in the game. Good luck.",
        sameId = "You cannot put yourself on the hunted list.",
        removedList = "The player has been removed from the hunted list.",
        maxGolds = "The maximum you can inform is %s %s.",
        blockItem = "This item cannot be provided.",
        limit = "You cannot put more players on the list. Your limit is %d players."
    },
    maxGold = 5000,
    maxPoints = 50,
    minLevel = 1,
    storageLimit = {
        value = 52371,
        free = 3,
        premium = 5,
    },
    blockItems = {2160},
}

function checkHunteds(targetGuid)
    local resultId = db.storeQuery(string.format('SELECT * FROM `hunted_system` WHERE `targetGuid` = %d', targetGuid))
    if not resultId then
        return false
    end
    local playerGuid = result.getString(resultId, "playerGuid")
    local targetGuid = result.getString(resultId, "targetGuid")
    local type = result.getString(resultId, "type")
    local count = result.getDataLong(resultId, "count")
    result.free(resultId)
    return {playerGuid = playerGuid, targetGuid = targetGuid, type = type, count = count}
end

local hunted = TalkAction("!hunted")

function hunted.onSay(player, words, param)
    if not player:getStorageValue(HuntedSystem.storageLimit.value) or player:getStorageValue(HuntedSystem.storageLimit.value) == -1 then
        player:setStorageValue(HuntedSystem.storageLimit.value, 0)
    end

    if player:getLevel() < HuntedSystem.minLevel then
        player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.levelMin:format(HuntedSystem.minLevel))
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    if not param or param == "" then
        player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.notParam)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    param = param:lower()
    local split = param:splitTrimmed(",")
    local command = split[1]
    local target = split[2]
    local type = split[3]
    local amount = split[4]

    if not command then
        player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.enoughParam)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    elseif not target then
        player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.enoughParam)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    if command == "add" then
        if not type or not amount then
            player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.enoughParam)
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
            return false
        end

        if player:isPremium() and player:getStorageValue(HuntedSystem.storageLimit.value) >= HuntedSystem.storageLimit.premium then
            player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.limit:format(HuntedSystem.storageLimit.premium))
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
            return false
        elseif not player:isPremium() and player:getStorageValue(HuntedSystem.storageLimit.value) >= HuntedSystem.storageLimit.free then
            player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.limit:format(HuntedSystem.storageLimit.free))
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
            return false
        end

        target = Player(target)

        if not target then
            player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.noTarget)
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
            return false
        end

        if player:getId() == target:getId() then
            player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.sameId)
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
            return false
        end

        local search = checkHunteds(target:getGuid())

        if search and tonumber(search.targetGuid) == tonumber(target:getGuid()) then
            player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.isHunted)
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
            return false
        end

        if type == "item" then
            if not amount then
                player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.noQnt:format("the item name or its id"))
                player:getPosition():sendMagicEffect(CONST_ME_POFF)
                return false
            end

            amount = tonumber(amount) or tostring(amount)

            item = player:getItemById(amount, true)
            if not item then
                player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.noItem)
                player:getPosition():sendMagicEffect(CONST_ME_POFF)
                return false
            end

            itemInfo = ItemType(item:getId())

            if isInArray(HuntedSystem.blockItems, item:getId()) then
                player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.blockItem)
                player:getPosition():sendMagicEffect(CONST_ME_POFF)
                return false
            end

            if item:remove() then
                db.query("INSERT INTO `hunted_system` (`playerGuid`, `targetGuid`, `type`, `count`) VALUES ('".. player:getGuid().. "', '".. target:getGuid() .."', '".. type .."', '".. item:getId() .. "')")
                player:getPosition():sendMagicEffect(14)
                target:getPosition():sendMagicEffect(6)
                player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.hunted:format(target:getName()))
                target:sendTextMessage(MESSAGE_EVENT_ADVANCE, HuntedSystem.messages.prefix .. HuntedSystem.messages.target)
                return false
            end

        elseif type == "gold" then

            if not amount then
                player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.noQnt:format("the amount of gold"))
                player:getPosition():sendMagicEffect(CONST_ME_POFF)
                return false
            end

            if not tonumber(amount) then
                player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.notNumber)
                player:getPosition():sendMagicEffect(CONST_ME_POFF)
                return false
            end

            if tonumber(amount) > HuntedSystem.maxGold then
                player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.maxGolds:format(HuntedSystem.maxGold, "golds"))
                player:getPosition():sendMagicEffect(CONST_ME_POFF)
                return false
            end

            if player:getMoney() < tonumber(amount) then
                player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.noGold)
                player:getPosition():sendMagicEffect(CONST_ME_POFF)
                return false
            end

            if player:removeMoney(tonumber(amount)) then
                db.query("INSERT INTO `hunted_system` (`playerGuid`, `targetGuid`, `type`, `count`) VALUES ('".. player:getGuid().. "', '".. target:getGuid() .."', '".. type .."', '".. tonumber(amount).. "')")
                player:getPosition():sendMagicEffect(14)
                target:getPosition():sendMagicEffect(6)
                player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.hunted:format(target:getName()))
                target:sendTextMessage(MESSAGE_EVENT_ADVANCE, HuntedSystem.messages.prefix .. HuntedSystem.messages.target)
                return false
            end

        elseif type == "points" then
            if not amount then
                player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.noQnt:format("the amount of points"))
                player:getPosition():sendMagicEffect(CONST_ME_POFF)
                return false
            end

            if not tonumber(amount) then
                player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.notNumber)
                player:getPosition():sendMagicEffect(CONST_ME_POFF)
                return false
            end

            if tonumber(amount) > HuntedSystem.maxPoints then
                player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.maxGolds:format(HuntedSystem.maxPoints, "points"))
                player:getPosition():sendMagicEffect(CONST_ME_POFF)
                return false
            end

            if player:removePremiumPoints(tonumber(amount)) then
                db.query("INSERT INTO `hunted_system` (`playerGuid`, `targetGuid`, `type`, `count`) VALUES ('".. player:getGuid().. "', '".. target:getGuid() .."', '".. type .."', '".. tonumber(amount).. "')")
                player:getPosition():sendMagicEffect(14)
                target:getPosition():sendMagicEffect(6)
                player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.hunted:format(target:getName()))
                target:sendTextMessage(MESSAGE_EVENT_ADVANCE, HuntedSystem.messages.prefix .. HuntedSystem.messages.target)
                return false
            end
        end
    elseif command == "delete" then
        targetPlayer = Player(target)
        targetPlayerGuid = targetPlayer:getGuid()
        
        if not targetPlayer then
            targetPlayer = Player(target, true)
                
            if not targetPlayer then
                return false
            end

            targetPlayerGuid = targetPlayer:getGuid()
            targetPlayer:delete()
        end

        local table = checkHunteds(targetPlayerGuid)

        if table then
            if tonumber(table.playerGuid) == tonumber(player:getGuid()) and targetPlayerGuid == tonumber(table.targetGuid) then
                if table.type == "item" then
                    sendMailbox(player:getId(), table.count, 1)
                elseif table.type == "gold" then
                    player:addMoney(tonumber(table.count))
                elseif table.type == "points" then
                    player:addPremiumPoints(tonumber(table.count))
                end
                db.query(string.format("DELETE FROM `hunted_system` WHERE playerGuid = %d AND targetGuid = %d", player:getGuid(), targetPlayerGuid))
                player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.removedList)
                player:getPosition():sendMagicEffect(30)
                return false
            end
        end
    elseif command == "check" then
        targetPlayer = Player(target)
        if targetPlayer then
            targetPlayerGuid = targetPlayer:getGuid()
        end
            
        if not targetPlayer then
            targetPlayer = Player(target, true)
                
            if not targetPlayer then
                return false
            end

            targetPlayerGuid = targetPlayer:getGuid()
            targetPlayer:delete()
        end

        if not checkHunteds(targetPlayerGuid) then
            player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.notHunted)
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
            return false
        end

        player:sendCancelMessage(HuntedSystem.messages.prefix .. HuntedSystem.messages.isHunted)
        player:getPosition():sendMagicEffect(6)
    end

    return false
end

hunted:separator(" ")
hunted:register()
