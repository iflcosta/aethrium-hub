local boost = TalkAction("!boostcreature")

function boost.onSay(player, words, param)
    if not boostCreature[1] then
        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "[Boosted Creature] Nenhum monstro foi escolhido ainda.")
        return false
    end

    local message = "---------[+]----------- [Boost Creature] -----------[+]---------\n\n" ..
        "   Every day, a monster is chosen to have additional experience and loot.\n\n" ..
        "---------[+]-----------------------------------[+]---------\n" ..
        "                                                  Selected Creature: " .. firstToUpper(boostCreature[1].name) .. "\n" ..
        "                                                        Experience: +" .. boostCreature[1].exp .. "%\n" ..
        "                                                              Loot: +" .. boostCreature[1].loot .. "%"

    player:popupFYI(message)
    return false
end

boost:register()
