function Player:onLook(thing, position, distance)
    local minDist = 5

    if thing:isCreature() and thing:isNpc() and distance <= minDist then
        self:say("hi", TALKTYPE_PRIVATE_PN, false, thing)
        self:say("trade", TALKTYPE_PRIVATE_PN, false, thing)
        return false
    end

    local description = thing:getDescription(distance)

    if thing:isPlayer() then
        -- Mining Level
        description = description .. "\nMining Level: " .. configMining.level[thing:getStorageValue(configMining.level.storageNivel)].name .. "."
        
        -- Reset Count
        local resets = math.max(0, thing:getStorageValue(50400))
        if resets == 1 then
            description = description .. "\n[Reset: 1]"
        elseif resets > 1 then
            description = description .. "\n[Resets: " .. resets .. "]"
        end
    end

    if thing:isItem() and thing:getCustomAttribute("premiumPoints") then
        description = description .. "\nThis item is worth " .. thing:getCustomAttribute("premiumPoints") .. " pontos."
    end

    -- Block removed to prevent duplication. Admin details are appended by default_onLook and default_onLookInBattleList.



    if thing:isPlayer() and not self:getGroup():getAccess() then
        thing:sendTextMessage(MESSAGE_STATUS_DEFAULT, self:getName() .. ' is looking at you.')
    end

    if hasEventCallback(EVENT_CALLBACK_ONLOOK) then
        description = EventCallback(EVENT_CALLBACK_ONLOOK, self, thing, position, distance, description)
    end

    self:sendTextMessage(MESSAGE_INFO_DESCR, description)
end

function Player:onLookInBattleList(creature, distance)
    local description = ""
    local minDist = 5
    
    if creature:isCreature() and creature:isNpc() and distance <= minDist then
        self:say("hi", TALKTYPE_PRIVATE_PN, false, creature)
        self:say("trade", TALKTYPE_PRIVATE_PN, false, creature)
        return false
    end
    
    description = "You see " .. creature:getDescription(distance)
    
    -- Block removed to prevent duplication. Admin details are appended by default_onLookInBattleList.
    
    if creature:isPlayer() then
        local resets = math.max(0, creature:getStorageValue(50400))
        if resets == 1 then
            description = description .. "\n[Reset: 1]"
        elseif resets > 1 then
            description = description .. "\n[Resets: " .. resets .. "]"
        end
    end
    
    if creature:isPlayer() and not self:getGroup():getAccess() then
        creature:sendTextMessage(MESSAGE_STATUS_DEFAULT, self:getName() .. ' is looking at you.')
    end
    
    if hasEventCallback(EVENT_CALLBACK_ONLOOKINBATTLELIST) then
        description = EventCallback(EVENT_CALLBACK_ONLOOKINBATTLELIST, self, creature, distance, description)
    end
    
    self:sendTextMessage(MESSAGE_INFO_DESCR, description)
end



function Player:onLookInTrade(partner, item, distance)
    local description = "You see " .. item:getDescription(distance)
    
    if item:getCustomAttribute("premiumPoints") then
        description = description .. "\nThis item is worth " .. item:getCustomAttribute("premiumPoints") .." points."
    end
    
    if hasEventCallback(EVENT_CALLBACK_ONLOOKINTRADE) then
        description = EventCallback(EVENT_CALLBACK_ONLOOKINTRADE, self, partner, item, distance, description)
    end
    
    self:sendTextMessage(MESSAGE_INFO_DESCR, description)
end


function Player:onLookInShop(itemType, count, description)
	local description = "You see " .. description
	if hasEventCallback(EVENT_CALLBACK_ONLOOKINSHOP) then
		description = EventCallback(EVENT_CALLBACK_ONLOOKINSHOP, self, itemType, count, description)
	end
	self:sendTextMessage(MESSAGE_INFO_DESCR, description)
end

