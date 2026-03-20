local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)
local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid) npcHandler:onCreatureAppear(cid) end
function onCreatureDisappear(cid) npcHandler:onCreatureDisappear(cid) end
function onCreatureSay(cid, type, msg) npcHandler:onCreatureSay(cid, type, msg) end
function onThink() npcHandler:onThink() end
function onPlayerCloseChannel(cid) npcHandler:onPlayerCloseChannel(cid) end

npcHandler:addModule(FocusModule:new())

function creatureSayCallback(cid, type, msg)
	if(not npcHandler:isFocused(cid)) then
		return false
	end
local player = Player(cid)
local msg = msg:lower()
------------------------------------------------------------------
if npcHandler.topic[cid] == 0 and msg == 'normal' then
	npcHandler:say("Ótimo. Que task de monstro você gostaria de fazer?", cid)
	npcHandler.topic[cid] = 1
elseif npcHandler.topic[cid] == 1 then
	if player:getStorageValue(task_sto_time) < os.time() then
		if player:getStorageValue(task_storage) == -1 then 
			for mon, l in ipairs(task_monsters) do
				if msg == string.lower(l.name) then
					npcHandler:say("Ok, agora você está fazendo a task de {"..l.name:gsub("^%l", string.upper).."},  você precisa matar "..l.amount.." deles. Boa sorte!", cid)
					player:setStorageValue(task_storage, mon)
					player:setStorageValue(task_kills, 0)
					npcHandler.topic[cid] = 0
					npcHandler:releaseFocus(cid)
					break
				elseif mon == #task_monsters then
					npcHandler:say("Desculpe, mas não temos essa task.", cid)
					npcHandler.topic[cid] = 0
					npcHandler:releaseFocus(cid)
				end
			end
		else
			npcHandler:say("Você já está fazendo uma task. Você pode fazer apenas um de cada vez. Diga {!task} para ver informações sobre a sua task atual.", cid)
			npcHandler.topic[cid] = 0
			npcHandler:releaseFocus(cid)
		end
	else
		npcHandler:say("Não tenho permissão para lhe dar nenhuma task porque você abandonou a anterior. Espere pelo "..task_time.." horas de punição.", cid)
		npcHandler.topic[cid] = 0
		npcHandler:releaseFocus(cid)
	end
elseif npcHandler.topic[cid] == 0 and msg == 'daily' or msg == 'diária' then
	if player:getStorageValue(time_daySto) < os.time() then
		npcHandler:say("Lembre-se, é de grande importância que as tasks diárias sejam realizadas. Agora me diga, qual task de monstro você gostaria de fazer?", cid)
		npcHandler.topic[cid] = 2
	else
		npcHandler:say('Você concluiu uma tarefa diária hoje, espere gastar 24 horas para fazê-lo novamente.', cid)
		npcHandler.topic[cid] = 0
		npcHandler:releaseFocus(cid)
	end
elseif npcHandler.topic[cid] == 2 then
	if player:getStorageValue(task_sto_time) < os.time() then
		if player:getStorageValue(taskd_storage) == -1 then 
			for mon, l in ipairs(task_daily) do 
				if msg == string.lower(l.name) then
					npcHandler:say("Muito bem, agora você está fazendo uma task diária {"..l.name:gsub("^%l", string.upper).."}, você precisa matar "..l.amount.." deles. Boa sorte!", cid)
					player:setStorageValue(taskd_storage, mon)
					player:setStorageValue(task_kills, 0)
					npcHandler.topic[cid] = 0
					npcHandler:releaseFocus(cid)
					break
				elseif mon == #task_daily then
					npcHandler:say("Desculpe, não temos esta task diária.", cid)
					npcHandler.topic[cid] = 0
					npcHandler:releaseFocus(cid)
				end
			end
		else
			npcHandler:say("Você já está fazendo uma task diária. Você pode fazer apenas um por dia. Diga {!task} para ver informações sobre sua task atual.", cid)
			npcHandler.topic[cid] = 0
			npcHandler:releaseFocus(cid)
		end
	else
		npcHandler:say("Não tenho permissão para lhe dar nenhuma task porque você abandonou a anterior. Espere pelo "..task_time.." horas de punição.", cid)
		npcHandler.topic[cid] = 0
		npcHandler:releaseFocus(cid)
	end
