if not boostCreature then boostCreature = {} end

BoostedCreature = {
    monsters = {
        "Demon", "Frost Dragon", "Grim Reaper",
        "Juggernaut", "Behemoth", "Hydra", "Serpent Spawn",
        "Dragon Lord", "Hellhound", "War Golem",
        "Undead Dragon", "Medusa", "Phantasm", "Dark Torturer",
        "Spectre", "Betrayed Wraith", "Infernal Phantom"
    },
    db = true,
    exp = {50, 50}, -- fixo 50% XP
    loot = {50, 50}, -- fixo 50% loot
    position = Position(977, 1208, 7),
    messages = {
        prefix = "[Boosted Creature] ",
        chosen = "The chosen creature is %s. When killed, you receive +%d%% experience and +%d%% loot.",
    },
}

function BoostedCreature:start()
    local rand = math.random
    local monsterRand = BoostedCreature.monsters[rand(#BoostedCreature.monsters)]
    local expRand = BoostedCreature.exp[1] -- fixo 50%
    local lootRand = BoostedCreature.loot[1] -- fixo 50%

    boostCreature[1] = {name = monsterRand:lower(), exp = expRand, loot = lootRand}

    local monster = Game.createMonster(boostCreature[1].name, BoostedCreature.position, false, true)
    if monster then
        monster:setDirection(SOUTH)
    end
end
