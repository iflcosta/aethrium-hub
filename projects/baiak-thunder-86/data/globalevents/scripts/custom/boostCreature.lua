local function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end

function onStartup()
    -- Sorteia o monstro inicial quando o servidor inicia
    BoostedCreature:start()
    if BoostedCreature.db and boostCreature[1] then
        db.query(string.format(
            "UPDATE `boost_creature` SET `name` = '%s', `exp` = %d, `loot` = %d",
            firstToUpper(boostCreature[1].name),
            boostCreature[1].exp,
            boostCreature[1].loot
        ))
    end
    return true
end

function onThink(interval)
    -- Apenas repete broadcast a cada intervalo configurado (ex: 3h)
    if boostCreature[1] then
        Game.broadcastMessage(
            BoostedCreature.messages.prefix ..
            BoostedCreature.messages.chosen:format(
                firstToUpper(boostCreature[1].name),
                boostCreature[1].exp,
                boostCreature[1].loot
            )
        )
    end
    return true
end

function onTime(interval)
    -- Sorteio automático diário (ex: às 00:00)
    BoostedCreature:start()
    if BoostedCreature.db and boostCreature[1] then
        db.query(string.format(
            "UPDATE `boost_creature` SET `name` = '%s', `exp` = %d, `loot` = %d",
            firstToUpper(boostCreature[1].name),
            boostCreature[1].exp,
            boostCreature[1].loot
        ))
    end
    Game.broadcastMessage("[Boosted Creature] Novo monstro sorteado: " ..
        firstToUpper(boostCreature[1].name) ..
        " (+50% XP, +50% loot).")
    return true
end
