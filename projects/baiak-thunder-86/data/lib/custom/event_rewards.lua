-- ============================================
-- BAIAK THUNDER - EVENT REWARDS SYSTEM
-- Centralized points management for events
-- ============================================

EventRewards = {
    storageTaskPoints = 20021,
    storageBossPoints = 20022,
    opcodeStore = 201
}

function Player:addEventPoints(type, amount)
    if not amount or amount <= 0 then return end
    
    local storage = (type == "task" and EventRewards.storageTaskPoints or EventRewards.storageBossPoints)
    local current = math.max(0, self:getStorageValue(storage))
    self:setStorageValue(storage, current + amount)
    
    local msg = (type == "task" and "Task Points" or "Boss Points")
    self:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You received %d %s as a reward!", amount, msg))
    
    -- Sync with Store UI
    self:syncStorePoints()
    return true
end

function Player:syncStorePoints()
    local accCoins = 0
    local queryCoins = db.storeQuery("SELECT `premium_points` FROM `accounts` WHERE `id` = " .. self:getAccountId())
    if queryCoins then
        accCoins = result.getDataInt(queryCoins, "premium_points")
        result.free(queryCoins)
    end
    
    local taskPoints = math.max(0, self:getStorageValue(EventRewards.storageTaskPoints))
    local bossPoints = math.max(0, self:getStorageValue(EventRewards.storageBossPoints))
    
    self:sendExtendedOpcode(EventRewards.opcodeStore, json.encode({
        action = "points", 
        data = {
            points = accCoins, 
            secondPoints = taskPoints, 
            thirdPoints = bossPoints
        }
    }))
end
