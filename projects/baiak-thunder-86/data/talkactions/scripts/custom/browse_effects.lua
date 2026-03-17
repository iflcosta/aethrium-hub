-- Magic Effect Browser for OTCv8
-- Created to find new Wings & Auras IDs

local effectEvent = {}

function browseLoop(cid, currentId)
    local player = Player(cid)
    if not player then 
        effectEvent[cid] = nil
        return false 
    end

    player:getPosition():sendMagicEffect(currentId)
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "[Effect Browser] ID Atual: " .. currentId)
    
    effectEvent[cid] = addEvent(browseLoop, 1000, cid, currentId + 1)
end

function onSay(player, words, param)
    if not player:getGroup():getAccess() then
        return true
    end

    local cid = player:getId()
    local split = param:split(",")
    local action = split[1]:lower():trim()

    if action == "start" then
        if effectEvent[cid] then
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, "[Effect Browser] O scanner ja esta rodando. Use !browse stop primeiro.")
            return true
        end

        local startId = tonumber(split[2]) or 1
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[Effect Browser] Iniciando scanner a partir do ID: " .. startId)
        browseLoop(cid, startId)
        
    elseif action == "stop" then
        if effectEvent[cid] then
            stopEvent(effectEvent[cid])
            effectEvent[cid] = nil
            player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[Effect Browser] Scanner parado.")
        else
            player:sendTextMessage(MESSAGE_STATUS_CONSOLE_RED, "[Effect Browser] Nao ha nenhum scanner rodando.")
        end
    else
        player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "Uso: !browse start, ID ou !browse stop")
    end

    return true
end
