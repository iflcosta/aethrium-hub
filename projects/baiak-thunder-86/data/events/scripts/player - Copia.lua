function Player:onLook(thing, position, distance)
    local minDist = 5

    if thing:isCreature() and thing:isNpc() and distance <= minDist then
        self:say("hi", TALKTYPE_PRIVATE_PN, false, thing)
        self:say("trade", TALKTYPE_PRIVATE_PN, false, thing)
        return false
    end

    local description = ""

    if LOOK_MARRIAGE_DESCR and thing:isCreature() and thing:isPlayer() and not thing:getGroup():getAccess() then
        description = description .. self:getMarriageDescription(thing)
    end

    if thing:isPlayer() then
        description = description .. "\nMining Level: " .. configMining.level[thing:getStorageValue(configMining.level.storageNivel)].name .. "."
    end

    if thing:isItem() and thing:getCustomAttribute("premiumPoints") then
        description = description .. "\nThis item is worth " .. thing:getCustomAttribute("premiumPoints") .. " pontos."
    end

    if self:getGroup():getAccess() then
        if thing:isItem() then
            description = string.format("%s\nItem ID: %d", description, thing:getId())

            local actionId = thing:getActionId()
            if actionId ~= 0 then
                description = string.format("%s, Action ID: %d", description, actionId)
            end

            local uniqueId = thing:getAttribute(ITEM_ATTRIBUTE_UNIQUEID)
            if uniqueId > 0 and uniqueId < 65536 then
                description = string.format("%s, Unique ID: %d", description, uniqueId)
            end

            local itemType = thing:getType()

            local transformEquipId = itemType:getTransformEquipId()
            local transformDeEquipId = itemType:getTransformDeEquipId()
            if transformEquipId ~= 0 then
                description = string.format("%s\nTransform to: %d (onEquip)", description, transformEquipId)
            elseif transformDeEquipId ~= 0 then
                description = string.format("%s\nTransform to: %d (onDeEquip)", description, transformDeEquipId)
            end

            local decayId = itemType:getDecayId()
            if decayId ~= -1 then
                description = string.format("%s\nDecays to: %d", description, decayId)
            end
        elseif thing:isCreature() then
            description = string.format("%s\nLife: %d / %d", description, thing:getHealth(), thing:getMaxHealth())

            if thing:isPlayer() and thing:getMaxMana() > 0 then
                description = string.format("%s, Mana: %d / %d", description, thing:getMana(), thing:getMaxMana())
            end
        end

        local pos = thing:getPosition()
        description = string.format("%s\nPosition: %d, %d, %d", description, pos.x, pos.y, pos.z)

        if thing:isCreature() and thing:isPlayer() and not thing:getGroup():getAccess() then
            description = string.format("%s\nTask Rank: %s", description, getRankTask(thing))
        end
    end

    self:sendTextMessage(MESSAGE_INFO_DESCR, description)

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
    
    if self:getGroup():getAccess() then
        local str = "%s\nHealth: %d / %d"
        if creature:isPlayer() and creature:getMaxMana() > 0 then
            str = string.format("%s, Mana: %d / %d", str, creature:getMana(), creature:getMaxMana())
        end
        description = string.format(str, description, creature:getHealth(), creature:getMaxHealth()) .. "."
        
        local position = creature:getPosition()
        description = string.format(
            "%s\nPosition: %d, %d, %d",
            description, position.x, position.y, position.z
        )
    end
    
    if creature:isCreature() and creature:isPlayer() and not creature:getGroup():getAccess() then
        description = string.format("%s\nTask Rank: %s", description, getRankTask(creature))
    end
    
    self:sendTextMessage(MESSAGE_INFO_DESCR, description)
    
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

    -- 5. XP Potion
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
	if APPLY_SKILL_MULTIPLIER == false then
		return hasEventCallback(EVENT_CALLBACK_ONGAINSKILLTRIES) and EventCallback(EVENT_CALLBACK_ONGAINSKILLTRIES, self, skill, tries) or tries
	end

	if skill == SKILL_MAGLEVEL then
		tries = tries * configManager.getNumber(configKeys.RATE_MAGIC)
		return hasEventCallback(EVENT_CALLBACK_ONGAINSKILLTRIES) and EventCallback(EVENT_CALLBACK_ONGAINSKILLTRIES, self, skill, tries) or tries
	end
	tries = tries * configManager.getNumber(configKeys.RATE_SKILL)
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
