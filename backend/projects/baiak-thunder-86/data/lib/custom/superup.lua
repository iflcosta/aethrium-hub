STORAGEVALUE_SUPERUP_INDEX = 95005
STORAGEVALUE_SUPERUP_TEMPO = 95006
STORAGEVALUE_SUPERUP_REENTRY = 95007

-- Configuração principal do SuperUP
SUPERUP = {
    msg = {
        naoDisponivel = "Esta cave esta ocupada ate %s",
        disponivel = "Parabens voce comprou uma cave do Super UP com duracao de %d %s",
        reentradaFree = "Voce voltou para sua cave (re-entrada gratis)",
        reentradaPaga = "Voce voltou para sua cave. Cobrado 25%% do valor original de %s",
        refund = "Voce desistiu da cave e recebeu 50%% de reembolso (%d %s)",
        naoItem = "Voce precisa de %d Nexus Coins para acessar esta area",
        naoMoeda = "Voce nao possui a quantidade necessaria de %s para acessar esta hunt",
        tempoAcabou = "O seu tempo de Super UP acabou",
        possuiCave = "Voce ja possui uma cave do Super UP",
    },
    areas = {
        -- [ LEVEL 500+ ] (50 Nexus Coins)
        [20000] = {monsters = {"Cobra Assassin", "Cobra Scout", "Cobra Vizier"}, time = 10800, currency = "coins", price = 50, displayPos = Position(542, 1251, 7), destination = Position(1930, 1741, 7), from = Position(1831, 1708, 7), to = Position(1930, 1741, 7)}, -- SuperUP 1
        [20001] = {monsters = {"Cobra Assassin", "Cobra Scout", "Cobra Vizier"}, time = 10800, currency = "coins", price = 50, destination = Position(1537, 2081, 7), from = Position(1496, 2047, 7), to = Position(1573, 2115, 7)}, -- SuperUP 2
        [20002] = {monsters = {"Cobra Assassin", "Cobra Scout", "Cobra Vizier"}, time = 10800, currency = "coins", price = 50, destination = Position(1682, 1932, 7), from = Position(1600, 1925, 7), to = Position(1714, 2012, 7)}, -- SuperUP 3

        -- [ LEVEL 700+ ] (100 Nexus Coins)
        [20003] = {monsters = {"Falcon Knight", "Falcon Paladin"}, time = 10800, currency = "coins", price = 100, destination = Position(1641, 1877, 7), from = Position(1614, 1801, 7), to = Position(1724, 1899, 7)}, -- SuperUP 4
        [20004] = {monsters = {"Falcon Knight", "Falcon Paladin"}, time = 10800, currency = "coins", price = 100, destination = Position(1812, 1915, 7), from = Position(1736, 1852, 7), to = Position(1861, 1980, 7)}, -- SuperUP 5
        [20005] = {monsters = {"Falcon Knight", "Falcon Paladin"}, time = 10800, currency = "coins", price = 100, destination = Position(2088, 1871, 7), from = Position(2023, 1860, 7), to = Position(2132, 1930, 7)}, -- SuperUP 6
        [20006] = {monsters = {"Falcon Knight", "Falcon Paladin"}, time = 10800, currency = "coins", price = 100, destination = Position(2192, 1919, 7), from = Position(2151, 1847, 7), to = Position(2254, 1934, 7)}, -- SuperUP 7

        -- [ LEVEL 900+ ] (150 Nexus Coins)
        [20007] = {monsters = {"Mould Phantom", "Rotten Golem", "Brachiodemon"}, time = 10800, currency = "coins", price = 150, destination = Position(2178, 1831, 7), from = Position(2149, 1752, 7), to = Position(2260, 1837, 7)}, -- SuperUP 8
        [20008] = {monsters = {"Mould Phantom", "Rotten Golem", "Brachiodemon"}, time = 10800, currency = "coins", price = 150, destination = Position(2083, 1675, 7), from = Position(2068, 1617, 7), to = Position(2169, 1696, 7)}, -- SuperUP 9
        [20009] = {monsters = {"Mould Phantom", "Rotten Golem", "Brachiodemon"}, time = 10800, currency = "coins", price = 150, destination = Position(1740, 1805, 7), from = Position(1729, 1761, 7), to = Position(1826, 1847, 7)}, -- SuperUP 10

        -- [ LEVEL 500+ ] (500 Task Points)
        [20010] = {monsters = {"True Dawnfire Asura", "True Frost Flower Asura", "True Midnight Asura"}, time = 10800, currency = "tasks", price = 500, destination = Position(198, 1446, 8), from = Position(184, 1434, 8), to = Position(313, 1533, 8)},
        [20011] = {monsters = {"True Dawnfire Asura", "True Frost Flower Asura", "True Midnight Asura"}, time = 10800, currency = "tasks", price = 500, destination = Position(845, 1545, 7), from = Position(790, 1529, 7), to = Position(885, 1671, 8)},
        [20012] = {monsters = {"True Dawnfire Asura", "True Frost Flower Asura", "True Midnight Asura"}, time = 10800, currency = "tasks", price = 500, destination = Position(864, 1692, 7), from = Position(850, 1667, 7), to = Position(934, 1768, 7)},

        -- [ LEVEL 700+ ] (1000 Task Points)
        [20013] = {monsters = {"Flimsy Lost Soul", "Freakish Lost Soul", "Mean Lost Soul"}, time = 10800, currency = "tasks", price = 1000, destination = Position(315, 647, 7), from = Position(291, 615, 7), to = Position(395, 705, 7)},
        [20014] = {monsters = {"Flimsy Lost Soul", "Freakish Lost Soul", "Mean Lost Soul"}, time = 10800, currency = "tasks", price = 1000, destination = Position(313, 757, 7), from = Position(250, 725, 7), to = Position(373, 809, 7)},
        [20016] = {monsters = {"Flimsy Lost Soul", "Freakish Lost Soul", "Mean Lost Soul"}, time = 10800, currency = "tasks", price = 1000, destination = Position(782, 943, 7), from = Position(727, 903, 7), to = Position(835, 966, 7)},

        -- [ LEVEL 900+ ] (1500 Task Points)
        [20017] = {monsters = {"Bony Sea Devil", "Cloak of Terror", "Courage Leech"}, time = 10800, currency = "tasks", price = 1500, destination = Position(911, 932, 7), from = Position(863, 902, 7), to = Position(954, 967, 7)},
        [20018] = {monsters = {"Bony Sea Devil", "Cloak of Terror", "Courage Leech"}, time = 10800, currency = "tasks", price = 1500, destination = Position(956, 1596, 7), from = Position(923, 1576, 7), to = Position(996, 1636, 7)},
        [20019] = {monsters = {"Bony Sea Devil", "Cloak of Terror", "Courage Leech"}, time = 10800, currency = "tasks", price = 1500, destination = Position(204, 638, 7), from = Position(189, 607, 7), to = Position(281, 687, 7)},
        [20020] = {monsters = {"Bony Sea Devil", "Cloak of Terror", "Courage Leech"}, time = 10800, currency = "tasks", price = 1500, destination = Position(1275, 1703, 8), from = Position(1220, 1694, 8), to = Position(1311, 1811, 8)}
    },
    setTime = 3, -- duração em horas
    nexusCoinCost = 0, -- Custo em Nexus Coins (Tibia Coins)
}

