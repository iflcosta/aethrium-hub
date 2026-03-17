function onThink(interval)
    if Game.getPlayerCount() == 0 then
        return true
    end

    local resultId = db.storeQuery("SELECT * FROM z_ots_comunication")
    if resultId ~= false then
        repeat
            local transactionId = tonumber(result.getDataInt(resultId, "id"))
            local playerName = result.getDataString(resultId, "name")
            local player = Player(playerName)

            if player then
                local itemId = result.getDataInt(resultId, "param1")
                local itemCount = result.getDataInt(resultId, "param2")
                local outfitParam = (result.getDataString(resultId, "param3")):lower()
                local containerItemsInsideCount = result.getDataInt(resultId, "param4")
                local shopOfferType = result.getDataString(resultId, "param5")
                local shopOfferName = result.getDataString(resultId, "param6")

                -- DELIVER ITEM
                if shopOfferType == 'item' then
                    local item = Game.createItem(tonumber(itemId), tonumber(itemCount))
                    local itemReceived = player:getInbox():addItemEx(item, INDEX_WHEREVER, FLAG_NOLIMIT)
                    if itemReceived == RETURNVALUE_NOERROR then
                        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You received the item ".. ItemType(itemId):getName() .." in your mailbox.")
                        player:getPosition():sendMagicEffect(31)
                        db.asyncQuery("DELETE FROM `z_ots_comunication` WHERE `id` = " .. transactionId)
                        db.asyncQuery("UPDATE `z_shop_history_item` SET `trans_state`= 'realized', `trans_real`=" .. os.time() .. " WHERE `id` = " .. transactionId)
                    else
                        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "There was an error while trying to deliver an item from the shop. Please contact the administrators.")
                        player:getPosition():sendMagicEffect(CONST_ME_POFF)
                        print("[SHOP] Error while trying to deliver ".. ItemType(itemId):getName() .." to ".. player:getName() .."." )
                    end

                -- DELIVER YOUR CUSTOM THINGS
                elseif shopOfferType == 'outfit' then
                    local outfitList = OUTFIT_LIST[outfitParam]
                    if outfitList then
                        player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You received the outfit ".. outfitParam ..".")
                        player:addOutfitAddon(outfitList[1], 3)
                        player:addOutfitAddon(outfitList[2], 3)
                        player:getPosition():sendMagicEffect(31)
                        db.asyncQuery("DELETE FROM `z_ots_comunication` WHERE `id` = " .. transactionId)
                        db.asyncQuery("UPDATE `z_shop_history_item` SET `trans_state`= 'realized', `trans_real`=" .. os.time() .. " WHERE `id` = " .. transactionId)  
                    end
                end
            end
        until not result.next(resultId)
        result.free(resultId)
    end

    return true
end