function Player:onMoveItem(item, count, fromPosition, toPosition, fromCylinder, toCylinder)
    local positionPlayer = self:getPosition()
    local blockPosition = {Position(951, 1208, 6), Position(951, 1209, 6), Position(951, 1210, 6), Position(952, 1209, 6)}
    local depotIds = {2589, 2590, 2591}
    local positionUnderDepot = {
        Position(positionPlayer.x, positionPlayer.y + 1, positionPlayer.z),
        Position(positionPlayer.x + 1, positionPlayer.y, positionPlayer.z),
        Position(positionPlayer.x - 1, positionPlayer.y, positionPlayer.z),
        Position(positionPlayer.x, positionPlayer.y - 1, positionPlayer.z),
    }

    local depotLocked = false
    local antiTrash = true
    local antiTheft = true

    -- RESTRIÇÃO TRAINING STATUE (Movable apenas dentro de casas)
    if item:getId() == 24682 then
        local fromTile = Tile(fromPosition)
        local toTile = Tile(toPosition)

        -- Se está sendo movida de um piso de casa
        if fromTile and fromTile:hasFlag(TILESTATE_HOUSE) then
            -- Só permite se o destino também for um piso de casa
            if not toTile or not toTile:hasFlag(TILESTATE_HOUSE) then
                self:sendCancelMessage("You can only move this statue within a house.")
                return false
            end

            -- Garante que é a mesma casa (não permite mover entre casas vizinhas)
            if fromTile:getHouse() ~= toTile:getHouse() then
                self:sendCancelMessage("You can only move this statue within the same house.")
                return false
            end
        end
    end

    if antiTrash then
        local tile = Tile(toPosition)
        if tile and tile:hasFlag(TILESTATE_HOUSE) then
            local house = tile:getHouse()
            if house then
                local accessList = house:getAccessList()
                local playerName = self:getName():lower()
                if house ~= self:getHouse() and (playerName ~= accessList[GUEST_LIST]:lower() or playerName ~= accessList[SUBOWNER_LIST]:lower()) then
                    self:sendTextMessage(MESSAGE_STATUS_SMALL, "You can't drop items into houses of players you're not invited to.")
                    return false
                end
            end
        end
    end

    -- ANTI-PUSH STACKADO (Bloqueia jogar lixo embaixo de jogadores)
    -- Esses sao exclusivamente items considerados lixo (golds, vials, worms). Itens de valor NUNCA estao nessa lista.
    local trashItems = {2148, 2152, 2160, 3976, 2064, 2063, 2062, 2061, 2060, 2059, 2058, 2057, 2056, 2055, 2054, 2053, 2052, 2051, 2050, 2049, 2048, 2047, 2046, 2045, 2044, 2043, 2042, 2041, 2040, 2039, 2038, 2037, 7618, 7620, 7588, 7589, 7590, 7591, 8472, 8473, 8474, 283, 284, 285}
    if toCylinder and toCylinder:isTile() then
        local tile = Tile(toPosition)
        if tile and tile:getCreatureCount() > 0 then
            for i = 1, tile:getThingCount() do
                local thing = tile:getThing(i)
                if thing and thing:isPlayer() then
                    if isInArray(trashItems, item:getId()) then
                        -- Em vez de deletar, nos BLOQUEAMOS a acao (Bounce Back)
                        self:sendCancelMessage("Anti-Push: Voce nao pode jogar lixo embaixo de jogadores.")
                        self:getPosition():sendMagicEffect(CONST_ME_POFF)
                        return false
                    end
                end
            end
        end
    end

    if antiTheft then
        local tile = Tile(fromPosition)
        if tile and tile:hasFlag(TILESTATE_HOUSE) then
            local house = tile:getHouse()
            if house then
                if house ~= self:getHouse() and self:getName():lower() ~= house:getAccessList()[SUBOWNER_LIST]:lower() then
                    self:sendTextMessage(MESSAGE_STATUS_SMALL, "You can't move items from houses you're only a guest in.")
                    return false
                end
            end
        end
    end

    -- local depotBlock = Tile(toPosition):getTopDownItem():getId()
    -- if depotLocked and isInArray(depotIds, depotBlock) and isInArray(positionUnderDepot, fromPosition) then
    --     self:sendCancelMessage("You can't drop items into a depot.")
    --     self:getPosition():sendMagicEffect(CONST_ME_POFF)
    --     return false
    -- end

    if isInArray(blockPosition, toPosition) then
        self:sendCancelMessage("You can't drop an item into this position.")
        self:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    -- Quiver Content Restriction refinement
    local isToQuiver = false
    local destinationItem = nil

    -- 1. If moving to an equipment slot, check the item already there
    if toPosition.x == CONTAINER_POSITION and toPosition.y <= 13 then
        destinationItem = self:getSlotItem(toPosition.y)
    end

    -- 2. If destinationItem is not found (normal move into container), check toCylinder
    if not destinationItem and toCylinder and toCylinder:isItem() then
        destinationItem = toCylinder
    end

    -- 3. Traverse parents to see if we are inside a quiver
    if destinationItem and destinationItem:isItem() then
        local temp = destinationItem
        while temp and temp:isItem() and not temp:isPlayer() do
            local name = temp:getName():lower()
            if name:find("quiver") then
                isToQuiver = true
                break
            end
            local parent = temp:getParent()
            if parent and parent:isItem() and not parent:isPlayer() then
                temp = parent
            else
                break
            end
        end
    end

    if isToQuiver then
        local it = item:getType()
        local ammoType = it:getAmmoType()
        
        -- Fallback for constants (BOLT=1, ARROW=2 in many engines)
        local arrowType = AMMO_ARROW or 2
        local boltType = AMMO_BOLT or 1
        
        -- Block if it's not specifically Arrow or Bolt
        if ammoType ~= arrowType and ammoType ~= boltType then
            self:sendCancelMessage("You can only put arrows and bolts in a quiver.")
            return false
        end
    end

    if hasEventCallback(EVENT_CALLBACK_ONMOVEITEM) then
        return EventCallback(EVENT_CALLBACK_ONMOVEITEM, self, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
    end

    return true
end


function Player:onItemMoved(item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if hasEventCallback(EVENT_CALLBACK_ONITEMMOVED) then
		EventCallback(EVENT_CALLBACK_ONITEMMOVED, self, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	end
end

function Player:onMoveCreature(creature, fromPosition, toPosition)
	if hasEventCallback(EVENT_CALLBACK_ONMOVECREATURE) then
		return EventCallback(EVENT_CALLBACK_ONMOVECREATURE, self, creature, fromPosition, toPosition)
	end
	return true
end

function Player:onReportRuleViolation(targetName, reportType, reportReason, comment, translation)
	if hasEventCallback(EVENT_CALLBACK_ONREPORTRULEVIOLATION) then
		EventCallback(EVENT_CALLBACK_ONREPORTRULEVIOLATION, self, targetName, reportType, reportReason, comment, translation)
	end
end

function Player:onReportBug(message, position, category)
	if hasEventCallback(EVENT_CALLBACK_ONREPORTBUG) then
		return EventCallback(EVENT_CALLBACK_ONREPORTBUG, self, message, position, category)
	end
	return true
end

function Player:onTurn(direction)
	if hasEventCallback(EVENT_CALLBACK_ONTURN) then
		return EventCallback(EVENT_CALLBACK_ONTURN, self, direction)
	end
	return true
end

function Player:onTradeRequest(target, item)
    local blockList = {7879, 7878, 7882, 8858, 7872, 12644, 8908, 2523} -- IDs

    if isInArray(blockList, item:getId()) then
        self:sendCancelMessage("You cannot trade this item.")
        self:getPosition():sendMagicEffect(CONST_ME_POFF)
        return false
    end

    if hasEventCallback(EVENT_CALLBACK_ONTRADEREQUEST) then
        return EventCallback(EVENT_CALLBACK_ONTRADEREQUEST, self, target, item)
    end

    return true
end


function Player:onTradeAccept(target, item, targetItem)
	if hasEventCallback(EVENT_CALLBACK_ONTRADEACCEPT) then
		return EventCallback(EVENT_CALLBACK_ONTRADEACCEPT, self, target, item, targetItem)
	end
	return true
end

function Player:onTradeCompleted(target, item, targetItem, isSuccess)
	if hasEventCallback(EVENT_CALLBACK_ONTRADECOMPLETED) then
		EventCallback(EVENT_CALLBACK_ONTRADECOMPLETED, self, target, item, targetItem, isSuccess)
	end
end

local soulCondition = Condition(CONDITION_SOUL, CONDITIONID_DEFAULT)
soulCondition:setTicks(4 * 60 * 1000)
soulCondition:setParameter(CONDITION_PARAM_SOULGAIN, 1)

local function useStamina(player)
	local staminaMinutes = player:getStamina()
	if staminaMinutes == 0 then
		return
	end

	local playerId = player:getId()
	if not nextUseStaminaTime[playerId] then
		nextUseStaminaTime[playerId] = 0
	end

	local currentTime = os.time()
	local timePassed = currentTime - nextUseStaminaTime[playerId]
	if timePassed <= 0 then
		return
	end

	if timePassed > 60 then
		if staminaMinutes > 2 then
			staminaMinutes = staminaMinutes - 2
		else
			staminaMinutes = 0
		end
		nextUseStaminaTime[playerId] = currentTime + 120
	else
		staminaMinutes = staminaMinutes - 1
		nextUseStaminaTime[playerId] = currentTime + 60
	end
	player:setStamina(staminaMinutes)
end

function Player:onGainExperience(source, exp, rawExp)
    if not source or source:isPlayer() then
        return exp
    end

    -- 1. Soul Regeneration
    local vocation = self:getVocation()
    if self:getSoul() < vocation:getMaxSoul() and exp >= self:getLevel() then
        soulCondition:setParameter(CONDITION_PARAM_SOULTICKS, vocation:getSoulGainTicks() * 1000)
        self:addCondition(soulCondition)
    end

    -- 2. Experience Stage
    exp = exp * Game.getExperienceStage(self:getLevel())

    -- 3. Stamina Modifier
    if configManager.getBoolean(configKeys.STAMINA_SYSTEM) then
        useStamina(self)
        local staminaMinutes = self:getStamina()
        if staminaMinutes > 2400 and self:isPremium() then
            exp = exp * 1.5
        elseif staminaMinutes <= 840 then
            exp = exp * 0.5
        end
    end

    -- [[ INICIO DA INTEGRAÇÃO VIP AUTOMÁTICA ]] --
    -- Verifica se a tabela VIP_CONFIG existe (carregada do vip_system.lua)
    if VIP_CONFIG then
        local vipTier = self:getStorageValue(VIP_CONFIG.STORAGE_VIP_TIER)
        local vipEnd = self:getStorageValue(VIP_CONFIG.STORAGE_VIP_END)

        -- Verifica se tem VIP e se o tempo é válido
        if vipTier > 0 and vipEnd > os.time() then
            -- Busca a configuração direto da tabela do vip_system.lua
            local tierInfo = VIP_CONFIG.tiers[vipTier]
            
            if tierInfo and tierInfo.xpBonus then
                -- Converte a porcentagem (ex: 30) para multiplicador (ex: 1.30)
                local multiplier = 1 + (tierInfo.xpBonus / 100)
                exp = exp * multiplier
            end
        end
    end
    -- [[ FIM DA INTEGRAÇÃO VIP AUTOMÁTICA ]] --

    -- 4. Castle 24H Guild
    local xpCastle = 0
    if self:getGuild() and self:getGuild():getId() == CASTLE24H:getGuildIdFromCastle() then
        xpCastle = exp * 0.2 -- +20% XP
    end

    -- 5. XP Potion (Persistent check)
    self:checkExpPotion()
    local xpPotion = 0
    if self:getStorageValue(STORAGEVALUE_POTIONXP_TEMPO) > os.time() then
        local potion = expPotion[self:getStorageValue(STORAGEVALUE_POTIONXP_ID)]
        if potion then
            xpPotion = exp * potion.exp / 100
        end
    end

    -- 6. Boost Creature
    local extraXp = 0
    if source:getName():lower() == boostCreature[1].name then
        local extraPercent = boostCreature[1].exp
        extraXp = exp * extraPercent / 100
        self:sendTextMessage(MESSAGE_STATUS_DEFAULT, "[Boosted Creature] You gained " .. extraXp .. " experience.")
    end

    -- 7. Castle 48H Winner
    local xpCastle48 = 0
    if self:getGuild() and self:getGuild():getId() == Game.getStorageValue(STORAGEVALUE_CASTLE48_WINNER) then
        xpCastle48 = exp * Castle48H.plusXP / 100
    end

    -- Soma final
    local totalExp = exp + extraXp + xpPotion + xpCastle + xpCastle48

    return hasEventCallback(EVENT_CALLBACK_ONGAINEXPERIENCE) and EventCallback(EVENT_CALLBACK_ONGAINEXPERIENCE, self, source, totalExp, rawExp) or totalExp
end


function Player:onLoseExperience(exp)
	return hasEventCallback(EVENT_CALLBACK_ONLOSEEXPERIENCE) and EventCallback(EVENT_CALLBACK_ONLOSEEXPERIENCE, self, exp) or exp
end

function Player:onGainSkillTries(skill, tries)
    -- Se os multiplicadores globais estiverem desligados, retorna direto
    if APPLY_SKILL_MULTIPLIER == false then
        return hasEventCallback(EVENT_CALLBACK_ONGAINSKILLTRIES) and EventCallback(EVENT_CALLBACK_ONGAINSKILLTRIES, self, skill, tries) or tries
    end

    -- 1. Aplica as rates padrões do servidor (Config.lua)
    if skill == SKILL_MAGLEVEL then
        tries = tries * configManager.getNumber(configKeys.RATE_MAGIC)
    else
        tries = tries * configManager.getNumber(configKeys.RATE_SKILL)
    end

    -- 2. Aplica o NEXUS TRAINING BOOST (Código Novo)
    -- Verifica se a função existe para não dar erro se o script não carregar
    if getTrainingBoostMultiplier then
        local multiplier = getTrainingBoostMultiplier(self)
        if multiplier > 1.0 then
            tries = tries * multiplier
        end
    end

    -- 3. Retorna o valor final para o servidor
    return hasEventCallback(EVENT_CALLBACK_ONGAINSKILLTRIES) and EventCallback(EVENT_CALLBACK_ONGAINSKILLTRIES, self, skill, tries) or tries
end


function Player:onSay(message)
    local msgBlock = {} -- Add blocked keywords here
    for _, blockedWord in ipairs(msgBlock) do
        local match = string.find(message, blockedWord)
        if match then
            self:getPosition():sendMagicEffect(CONST_ME_POFF)
            self:sendTextMessage(MESSAGE_STATUS_DEFAULT, "You cannot send this message here.")
            local file = io.open("data/logs/messages/block.txt", "a")
            if not file then
                print(">> Error trying to access the block messages file in the log.")
                return
            end
            io.output(file)
            io.write("------------------------------\n")
            io.write(self:getName() .. ": " .. message .. "\n")
            io.close(file)
            return false
        end
    end

    return true
end
