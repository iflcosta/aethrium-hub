-- ============================================================
-- NEXUS STORE - Shop Configuration
-- To add items: copy an existing entry and change the values.
-- itemId must exist in your server's items.otb AND OTClient sprites.
-- ============================================================

shopConfig = {
    opcode = 201,
    currencyName = "Nexus Coins",

    categories = {
        [1] = {
            name = "Itens",
            items = {
                {name = "Crystal Coin (100x)", itemId = 2160, count = 100, price = 10},
                {name = "Magic Longsword",     itemId = 2390, count = 1,   price = 50},
                {name = "Solar Axe",           itemId = 8925, count = 1,   price = 50},
            }
        },
        [2] = {
            name = "Consumiveis",
            items = {
                {name = "Sudden Death (1000x)",   itemId = 2268,  count = 1000, price = 1},
                {name = "Ultimate Healing (1500x)", itemId = 2273, count = 1500, price = 1},
                {name = "Avalanche Rune (2000x)", itemId = 2274,  count = 2000, price = 1},
                {name = "Great Fireball (2000x)", itemId = 2304,  count = 2000, price = 1},
                {name = "Magic Wall (800x)",      itemId = 2293,  count = 800,  price = 1},
                {name = "Paralyze Rune (500x)",   itemId = 2278,  count = 500,  price = 1},
                -- Potions de Elite
                {name = "Ultimate Mana (500x)",   itemId = 26029, count = 500,  price = 1},
                {name = "Supreme Health (500x)",  itemId = 26031, count = 500,  price = 1},
                {name = "Ultimate Spirit (500x)", itemId = 26030, count = 500,  price = 1},
            }
        },
        [3] = {
            name = "Training Boost",
            items = {
                {name = "Basic Training (7d)",   itemId = 7371, count = 1, price = 3},
                {name = "Advanced Training (7d)", itemId = 7370, count = 1, price = 5},
                {name = "Premium Training (7d)", itemId = 7369, count = 1, price = 8},
            }
        },
        [4] = {
            name = "VIP Days",
            items = {
                {name = "VIP Bronze (30 dias)", itemId = 10135, count = 1, price = 20},
                {name = "VIP Prata (30 dias)",  itemId = 10134, count = 1, price = 40},
                {name = "VIP Ouro (30 dias)",   itemId = 10133, count = 1, price = 60},
            }
        },
        [5] = {
            name = "Boosts & Eventos",
            items = {
                {name = "Stamina Potion 3h",     itemId = 39381, count = 1, price = 5},
                {name = "Stamina Full 42h",      itemId = 39380, count = 1, price = 10},
                {name = "Stamina Infinite 7d",   itemId = 39391, count = 1, price = 15},
            }
        },
        [6] = {
            name = "House Furniture",
            items = {
                {name = "Food Maker",            itemId = 16098, count = 1, price = 10, requireHouse = true},
                {name = "Supply Statue",         itemId = 26075, count = 1, price = 15, requireHouse = true},
                {name = "Training Statue",       itemId = 24682, count = 1, price = 30, requireHouse = true},
                {name = "Monk Trainer",          itemId = 31219, count = 1, price = 50, requireHouse = true},
                {name = "Demon Trainer",         itemId = 31217, count = 1, price = 100, requireHouse = true},
                {name = "Ferumbras Trainer",     itemId = 31215, count = 1, price = 200, requireHouse = true},
            }
        },
        [7] = {
            name = "Exercise Weapons",
            items = {
                {name = "Lasting Sword",         itemId = 37941, count = 1, charges = 14400, price = 5},
                {name = "Lasting Axe",           itemId = 37942, count = 1, charges = 14400, price = 5},
                {name = "Lasting Club",          itemId = 37943, count = 1, charges = 14400, price = 5},
                {name = "Lasting Bow",           itemId = 37944, count = 1, charges = 14400, price = 5},
                {name = "Lasting Rod",           itemId = 37945, count = 1, charges = 14400, price = 5},
                {name = "Lasting Wand",          itemId = 37946, count = 1, charges = 14400, price = 5},
            }
        },
        [8] = {
            name = "Task Rewards",
            items = {
                -- TIER 1: UTILITÁRIOS DA FORJA
                {
                    name = "Cleansing Stone",
                    itemId = 8302, 
                    count = 1,
                    price = 50,
                    isSecondPrice = true, 
                    description = "Apaga os atributos RNG de um equipamento para roletar novamente."
                },
                {
                    name = "Protection Scroll",
                    itemId = 8301, 
                    count = 1,
                    price = 150,
                    isSecondPrice = true,
                    description = "Seguro Anti-Quebra: Protege seu equipamento de trincar na Forja."
                },
                {
                    name = "Repair Hammer",
                    itemId = 8303, 
                    count = 1,
                    price = 400,
                    isSecondPrice = true,
                    description = "Conserta um equipamento [Trincado], devolvendo seus status."
                },
                -- TIER 2: COSMÉTICOS
                {
                    name = "Ferumbras Hat", 
                    itemId = 5903,
                    count = 1,
                    price = 5000,
                    isSecondPrice = true,
                    description = "Item cosmetico classico para liberar o Addon 2 do Mage."
                }
            }
        },
        [9] = {
            name = "Boss Rewards",
            items = {
                {
                    name = "Ferumbras Hat", 
                    itemId = 5903,
                    count = 1,
                    price = 50,
                    isThirdPrice = true,
                    description = "Comprado com Boss Points."
                },
                {
                    name = "Morgaroth's Heart", 
                    itemId = 5943,
                    count = 1,
                    price = 40,
                    isThirdPrice = true,
                    description = "Comprado com Boss Points."
                }
            }
        },
    }
}
