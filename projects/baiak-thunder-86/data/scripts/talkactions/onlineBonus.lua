local bonus = TalkAction("!onlinebonus")

function bonus.onSay(player, words, param)
    local onlineTime = player:getOnlineTime()
    local message = "--------[+]------- [Online Bonus System] -------[+]--------\n\nEarn an online token for every hour you spend online without logging out.\n\n---------------------------------------------------\n                                                            Total:\n             Since the server save, you have earned " .. onlineTime .. " online tokens."
    player:popupFYI(message)
end

bonus:register()
