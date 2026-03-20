configMining = {
    msg = {
        naoLocal = "You can't mine here.",
        naoPick = "You can only mine with a pick.",
        minerouWin = "You won a %s.",
        dano = "The rocks collapsed, and you took a hit.",
        fail = "Fail!",
        upNivel = "You've leveled up in mining! You are now %s. Congratulations!",
        usarEspecial = true,
        especial = "[PREMIUM]",
    },
    level = {
        active = true,
        storageTentativas = 81056,
        storageNivel = 81057,
        [1] = {name = "Beginner", qntMin = 0, qntMax = 50},
        [2] = {name = "Intermediate", qntMin = 51, qntMax = 199},
        [3] = {name = "Advanced", qntMin = 200, qntMax = 399},
        [4] = {name = "Experienced", qntMin = 400},
    },
    itens = {
        {itemid = 2147, chancePickNormal = 0.02, chancePickEspecial = 0.05},
        {itemid = 2146, chancePickNormal = 0.02, chancePickEspecial = 0.05},
        {itemid = 2150, chancePickNormal = 0.02, chancePickEspecial = 0.05},
        {itemid = 9970, chancePickNormal = 0.02, chancePickEspecial = 0.05},
        {itemid = 2149, chancePickNormal = 0.02, chancePickEspecial = 0.05},
        {itemid = 2145, chancePickNormal = 0.02, chancePickEspecial = 0.05},
        {itemid = 2156, chancePickNormal = 0.01, chancePickEspecial = 0.04},
        {itemid = 2155, chancePickNormal = 0.01, chancePickEspecial = 0.04},
        {itemid = 2158, chancePickNormal = 0.01, chancePickEspecial = 0.04},
        {itemid = 2153, chancePickNormal = 0.01, chancePickEspecial = 0.04},
        {itemid = 11421, chancePickNormal = 0.001, chancePickEspecial = 0.015, level = true, nivelMin = 3},
        {itemid = 12345, chancePickNormal = 0.0, chancePickEspecial = 0.01, level = true, nivelMin = 3}, -- Aethrium Ore
    },
    hit = {
        active = true,
        danoMin = 300, 
        danoMax = 500, 
        chance = 0.02
    },
    idPick = 2553,
    idPickEspecial = 11421,
    actionIdPedras = 34561,
}
