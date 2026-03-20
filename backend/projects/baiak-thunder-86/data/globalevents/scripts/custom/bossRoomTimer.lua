function onThink(interval)
    if not BossRoom then return true end

    -- Load the state of all rooms in bulk to avoid hammering the database with 20 separate queries every second
    local states = {}
    local resultId = db.storeQuery("SELECT `room_id`, `to_time` FROM `boss_room`")
    if resultId then
        repeat
            local rId = result.getDataInt(resultId, "room_id")
            local toTime = result.getDataInt(resultId, "to_time")
            states[rId] = toTime
        until not result.next(resultId)
        result.free(resultId)
    end

    local currentTime = os.time()
    
    if _G.BossRoomToggleState == nil then _G.BossRoomToggleState = false end
    _G.BossRoomToggleState = not _G.BossRoomToggleState

    local players = Game.getPlayers()
    if #players == 0 then return true end

    for actionid, bossData in pairs(BossRoom.monstros) do
        if bossData.displayPos then
            -- Only render if there's a player nearby (reduces unneeded CPU usage like textEffect.lua)
            local hasSpectator = false
            local textPlayer = nil
            for _, player in ipairs(players) do
                if player:getPosition():getDistance(bossData.displayPos) <= 12 then
                    hasSpectator = true
                    textPlayer = player
                    break
                end
            end

            if hasSpectator and textPlayer then
                local toTime = states[actionid] or 0
                
                if toTime > currentTime then
                    -- Room is occupied
                    local minutesLeft = math.floor((toTime - currentTime) / 60)
                    local strMsg = minutesLeft .. " min"
                    if minutesLeft < 1 then strMsg = "< 1 min" end
                    
                    textPlayer:say(strMsg, TALKTYPE_MONSTER_SAY, false, nil, bossData.displayPos)
                    bossData.displayPos:sendMagicEffect(CONST_ME_MAGIC_RED)
                else
                    -- Room is free
                    -- textPlayer:say("LIVRE", TALKTYPE_MONSTER_SAY, false, nil, bossData.displayPos)
                    -- bossData.displayPos:sendMagicEffect(CONST_ME_MAGIC_GREEN)
                end
            end
        end
    end

    return true
end
