function onThink(interval)
    -- Pega todas as caves registradas
    local caves = SUPERUP:freeCave()
    if not caves or type(caves) ~= "table" then
        print("[SuperUP] Nenhuma cave encontrada ou erro na função freeCave.")
        return true
    end

    local currentTime = os.time()
    for _, cave in pairs(caves) do
        local huntId = cave[1]
        local tempoFinal = cave[2]
        local guidPlayer = cave[3]

        -- Se a cave está ocupada (guidPlayer > 0) e o tempo expirou (tempoFinal > 0 e <= currentTime)
        if guidPlayer > 0 and tempoFinal > 0 and currentTime >= tempoFinal then
            local updateQuery = string.format("UPDATE exclusive_hunts SET `guid_player` = 0, `time` = 0, `to_time` = 0 WHERE `hunt_id` = %d", huntId)
            if db.query(updateQuery) then
                print(string.format("[SuperUP] Cave %d liberada (tempo expirado).", huntId))
            end
        end
    end

    return true
end
