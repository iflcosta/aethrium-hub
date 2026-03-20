local OPCODE_BANK = 203

local function sendBankJSON(player, data)
    player:sendExtendedOpcode(OPCODE_BANK, json.encode(data))
end

local function sendBalance(player)
    sendBankJSON(player, {
        action = "balance",
        bank = player:getBankBalance(),
        inventory = player:getMoneyTotal()
    })
end

local function bankPlayerExists(name)
    local resultId = db.storeQuery('SELECT `name` FROM `players` WHERE `name` = ' .. db.escapeString(name))
    if resultId then
        result.free(resultId)
        return true
    end
    return false
end

function processBankOpcode(player, data)
    -- PZ Restriction (Removed per user request)
    --[[
    local tile = player:getTile()
    if not tile or not tile:hasFlag(TILESTATE_PROTECTIONZONE) then
        sendBankJSON(player, {action = "msg", type = "error", msg = "Bank access requires Protection Zone (PZ).", close = true})
        return true
    end
    ]]

    local action = data.action

    if action == "init" then
        sendBalance(player)
        return true
    end

    if action == "deposit" then
        local amount = tonumber(data.amount)
        if not amount or amount <= 0 then
            sendBankJSON(player, {action = "msg", type = "error", msg = "Invalid amount."})
            return true
        end
        if player:removeMoneyTotal(amount) then
            player:setBankBalance(player:getBankBalance() + amount)
            sendBankJSON(player, {action = "msg", type = "info", msg = string.format("Deposited %d gold.", amount)})
            player:save()
        else
            sendBankJSON(player, {action = "msg", type = "error", msg = "You don't have enough money in your inventory."})
        end
        sendBalance(player)

    elseif action == "depositall" then
        local amount = player:getMoneyTotal()
        if amount > 0 and player:removeMoneyTotal(amount) then
            player:setBankBalance(player:getBankBalance() + amount)
            sendBankJSON(player, {action = "msg", type = "info", msg = string.format("Deposited %d gold.", amount)})
            player:save()
        else
            sendBankJSON(player, {action = "msg", type = "error", msg = "You don't have any money to deposit."})
        end
        sendBalance(player)

    elseif action == "withdraw" then
        local amount = tonumber(data.amount)
        if not amount or amount <= 0 then
            sendBankJSON(player, {action = "msg", type = "error", msg = "Invalid amount."})
            return true
        end
        local balance = player:getBankBalance()
        if amount <= balance then
            if player:addMoney(amount) then
                player:setBankBalance(balance - amount)
                sendBankJSON(player, {action = "msg", type = "info", msg = string.format("Withdrew %d gold.", amount)})
                player:save()
            else
                sendBankJSON(player, {action = "msg", type = "error", msg = "Not enough capacity or space to receive the money."})
            end
        else
            sendBankJSON(player, {action = "msg", type = "error", msg = "You don't have enough money in your bank."})
        end
        sendBalance(player)

    elseif action == "withdrawall" then
        local balance = player:getBankBalance()
        if balance > 0 then
            if player:addMoney(balance) then
                player:setBankBalance(0)
                sendBankJSON(player, {action = "msg", type = "info", msg = string.format("Withdrew %d gold.", balance)})
                player:save()
            else
                sendBankJSON(player, {action = "msg", type = "error", msg = "Not enough capacity or space to receive the money."})
            end
        else
            sendBankJSON(player, {action = "msg", type = "error", msg = "Your bank account is empty."})
        end
        sendBalance(player)

    elseif action == "transfer" then
        local amount = tonumber(data.amount)
        local targetName = data.target
        if not amount or amount <= 0 then
            sendBankJSON(player, {action = "msg", type = "error", msg = "Invalid amount."})
            return true
        end
        if not targetName or targetName == "" then
            sendBankJSON(player, {action = "msg", type = "error", msg = "Invalid player name."})
            return true
        end

        local balance = player:getBankBalance()
        if amount > balance then
            sendBankJSON(player, {action = "msg", type = "error", msg = "You don't have enough money in your bank."})
            sendBalance(player)
            return true
        end

        -- Check if target exists
        if not bankPlayerExists(targetName) then
            sendBankJSON(player, {action = "msg", type = "error", msg = string.format("Player '%s' does not exist.", targetName)})
            return true
        end

        if player:transferMoneyTo(targetName, amount) then
            sendBankJSON(player, {action = "msg", type = "info", msg = string.format("Transferred %d gold to %s.", amount, targetName)})
            player:save()

            -- Notify target if online
            local targetPlayer = Player(targetName)
            if targetPlayer then
                targetPlayer:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You received %d gold from %s.", amount, player:getName()))
                targetPlayer:save()
            end
        else
            sendBankJSON(player, {action = "msg", type = "error", msg = "Transfer failed."})
        end
        sendBalance(player)
    end
end
