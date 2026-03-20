function Player:sendAddonWindow(outfits)
    local function buttonCallback(button, choice)
        local outfitName = string.lower(outfits[choice.id].name) -- Converte o nome do outfit para minúsculo
        -- Funcionalidade da janela modal
        if button.text == "Confirmar" then
            -- Início das verificações
            -- Verifica se o jogador possui o boneco do addon na mochila.
            if self:getItemCount(outfits.dollID) == 0 then
                self:sendAddonWindow_noDoll(outfits)
                return false
            end

            -- Se o choiceID for igual a 0, retorna false e fecha a janela (Se o jogador já tiver todos os addons, choiceID será 0).
            if choice.id == 0 then
                return false
            end

            -- Verifica se o jogador já possui o outfit, se verdadeiro envia mensagem de erro e reabre a janela
            if self:hasOutfit(outfits[choice.id].male, 3) or self:hasOutfit(outfits[choice.id].female, 3) then
                self:sendAddonWindow_owned(outfits)
                return false
            end

            -- Verifica o sexo do jogador e concede o addon com base nele.
            if self:getSex() == 0 then
                self:addOutfitAddon(outfits[choice.id].female, 3)
            else
                self:addOutfitAddon(outfits[choice.id].male, 3)
            end
        end
        -- Fim das verificações

        -- Remove o boneco do addon, envia mensagem de confirmação e efeitos especiais.
        self:removeItem(outfits.dollID, 1)
        self:getPosition():sendMagicEffect(CONST_ME_FIREWORK_YELLOW)
        self:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Agora você pode usar o outfit " .. outfitName .. " e seus addons!")
    end

    -- Design da janela modal
    local window = ModalWindow {
        title = outfits.mainTitle, -- Título da janela modal
        message = outfits.mainMsg, -- A mensagem a ser exibida na janela modal
    }

    -- Adiciona botões à janela (Nota: se você alterar os nomes destes, você deve alterar as funções nas funcionalidades da janela modal!)
    window:addButton("Confirmar", buttonCallback)
    window:addButton("Cancelar")

    -- Define qual botão é pressionado quando o jogador pressiona enter ou escape
    window:setDefaultEnterButton("Confirmar")
    window:setDefaultEscapeButton("Cancelar")

    -- Adiciona as opções do script de ação à janela
    for i = 1, #outfits do
        local o = outfits[i].name

        -- Verifica quais outfits o jogador possui/não possui
        if not self:hasOutfit(outfits[i].male, 3) and not self:hasOutfit(outfits[i].female, 3) then
            -- Adiciona "mulher nobre" ou "homem nobre"
            if o == "Nobre" or o == "Norse" then 
                if self:getSex() == 0 then
                    o = o .. "woman"
                else
                    o = o .. "man"
                end
            end

            -- Adiciona a escolha se o jogador não tiver o outfit
            local choice = window:addChoice(o)
        else
            -- Adiciona "[Possui]" à escolha se o jogador já tiver.
            local choice = window:addChoice(o.." [Possui]")
        end
    end

    -- Envia a janela para o jogador
    window:sendToPlayer(self)
end

-- A janela modal que é exibida se o jogador já possui o addon.
function Player:sendAddonWindow_owned(outfits)
    local function buttonCallback(button, choice)
        if button.text == "Voltar" then
            self:sendAddonWindow(outfits)
        end
    end

    -- Design da janela modal
    local window = ModalWindow {
        title = outfits.ownedTitle, -- Título da janela modal
        message = outfits.ownedMsg, -- A mensagem a ser exibida na janela modal
    }

    -- Adiciona botões à janela
    window:addButton("Voltar", buttonCallback)

    -- Define qual botão é pressionado quando o jogador pressiona enter ou escape
    window:setDefaultEnterButton("Voltar")
    window:setDefaultEscapeButton("Voltar")

    -- Envia a janela para o jogador
    window:sendToPlayer(self)
end

-- A janela modal que é exibida se o jogador não possui o boneco do addon na mochila
function Player:sendAddonWindow_noDoll(outfits)
    local function buttonCallback(button, choice)
        if button.text == "Voltar" then
            self:sendAddonWindow(outfits)
        end
    end

    -- Design da janela modal
    local window = ModalWindow {
        title = outfits.dollTitle, -- Título da janela modal
        message = outfits.dollMsg, -- A mensagem a ser exibida na janela modal
    }

    -- Adiciona botões à janela
    window:addButton("Voltar", buttonCallback)

    -- Define qual botão é pressionado quando o jogador pressiona enter ou escape
    window:setDefaultEnterButton("Voltar")
    window:setDefaultEscapeButton("Voltar")

    -- Envia a janela para o jogador
    window:sendToPlayer(self)
end
