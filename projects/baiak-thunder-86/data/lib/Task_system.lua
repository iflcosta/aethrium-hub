-- ============================================
-- BAIAK THUNDER - HIGH LEVEL TASK SYSTEM
-- Server: Level 600-800 average, Reset at 1000
-- Monsters: Level 100+ (1000+ experience)
-- ============================================

taskSystem = {
    -- Task 1: Easy High Level (1000-1500 exp)
    [1] = {
        name = "Dragon Lords Hunt",
        start = 176201,
        monsters_list = {"Dragon Lord"},
        level = 100,
        count = 50,
        points = 10,
        items = {},
        reward = {{2155, 100}, {9971, 10}},
        exp = 50000,
        money = 5000
    },

    -- Task 2: Medium High Level (1500-2000 exp)
    [2] = {
        name = "Behemoth Slayer",
        start = 176201,
        monsters_list = {"Behemoth"},
        level = 150,
        count = 40,
        points = 15,
        items = {},
        reward = {{2155, 150}, {9971, 15}},
        exp = 75000,
        money = 7500
    },

    -- Task 3: Hard High Level (2000-3000 exp)
    [3] = {
        name = "Warlock War",
        start = 176201,
        monsters_list = {"Warlock"},
        level = 200,
        count = 35,
        points = 20,
        items = {},
        reward = {{2155, 200}, {9971, 20}},
        exp = 100000,
        money = 10000
    },

    -- Task 4: Demon Hunt (3000+ exp)
    [4] = {
        name = "Demon Hunter",
        start = 176201,
        monsters_list = {"Demon"},
        level = 250,
        count = 30,
        points = 25,
        items = {},
        reward = {{2155, 300}, {9971, 30}},
        exp = 150000,
        money = 15000
    },

    -- Task 5: Hellhound Challenge (4000+ exp)
    [5] = {
        name = "Hellhound Master",
        start = 176201,
        monsters_list = {"Hellhound"},
        level = 300,
        count = 25,
        points = 30,
        items = {},
        reward = {{2155, 400}, {9971, 40}},
        exp = 200000,
        money = 20000
    },

    -- Task 6: Juggernaut War (5000+ exp)
    [6] = {
        name = "Juggernaut Destroyer",
        start = 176201,
        monsters_list = {"Juggernaut"},
        level = 350,
        count = 20,
        points = 35,
        items = {},
        reward = {{2155, 500}, {9971, 50}},
        exp = 250000,
        money = 25000
    },

    -- Task 7: Plaguesmith Elite (4500+ exp)
    [7] = {
        name = "Plaguesmith Nemesis",
        start = 176201,
        monsters_list = {"Plaguesmith"},
        level = 400,
        count = 20,
        points = 40,
        items = {},
        reward = {{2155, 600}, {9971, 60}},
        exp = 300000,
        money = 30000
    },

    -- Task 8: Undead Dragon Slayer (6000+ exp)
    [8] = {
        name = "Undead Dragon Hunter",
        start = 176201,
        monsters_list = {"Undead Dragon"},
        level = 450,
        count = 15,
        points = 50,
        items = {},
        reward = {{2155, 800}, {9971, 80}},
        exp = 400000,
        money = 40000
    },

    -- Task 9: Blightwalker Challenge (5000+ exp)
    [9] = {
        name = "Blightwalker Exorcist",
        start = 176201,
        monsters_list = {"Blightwalker"},
        level = 500,
        count = 15,
        points = 60,
        items = {},
        reward = {{2155, 1000}, {9971, 100}},
        exp = 500000,
        money = 50000
    },

    -- Task 10: Grim Reaper Hunt (5500+ exp)
    [10] = {
        name = "Grim Reaper Slayer",
        start = 176201,
        monsters_list = {"Grim Reaper"},
        level = 550,
        count = 12,
        points = 75,
        items = {},
        reward = {{2155, 1200}, {9971, 120}},
        exp = 600000,
        money = 60000
    },

    -- Task 11: Silencer Elite (5000+ exp)
    [11] = {
        name = "Silencer Hunter",
        start = 176201,
        monsters_list = {"Silencer"},
        level = 600,
        count = 10,
        points = 100,
        items = {},
        reward = {{2155, 1500}, {9971, 150}},
        exp = 750000,
        money = 75000
    },

    -- Task 12: Guzzlemaw Master (5500+ exp)
    [12] = {
        name = "Guzzlemaw Master",
        start = 176201,
        monsters_list = {"Guzzlemaw"},
        level = 650,
        count = 10,
        points = 125,
        items = {},
        reward = {{2155, 1800}, {9971, 180}},
        exp = 900000,
        money = 90000
    },

    -- Task 13: Demon Outcast Elite (6000+ exp)
    [13] = {
        name = "Demon Outcast Slayer",
        start = 176201,
        monsters_list = {"Demon Outcast"},
        level = 700,
        count = 8,
        points = 150,
        items = {},
        reward = {{2155, 2000}, {9971, 200}},
        exp = 1000000,
        money = 100000
    },

    -- Task 14: Terrorsleep Hunt (5900+ exp)
    [14] = {
        name = "Terrorsleep Exorcist",
        start = 176201,
        monsters_list = {"Terrorsleep"},
        level = 750,
        count = 8,
        points = 175,
        items = {},
        reward = {{2155, 2500}, {9971, 250}},
        exp = 1250000,
        money = 125000
    },

    -- Task 15: Boss Hunter - Ferumbras
    [15] = {
        name = "Ferumbras Nemesis",
        start = 176201,
        monsters_list = {"Ferumbras"},
        level = 800,
        count = 3,
        points = 250,
        items = {},
        reward = {{2155, 5000}, {9971, 500}, {6500, 5}},
        exp = 2500000,
        money = 250000
    },

    -- Task 16: Boss Hunter - Morgaroth
    [16] = {
        name = "Morgaroth Slayer",
        start = 176201,
        monsters_list = {"Morgaroth"},
        level = 850,
        count = 3,
        points = 300,
        items = {},
        reward = {{2155, 6000}, {9971, 600}, {6500, 10}},
        exp = 3000000,
        money = 300000
    },

    -- Task 17: Boss Hunter - Ghazbaran
    [17] = {
        name = "Ghazbaran Destroyer",
        start = 176201,
        monsters_list = {"Ghazbaran"},
        level = 900,
        count = 2,
        points = 400,
        items = {},
        reward = {{2155, 8000}, {9971, 800}, {6500, 15}},
        exp = 4000000,
        money = 400000
    },

    -- Task 18: Boss Hunter - Apocalypse
    [18] = {
        name = "Apocalypse Champion",
        start = 176201,
        monsters_list = {"Apocalypse"},
        level = 950,
        count = 1,
        points = 500,
        items = {},
        reward = {{2155, 10000}, {9971, 1000}, {6500, 20}},
        exp = 5000000,
        money = 500000
    },

    -- Task 19: Boss Hunter - Bazir
    [19] = {
        name = "Bazir Nemesis",
        start = 176201,
        monsters_list = {"Bazir"},
        level = 975,
        count = 1,
        points = 600,
        items = {},
        reward = {{2155, 12000}, {9971, 1200}, {6500, 25}},
        exp = 6000000,
        money = 600000
    },

    -- Task 20: Ultimate Boss - Gaz'haragoth
    [20] = {
        name = "Gaz'haragoth Killer",
        start = 176201,
        monsters_list = {"Gaz'haragoth"},
        level = 1000,
        count = 1,
        points = 1000,
        items = {},
        reward = {{2155, 20000}, {9971, 2000}, {6500, 50}},
        exp = 10000000,
        money = 1000000
    },
}

