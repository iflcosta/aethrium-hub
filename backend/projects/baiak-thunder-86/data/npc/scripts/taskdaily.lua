local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)
local talkState = {}
function onCreatureAppear(cid)              npcHandler:onCreatureAppear(cid)            end
function onCreatureDisappear(cid)           npcHandler:onCreatureDisappear(cid)         end
function onCreatureSay(cid, type, msg)      npcHandler:onCreatureSay(cid, type, msg)    end
function onThink()                          npcHandler:onThink()                         end
function creatureSayCallback(cid, type, msg)
    if not npcHandler:isFocused(cid) then
        return false
    end
    local player = Player(cid)
    local talkUser,msg, str,rst = NPCHANDLER_CONVbehavior == CONVERSATION_DEFAULT and 0 or cid, msg:lower(),"",""

     task,daily, hours = player:getTaskMission(),player:getDailyTaskMission(), 24
    if isInArray({"task","tasks","missao","mission"}, msg) then
        if taskSystem[task] then
            if player:getStorageValue(taskSystem[task].start) <= 0 then
                if player:getLevel() >= taskSystem[task].level then
                    player:setStorageValue(taskSystem[task].start, 1)
                    npcHandler:say("[Task System] Congratulations, you are now participating in the Task of "..taskSystem[task].name.." and shall kill "..taskSystem[task].count.." from this list: "..getMonsterFromList(taskSystem[task].monsters_list)..". "..(#taskSystem[task].items > 0 and "Oh and please bring me "..getItemsFromList(taskSystem[task].items).." for me." or "").."" , cid)
                else
                    npcHandler:say("Sorry, but you need to reach level "..taskSystem[task].level.." to be able to participate in the Task of "..taskSystem[task].name.."!", cid)
                end
            else
                npcHandler:say("Sorry, but you are currently on the task "..taskSystem[task].name..". You may {reward} if it's already over.", cid)
            end
        else
            npcHandler:say("Sorry, but for now I don't have any more tasks for you!", cid)
        end
    elseif isInArray({"diaria","daili","daily","dayli","diario"}, msg) then
        if player:getStorageValue(taskSystem_storages[6]) - os.time() > 0 then
            npcHandler:say("Sorry, you must wait until "..os.date("%d %B %Y %X ", player:getStorageValue(taskSystem_storages[6])).." to start a new daily task!", cid) return true
        elseif dailyTasks[daily] and player:getStorageValue(taskSystem_storages[5]) >= dailyTasks[daily].count then
            npcHandler:say("Sorry, do you have task for {reward} !", cid) return true
        end
        local r = player:randomDailyTask()
        if r == 0 then
            npcHandler:say("Sorry, but you don't have the level to complete any daily tasks.", cid) return true
        end
        player:setStorageValue(taskSystem_storages[4], r)
        player:setStorageValue(taskSystem_storages[6], os.time()+hours*3600)
        player:setStorageValue(taskSystem_storages[7], 1)
        player:setStorageValue(taskSystem_storages[5], 0)
       local dtask = dailyTasks[r]
        npcHandler:say("[Daily Task System] Congratulations, you are now participating in the Daily Task of "..dtask.name.." and shall kill "..dtask.count.." monsters from this list: "..getMonsterFromList(dtask.monsters_list).." up until "..os.date("%d %B %Y %X ", player:getStorageValue(taskSystem_storages[6]))..". Good luck!" , cid)
    elseif isInArray({"receber","reward","recompensa","report","reportar","entregar","entrega"}, msg) then
        local v, k = taskSystem[task], dailyTasks[daily]
        if v then -- original task
            if player:getStorageValue(v.start) > 0 then
                if player:getStorageValue(taskSystem_storages[3]) >= v.count then
                    if #v.items > 0 and not doRemoveItemsFromList(cid, v.items) then
                        npcHandler:say("Sorry, but you also need to deliver the items on this list: "..getItemsFromList(v.items), cid) return true
                    end

             if v.exp > 0 then player:addExperience(v.exp) str = str.."".. (str == "" and "" or ", ") .." "..v.exp.." de exp" end
                 if v.points > 0 then player:setStorageValue(taskSystem_storages[2], (player:getTaskPoints()+v.points)) str = str.."".. (str == "" and "" or ", ") .." + "..v.points.."task points" end
                 if v.money > 0 then player:addMoney(v.money) str = str.."".. (str == "" and "" or ", ") ..""..v.money.." gps" end
                 if table.maxn(v.reward) > 0 then player:giveRewardsTask(v.reward) str = str.."".. (str == "" and "" or ", ") ..""..getItemsFromList(v.reward) end
                    npcHandler:say("Thanks for your help Rewards: "..(str == "" and "nenhuma" or ""..str.."").." for completing the task of "..v.name, cid)
                    player:setStorageValue(taskSystem_storages[3], 0)
                    player:setStorageValue(taskSystem_storages[1], (task+1))
                else
                    npcHandler:say("Sorry, but you haven't finished your do task yet. "..v.name..". I need you to kill more "..(player:getStorageValue(taskSystem_storages[3]) < 0 and v.count or -(player:getStorageValue(taskSystem_storages[3])-v.count)).." of these terrible monsters!", cid)
                end
            end
        end
        if k then -- daily task
            if player:getStorageValue(taskSystem_storages[7]) > 0 then
                if player:getStorageValue(taskSystem_storages[5]) >= k.count then
                if k.exp > 0 then player:addExperience(k.exp) rst = rst.."".. (rst == "" and "" or ", ") .." "..k.exp.." de exp" end
                 if k.points > 0 then player:setStorageValue(taskSystem_storages[2], (player:getTaskPoints()+k.points)) rst = rst.."".. (rst == "" and "" or ", ") .." + "..k.points.."task points" end
                 if k.money > 0 then player:addMoney(k.money) rst = rst.."".. (rst == "" and "" or ", ") ..""..k.money.." gps" end
                 if table.maxn(k.reward) > 0 then player:giveRewardsTask(k.reward) rst = rst.."".. (rst == "" and "" or ", ") ..""..getItemsFromList(k.reward) end
                    npcHandler:say("Obrigado pela sua ajuda! Recompensas: "..(rst == "" and "nenhuma" or ""..rst.."").." por ter completado a task do "..k.name, cid)
                    player:setStorageValue(taskSystem_storages[4], 0)
                    player:setStorageValue(taskSystem_storages[5], 0)
                    player:setStorageValue(taskSystem_storages[7], 0)
                    else
                    npcHandler:say("Sorry, but you still haven't finished your daily task "..k.name..". I need you to kill more "..(player:getStorageValue(taskSystem_storages[5]) < 0 and k.count or -(player:getStorageValue(taskSystem_storages[5])-k.count)).." of these monsters!", cid)
                end
            end
        end
    elseif msg == "no" then
        selfSay("Tudo bem então", cid)
        talkState[talkUser] = 0
        npcHandler:releaseFocus(cid)
    end
    return true
end
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())