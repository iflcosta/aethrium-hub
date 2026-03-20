-- Optimized Text Effect System
-- Moves config outside onThink and adds distance checks to save CPU

local effects = {
    {position = Position(987, 1215, 7), effect = 29},
    {position = Position(998, 1216, 7), effect = 29},
    {position = Position(987, 1215, 7), text = "[VIP]", effect = 40, say = true, color = TEXTCOLOR_GOLD},
    {position = Position(1000, 1208, 7), text = "Depot", effect = 40, say = true, color = TEXTCOLOR_LIGHTBLUE},
    {position = Position(982, 1208, 7), text = "MiniGames", effect = 18, say = true, color = TEXTCOLOR_ORANGE},
    {position = Position(983, 1208, 7), text = "SuperUP", effect = 18, say = true, color = TEXTCOLOR_RED},
    {position = Position(991, 1210, 7), text = "Welcome", effect = 18, say = true, color = TEXTCOLOR_WHITE},
    {position = Position(985, 1208, 7), text = "Trainers", effect = 18, say = true, color = TEXTCOLOR_GREEN},
    {position = Position(986, 1208, 7), text = "Hunts", effect = 18, say = true, color = TEXTCOLOR_YELLOW},
    {position = Position(996, 1208, 7), text = "Quests", effect = 18, say = true, color = TEXTCOLOR_TEAL},
    {position = Position(997, 1208, 7), text = "NPCs", effect = 18, say = true, color = TEXTCOLOR_LIGHTBLUE},
    {position = Position(999, 1208, 7), text = "Cities", effect = 18, say = true, color = TEXTCOLOR_PINK},
    {position = Position(998, 1208, 7), text = "Boss", effect = 18, say = true, color = TEXTCOLOR_RED},
    {position = Position(980, 1215, 7), text = "Mining", effect = 45, color = TEXTCOLOR_GREY},
    {position = Position(998, 1216, 7), text = "Castle 24H", effect = 7, say = true, color = TEXTCOLOR_PURPLE},
    {position = Position(817, 1408, 7), text = "Wintermere", effect = 40, say = true, color = TEXTCOLOR_WHITE},
    {position = Position(819, 1408, 7), text = "Shadow Wood", effect = 40, say = true, color = TEXTCOLOR_GREEN},
    {position = Position(821, 1408, 7), text = "Akravi", effect = 40, say = true, color = TEXTCOLOR_YELLOW},
    {position = Position(825, 1408, 7), text = "Al Arar", effect = 40, say = true, color = TEXTCOLOR_ORANGE},
    {position = Position(827, 1408, 7), text = "Bhark", effect = 40, say = true, color = TEXTCOLOR_RED},
    {position = Position(829, 1408, 7), text = "Jamila Island", effect = 40, say = true, color = TEXTCOLOR_PURPLE},
    {position = Position(823, 1415, 7), text = "Temple", effect = 40, say = true, color = TEXTCOLOR_BLUE},
    {position = Position(1653, 1108, 8), text = "Back", effect = 45, say = true, color = TEXTCOLOR_LIGHTGREY},
    {position = Position(1545, 1067, 4), text = "Exit", effect = 1, say = true, color = TEXTCOLOR_WHITE},
    {position = Position(401, 1248, 7), text = "Temple", effect = 40, say = true, color = TEXTCOLOR_BLUE},
    {position = Position(1418, 1309, 8), text = "Temple", effect = 40, say = true, color = TEXTCOLOR_BLUE},
    {position = Position(1426, 1309, 8), text = "Quests", effect = 40, say = true, color = TEXTCOLOR_RED},
    {position = Position(1422, 1281, 7), text = "Temple", effect = 40, say = true, color = TEXTCOLOR_BLUE},
    {position = Position(469, 1219, 6), text = "Temple", effect = 40, say = true, color = TEXTCOLOR_BLUE},
    {position = Position(471, 1379, 6), text = "Hunts", effect = 49, say = true, color = TEXTCOLOR_YELLOW},
    {position = Position(472, 1379, 6), text = "Trainers", effect = 49, say = true, color = TEXTCOLOR_GREEN},
    {position = Position(473, 1379, 6), text = "NPCs", effect = 49, say = true, color = TEXTCOLOR_TEAL},
    {position = Position(983, 1213, 8), text = "Citizen Addon", effect = 49, say = true, color = TEXTCOLOR_GOLD},
    {position = Position(997, 1203, 7), text = "Castle 48H", effect = 40, say = true, color = TEXTCOLOR_DARKRED},
    {position = Position(546, 1240, 7), text = "Temple", effect = 40, say = true, color = TEXTCOLOR_BLUE},
    {position = Position(583, 1240, 7), text = "Temple", effect = 40, say = true, color = TEXTCOLOR_BLUE},
    {position = Position(477, 1379, 6), text = "Cities", effect = 49, say = true, color = TEXTCOLOR_PINK},
    {position = Position(633, 1231, 5), text = "Temple", effect = 40, say = true, color = TEXTCOLOR_BLUE},
    {position = Position(478, 1379, 6), text = "Bosses", effect = 49, say = true, color = TEXTCOLOR_RED},
    {position = Position(1721, 946, 7), text = "Exit", effect = 49, say = true, color = TEXTCOLOR_WHITE},
    {position = Position(1655, 982, 7), text = "Exit", effect = 49, say = true, color = TEXTCOLOR_WHITE},
    {position = Position(1655, 985, 7), text = "Join to\nPlay!", effect = 49, say = true, color = TEXTCOLOR_GREEN},
    {position = Position(984, 1212, 7), text = "Rotworms", effect = 57, say = false, color = TEXTCOLOR_BLACK},
    {position = Position(1002, 1204, 7), text = "Reward Chest", effect = 40, say = true, color = TEXTCOLOR_LIGHTBLUE},
    {position = Position(817, 1424, 7), text = "Snake", effect = 40, say = true, color = TEXTCOLOR_GREEN},
    {position = Position(819, 1424, 7), text = "Bomberman", effect = 40, say = true, color = TEXTCOLOR_RED},
    {position = Position(821, 1433, 7), text = "Temple", effect = 40, say = true, color = TEXTCOLOR_BLUE}
}

