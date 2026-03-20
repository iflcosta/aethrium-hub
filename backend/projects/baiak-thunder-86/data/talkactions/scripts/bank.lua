function playerExists(name)
    local resultId = db.storeQuery('SELECT `name` FROM `players` WHERE `name` = ' .. db.escapeString(name))
    if resultId then
        result.free(resultId)
        return true
    end
    return false
end

function Player.deposit(self, amount)
    if not self:removeMoneyTotal(amount) then
        self:sendCancelMessage("[Bank System] You don't have money with you.")
        return false
    end
    self:setBankBalance(self:getBankBalance() + amount)
    return true
end

function Player.withdraw(self, amount)
    local balance = self:getBankBalance()
    if amount > balance or not self:addMoney(amount) then
        self:sendCancelMessage("[Bank System] You don't have enough money in your bank account.")
        return false
    end
    self:setBankBalance(balance - amount)
    return true
end

function Player.depositMoney(self, amount)
    if not self:removeMoneyTotal(amount) then
        return false
    end
    self:setBankBalance(self:getBankBalance() + amount)
    return true
end

function onSay(player, words, param)
    print(">> !bank triggered. Param: '" .. tostring(param) .. "'")
    local split = param:split(",")
    
    local balance = player:getBankBalance()
    if split[1] == nil or split[1] == "" then
        print(">> Sending extended opcode 203 to client")
        local success, err = pcall(function()
            player:sendExtendedOpcode(203, json.encode({action = "open"}))
        end)
        if not success then
            print(">> Error sending bank opcode: " .. tostring(err))
        end
        return false
    end
    
    --------------------------- Balance ---------------------------
    if split[1] == 'balance' then
        player:sendCancelMessage("[Bank System] Your account balance is " .. balance .. ".")
    --------------------------- Depositall ---------------------------
    elseif split[1] == 'depositall' then
        local amount = player:getMoneyTotal()
        local amount = math.abs(amount)
        if amount > 0 and amount == player:getMoneyTotal() then
            player:deposit(amount)
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[Bank System] You have added " .. amount .. " to your account, you can withdraw your money anytime.\nYour account balance is " .. player:getBankBalance() .. ".")
            player:save()
        else
            player:sendCancelMessage("[Bank System] You don't have enough money to deposit.")
        end
--------------------------- Deposit ---------------------------
    elseif split[1] == 'deposit' then
        local amount = tonumber(split[2])
        if not amount then
            player:sendCancelMessage("[Bank System] You need to specify the amount of money to deposit.")
            return false
        end
        local amount = math.abs(amount)
        if amount > 0 and amount <= player:getMoneyTotal() then
            player:deposit(amount)
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[Bank System] You have added " .. amount .. " to your account, you can withdraw your money anytime.\nYour account balance is " .. player:getBankBalance() .. ".")
            player:save()
        else
            player:sendCancelMessage("[Bank System] You don't have enough money to deposit.")
        end
    --------------------------- Withdraw all ---------------------------
    elseif split[1] == 'withdrawall' then
        local amount = player:getBankBalance()
        local amount = math.abs(amount)
        if amount > 0 and amount <= player:getBankBalance() then
            player:withdraw(amount)
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[Bank System] Here is all your money in your account. You can deposit your money anytime.\nYour account balance is " .. player:getBankBalance() .. ".")
            player:save()
        else
            player:sendCancelMessage("[Bank System] You don't have enough money in your bank account.")
        end
    --------------------------- Withdraw ---------------------------
    elseif split[1] == 'withdraw' then
        local amount = tonumber(split[2])
        if not amount then
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[Bank System] You need to specify the amount of money to withdraw.")
            return false
        end
        local amount = math.abs(amount)
        if amount > 0 and amount <= player:getBankBalance() then
            player:withdraw(amount)
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[Bank System] Here is " .. amount .. " gold coins from your account, you can deposit your money anytime.\nYour account balance is " .. player:getBankBalance() .. ".")
            player:save()
        else
            player:sendCancelMessage("[Bank System] You don't have enough money in your bank account.")
        end
    --------------------------- Transfer All ---------------------------
    elseif split[1] == 'transferall' then
        if split[2] == nil or split[2] == "" then
            player:sendCancelMessage("[Bank System] You need to specify the player's name.")
            return false
        end
        local amount = player:getBankBalance()
        local getPlayer = Player(split[2])
        if amount <= 0 then
            player:sendCancelMessage("[Bank System] You need to have more than 0 gold coins in your bank account.")
            return false
        end
        if getPlayer then
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[Bank System] You successfully transferred " .. amount .. " to " .. split[2] .. ".")
            player:transferMoneyTo(split[2], amount)
            player:save()
        else
            if not playerExists(split[2]) then
                player:sendCancelMessage("[Bank System] A player with the name " .. split[2] .. " does not exist.")
                return false
            end
            if playerExists(split[2]) and player:transferMoneyTo(split[2], amount) then
                player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[Bank System] You successfully transferred " .. amount .. " to " .. split[2] .. ".")
                player:save()
            end
        end
    --------------------------- Transfer ---------------------------
    elseif split[1] == 'transfer' then
        local data = param
        local s = data:split(",")
        local bankTotal = player:getBankBalance()
        if s[2] == nil then
            player:sendCancelMessage("[Bank System] You need to specify the amount of money.")
            return false
        else
            if s[3] == nil then
                player:sendCancelMessage("[Bank System] You need to specify the player's name.")
                return false
            end
        end
        local a = tonumber(s[2])
        local amount = math.abs(a)
        local getPlayer = Player(s[3])
        if amount <= bankTotal then
            if getPlayer then
                player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[Bank System] You successfully transferred " .. s[2] .. " to " .. s[3] .. ".")
                player:transferMoneyTo(s[3], amount)
                player:save()
            else
                if not playerExists(s[3]) then
                    player:sendCancelMessage("[Bank System] A player with the name " .. s[3] .. " does not exist.")
                    return false
                end
                if playerExists(s[3]) and player:transferMoneyTo(s[3], amount) then
                    player:sendCancelMessage("[Bank System] You successfully transferred " .. s[2] .. " to " .. s[3] .. ".")
                    player:save()
                end
            end
        else
            player:sendCancelMessage("[Bank System] You don't have that much money.")
            return false
        end
    else
        player:sendCancelMessage("[Bank System] Invalid parameter.")
    end
    return false
end
