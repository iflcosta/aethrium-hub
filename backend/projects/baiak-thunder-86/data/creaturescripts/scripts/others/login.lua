local MC_LIMIT = 4
local ignoreAccountTypes = {ACCOUNT_TYPE_GAMEMASTER, ACCOUNT_TYPE_GOD}

function onLogin(player)
    -- INSTANTANEOUS RAM LOCKOUT FOR RESET SYSTEM EXPLOITERS
    -- This uses Game storage (Engine RAM) to share data between Revscripts and Creaturescripts
    local guid = player:getGuid()
    local lockTime = Game.getStorageValue(2000000 + guid) or 0
    if lockTime > os.time() then
        return false -- Rejects login instantly, preventing any other onLogin scripts from running
    end
    -- MC Limit Check
    if not table.contains(ignoreAccountTypes, player:getAccountType()) then
        local mcCount = 0
        local playerIp = player:getIp()
        for _, onlinePlayer in ipairs(Game.getPlayers()) do
            if onlinePlayer:getIp() == playerIp then
                mcCount = mcCount + 1
            end
        end

        if mcCount > MC_LIMIT then
            return false
        end
    end

    local loginStr = "Welcome to {" .. configManager.getString(configKeys.SERVER_NAME) .. "}!"
    if player:getLastLoginSaved() <= 0 then
        loginStr = loginStr .. " Please choose your outfit."
        player:sendOutfitWindow()
    else
        if loginStr ~= "" then
            player:sendTextMessage(MESSAGE_STATUS_BLUE_LIGHT, loginStr)
        end
        loginStr = string.format("Your last visit was on {%s}.", os.date("%a %b %d %X %Y", player:getLastLoginSaved()))
    end
    player:sendTextMessage(MESSAGE_STATUS_BLUE_LIGHT, loginStr)

    -- Guild Leaders Highlight
    if configManager.getBoolean(configKeys.GUILD_LEADER_SQUARE) and player:getAccountType() < ACCOUNT_TYPE_GAMEMASTER then
        Game.guildLeaderSquare(player:getId())
    end

    -- Events
    if player:getStorageValue(STORAGEVALUE_EVENTS) >= 1 then
        player:teleportTo(player:getTown():getTemplePosition())
        player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
        player:setStorageValue(STORAGEVALUE_EVENTS, 0)
    end

    -- Upgrade System (inicializar storages se necessário)
    if player:getStorageValue(STORAGE_BONUS_HP) == -1 then
        player:setStorageValue(STORAGE_BONUS_HP, 0)
    end
    if player:getStorageValue(STORAGE_BONUS_MANA) == -1 then
        player:setStorageValue(STORAGE_BONUS_MANA, 0)
    end
    if player:getStorageValue(STORAGE_BONUS_SPEED) == -1 then
        player:setStorageValue(STORAGE_BONUS_SPEED, 0)
    end

    -- Monster Hunt
    if Game.getStorageValue(MONSTER_HUNT.storages.monster) == nil then
        player:setStorageValue(MONSTER_HUNT.storages.player, 0)
    end

    -- Mining
    if player:getStorageValue(configMining.level.storageTentativas) == -1 or player:getStorageValue(configMining.level.storageNivel) == -1 then
        player:setStorageValue(configMining.level.storageTentativas, 0) -- Attempts
        player:setStorageValue(configMining.level.storageNivel, 1) -- Level
    end

    -- PVP Balance
    if configManager.getBoolean(configKeys.PVP_BALANCE) then
        player:registerEvent("PvpBalance")
        player:registerEvent("PvpBalanceMA")
    end

    player:loadSpecialStorage()

    --[[ Promotion
    local vocation = player:getVocation()
    local promotion = vocation:getPromotion()
    if player:isPremium() then
        local value = player:getStorageValue(STORAGEVALUE_PROMOTION)
        if not promotion and value ~= 1 then
            player:setStorageValue(STORAGEVALUE_PROMOTION, 1)
        elseif value == 1 then
            player:setVocation(promotion)
        end
    elseif not promotion then
        player:setVocation(vocation:getDemotion())
    end
    --]]

    -- Potion System (Persistent)
    player:updatePotionStatus()

    -- Events
    player:registerEvent("PlayerDeath")
    player:registerEvent("PotionCheck")
    player:registerEvent("AnimationUp")
    player:registerEvent("DropLoot")
    player:registerEvent("MonsterHunt")
    player:registerEvent("AutoLoot")
    player:registerEvent("Exiva")
    player:registerEvent("Events")
    player:registerEvent("Tasks")
    player:registerEvent("SuperUP")
    player:registerEvent("GuildLevel")
    player:registerEvent("TaskSystemWindow")
    player:registerEvent("TaskSystemKill")
    player:registerEvent("HouseFurnitureModal")
    player:registerEvent("MarketPrice")
    player:registerEvent("Promotion")
    player:registerEvent("GameShop")
    player:registerEvent("TitleAdvance")
    player:registerEvent("TitleKill")
    player:registerEvent("ModalWindowHelper")
    player:registerEvent("BattlePassModal")
    player:registerEvent("TitleLogin")
    player:registerEvent("ElementalReduction")
    
    -- Titles: check automatic unlocks on login
    if Player.checkTitleUnlocks then
        player:checkTitleUnlocks()
    end
    
    -- Market Offline Delivery (Items and Gold)
    local deliveryQuery = db.storeQuery("SELECT id, item_id, amount FROM market_deliveries WHERE player_id = " .. player:getGuid())
    if deliveryQuery then
        repeat
            local deliveryId = result.getNumber(deliveryQuery, "id")
            local itId = result.getNumber(deliveryQuery, "item_id")
            local amount = result.getNumber(deliveryQuery, "amount")
            
            if itId == 0 then
                -- Gold delivery from a sold item
                player:addMoney(amount)
                player:sendTextMessage(MESSAGE_INFO_DESCR, "[Market] Você recebeu " .. amount .. " gold de uma venda no Market!")
            else
                -- Item delivery from a Buy Offer
                player:addItem(itId, amount, true)
                player:sendTextMessage(MESSAGE_INFO_DESCR, "[Market] Você recebeu " .. amount .. "x " .. ItemType(itId):getName() .. " de uma Oferta de Compra!")
            end
            db.asyncQuery("DELETE FROM market_deliveries WHERE id = " .. deliveryId)
        until not result.next(deliveryQuery)
        result.free(deliveryQuery)
    end
    
    -- Upgrade System (evento de combate será registrado pelo UpgradeSystemLogin)

	player:registerEvent("TitleKill")

	-- Titles: sync with everyone online
	if Player.syncTitle then
		player:syncTitle()
	end

	return true
end
