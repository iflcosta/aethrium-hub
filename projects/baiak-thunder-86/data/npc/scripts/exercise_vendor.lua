local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid) npcHandler:onCreatureAppear(cid) end
function onCreatureDisappear(cid) npcHandler:onCreatureDisappear(cid) end
function onCreatureSay(cid, type, msg) npcHandler:onCreatureSay(cid, type, msg) end
function onThink() npcHandler:onThink() end

local function openExerciseShop(player)
    local window = ModalWindow(1000, "Exercise Weapons Shop", "Choose your weapon:")
    window:addChoice(1, "Exercise Sword - 2000 gold (500 charges)")
    window:addChoice(2, "Durable Exercise Sword - 8000 gold (1800 charges)")
    window:addChoice(3, "Lasting Exercise Sword - 50000 gold (14400 charges)")

    window:addChoice(4, "Exercise Axe - 2000 gold (500 charges)")
    window:addChoice(5, "Durable Exercise Axe - 8000 gold (1800 charges)")
    window:addChoice(6, "Lasting Exercise Axe - 50000 gold (14400 charges)")

    window:addChoice(7, "Exercise Club - 2000 gold (500 charges)")
    window:addChoice(8, "Durable Exercise Club - 8000 gold (1800 charges)")
    window:addChoice(9, "Lasting Exercise Club - 50000 gold (14400 charges)")

    window:addChoice(10, "Exercise Bow - 2000 gold (500 charges)")
    window:addChoice(11, "Durable Exercise Bow - 8000 gold (1800 charges)")
    window:addChoice(12, "Lasting Exercise Bow - 50000 gold (14400 charges)")

    window:addChoice(13, "Exercise Rod - 2000 gold (500 charges)")
    window:addChoice(14, "Durable Exercise Rod - 8000 gold (1800 charges)")
    window:addChoice(15, "Lasting Exercise Rod - 50000 gold (14400 charges)")

    window:addChoice(16, "Exercise Wand - 2000 gold (500 charges)")
    window:addChoice(17, "Durable Exercise Wand - 8000 gold (1800 charges)")
    window:addChoice(18, "Lasting Exercise Wand - 50000 gold (14400 charges)")

    window:addButton(1, "Buy")
    window:addButton(2, "Cancel")
    window:setDefaultEnterButton(1)
    window:setDefaultEscapeButton(2)

    player:registerEvent("ExerciseShop")
    window:sendToPlayer(player)
end

function creatureSayCallback(cid, type, msg)
    local player = Player(cid)
    if msg:lower() == "trade" then
        openExerciseShop(player)
        return true
    end
    return false
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
