function onSay(player, words, param)
    if player:getGroup():getId() < 3 then
        return true
    end

    db.query("DELETE FROM market_offers")
    db.query("DELETE FROM market_deliveries")
    player:sendTextMessage(MESSAGE_STATUS_CONSOLE_BLUE, "DONE - Todas as ofertas foram removidas.")
    return false
end