-- Função para consultar dono e tempo de uma cave
function SUPERUP:getCave(id)
    local resultCave = db.storeQuery("SELECT guid_player, to_time FROM exclusive_hunts WHERE `hunt_id` = " .. id)
    if not resultCave then
        return false
    end

    local caveOwner = result.getDataInt(resultCave, "guid_player")
    local caveTime = result.getDataLong(resultCave, "to_time")
    result.free(resultCave)

    return {dono = caveOwner, tempo = caveTime}
end

-- Função para listar todas as caves registradas no banco
function SUPERUP:freeCave()
    local freeCaves = {}
    local dbRes = db.storeQuery("SELECT `hunt_id`, `to_time`, `guid_player` FROM exclusive_hunts")
    if not dbRes then
        return freeCaves
    end

    repeat
        local idHunt = result.getDataInt(dbRes, "hunt_id")
        local tempoFinal = result.getDataLong(dbRes, "to_time")
        local guidPlayer = result.getDataInt(dbRes, "guid_player")

        table.insert(freeCaves, {idHunt, tempoFinal, guidPlayer})
    until not result.next(dbRes)

    result.free(dbRes)
    return freeCaves
end

-- Inicialização automática do banco de dados
db.query("CREATE TABLE IF NOT EXISTS `exclusive_hunts` (`hunt_id` INT PRIMARY KEY, `guid_player` INT DEFAULT 0, `time` INT DEFAULT 0, `to_time` INT DEFAULT 0);")

for id, _ in pairs(SUPERUP.areas) do
    db.query(string.format("INSERT IGNORE INTO `exclusive_hunts` (`hunt_id`) VALUES (%d);", id))
end
