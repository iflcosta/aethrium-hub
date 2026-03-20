BossRoom = {
    monstros = { -- Nome do boss, tempo em minutos para matar o boss, moeda usada para entrar na sala
        [30000] = {bossName = "Gaz'haragoth", currencyType = "coins", price = 100, killTime = 15, center = Position(1646, 975, 9), x = 6, y = 6, displayPos = Position(579, 1252, 7), pointsReward = 7},
        [30001] = {bossName = "Abyssador", currencyType = "coins", price = 80, killTime = 15, center = Position(1695, 977, 9), x = 6, y = 6, displayPos = Position(581, 1252, 7), pointsReward = 5},
        [30002] = {bossName = "Deathstrike", currencyType = "coins", price = 80, killTime = 15, center = Position(1743, 978, 9), x = 6, y = 6, displayPos = Position(583, 1252, 7), pointsReward = 4},
        [30003] = {bossName = "Gnomevil", currencyType = "coins", price = 70, killTime = 15, center = Position(1792, 980, 9), x = 6, y = 6, displayPos = Position(585, 1252, 7), pointsReward = 4},
        [30004] = {bossName = "Chizzoron The Distorter", currencyType = "coins", price = 60, killTime = 15, center = Position(1646, 921, 9), x = 6, y = 6, displayPos = Position(587, 1252, 7), pointsReward = 1},
        [30005] = {bossName = "The Abomination", currencyType = "coins", price = 50, killTime = 12, center = Position(1695, 923, 9), x = 6, y = 6, displayPos = Position(591, 1245, 7), pointsReward = 10},
        [30006] = {bossName = "Jaul", currencyType = "coins", price = 40, killTime = 12, center = Position(1743, 924, 9), x = 6, y = 6, displayPos = Position(591, 1243, 7), pointsReward = 3},
        [30007] = {bossName = "Tanjis", currencyType = "coins", price = 40, killTime = 12, center = Position(1792, 926, 9), x = 6, y = 6, displayPos = Position(591, 1241, 7), pointsReward = 2},
        [30008] = {bossName = "Obujos", currencyType = "coins", price = 40, killTime = 12, center = Position(1646, 867, 9), x = 6, y = 6, displayPos = Position(591, 1239, 7), pointsReward = 2},
        [30009] = {bossName = "Zulazza the Corruptor", currencyType = "coins", price = 30, killTime = 12, center = Position(1695, 869, 9), x = 6, y = 6, displayPos = Position(591, 1237, 7), pointsReward = 2},
        [30010] = {bossName = "Apocalypse", currencyType = "tasks", price = 1000, killTime = 10, center = Position(1743, 870, 9), x = 6, y = 6, displayPos = Position(587, 1230, 7), pointsReward = 3},
        [30011] = {bossName = "Bazir", currencyType = "tasks", price = 900, killTime = 10, center = Position(1792, 872, 9), x = 6, y = 6, displayPos = Position(585, 1230, 7), pointsReward = 3},
        [30012] = {bossName = "Infernatil", currencyType = "tasks", price = 800, killTime = 10, center = Position(1646, 813, 9), x = 6, y = 6, displayPos = Position(583, 1230, 7), pointsReward = 3},
        [30013] = {bossName = "Verminor", currencyType = "tasks", price = 700, killTime = 10, center = Position(1695, 815, 9), x = 6, y = 6, displayPos = Position(581, 1230, 7), pointsReward = 3},
        [30014] = {bossName = "Ferumbras", currencyType = "tasks", price = 600, killTime = 10, center = Position(1743, 816, 9), x = 6, y = 6, displayPos = Position(579, 1230, 7), pointsReward = 3},
        [30016] = {bossName = "Morgaroth", currencyType = "tasks", price = 500, killTime = 10, center = Position(1792, 818, 9), x = 6, y = 6, displayPos = Position(575, 1237, 7), pointsReward = 3},
        [30017] = {bossName = "Ghazbaran", currencyType = "tasks", price = 500, killTime = 10, center = Position(1645, 761, 9), x = 6, y = 6, displayPos = Position(575, 1239, 7), pointsReward = 3},
        [30018] = {bossName = "The Pale Count", currencyType = "tasks", price = 400, killTime = 10, center = Position(1694, 763, 9), x = 6, y = 6, displayPos = Position(575, 1241, 7), pointsReward = 2},
        [30019] = {bossName = "Zoralurk", currencyType = "tasks", price = 300, killTime = 10, center = Position(1742, 764, 9), x = 6, y = 6, displayPos = Position(575, 1243, 7), pointsReward = 2},
        [30020] = {bossName = "Annihilon", currencyType = "tasks", price = 200, killTime = 10, center = Position(1791, 766, 9), x = 6, y = 6, displayPos = Position(575, 1245, 7), pointsReward = 2}
    },
    msg = {
        notAvailable = "There is already a player inside this room. Please wait.",
        notItem = "You do not have the required %d %s to enter this room.",
        notItemTeam = "%s does not have the required %d %s to enter this room.",
        timeOver = "Time's up and you didn't kill the boss.",
        enterRoom = "The boss will spawn in %d seconds, and you will have %d minutes to kill it! Good luck!",
    }
}

function BossRoom:setFreeRoom(id)
    local db = db.query("UPDATE `boss_room` SET `guid_player` = -1, `time` = 0, `to_time` = 0 WHERE room_id = ".. id)
    if not db then
        print("Error updating room ".. id .." of boss rooms.")
    end
end

function BossRoom:removeMonster(id)
    local monster = Monster(id)
    if monster then
        monster:getPosition():sendMagicEffect(CONST_ME_POFF)
        monster:remove()
    end
end

function BossRoom:checkAndCleanPlayer(player)
    if not player then return false end
    local pAccId = player:getGuid()
    
    -- Fast Path: Query the database with proper string quotes around the GUID integer
    local query = db.storeQuery("SELECT `room_id` FROM `boss_room` WHERE `guid_player` = '" .. pAccId .. "'")
    if query then
        local actionid = result.getDataInt(query, "room_id")
        result.free(query)
        
        local bossData = self.monstros[actionid]
        if bossData then
            local spectators = Game.getSpectators(bossData.center, false, false, 0, bossData.x, 0, bossData.y)
            if spectators then
                for _, spec in ipairs(spectators) do
                    if spec:isMonster() then
                        spec:getPosition():sendMagicEffect(CONST_ME_POFF)
                        spec:remove()
                    elseif spec:isPlayer() and spec:getId() ~= player:getId() then
                        spec:teleportTo(Position(583, 1242, 7))
                        spec:sendTextMessage(MESSAGE_EVENT_ADVANCE, "O dono da sala saiu. O evento foi encerrado.")
                    end
                end
            end
            if bossData.bossId then bossData.bossId = nil end
            self:setFreeRoom(actionid)
            return true
        end
    end

    -- Fallback Path: Check all rooms radially (in case SQL was out of sync)
    for actionid, bossData in pairs(self.monstros) do
        local spectators = Game.getSpectators(bossData.center, false, false, 0, bossData.x, 0, bossData.y)
        if spectators then
            local playerHere = false
            for _, spec in ipairs(spectators) do
                if spec:isPlayer() and spec:getId() == player:getId() then
                    playerHere = true
                    break
                end
            end
            
            if playerHere then
                for _, spec in ipairs(spectators) do
                    if spec:isMonster() then
                        spec:getPosition():sendMagicEffect(CONST_ME_POFF)
                        spec:remove()
                    end
                end
                self:setFreeRoom(actionid)
                return true
            end
        end
    end
    
    return false
end
