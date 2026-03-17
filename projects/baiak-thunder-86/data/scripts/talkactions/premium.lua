local premium = TalkAction("!sellpoints")

function premium.onSay(player, words, param)
    local var = "[Sell Points System] This document is worth %d points for you to use on the website."
    local points = player:getPremiumPoints()
    local min, max = 5, 100

    if param == "" or not tonumber(param) then
        player:sendCancelMessage("Sorry, please use only numbers.")
        return false
    elseif tonumber(param) < min or tonumber(param) > max then
        player:sendCancelMessage("Sorry, minimum of "..min.." and maximum of "..max.." points.")
        return false
    elseif points < tonumber(param) then
        player:sendCancelMessage("Sorry, but you only have "..points.." Premium Points.")
        return false
    end

    local item = player:addItem(7702)
    item:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, string.format(var, tonumber(param)))
    item:setAttribute(ITEM_ATTRIBUTE_NAME, "Premium Points Document")
    item:setAttribute(ITEM_ATTRIBUTE_ARTICLE, "a")
    item:setAttribute(ITEM_ATTRIBUTE_TEXT, "This document is worth "..tonumber(param).." premium points for you to use on the website.")
    player:addPremiumPoints(-tonumber(param))
    player:sendCancelMessage("[Sell Points System] You received a document with "..param.." Premium Points.")
    return false
end

premium:separator(" ")
premium:register()
