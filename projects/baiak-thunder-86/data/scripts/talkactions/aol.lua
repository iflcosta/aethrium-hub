local amulet = TalkAction("!aol")
local price_aol = 10000

function amulet.onSay(player, words, param)
    if player:removeMoney(price_aol) then
        player:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)
        player:say("[AOL]", TALKTYPE_MONSTER_SAY, true)
        player:addItem(2173, 1)
        player:sendCancelMessage("You have purchased an Amulet of Loss.")
    else
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        player:sendCancelMessage("You don't have enough money.")
    end
    return false
end

amulet:register()
