-- ============================================
-- BAIAK THUNDER - HIGH LEVEL TASK SYSTEM
-- Server: Level 600-800 average, Reset at 1000
-- Monsters: Level 100+ (1000+ experience)
-- Used by NPC Bianca
-- ============================================

task_monsters = {
    -- Task 1: Dragon Lords (Easy High Level)
    [1] = {
        name = "Dragon Lord",
        mons_list = {"Dragon Lord"},
        storage = 30000,
        amount = 50,
        exp = 50000,
        pointsTask = {10, 1},
        items = {{id = 2155, count = 100}, {id = 9971, count = 10}}
    },

    -- Task 2: Behemoth (Medium High Level)
    [2] = {
        name = "Behemoth",
        mons_list = {"Behemoth"},
        storage = 30001,
        amount = 40,
        exp = 75000,
        pointsTask = {15, 2},
        items = {{id = 2155, count = 150}, {id = 9971, count = 15}}
    },

    -- Task 3: Warlock (Hard High Level)
    [3] = {
        name = "Warlock",
        mons_list = {"Warlock"},
        storage = 30002,
        amount = 35,
        exp = 100000,
        pointsTask = {20, 3},
        items = {{id = 2155, count = 200}, {id = 9971, count = 20}}
    },

    -- Task 4: Demon (Elite)
    [4] = {
        name = "Demon",
        mons_list = {"Demon"},
        storage = 30003,
        amount = 30,
        exp = 150000,
        pointsTask = {25, 4},
        items = {{id = 2155, count = 300}, {id = 9971, count = 30}}
    },

    -- Task 5: Hellhound (Elite+)
    [5] = {
        name = "Hellhound",
        mons_list = {"Hellhound"},
        storage = 30004,
        amount = 25,
        exp = 200000,
        pointsTask = {30, 5},
        items = {{id = 2155, count = 400}, {id = 9971, count = 40}}
    },

    -- Task 6: Juggernaut (Ultra Elite)
    [6] = {
        name = "Juggernaut",
        mons_list = {"Juggernaut"},
        storage = 30005,
        amount = 20,
        exp = 250000,
        pointsTask = {35, 6},
        items = {{id = 2155, count = 500}, {id = 9971, count = 50}}
    },

    -- Task 7: Plaguesmith Elite
    [7] = {
        name = "Plaguesmith",
        mons_list = {"Plaguesmith"},
        storage = 30006,
        amount = 20,
        exp = 300000,
        pointsTask = {40, 7},
        items = {{id = 2155, count = 600}, {id = 9971, count = 60}}
    },

    -- Task 8: Undead Dragon
    [8] = {
        name = "Undead Dragon",
        mons_list = {"Undead Dragon"},
        storage = 30007,
        amount = 15,
        exp = 400000,
        pointsTask = {50, 8},
        items = {{id = 2155, count = 800}, {id = 9971, count = 80}}
    },

    -- Task 9: Blightwalker
    [9] = {
        name = "Blightwalker",
        mons_list = {"Blightwalker"},
        storage = 30008,
        amount = 15,
        exp = 500000,
        pointsTask = {60, 10},
        items = {{id = 2155, count = 1000}, {id = 9971, count = 100}}
    },

    -- Task 10: Grim Reaper
    [10] = {
        name = "Grim Reaper",
        mons_list = {"Grim Reaper"},
        storage = 30009,
        amount = 12,
        exp = 600000,
        pointsTask = {75, 12},
        items = {{id = 2155, count = 1200}, {id = 9971, count = 120}}
    },

    -- Task 11: Silencer
    [11] = {
        name = "Silencer",
        mons_list = {"Silencer"},
        storage = 30010,
        amount = 10,
        exp = 750000,
        pointsTask = {100, 15},
        items = {{id = 2155, count = 1500}, {id = 9971, count = 150}}
    },

    -- Task 12: Guzzlemaw
    [12] = {
        name = "Guzzlemaw",
        mons_list = {"Guzzlemaw"},
        storage = 30011,
        amount = 10,
        exp = 900000,
        pointsTask = {125, 18},
        items = {{id = 2155, count = 1800}, {id = 9971, count = 180}}
    },

    -- Task 13: Demon Outcast
    [13] = {
        name = "Demon Outcast",
        mons_list = {"Demon Outcast"},
        storage = 30012,
        amount = 8,
        exp = 1000000,
        pointsTask = {150, 20},
        items = {{id = 2155, count = 2000}, {id = 9971, count = 200}}
    },

    -- Task 14: Terrorsleep
    [14] = {
        name = "Terrorsleep",
        mons_list = {"Terrorsleep"},
        storage = 30013,
        amount = 8,
        exp = 1250000,
        pointsTask = {175, 25},
        items = {{id = 2155, count = 2500}, {id = 9971, count = 250}}
    },

    -- Task 15: Boss - Ferumbras
    [15] = {
        name = "Ferumbras",
        mons_list = {"Ferumbras"},
        storage = 30014,
        amount = 3,
        exp = 2500000,
        pointsTask = {250, 30},
        items = {{id = 2155, count = 5000}, {id = 9971, count = 500}, {id = 6500, count = 5}}
    },

    -- Task 16: Boss - Morgaroth
    [16] = {
        name = "Morgaroth",
        mons_list = {"Morgaroth"},
        storage = 30015,
        amount = 3,
        exp = 3000000,
        pointsTask = {300, 35},
        items = {{id = 2155, count = 6000}, {id = 9971, count = 600}, {id = 6500, count = 10}}
    },

    -- Task 17: Boss - Ghazbaran
    [17] = {
        name = "Ghazbaran",
        mons_list = {"Ghazbaran"},
        storage = 30016,
        amount = 2,
        exp = 4000000,
        pointsTask = {400, 40},
        items = {{id = 2155, count = 8000}, {id = 9971, count = 800}, {id = 6500, count = 15}}
    },

    -- Task 18: Boss - Apocalypse
    [18] = {
        name = "Apocalypse",
        mons_list = {"Apocalypse"},
        storage = 30017,
        amount = 1,
        exp = 5000000,
        pointsTask = {500, 50},
        items = {{id = 2155, count = 10000}, {id = 9971, count = 1000}, {id = 6500, count = 20}}
    },

    -- Task 19: Boss - Bazir
    [19] = {
        name = "Bazir",
        mons_list = {"Bazir"},
        storage = 30018,
        amount = 1,
        exp = 6000000,
        pointsTask = {600, 60},
        items = {{id = 2155, count = 12000}, {id = 9971, count = 1200}, {id = 6500, count = 25}}
    },

    -- Task 20: Ultimate Boss - Gaz'haragoth
    [20] = {
        name = "Gaz'haragoth",
        mons_list = {"Gaz'haragoth"},
        storage = 30019,
        amount = 1,
        exp = 10000000,
        pointsTask = {1000, 100},
        items = {{id = 2155, count = 20000}, {id = 9971, count = 2000}, {id = 6500, count = 50}}
    },
}

