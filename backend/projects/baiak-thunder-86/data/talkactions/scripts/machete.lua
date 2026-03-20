local price = 500

function onSay(player, words, param)
    if player:removeMoney(price) then
        player:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)
        player:addItem(2420, 1) 
        player:sendCancelMessage("You have bought a machete.") 
    else
        player:getPosition():sendMagicEffect(CONST_ME_POFF)
        player:sendCancelMessage("You don't have enough money.") 
    end

    return false 
end
