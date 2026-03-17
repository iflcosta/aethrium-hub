function capAll(str)
    local newStr = ""; wordSeparate = string.gmatch(str, "([^%s]+)")
    for v in wordSeparate do
        v = v:gsub("^%l", string.upper)
        if newStr ~= "" then
            newStr = newStr.." "..v
        else
            newStr = v
        end
    end
    return newStr
end

craftingConfig = {
    -- Window Config
    mainTitleMsg = "Crafting System",
    mainMsg = "Welcome to the crafting system. Please choose a vocation to begin.",
     
    craftTitle = "Crafting System: ",
    craftMsg = "Here is a list of all items that can be crafted for the ",
    
    -- Player Notifications Config
    needItems = "You do not have all the required items to make ",
     
    -- Material IDs
    materials = {
        goldToken = 25377,
        soulOrb = 5944,
        goldIngot = 9971,
        catalyst = 1949, -- Aethrium Scroll (ID: 1949)
        storeItem = 48946, -- Aethrium Essence (Unique Store Item)
        elementalFee = 10, -- Fee to seal an element
        reSealFee = 5, -- Fee to change an element
        resetFee = 5, -- Fee in Gold Tokens to reset an element
        sealingItem = 25377 -- Gold Token (Placeholder, can be changed)
    },

    -- Elemental Config
    elements = {
        [1] = {name = "None", attr = nil},
        [2] = {name = "Fire", attr = "absorbPercentFire"},
        [3] = {name = "Ice", attr = "absorbPercentIce"},
        [4] = {name = "Earth", attr = "absorbPercentEarth"},
        [5] = {name = "Death", attr = "absorbPercentDeath"},
        [6] = {name = "Energy", attr = "absorbPercentEnergy"},
        [7] = {name = "Holy", attr = "absorbPercentHoly"},
        [8] = {name = "Physical", attr = "absorbPercentPhysical", value = 5} -- Physical is fixed 5%
    },

    elementalTiers = {
        ["Ancient"] = 8,
        ["Celestial"] = 8,
        ["Ethereal"] = 8,
        ["Aethrium"] = 12
    },

    setBonusValues = {
        ["Ancient"] = 12,
        ["Celestial"] = 12,
        ["Ethereal"] = 12,
        ["Aethrium"] = 18
    },

    -- Crafting Config
    system = {
        [1] = {
            vocation = "Knight (Weapons)",
            items = {
                [1] = {item = "Ancient Edge",  itemID = 48920, reqItems = {{item = 36811, count = 1}, {item = 5944, count = 100}, {item = 9971, count = 10}, {item = 25377, count = 10}}}, 
                [2] = {item = "Ancient Cleaver", itemID = 48924, reqItems = {{item = 36740, count = 1}, {item = 5944, count = 100}, {item = 9971, count = 10}, {item = 25377, count = 10}}}, 
                [3] = {item = "Ancient Mace", itemID = 48922, reqItems = {{item = 36742, count = 1}, {item = 5944, count = 100}, {item = 9971, count = 10}, {item = 25377, count = 10}}}, 
                [4] = {item = "Ancient Greatsword", itemID = 48926, reqItems = {{item = 36739, count = 1}, {item = 5944, count = 100}, {item = 9971, count = 10}, {item = 25377, count = 10}}}, 
                [5] = {item = "Ancient Battleaxe", itemID = 48930, reqItems = {{item = 36741, count = 1}, {item = 5944, count = 100}, {item = 9971, count = 10}, {item = 25377, count = 10}}}, 
                [6] = {item = "Ancient Warhammer", itemID = 48928, reqItems = {{item = 36743, count = 1}, {item = 5944, count = 100}, {item = 9971, count = 10}, {item = 25377, count = 10}}}, 
                -- Aethrium Weapons
                [7] = {item = "Aethrium Sword",  itemID = 44764, reqItems = {{item = 48920, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 1}, {item = 5944, count = 300}, {item = 9971, count = 30}, {item = 25377, count = 30}}},
                [8] = {item = "Aethrium Shredder",  itemID = 36987, reqItems = {{item = 48926, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 1}, {item = 5944, count = 300}, {item = 9971, count = 30}, {item = 25377, count = 30}}},
                [9] = {item = "Aethrium Splitter",  itemID = 41003, reqItems = {{item = 48924, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 1}, {item = 5944, count = 300}, {item = 9971, count = 30}, {item = 25377, count = 30}}},
                [10] = {item = "Aethrium Devourer",  itemID = 41004, reqItems = {{item = 48930, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 1}, {item = 5944, count = 300}, {item = 9971, count = 30}, {item = 25377, count = 30}}},
                [11] = {item = "Aethrium Crusher",  itemID = 41005, reqItems = {{item = 48922, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 1}, {item = 5944, count = 300}, {item = 9971, count = 30}, {item = 25377, count = 30}}},
                [12] = {item = "Aethrium Maimer",  itemID = 41006, reqItems = {{item = 48928, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 1}, {item = 5944, count = 300}, {item = 9971, count = 30}, {item = 25377, count = 30}}},
            },
        },
        [2] = {
            vocation = "Knight (Set)",
            items = {
                [1] = {item = "Ancient Plate", itemID = 40008, reqItems = {{item = 31375, count = 1}, {item = 5944, count = 100}, {item = 9971, count = 10}, {item = 25377, count = 10}}}, 
                [2] = {item = "Ancient Greaves", itemID = 40009, reqItems = {{item = 31376, count = 1}, {item = 5944, count = 100}, {item = 9971, count = 10}, {item = 25377, count = 10}}}, 
                [3] = {item = "Ancient Helm", itemID = 40010, reqItems = {{item = 31371, count = 1}, {item = 5944, count = 100}, {item = 9971, count = 10}, {item = 25377, count = 10}}}, 
                [4] = {item = "Ancient Boots", itemID = 48939, reqItems = {{item = 36753, count = 1}, {item = 5944, count = 100}, {item = 9971, count = 10}, {item = 25377, count = 10}}}, 
                [5] = {item = "Ancient Shield",  itemID = 25545, reqItems = {{item = 25372, count = 1}, {item = 5944, count = 100}, {item = 9971, count = 10}, {item = 25377, count = 10}}},
                [6] = {item = "Ancient Legs", itemID = 48931, reqItems = {{item = 36731, count = 1}, {item = 5944, count = 100}, {item = 9971, count = 10}, {item = 25377, count = 10}}}, 
                -- Aethrium Set
                [7] = {item = "Aethrium Bulwark",  itemID = 41007, reqItems = {{item = 40008, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 1}, {item = 5944, count = 300}, {item = 9971, count = 30}, {item = 25377, count = 30}}},
                [8] = {item = "Aethrium Legguards",  itemID = 41008, reqItems = {{item = 40009, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 1}, {item = 5944, count = 300}, {item = 9971, count = 30}, {item = 25377, count = 30}}},
                [9] = {item = "Aethrium Greathelm",  itemID = 41009, reqItems = {{item = 40010, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 1}, {item = 5944, count = 300}, {item = 9971, count = 30}, {item = 25377, count = 30}}},
                [10] = {item = "Aethrium Treads",  itemID = 41010, reqItems = {{item = 48939, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 1}, {item = 5944, count = 300}, {item = 9971, count = 30}, {item = 25377, count = 30}}},
                [11] = {item = "Aethrium Shield",  itemID = 31571, reqItems = {{item = 25545, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 1}, {item = 5944, count = 300}, {item = 9971, count = 30}, {item = 25377, count = 30}}},
            },
        },
        [3] = {
            vocation = "Paladin items",
            items = {
                [1] = {item = "Ancient Bow", itemID = 48933, reqItems = {{item = 36734, count = 1}, {item = 5944, count = 100}, {item = 9971, count = 10}, {item = 25377, count = 10}}}, 
                [2] = {item = "Ancient Crossbow", itemID = 48935, reqItems = {{item = 36735, count = 1}, {item = 5944, count = 100}, {item = 9971, count = 10}, {item = 25377, count = 10}}}, 
                [3] = {item = "Celestial Armor", itemID = 40014, reqItems = {{item = 31379, count = 1}, {item = 5944, count = 100}, {item = 9971, count = 10}, {item = 25377, count = 10}}},
                [4] = {item = "Celestial Greaves", itemID = 40015, reqItems = {{item = 31380, count = 1}, {item = 5944, count = 100}, {item = 9971, count = 10}, {item = 25377, count = 10}}},
                [5] = {item = "Celestial Helmet", itemID = 40016, reqItems = {{item = 31372, count = 1}, {item = 5944, count = 100}, {item = 9971, count = 10}, {item = 25377, count = 10}}},
                [6] = {item = "Celestial Boots", itemID = 40017, reqItems = {{item = 36754, count = 1}, {item = 5944, count = 100}, {item = 9971, count = 10}, {item = 25377, count = 10}}},
                -- Aethrium Paladin
                [7] = {item = "Aethrium Bow",  itemID = 41012, reqItems = {{item = 48933, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 1}, {item = 5944, count = 300}, {item = 9971, count = 30}, {item = 25377, count = 30}}},
                [8] = {item = "Aethrium Crossbow",  itemID = 41013, reqItems = {{item = 48935, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 1}, {item = 5944, count = 300}, {item = 9971, count = 30}, {item = 25377, count = 30}}},
                [9] = {item = "Aethrium Armor",  itemID = 41014, reqItems = {{item = 40014, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 1}, {item = 5944, count = 300}, {item = 9971, count = 30}, {item = 25377, count = 30}}},
                [10] = {item = "Aethrium Legs",  itemID = 41015, reqItems = {{item = 40015, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 1}, {item = 5944, count = 300}, {item = 9971, count = 30}, {item = 25377, count = 30}}},
                [11] = {item = "Aethrium Helmet",  itemID = 41016, reqItems = {{item = 40016, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 1}, {item = 5944, count = 300}, {item = 9971, count = 30}, {item = 25377, count = 30}}},
                [12] = {item = "Aethrium Boots",  itemID = 41017, reqItems = {{item = 40017, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 1}, {item = 5944, count = 300}, {item = 9971, count = 30}, {item = 25377, count = 30}}},
            },
        },
        [4] = {
            vocation = "Mage items",
            items = {
                [1] = {item = "Ethereal Rod", itemID = 40018, reqItems = {{item = 36746, count = 1}, {item = 5944, count = 100}, {item = 9971, count = 10}, {item = 25377, count = 10}}},
                [2] = {item = "Ethereal Wand", itemID = 40019, reqItems = {{item = 36745, count = 1}, {item = 5944, count = 100}, {item = 9971, count = 10}, {item = 25377, count = 10}}},
                [3] = {item = "Ethereal Gown", itemID = 40020, reqItems = {{item = 33316, count = 1}, {item = 5944, count = 100}, {item = 9971, count = 10}, {item = 25377, count = 10}}},
                [4] = {item = "Ethereal Legs", itemID = 40021, reqItems = {{item = 33317, count = 1}, {item = 5944, count = 100}, {item = 9971, count = 10}, {item = 25377, count = 10}}},
                [5] = {item = "Ethereal Tiara", itemID = 40022, reqItems = {{item = 31374, count = 1}, {item = 5944, count = 100}, {item = 9971, count = 10}, {item = 25377, count = 10}}},
                [6] = {item = "Ethereal Shoes", itemID = 40023, reqItems = {{item = 31405, count = 1}, {item = 5944, count = 100}, {item = 9971, count = 10}, {item = 25377, count = 10}}},
                -- Aethrium Mage
                [7] = {item = "Aethrium Rod",  itemID = 41018, reqItems = {{item = 40018, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 1}, {item = 5944, count = 300}, {item = 9971, count = 30}, {item = 25377, count = 30}}},
                [8] = {item = "Aethrium Wand",  itemID = 41019, reqItems = {{item = 40019, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 1}, {item = 5944, count = 300}, {item = 9971, count = 30}, {item = 25377, count = 30}}},
                [9] = {item = "Aethrium Robe",  itemID = 41020, reqItems = {{item = 40020, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 1}, {item = 5944, count = 300}, {item = 9971, count = 30}, {item = 25377, count = 30}}},
                [10] = {item = "Aethrium Pantaloons",  itemID = 41021, reqItems = {{item = 40021, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 1}, {item = 5944, count = 300}, {item = 9971, count = 30}, {item = 25377, count = 30}}},
                [11] = {item = "Aethrium Hat",  itemID = 41022, reqItems = {{item = 40022, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 1}, {item = 5944, count = 300}, {item = 9971, count = 30}, {item = 25377, count = 30}}},
                [12] = {item = "Aethrium Shoes",  itemID = 41023, reqItems = {{item = 40023, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 1}, {item = 5944, count = 300}, {item = 9971, count = 30}, {item = 25377, count = 30}}},
            },
        },
        [5] = {
            vocation = 'Master Rings',
            items = {
                [1] = {item = 'Apprentice Band (All)', itemID = 48943, reqItems = {{item = 5944, count = 150}, {item = 9971, count = 10}, {item = 25377, count = 10}}},
                [2] = {item = 'Ancient Band (Knight)', itemID = 48944, reqItems = {{item = 48943, count = 1}, {item = 5944, count = 300}, {item = 9971, count = 20}, {item = 25377, count = 20}}},
                [3] = {item = 'Celestial Signet (Paladin)', itemID = 40024, reqItems = {{item = 48943, count = 1}, {item = 5944, count = 400}, {item = 9971, count = 30}, {item = 25377, count = 20}}},
                [4] = {item = 'Ethereal Loop (Mage)', itemID = 40025, reqItems = {{item = 48943, count = 1}, {item = 5944, count = 400}, {item = 9971, count = 30}, {item = 25377, count = 20}}},
                [5] = {item = 'Aethrium Sovereign (Warrior)', itemID = 41024, reqItems = {{item = 48944, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 2}, {item = 5944, count = 900}, {item = 9971, count = 60}, {item = 25377, count = 60}}},
                [6] = {item = 'Direct Sovereign (Warrior)', itemID = 41024, reqItems = {{item = 48943, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 2}, {item = 5944, count = 1100}, {item = 9971, count = 75}, {item = 25377, count = 75}}},
                [7] = {item = 'Aethrium Sovereign (Archer)', itemID = 41025, reqItems = {{item = 40024, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 2}, {item = 5944, count = 1200}, {item = 9971, count = 90}, {item = 25377, count = 60}}},
                [8] = {item = 'Direct Sovereign (Archer)', itemID = 41025, reqItems = {{item = 48943, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 2}, {item = 5944, count = 1400}, {item = 9971, count = 100}, {item = 25377, count = 70}}},
                [9] = {item = 'Aethrium Sovereign (Sage)', itemID = 41026, reqItems = {{item = 40025, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 2}, {item = 5944, count = 1200}, {item = 9971, count = 90}, {item = 25377, count = 60}}},
                [10] = {item = 'Direct Sovereign (Sage)', itemID = 41026, reqItems = {{item = 48943, count = 1}, {item = 48946, count = 1}, {item = 1949, count = 2}, {item = 5944, count = 1400}, {item = 9971, count = 100}, {item = 25377, count = 70}}},
            },
        },
    },
}
