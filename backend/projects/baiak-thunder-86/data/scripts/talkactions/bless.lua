local bless = TalkAction("!bless")

local config = {
    blessCount = 5, -- Number of blessings available
    pricePerLevel = 750, -- 750 gold coins per level
    messages = {
        notEnoughMoney = "You don't have enough gold coins to buy all blessings.",
        blessed = "You have been blessed!",
        alreadyBlessed = "You already have all blessings.",
    },
}

function bless.onSay(player, words, param)
    local totalCost = player:getLevel() * config.pricePerLevel

    for i = 1, config.blessCount do
        if player:hasBlessing(i) then
            player:sendCancelMessage(config.messages.alreadyBlessed)
            player:getPosition():sendMagicEffect(CONST_ME_POFF)
            return false
        end
    end

    if player:removeMoney(totalCost) then
        for i = 1, config.blessCount do
            player:addBlessing(i)
        end
        player:sendCancelMessage(config.messages.blessed)
        player:getPosition():sendMagicEffect(50) 
        player:say("[BLESS]", TALKTYPE_MONSTER_SAY)
    else
        player:sendCancelMessage(config.messages.notEnoughMoney)
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
    end

    return false
end

bless:register()
