local staminaBonus = {
    target = 'Trainer',
    period = 180000,
    periodPremium = 120000,
    bonus = 1,
    events = {},
    players = {},
}

local ipPlayers = {}

local function addStamina(name)
    local player = Player(name)
    if not player then
        staminaBonus.events[name] = nil
    else
        local target = player:getTarget()
        if not target or target:getName() ~= staminaBonus.target then
            staminaBonus.events[name] = nil
        else
            if player:isPremium() then
                player:setStamina(player:getStamina() + staminaBonus.bonus)
                staminaBonus.events[name] = addEvent(addStamina, staminaBonus.periodPremium, name)
            else
                player:setStamina(player:getStamina() + staminaBonus.bonus)
                staminaBonus.events[name] = addEvent(addStamina, staminaBonus.period, name)
            end
        end
    end
end

local function checkIp(name)
    local player = Player(name)
    if not player then
        ipPlayers[name] = nil
    else
        if player:getIp() == 0 then
            ipPlayers[name] = nil
            player:setTarget(nil)
            player:teleportTo(player:getTown():getTemplePosition())
            player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
            return
        end
        ipPlayers[name] = addEvent(checkIp, 30000, player:getName())
    end
end

function Creature:onChangeOutfit(outfit)
    if self:isPlayer() and self:getStorageValue(STORAGEVALUE_EVENTS) >= 1 then
        self:sendTextMessage(MESSAGE_INFO_DESCR, "You cannot change your clothes while inside an event.")
        return false
    end
    
    if hasEventCallback(EVENT_CALLBACK_ONCHANGEMOUNT) then
        if not EventCallback(EVENT_CALLBACK_ONCHANGEMOUNT, self, outfit.lookMount) then
            return false
        end
    end
    
    if hasEventCallback(EVENT_CALLBACK_ONCHANGEOUTFIT) then
        return EventCallback(EVENT_CALLBACK_ONCHANGEOUTFIT, self, outfit)
    else
        return true
    end
end

function Creature:onAreaCombat(tile, isAggressive)
    local function addStamina(name)
        local player = Player(name)
        if not player then
            staminaBonus.events[name] = nil
        else
            local target = player:getTarget()
            if not target or target:getName() ~= staminaBonus.target then
                staminaBonus.events[name] = nil
            else
                if player:isPremium() then
                    player:setStamina(player:getStamina() + staminaBonus.bonus)
                    staminaBonus.events[name] = addEvent(addStamina, staminaBonus.periodPremium, name)
                else
                    player:setStamina(player:getStamina() + staminaBonus.bonus)
                    staminaBonus.events[name] = addEvent(addStamina, staminaBonus.period, name)
                end
            end
        end
    end

    if hasEventCallback(EVENT_CALLBACK_ONAREACOMBAT) then
        return EventCallback(EVENT_CALLBACK_ONAREACOMBAT, self, tile, isAggressive)
    else
        return RETURNVALUE_NOERROR
    end
end

function Creature:onTargetCombat(target)
    if not self or not self:isPlayer() then
        return RETURNVALUE_NOERROR
    end

    local name = self:getName()

    if target and target:getName() == staminaBonus.target then
        if not ipPlayers[name] then
            ipPlayers[name] = addEvent(function() checkIp(name) end, 30000) 
        end
        if not staminaBonus.events[name] then
            staminaBonus.events[name] = addEvent(function() addStamina(name) end, staminaBonus.period)
        end
    end

    -- Quiver Auto-Refill Logic
    local ammoSlotItem = self:getSlotItem(CONST_SLOT_AMMO)
    
    if not ammoSlotItem or ammoSlotItem:getCount() < 50 then
        local handSlots = {CONST_SLOT_LEFT, CONST_SLOT_RIGHT}
        local quiver = nil
        for _, slot in ipairs(handSlots) do
            local item = self:getSlotItem(slot)
            if item and item:isContainer() and item:getName():lower():find("quiver") then
                quiver = item
                break
            end
        end

        if quiver then
            for i = quiver:getSize() - 1, 0, -1 do
                local item = quiver:getItem(i)
                if item and item:getType():getWeaponType() == WEAPON_AMMO then
                    if not ammoSlotItem then
                        item:moveTo(self)
                        break
                    elseif ammoSlotItem:getId() == item:getId() then
                        local space = 100 - ammoSlotItem:getCount()
                        if space > 0 then
                            local transfer = math.min(item:getCount(), space)
                            ammoSlotItem:transform(ammoSlotItem:getId(), ammoSlotItem:getCount() + transfer)
                            item:remove(transfer)
                            break
                        end
                    end
                end
            end
        end
    end

    if configManager.getBoolean(configKeys.PVP_BALANCE) then
        target:registerEvent("PvpBalance")
        target:registerEvent("PvpBalanceMA")
    end

    if hasEventCallback(EVENT_CALLBACK_ONTARGETCOMBAT) then
        return EventCallback(EVENT_CALLBACK_ONTARGETCOMBAT, self, target)
    else
        return RETURNVALUE_NOERROR
    end
end


function Creature:onHear(speaker, words, type)
    if hasEventCallback(EVENT_CALLBACK_ONHEAR) then
        EventCallback(EVENT_CALLBACK_ONHEAR, self, speaker, words, type)
    end
end
