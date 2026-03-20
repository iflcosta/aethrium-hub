local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid) npcHandler:onCreatureAppear(cid) end
function onCreatureDisappear(cid) npcHandler:onCreatureDisappear(cid) end
function onCreatureSay(cid, type, msg) npcHandler:onCreatureSay(cid, type, msg) end
function onThink() npcHandler:onThink() end

local playerState = {}

function creatureSayCallback(cid, type, msg)
    if not npcHandler:isFocused(cid) then
        return false
    end

    local player = Player(cid)
    local guid = player:getGuid()
    msg = msg:lower()

    if msg == "buy" then
        selfSay("Excelente! Qual tipo de bilhete deseja? {simple} (10k), {double} (18k), {quintuple} (40k) ou {mega} (75k)?", cid)
        playerState[guid] = {step = "type"}
    
    elseif playerState[guid] and playerState[guid].step == "type" then
        if NexusLottery.Config.Prices[msg] then
            playerState[guid].type = msg
            playerState[guid].step = "method"
            selfSay("Como deseja escolher os números? {manual} (você digita), {quick} (aleatório) ou {lucky} (seus números salvos)?", cid)
        else
            selfSay("Desculpe, não entendi o tipo. Escolha entre simple, double, quintuple ou mega.", cid)
        end

    elseif playerState[guid] and playerState[guid].step == "method" then
        local numBets = NexusLottery.Config.BetsPerType[playerState[guid].type]
        
        if msg == "quick" then
            local bets = {}
            for i = 1, numBets do
                table.insert(bets, NexusLottery.generateQuickPick())
            end
            playerState[guid].bets = bets
            selfSay("Gerado " .. numBets .. " aposta(s) aleatória(s). Confirmar compra por " .. NexusLottery.Config.Prices[playerState[guid].type] .. " gold? {yes}", cid)
            playerState[guid].step = "confirm"
        
        elseif msg == "manual" then
            playerState[guid].step = "numbers"
            playerState[guid].tempBets = {}
            selfSay("Digite 6 números (1-60) separados por espaço para a aposta #1.", cid)
        
        else
            selfSay("Método não suportado no momento. Tente {quick} ou {manual}.", cid)
        end

    elseif playerState[guid] and playerState[guid].step == "numbers" then
        local parts = msg:split(" ")
        local nums = {}
        for _, p in ipairs(parts) do
            local n = tonumber(p)
            if n then table.insert(nums, n) end
        end

        if #nums == 6 then
            if NexusLottery.validateNumbers(nums) then
                table.insert(playerState[guid].tempBets, nums)
                local needed = NexusLottery.Config.BetsPerType[playerState[guid].type]
                if #playerState[guid].tempBets < needed then
                    selfSay("Aposta salva. Digite os números para a aposta #" .. (#playerState[guid].tempBets + 1) .. ".", cid)
                else
                    playerState[guid].bets = playerState[guid].tempBets
                    selfSay("Todas as apostas foram salvas. Confirmar compra por " .. NexusLottery.Config.Prices[playerState[guid].type] .. " gold? {yes}", cid)
                    playerState[guid].step = "confirm"
                end
            else
                selfSay("Números inválidos (devem ser únicos entre 1 e 60). Tente novamente para esta aposta.", cid)
            end
        else
            selfSay("Você precisa digitar exatamente 6 números.", cid)
        end

    elseif playerState[guid] and playerState[guid].step == "confirm" and msg == "yes" then
        local success, errorMsg = NexusLottery.buyTicket(player, playerState[guid].type, playerState[guid].bets)
        if success then
            selfSay("Bilhete comprado com sucesso! Boa sorte no sorteio de Sábado às 20h!", cid)
        else
            selfSay("Erro: " .. errorMsg, cid)
        end
        playerState[guid] = nil

    elseif msg == "info" then
        local draw = NexusLottery.getCurrentDraw()
        if draw then
            local total = draw.prize_pool + draw.jackpot_accumulated
            selfSay("O Jackpot atual do sorteio #" .. draw.draw_number .. " está em " .. total .. " gold! O sorteio será Sábado às 20:00.", cid)
        else
            selfSay("Não há sorteio pendente no momento.", cid)
        end

    elseif msg == "check" then
        local draw = NexusLottery.getCurrentDraw()
        if draw then
            local count = NexusLottery.getPlayerTicketCount(player:getId(), draw.id)
            selfSay("Você tem " .. count .. " bilhetes ativos para o sorteio #" .. draw.draw_number .. ".", cid)
        else
             selfSay("Nenhum sorteio registrado.", cid)
        end
    end

    return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new())