elseif msg == 'receive' or msg == 'receber' then
	if npcHandler.topic[cid] == 0 then
		npcHandler:say("Que tipo de task você terminou, {normal} ou {diária} ?", cid)
		npcHandler.topic[cid] = 3
	end
elseif npcHandler.topic[cid] == 3 then
	if msgcontains(msg, 'normal') then
	local ret_t = getTaskInfos(player)
		if ret_t then
			if math.max(0, player:getStorageValue(task_kills)) >= ret_t.amount then
				local pt1 = ret_t.pointsTask[1]
				local pt2 = ret_t.pointsTask[2]
				local txt = 'Obrigado por concluir a task, seus prêmios são: '..(pt1 > 1 and pt1..' task points' or pt1 <= 1 and pt1..' task point')..' and '..(pt2 > 1 and pt2..' rank points' or pt2 <= 1 and pt2..' rank point')..', '
				if #getItemsFromTable(ret_t.items) > 0 then
					txt = txt..'além de ganhar: '..getItemsFromTable(ret_t.items)..', '
				for g = 1, #ret_t.items do
					player:addItem(ret_t.items[g].id, ret_t.items[g].count)
				end
				end

				local exp = ret_t.exp
				if exp > 0 then
					txt = txt..'Eu também te darei '..exp..' de experiência, '
					player:addExperience(exp)
				end

				taskPoints_add(player, pt1)
				taskRank_add(player, pt2)
				player:setStorageValue(task_kills, -1)
				player:setStorageValue(task_storage, -1)
				npcHandler:say(txt..'obrigada novamente e até a próxima!', cid)
				npcHandler.topic[cid] = 0
				npcHandler:releaseFocus(cid)
			else
				npcHandler:say('Você ainda não concluiu sua task atual. Você o receberá quando terminar.', cid)
				npcHandler.topic[cid] = 0
				npcHandler:releaseFocus(cid)
			end
		else
			npcHandler:say("Você não está fazendo nenhuma task.", cid)
			npcHandler.topic[cid] = 0
			npcHandler:releaseFocus(cid)
		end
	elseif npcHandler.topic[cid] == 3 and msg == 'daily' or msg == 'diária' then
		if player:getStorageValue(time_daySto)-os.time() <= 0 then
		local ret_td = getTaskDailyInfo(player)
			if ret_td then
				if getTaskDailyInfo(player) then
					if math.max(0, player:getStorageValue(taskd_kills)) >= getTaskDailyInfo(player).amount then
					local pt1 = getTaskDailyInfo(player).pointsTask[1]
					local pt2 = getTaskDailyInfo(player).pointsTask[2]
					local txt = 'Obrigado por concluir a task, seus prêmios são: '..(pt1 > 1 and pt1..' task points' or pt1 <= 1 and pt1..' task point')..' e '..(pt2 > 1 and pt2..' rank points' or pt2 <= 1 and pt2..' rank point')..', '
						if #getTaskDailyInfo(player).items > 0 then
							txt = txt..'além de ganhar: '..getItemsFromTable(getTaskDailyInfo(player).items)..', '
						for g = 1, #getTaskDailyInfo(player).items do
							player:addItem(getTaskDailyInfo(player).items[g].id, getTaskDailyInfo(player).items[g].count)
						end
						end
						local exp = getTaskDailyInfo(player).exp
						if exp > 0 then
							txt = txt..'Eu também te darei '..exp..' experiência, '
							player:addExperience(exp)
						end
						npcHandler:say(txt..' obrigada novamente e até a próxima!', cid)
						taskPoints_add(player, pt1)
						taskRank_add(player, pt2)
						player:setStorageValue(taskd_kills, -1)
						player:setStorageValue(taskd_storage, -1)
						player:setStorageValue(time_daySto, 1*60*60*24+os.time())
						npcHandler.topic[cid] = 0
						npcHandler:releaseFocus(cid)
					else
						npcHandler:say('Você ainda não concluiu sua task atual. Você o receberá quando terminar.', cid)
						npcHandler.topic[cid] = 0
						npcHandler:releaseFocus(cid)
					end
				else
					npcHandler:say("Você não está fazendo nenhuma task.", cid)
					npcHandler.topic[cid] = 0
					npcHandler:releaseFocus(cid)
				end
			end
		else
			npcHandler:say("Você fez uma task diária, aguarde 24 horas para fazer outra novamente.", cid)
			npcHandler.topic[cid] = 0
			npcHandler:releaseFocus(cid)
		end
	end