function onThink(interval)
    local players = Game.getPlayers()
    if #players == 0 then
        return true
    end

    local today = tonumber(os.date("%Y%m%d"))
    local dailyPos = Position(1002, 1204, 7)
    local boostedPos = Position(977, 1208, 7)

    -- Group effects by "chunk" or just iterate them efficiently
    -- Since they are static, we can optimize by only processing effects near players
    for i = 1, #effects do
        local settings = effects[i]
        local hasSpectator = false
        
        -- Cheap distance check before calling heavy getSpectators
        for _, player in ipairs(players) do
            if getDistanceBetween(player:getPosition(), settings.position) <= 10 then
                hasSpectator = true
                
                -- Personalized Daily Reward (Move inside player loop for true privacy)
                if settings.position == dailyPos and player:getStorageValue(50801) ~= today and player:getLevel() >= 150 then
                    -- Use private message or status message to avoid O(N^2) network flooding
                    player:sendTextMessage(MESSAGE_STATUS_SMALL, "Your Daily Reward is ready!")
                end
                
                -- Visual effects only need to be sent once per think, engine handles broadcasting
                player:say(settings.text, TALKTYPE_MONSTER_SAY, false, nil, settings.position)
                
                if settings.effect then
                    settings.position:sendMagicEffect(settings.effect)
                end
                
                break -- Only need to trigger once per think for visual effects
            end
        end
    end

    -- Boosted Creature logic (One broadcast is enough)
    if boostCreature and boostCreature[1] then
        for _, player in ipairs(players) do
            if getDistanceBetween(player:getPosition(), boostedPos) <= 10 then
                player:say("Boosted Creature\n ", TALKTYPE_MONSTER_SAY, false, nil, boostedPos)
                player:say("+" .. boostCreature[1].exp .."% EXP", TALKTYPE_MONSTER_SAY, false, nil, Position(977, 1207, 7))
                player:say("+" .. boostCreature[1].loot .."% Loot", TALKTYPE_MONSTER_SAY, false, nil, Position(977, 1209, 7))
                break
            end
        end
    end

    return true
end
