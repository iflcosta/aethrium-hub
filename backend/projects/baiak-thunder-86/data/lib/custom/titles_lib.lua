-- ============================================================
-- TITLES SYSTEM - Library
-- ============================================================

dofile('data/lib/custom/titles_config.lua')

function Player.addTitle(self, titleId)
    local title = TitleConfig.titles[titleId]
    if not title then return false end
    
    if self:hasTitle(titleId) then return true end
    
    db.query(string.format("INSERT INTO `player_titles` (`player_id`, `title_id`) VALUES (%d, %d)", self:getGuid(), titleId))
    self:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have unlocked a new title: [" .. title.name .. "]!")
    return true
end

function Player.removeTitle(self, titleId)
    db.query(string.format("DELETE FROM `player_titles` WHERE `player_id` = %d AND `title_id` = %d", self:getGuid(), titleId))
    return true
end

function Player.hasTitle(self, titleId)
    local resultId = db.storeQuery(string.format("SELECT 1 FROM `player_titles` WHERE `player_id` = %d AND `title_id` = %d", self:getGuid(), titleId))
    if resultId then
        result.free(resultId)
        return true
    end
    return false
end

function Player.getUnlockedTitles(self)
    local unlocked = {}
    local resultId = db.storeQuery(string.format("SELECT `title_id` FROM `player_titles` WHERE `player_id` = %d", self:getGuid()))
    if resultId then
        repeat
            local tid = result.getDataInt(resultId, "title_id")
            if TitleConfig.titles[tid] then
                table.insert(unlocked, tid)
            end
        until not result.next(resultId)
        result.free(resultId)
    end
    return unlocked
end

function Player.getSelectedTitle(self)
    local tid = self:getStorageValue(TitleConfig.storageSelected)
    if tid and tid > 0 and TitleConfig.titles[tid] then
        return tid
    end
    return nil
end

function Player.setSelectedTitle(self, titleId)
    if titleId == 0 then
        self:setStorageValue(TitleConfig.storageSelected, -1)
        return true
    end
    
    if not TitleConfig.titles[titleId] or not self:hasTitle(titleId) then
        return false
    end
    
    self:setStorageValue(TitleConfig.storageSelected, titleId)
    return true
end

function Player.getTitleName(self)
    local tid = self:getSelectedTitle()
    if tid then
        return TitleConfig.titles[tid].name
    end
    return nil
end

-- ============================================================
-- AUTOMATIC UNLOCKS
-- ============================================================

function Player.checkTitleUnlocks(self)
    -- [2] Legendary: Level 1000+
    if self:getLevel() >= 1000 then
        self:addTitle(2)
    end

    -- [6] Bloodthirsty: 100+ Player Kills (using storage 49001)
    local kills = math.max(0, self:getStorageValue(49001))
    if kills >= 100 then
        self:addTitle(6)
    end

    -- [1] The King: Member of the winning Castle 24h guild
    if self:getGuild() then
        local winnerGuildId = CASTLE24H:getGuildIdFromCastle()
        if winnerGuildId == self:getGuild():getId() then
            self:addTitle(1)
        end
    end
end

function Player.getChatTitle(self)
    local tid = self:getSelectedTitle()
    if tid then
        return "[" .. TitleConfig.titles[tid].name .. "] "
    end
    return ""
end

function Player.syncTitle(self, target)
    local tid = self:getSelectedTitle()
    local text = ""
    local color = "white"
    if tid then
        text = "[" .. TitleConfig.titles[tid].name .. "]"
        color = TitleConfig.titles[tid].color or "white"
    end
    
    local data = {
        cid = self:getId(),
        name = self:getName(),
        text = text,
        color = color
    }
    
    local buffer = json.encode(data)

    
    -- Always send to the player themselves
    self:sendExtendedOpcode(155, buffer)
    
    if target and target ~= self then
        target:sendExtendedOpcode(155, buffer)
    elseif not target then
        -- Broadcast to all OTHER online players
        local count = 0
        for _, p in ipairs(Game.getPlayers()) do
            if p ~= self then
                p:sendExtendedOpcode(155, buffer)
                count = count + 1
            end
        end

    end
end