-- ============================================
-- DAILY TASKS - High Level
-- ============================================

dailyTasks = {
    -- Daily 1: Dragon Lords
    [1] = {
        name = "Daily: Dragon Lord Hunt",
        monsters_list = {"Dragon Lord"},
        count = 30,
        points = 5,
        reward = {{2155, 50}, {9971, 5}},
        exp = 25000,
        money = 2500
    },

    -- Daily 2: Behemoths
    [2] = {
        name = "Daily: Behemoth Slayer",
        monsters_list = {"Behemoth"},
        count = 25,
        points = 7,
        reward = {{2155, 75}, {9971, 7}},
        exp = 35000,
        money = 3500
    },

    -- Daily 3: Warlocks
    [3] = {
        name = "Daily: Warlock War",
        monsters_list = {"Warlock"},
        count = 20,
        points = 10,
        reward = {{2155, 100}, {9971, 10}},
        exp = 50000,
        money = 5000
    },

    -- Daily 4: Demons
    [4] = {
        name = "Daily: Demon Hunter",
        monsters_list = {"Demon"},
        count = 15,
        points = 15,
        reward = {{2155, 150}, {9971, 15}},
        exp = 75000,
        money = 7500
    },

    -- Daily 5: Hellhounds
    [5] = {
        name = "Daily: Hellhound Master",
        monsters_list = {"Hellhound"},
        count = 12,
        points = 20,
        reward = {{2155, 200}, {9971, 20}},
        exp = 100000,
        money = 10000
    },

    -- Daily 6: Undead Dragons
    [6] = {
        name = "Daily: Undead Dragon Hunter",
        monsters_list = {"Undead Dragon"},
        count = 10,
        points = 25,
        reward = {{2155, 300}, {9971, 30}},
        exp = 150000,
        money = 15000
    },

    -- Daily 7: Blightwalkers
    [7] = {
        name = "Daily: Blightwalker Exorcist",
        monsters_list = {"Blightwalker"},
        count = 8,
        points = 30,
        reward = {{2155, 400}, {9971, 40}},
        exp = 200000,
        money = 20000
    },

    -- Daily 8: Grim Reapers
    [8] = {
        name = "Daily: Grim Reaper Slayer",
        monsters_list = {"Grim Reaper"},
        count = 5,
        points = 40,
        reward = {{2155, 500}, {9971, 50}},
        exp = 250000,
        money = 25000
    },

    -- Daily 9: Silencers
    [9] = {
        name = "Daily: Silencer Hunter",
        monsters_list = {"Silencer"},
        count = 5,
        points = 50,
        reward = {{2155, 600}, {9971, 60}},
        exp = 300000,
        money = 30000
    },

    -- Daily 10: Guzzlemaws
    [10] = {
        name = "Daily: Guzzlemaw Master",
        monsters_list = {"Guzzlemaw"},
        count = 5,
        points = 60,
        reward = {{2155, 750}, {9971, 75}},
        exp = 375000,
        money = 37500
    },

    -- Daily 11: Juggernauts
    [11] = {
        name = "Daily: Juggernaut Destroyer",
        monsters_list = {"Juggernaut"},
        count = 4,
        points = 75,
        reward = {{2155, 1000}, {9971, 100}},
        exp = 500000,
        money = 50000
    },

    -- Daily 12: Demon Outcasts
    [12] = {
        name = "Daily: Demon Outcast Slayer",
        monsters_list = {"Demon Outcast"},
        count = 3,
        points = 100,
        reward = {{2155, 1500}, {9971, 150}},
        exp = 750000,
        money = 75000
    },
}

