-- Potion System: Centralized check and expiration logic
-- Designed for persistence across server restarts and logouts

function Player.checkExpPotion(self)
    if self:getStorageValue(STORAGEVALUE_POTIONXP_ID) <= 0 then
        return
    end

    local tempo = self:getStorageValue(STORAGEVALUE_POTIONXP_TEMPO)
    if tempo <= os.time() then
        self:setStorageValue(STORAGEVALUE_POTIONXP_ID, -1)
        self:setStorageValue(STORAGEVALUE_POTIONXP_TEMPO, -1)
        self:sendCancelMessage("Your experience bonus time from the experience potion has ended!")
        self:getPosition():sendMagicEffect(CONST_ME_POFF)
    end
end

function Player.checkLootPotion(self)
    if self:getStorageValue(STORAGEVALUE_LOOT_ID) <= 0 then
        return
    end

    local tempo = self:getStorageValue(STORAGEVALUE_LOOT_TEMPO)
    if tempo <= os.time() then
        self:setStorageValue(STORAGEVALUE_LOOT_ID, -1)
        self:setStorageValue(STORAGEVALUE_LOOT_TEMPO, -1)
        self:sendCancelMessage("Your loot bonus time from the potion has ended!")
        self:getPosition():sendMagicEffect(CONST_ME_POFF)
    end
end

function Player.updatePotionStatus(self)
    self:checkExpPotion()
    self:checkLootPotion()
end