elseif msg == 'abandon' or msg == 'abandonar' then
	if npcHandler.topic[cid] == 0 then
		npcHandler:say("Aff, que tipo de task você deseja sair, {normal} ou {diária}?", cid)
		npcHandler.topic[cid] = 4
	end
elseif npcHandler.topic[cid] == 4 and msgcontains(msg, 'normal') then
	local ret_t = getTaskInfos(player)
	if ret_t then
		npcHandler:say('Infelizmente esta situação, tinha fé que você me traria essa task, mas eu estava errada. Como punição será '..task_time..' horas sem poder executar nenhuma task.', cid)
		player:setStorageValue(task_sto_time, os.time()+task_time*60*60)
		player:setStorageValue(task_kills, -1)
		player:setStorageValue(task_storage, -1)
		npcHandler.topic[cid] = 0
		npcHandler:releaseFocus(cid)
	else
		npcHandler:say("Você não está fazendo nenhuma task para poder abandoná-la.", cid)
		npcHandler.topic[cid] = 0
		npcHandler:releaseFocus(cid)
	end
elseif npcHandler.topic[cid] == 4 and msg == 'daily' or msg == 'diária' then
	local ret_td = getTaskDailyInfo(player)
	if ret_td then
		npcHandler:say('nfelizmente esta situação, tinha fé que você me traria essa task, mas eu estava errado. Como punição será '..task_time..' horas sem poder fazer nenhuma task.', cid)
		player:setStorageValue(task_sto_time, os.time()+task_time*60*60)
		player:setStorageValue(taskd_kills, -1)
		player:setStorageValue(taskd_storage, -1)
		npcHandler.topic[cid] = 0
		npcHandler:releaseFocus(cid)
	else
		npcHandler:say("Você não está executando nenhuma task diária para poder abandoná-la.", cid)
		npcHandler.topic[cid] = 0
		npcHandler:releaseFocus(cid)
	end
elseif msg == "normal task list" or msg == "lista de task normal" then
	local text = "----**| -> Tasks Normais <- |**----\n\n"
		for _, d in pairs(task_monsters) do
			text = text .."------ [*] "..d.name.." [*] ------ \n[+] Quantidade [+] -> ["..((player:getStorageValue(task_storage) == _) and math.max(0, player:getStorageValue(task_kills)) or 0).."/"..d.amount.."]:\n[+] Prêmios [+] -> "..(#d.items > 1 and getItemsFromTable(d.items).." - " or "")..""..d.exp.." experience \n\n"
		end

		player:showTextDialog(1949, "" .. text)
		npcHandler:say("Aqui está a lista de tasks normais.", cid)
elseif msg == "daily task list" or msg == "lista de task diária" then
	local text = "----**| -> Tasks Diárias <- |**----\n\n"
		for _, d in pairs(task_daily) do
			text = text .."------ [*] "..d.name.." [*] ------ \n[+] Quantidade [+] -> ["..((player:getStorageValue(task_storage) == _) and math.max(0, player:getStorageValue(task_kills)) or 0).."/"..d.amount.."]:\n[+] Prêmios [+] -> "..(#d.items > 1 and getItemsFromTable(d.items).." - " or "")..""..d.exp.." experience \n\n"
		end

		player:showTextDialog(1949, "" .. text)
		npcHandler:say("Aqui está a lista de tasks diárias.", cid)
end
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)