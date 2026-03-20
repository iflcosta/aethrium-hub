local config = {
    storage = 84151,
    health = 5000,
    healthToAdd = 20000,
    storageTime = 5, -- In seconds
}

function onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
    if attacker then
        if creature:getHealth() <= config.health and Game.getStorageValue(config.storage) ~= 1 then
            creature:say("I AM IMMORTAL!", TALKTYPE_MONSTER_SAY)
            creature:addHealth(config.healthToAdd)
            creature:getPosition():sendMagicEffect(18)
            Game.setStorageValue(config.storage, 1)
            addEvent(Game.setStorageValue, config.storageTime * 1000, config.storage, 0)
        end
    end

    return primaryDamage, primaryType, secondaryDamage, secondaryType
end

function onDeath(player, corpse, killer, mostDamageKiller, unjustified, mostDamageUnjustified)
    local creature = player
    if creature then
        creature:say("I WILL RETURN!", TALKTYPE_MONSTER_SAY)
    end
    killer:say("[LAST HIT]", TALKTYPE_MONSTER_SAY)
end
