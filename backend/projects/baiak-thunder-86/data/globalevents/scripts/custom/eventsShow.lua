local EventsList = {
    ["Sunday"] = {
        {name = "SnowBall", time = "10:00"},
        {name = "Battlefield", time = "15:00"},
        {name = "SafeZone", time = "20:00"},
    },
    ["Monday"] = {
        {name = "SnowBall", time = "10:00"},
        {name = "Battlefield", time = "15:00"},
        {name = "SafeZone", time = "20:00"},
    },
    ["Tuesday"] = {
        {name = "SnowBall", time = "10:00"},
        {name = "Battlefield", time = "15:00"},
        {name = "SafeZone", time = "20:00"},
    },
    ["Wednesday"] = {
        {name = "SnowBall", time = "10:00"},
        {name = "Battlefield", time = "15:00"},
        {name = "SafeZone", time = "20:00"},
    },
    ["Thursday"] = {
        {name = "SnowBall", time = "10:00"},
        {name = "Battlefield", time = "15:00"},
        {name = "SafeZone", time = "20:00"},
    },
    ["Friday"] = {
        {name = "SnowBall", time = "12:00"},
        {name = "Battlefield", time = "15:00"},
        {name = "SafeZone", time = "20:00"},
    },
    ["Saturday"] = {
        {name = "SnowBall", time = "12:00"},
        {name = "Battlefield", time = "15:00"},
        {name = "SafeZone", time = "20:00"},
    },
}

-- Função para converter hora string para número (ex: "10:30" -> 1030)
local function hourToNumber(timeStr)
    local hour, minute = timeStr:match("(%d+):(%d+)")
    return tonumber(hour) * 60 + tonumber(minute)
end

local position = Position(1003, 1217, 7)

function onThink(interval, lastExecution)
    local spectators = Game.getSpectators(position, false, true, 7, 7, 5, 5)
    local event = EventsList[os.date("%A")]
    for _, eventData in pairs(event) do
        local eventTime = hourToNumber(eventData.time)
        local realTime = hourToNumber(os.date("%H:%M:%S"))
        if eventTime >= realTime then
            if #spectators > 0 then
                local first = true
                for _, spectator in ipairs(spectators) do
                    local tile = Tile(position)
                    if tile then
                        local item = tile:getItemById(1387)
                        if item then
                            if item:getActionId() == Bosses.actionIdTp then
                                spectator:say("[BOSS] ".. Bosses:getBossName() .."!", TALKTYPE_MONSTER_SAY, false, spectator, position)
                                if first then
                                    position:sendMagicEffect(56)
                                    position:sendMagicEffect(57)
                                    first = false
                                end
                            else
                                spectator:say("Join the event now!", TALKTYPE_MONSTER_SAY, false, spectator, position)
                                if first then
                                    position:sendMagicEffect(56)
                                    position:sendMagicEffect(57)
                                    first = false
                                end
                            end
                        else
                            spectator:say("Next event: ".. eventData.name .." at ".. eventData.time ..".", TALKTYPE_MONSTER_SAY, false, spectator, position)
                            if first then
                                position:sendMagicEffect(40)
                                first = false
                            end
                        end
                    end
                end
                return true
            end
        end
    end
    return true
end
