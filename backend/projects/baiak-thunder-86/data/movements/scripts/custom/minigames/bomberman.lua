function onStepIn(creature, item, position, fromPosition)
    local player = creature:getPlayer()
    if not player then
        return
    end
    
    if item:getActionId() == 19001 then
        if player:getStorageValue(STORAGEVALUE_MINIGAME_BOMBERMAN_SIZE) == 10 then
            player:sendTextMessage(MESSAGE_INFO_DESCR, "Your bomb reaches the maximum (+10) sqms.")
            return true
        end
        player:setStorageValue(STORAGEVALUE_MINIGAME_BOMBERMAN_SIZE, player:getStorageValue(STORAGEVALUE_MINIGAME_BOMBERMAN_SIZE) + 1)
        player:sendTextMessage(MESSAGE_INFO_DESCR, "Now your bomb reaches up to "..player:getStorageValue(STORAGEVALUE_MINIGAME_BOMBERMAN_SIZE).." sqm.")
        item:remove()
    elseif item:getActionId() == 19002 then
        if player:getStorageValue(STORAGEVALUE_MINIGAME_BOMBERMAN_MAXBOMB) == 10 then
            player:sendTextMessage(MESSAGE_INFO_DESCR, "You can drop the maximum number (+10) of bombs.")
            return true
        end
        player:setStorageValue(STORAGEVALUE_MINIGAME_BOMBERMAN_MAXBOMB, player:getStorageValue(STORAGEVALUE_MINIGAME_BOMBERMAN_MAXBOMB) + 1)
        player:sendTextMessage(MESSAGE_INFO_DESCR, "Now you can drop up to "..player:getStorageValue(STORAGEVALUE_MINIGAME_BOMBERMAN_MAXBOMB).." bombs.")
        item:remove()    
    elseif item:getActionId() == 19003 then
        if player:getStorageValue(STORAGEVALUE_MINIGAME_BOMBERMAN_SPEED) == 10 then
            player:sendTextMessage(MESSAGE_INFO_DESCR, "You are at maximum speed (+10).")
            return true
        end
    
        local speed = player:getStorageValue(STORAGEVALUE_MINIGAME_BOMBERMAN_SPEED)
        if speed >= 0 and speed < 11 then
            player:setStorageValue(STORAGEVALUE_MINIGAME_BOMBERMAN_SPEED, player:getStorageValue(STORAGEVALUE_MINIGAME_BOMBERMAN_SPEED) + 1)
            player:sendTextMessage(MESSAGE_INFO_DESCR, "Now your speed is +("..player:getStorageValue(STORAGEVALUE_MINIGAME_BOMBERMAN_SPEED)..") points.")
            doChangeSpeed(creature, getCreatureBaseSpeed(creature))
        end
        item:remove()    
    elseif item:getActionId() == 19004 then
        exitPosition = Position(1721, 942, 7)
        local team1, team2 = #BomberTeam1, #BomberTeam2
        if team1 == 0 or team2 == 0 then
            stopEvent(bombermanEnd)
            if team1 > team2 then
                for i = 1, #BomberTeam1 do
                    if isPlayer(BomberTeam1[i]) then
                        resetplayerbomberman(BomberTeam1[i])
                        BomberTeam1[i]:sendTextMessage(MESSAGE_INFO_DESCR, "Your team won. Congratulations!")
						
						-- Event Rewards
						BomberTeam1[i]:addEventPoints("boss", 100)
						BomberTeam1[i]:addEventPoints("task", 100)
						
                        BomberTeam1[i]:setOutfit(BombermanOutfit[BomberTeam1[i]:getGuid()])
                    end
                    BomberTeam1[i]:teleportTo(Position(exitPosition))
                end
            else
                for i = 1, #BomberTeam2 do
                    if isPlayer(BomberTeam2[i]) then
                        resetplayerbomberman(BomberTeam2[i])
                        BomberTeam2[i]:setOutfit(BombermanOutfit[BomberTeam2[i]:getGuid()])
                        BomberTeam2[i]:sendTextMessage(MESSAGE_INFO_DESCR, "Your team won. Congratulations!")
						
						-- Event Rewards
						BomberTeam2[i]:addEventPoints("boss", 100)
						BomberTeam2[i]:addEventPoints("task", 100)
                    end
                    BomberTeam2[i]:teleportTo(Position(exitPosition))
                end
            end
            BomberTeam1, BomberTeam2 = {}, {} 
            for i = 1, #BlockListBomberman do
                local powerItens = {2684, 4852, 2642}
                for pointer = 1, 3 do
                    if Tile(BlockListBomberman[i]):getItemById(powerItens[pointer]) then
                        remover = Tile(BlockListBomberman[i]):getItemById(powerItens[pointer])
                        remover:remove()
                    end
                end
                if not Tile(BlockListBomberman[i]):getItemById(9421) then
                    Game.createItem(9421, 1, BlockListBomberman[i])
                end 
            end
            BlockListBomberman = {}
            BombermanPortal = 0
            item:remove()
        else
            player:sendTextMessage(MESSAGE_INFO_DESCR, "There are members of the opposing team left.")
        end
    end
    return true
end

function resetplayerbomberman(player)
    local player = Player(player)
    player:setStorageValue(STORAGEVALUE_MINIGAME_BOMBERMAN_ACTIVEBOMB, -1)
    player:setStorageValue(STORAGEVALUE_MINIGAME_BOMBERMAN_MAXBOMB, -1)
    player:setStorageValue(STORAGEVALUE_MINIGAME_BOMBERMAN_SPEED, -1)
    doChangeSpeed(player, getCreatureBaseSpeed(player)-player:getSpeed())
end