-- ============================================
-- DAILY TASKS - High Level
-- ============================================

task_daily = {
    -- Daily 1: Dragon Lords
    [1] = {
        name = "Dragon Lord",
        mons_list = {"Dragon Lord"},
        storage = 40000,
        amount = 30,
        exp = 25000,
        pointsTask = {5, 1},
        items = {{id = 2155, count = 50}, {id = 9971, count = 5}}
    },

    -- Daily 2: Behemoths
    [2] = {
        name = "Behemoth",
        mons_list = {"Behemoth"},
        storage = 40001,
        amount = 25,
        exp = 35000,
        pointsTask = {7, 1},
        items = {{id = 2155, count = 75}, {id = 9971, count = 7}}
    },

    -- Daily 3: Warlocks
    [3] = {
        name = "Warlock",
        mons_list = {"Warlock"},
        storage = 40002,
        amount = 20,
        exp = 50000,
        pointsTask = {10, 2},
        items = {{id = 2155, count = 100}, {id = 9971, count = 10}}
    },

    -- Daily 4: Demons
    [4] = {
        name = "Demon",
        mons_list = {"Demon"},
        storage = 40003,
        amount = 15,
        exp = 75000,
        pointsTask = {15, 2},
        items = {{id = 2155, count = 150}, {id = 9971, count = 15}}
    },

    -- Daily 5: Hellhounds
    [5] = {
        name = "Hellhound",
        mons_list = {"Hellhound"},
        storage = 40004,
        amount = 12,
        exp = 100000,
        pointsTask = {20, 3},
        items = {{id = 2155, count = 200}, {id = 9971, count = 20}}
    },

    -- Daily 6: Undead Dragons
    [6] = {
        name = "Undead Dragon",
        mons_list = {"Undead Dragon"},
        storage = 40005,
        amount = 10,
        exp = 150000,
        pointsTask = {25, 4},
        items = {{id = 2155, count = 300}, {id = 9971, count = 30}}
    },

    -- Daily 7: Blightwalkers
    [7] = {
        name = "Blightwalker",
        mons_list = {"Blightwalker"},
        storage = 40006,
        amount = 8,
        exp = 200000,
        pointsTask = {30, 5},
        items = {{id = 2155, count = 400}, {id = 9971, count = 40}}
    },

    -- Daily 8: Grim Reapers
    [8] = {
        name = "Grim Reaper",
        mons_list = {"Grim Reaper"},
        storage = 40007,
        amount = 5,
        exp = 250000,
        pointsTask = {40, 6},
        items = {{id = 2155, count = 500}, {id = 9971, count = 50}}
    },

    -- Daily 9: Silencers
    [9] = {
        name = "Silencer",
        mons_list = {"Silencer"},
        storage = 40008,
        amount = 5,
        exp = 300000,
        pointsTask = {50, 7},
        items = {{id = 2155, count = 600}, {id = 9971, count = 60}}
    },

    -- Daily 10: Guzzlemaws
    [10] = {
        name = "Guzzlemaw",
        mons_list = {"Guzzlemaw"},
        storage = 40009,
        amount = 5,
        exp = 375000,
        pointsTask = {60, 8},
        items = {{id = 2155, count = 750}, {id = 9971, count = 75}}
    },

    -- Daily 11: Juggernauts
    [11] = {
        name = "Juggernaut",
        mons_list = {"Juggernaut"},
        storage = 40010,
        amount = 4,
        exp = 500000,
        pointsTask = {75, 10},
        items = {{id = 2155, count = 1000}, {id = 9971, count = 100}}
    },

    -- Daily 12: Demon Outcasts
    [12] = {
        name = "Demon Outcast",
        mons_list = {"Demon Outcast"},
        storage = 40011,
        amount = 3,
        exp = 750000,
        pointsTask = {100, 12},
        items = {{id = 2155, count = 1500}, {id = 9971, count = 150}}
    },
}