-- ============================================
-- TASK SYSTEM STORAGES
-- ============================================
-- Storage usage:
-- [1]: Current task ID (176601)
-- [2]: Task points accumulated (176602)
-- [3]: Current task kill count (176603)
-- [4]: Current daily task ID (176604)
-- [5]: Current daily task kill count (176605)
-- [6]: Daily task reset time (176606)
-- [7]: Daily task start time (176607)
-- [8]: Kill message cooldown (176608)
-- ============================================

taskSystem_storages = {176601, 176602, 176603, 176604, 176605, 176606, 176607, 176608}

-- ============================================
-- PLAYER FUNCTIONS
-- ============================================

function Player:getTaskMission()
    return self:getStorageValue(taskSystem_storages[1]) < 0 and 1 or self:getStorageValue(taskSystem_storages[1])
end

function Player:getDailyTaskMission()
    return self:getStorageValue(taskSystem_storages[4]) < 0 and 1 or self:getStorageValue(taskSystem_storages[4])
end

function Player:getTaskPoints()
    return self:getStorageValue(taskSystem_storages[2]) < 0 and 0 or self:getStorageValue(taskSystem_storages[2])
end

function Player:randomDailyTask()
    local t = {
        [{1, 99}] = {1, 4},
        [{100, 249}] = {1, 6},
        [{250, 499}] = {1, 8},
        [{500, 749}] = {1, 10},
        [{750, 999}] = {1, 12},
        [{1000, math.huge}] = {1, 12}
    }
    for a, b in pairs(t) do
        if self:getLevel() >= a[1] and self:getLevel() <= a[2] then
            return math.random(b[1], b[2])
        end
    end
    return 1
end

function Player:getRankTask()
    local ranks = {
        [{1, 50}] = "Apprentice Hunter",
        [{51, 150}] = "Journeyman Hunter",
        [{151, 300}] = "Expert Hunter",
        [{301, 500}] = "Master Hunter",
        [{501, 750}] = "Grand Master Hunter",
        [{751, 1000}] = "Legendary Hunter",
        [{1001, math.huge}] = "Mythical Hunter"
    }

    local defaultRank = "Novice Hunter"

    for v, r in pairs(ranks) do
        if self:getTaskPoints() >= v[1] and self:getTaskPoints() <= v[2] then
            return r
        end
    end

    return defaultRank
end

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

function getItemsFromList(items)
    local str = ''
    if #items > 0 then
        for i = 1, #items do
            local itemID = items[i][1]
            local itemName = ItemType(itemID):getName()
            if itemName then
                str = str .. items[i][2] .. ' ' .. itemName
            else
                str = str .. items[i][2] .. ' ' .. "Item ID: " .. itemID
            end
            if i ~= #items then str = str .. ', ' end
        end
    end
    return str
end

function Player:doRemoveItemsFromList(items)
    local count = 0
    if #items > 0 then
        for i = 1, #items do
            if self:getItemCount(items[i][1]) >= items[i][2] then
                count = count + 1
            end
        end
    end
    if count == #items then
        for i = 1, #items do
            self:removeItem(items[i][1], items[i][2])
        end
    else
        return false
    end
    return true
end

function getMonsterFromList(monster)
    local str = ''
    if #monster > 0 then
        for i = 1, #monster do
            str = str .. monster[i]
            if i ~= #monster then str = str .. ', ' end
        end
    end
    return str
end

function Player:giveRewardsTask(items)
    local backpack = self:addItem(1999, 1)
    if not backpack then
        -- If no backpack, try to add directly
        for _, i_i in ipairs(items) do
            local item, amount = i_i[1], i_i[2]
            self:addItem(item, amount)
        end
        return
    end
    
    for _, i_i in ipairs(items) do
        local item, amount = i_i[1], i_i[2]
        if ItemType(item):isStackable() or amount == 1 then
            backpack:addItem(item, amount)
        else
            for i = 1, amount do
                backpack:addItem(item, 1)
            end
        end
    end
end
