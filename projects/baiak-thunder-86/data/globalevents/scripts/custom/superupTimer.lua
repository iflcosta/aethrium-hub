function onThink(interval)
    if not SUPERUP or not SUPERUP.areas then return true end

    -- Carregar estados das caves
    local states = {}
    local resultId = db.storeQuery("SELECT `hunt_id`, `to_time` FROM `exclusive_hunts` WHERE `to_time` > " .. os.time())
    if resultId then
        repeat
            local hId = result.getDataInt(resultId, "hunt_id")
            local toTime = result.getDataInt(resultId, "to_time")
            states[hId] = toTime
        until not result.next(resultId)
        result.free(resultId)
    end

    local currentTime = os.time()
    local players = Game.getPlayers()
    if #players == 0 then return true end

    for actionid, areaData in pairs(SUPERUP.areas) do
        if areaData.displayPos then
            local hasSpectator = false
            local textPlayer = nil
            for _, player in ipairs(players) do
                if player:getPosition():getDistance(areaData.displayPos) <= 12 then
                    hasSpectator = true
                    textPlayer = player
                    break
                end
            end

            if hasSpectator and textPlayer then
                local toTime = states[actionid] or 0
                if toTime > currentTime then
                    local timeLeft = toTime - currentTime
                    local hours = math.floor(timeLeft / 3600)
                    local minutes = math.floor((timeLeft % 3600) / 60)
                    local strMsg = string.format("%02d:%02d", hours, minutes)
                    
                    textPlayer:say(strMsg, TALKTYPE_MONSTER_SAY, false, nil, areaData.displayPos)
                    areaData.displayPos:sendMagicEffect(CONST_ME_MAGIC_RED)
                end
            end
        end
    end

    return true
end