-- ============================================
-- STORAGE CONFIGURATION
-- ============================================

task_storage = 50600          -- Current normal task ID
task_kills = 50601            -- Current normal task kills
taskd_storage = 50602         -- Current daily task ID
taskd_kills = 50603           -- Current daily task kills
task_sto_time = 50604         -- Delay after abandoning normal task
time_daySto = 50605           -- Daily task reset time (24 hours)

task_points = 20021           -- Task points accumulated
task_time = 20                -- Hours of punishment for abandoning
task_rank = 20023             -- Task rank (not used in this version)

-- ============================================
-- RANK SYSTEM
-- ============================================

ranks_task = {
    [{1, 50}] = "Novice Hunter",
    [{51, 150}] = "Apprentice Hunter",
    [{151, 300}] = "Journeyman Hunter",
    [{301, 500}] = "Expert Hunter",
    [{501, 750}] = "Master Hunter",
    [{751, 1000}] = "Grand Master Hunter",
    [{1001, math.huge}] = "Legendary Hunter"
}

local RankSequence = {
    ["Novice Hunter"] = 1,
    ["Apprentice Hunter"] = 2,
    ["Journeyman Hunter"] = 3,
    ["Expert Hunter"] = 4,
    ["Master Hunter"] = 5,
    ["Grand Master Hunter"] = 6,
    ["Legendary Hunter"] = 7,
}

function rankIsEqualOrHigher(myRank, RankCheck)
    local ret_1 = RankSequence[myRank]
    local ret_2 = RankSequence[RankCheck]
    return ret_1 >= ret_2
end

-- ============================================
-- PLAYER FUNCTIONS
-- ============================================

function getTaskInfos(player)
    local player = Player(player)
    if not player then return false end
    return task_monsters[player:getStorageValue(task_storage)] or false
end

function getTaskDailyInfo(player)
    local player = Player(player)
    if not player then return false end
    return task_daily[player:getStorageValue(taskd_storage)] or false
end

function taskPoints_get(player)
    local player = Player(player)
    if not player then return 0 end
    if player:getStorageValue(task_points) == -1 then
        return 0
    end
    return player:getStorageValue(task_points)
end

function taskPoints_add(player, count)
    local player = Player(player)
    if not player then return false end
    return player:setStorageValue(task_points, taskPoints_get(player) + count)
end

function taskPoints_remove(player, count)
    local player = Player(player)
    if not player then return false end
    return player:setStorageValue(task_points, taskPoints_get(player) - count)
end

function taskRank_get(player)
    local player = Player(player)
    if not player then return 1 end
    if player:getStorageValue(task_rank) == -1 then
        return 1
    end
    return player:getStorageValue(task_rank)
end

function taskRank_add(player, count)
    local player = Player(player)
    if not player then return false end
    return player:setStorageValue(task_rank, taskRank_get(player) + count)
end

function getRankTask(player)
    local points = taskPoints_get(player)
    local ret = "Novice Hunter"
    for _, v in pairs(ranks_task) do
        if points >= _[1] and points <= _[2] then
            ret = v
        end
    end
    return ret
end

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

function getItemsFromTable(itemtable)
    local text = ""
    for v = 1, #itemtable do
        local count, info = itemtable[v].count, ItemType(itemtable[v].id)
        local ret = ", "
        if v == 1 then
            ret = ""
        elseif v == #itemtable then
            ret = " - "
        end
        text = text .. ret
        text = text .. (count > 1 and count or info:getArticle()) .. " " .. (count > 1 and info:getPluralName() or info:getName())
    end
    return text
end
