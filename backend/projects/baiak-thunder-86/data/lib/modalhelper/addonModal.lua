function Player:sendMainAddonWindow(config)
    local window = ModalWindow {
        title = "Selecione um dos Addons",
        message = "Para prosseguir, selecione o Addon",
    }
  
    local cid = self:getId()
  
    -- Add choices from the action script
    for i = 1, #config.system do
        if not self:hasOutfit(config.system[i].male, 3) and not self:hasOutfit(config.system[i].female, 3) then 
            local choice = window:addChoice(config.system[i].addonName)
            choice.addonID = i
        end
    end 
  
    buttonText = "Selecionar"
    window:addButton(buttonText,
        function(button, choice)
            local self = Player(cid)
            if self then
                self:sendAllAddonListWindow(config, choice.id)
            end
        end
    )
    window:setDefaultEnterButton(buttonText)
  
  
    window:addButton("Sair")

    window:setDefaultEnterButton("Selecionar")
    window:setDefaultEscapeButton("Sair")
    window:sendToPlayer(self)
end

function Player:checkSexPlayer(config)
    if self:getSex() == 0 then
        return config.outfitId.female
    else
        return config.outfitId.male
    end 
end

function Player:sendAllAddonListWindow(config, lastChoice)
    local window = ModalWindow {
        title = config.system[lastChoice].addonName,
        message = "Selecione o seu Addon (Primeiro ou Segundo Addon)",
    }   
    local idOutfit = self:checkSexPlayer(config.system[lastChoice]) 
    local addonTable = config.system[lastChoice].items[idOutfit]
    local onlyIdOutfits = config.system[lastChoice].outfitId

    local cid = self:getId()
  
  
   window:addButton("Sair")
    window:setDefaultEscapeButton("Sair")
  
    if not self:hasOutfit(onlyIdOutfits.male, 1) and not self:hasOutfit(onlyIdOutfits.female, 1) then 
        buttonText = "Primeiro"
        window:addButton(buttonText,
            function(button, choice)
                local self = Player(cid)
                if self then
                    self:acceptAddonWindow(addonTable, 1, onlyIdOutfits, lastChoice, config)
                end
            end
        )
    end
  
  
  
  
  
    if not self:hasOutfit(onlyIdOutfits.male, 2) and not self:hasOutfit(onlyIdOutfits.female, 2) then 
        buttonText = "Segunda"
        window:addButton(buttonText,
            function(button, choice)
                local self = Player(cid)
                if self then
                    self:acceptAddonWindow(addonTable, 2, onlyIdOutfits, lastChoice, config)
                end
            end
        )
    end 

   

    window:sendToPlayer(self)
end

function Player:acceptAddonWindow(config, addonId, onlyIdOutfits, lastChoice, configMainTable)
    local window = ModalWindow {
        title = "Selecione uma opção para prosseguir",
        message = "Clique em Detalhes para verificar os itens necessários ou clique em Aceitar para obter o seu addon",
    }   
    local cid = self:getId()     
    local checkItensAddon = self:checkItensAddon(config[addonId])
  
    if checkItensAddon then
        window:addButton("OK",
            function(button, choice)
                local self = Player(cid)
                if self then
                    self:setAddonId(onlyIdOutfits, addonId)
                end
                return true
            end
        )
    end 
  
    buttonText = "Voltar"
    window:addButton(buttonText,
        function(button, choice)
            local self = Player(cid)
            if self then
                self:sendAllAddonListWindow(configMainTable, lastChoice)
            end
        end
    )

    buttonText = "Detalhes"
    window:addButton(buttonText,
        function(button, choice)
            local self = Player(cid)
            if self then
                self:detailsAddonWindowFirst(config[addonId], config , addonId, onlyIdOutfits, lastChoice, configMainTable)
            end
        end
    )
  
    window:addButton("Sair")
    window:setDefaultEscapeButton("Sair")
    window:sendToPlayer(self)
end

function Player:detailsAddonWindowFirst(config, tableConfig, addonId, onlyIdOutfits, lastChoice, configMainTable)
    local window = ModalWindow {
        title = "Itens Requiridos para seu Addon",
        message = self:detailsAddonWindow(config),
    }
  
    local cid = self:getId()
    local checkItensAddon = self:checkItensAddon(config)
  
    if checkItensAddon then
        window:addButton("OK",
            function(button, choice)
                local self = Player(cid)
                if self then
                    self:setAddonId(config, onlyIdOutfits, addonId, configMainTable, lastChoice)
                end
                return true
            end
        )
    end
  
    window:addButton("Voltar",
        function(button, choice)
            local self = Player(cid)
            if self then
                self:acceptAddonWindow(tableConfig, addonId, onlyIdOutfits , lastChoice,  configMainTable)
            end
            return true
        end
    )
  
    window:sendToPlayer(self)
end

function Player:checkItensAddon(config)
    for i = 1, #config.reqItems do
        if self:getItemCount(config.reqItems[i].item) < config.reqItems[i].count then         
            return false
        end
    end 
  
    return true
end

function Player:detailsAddonWindow(config)
    local itemTable = config.reqItems 
    local details = "Itens Requeridos para o Addon:\n"
    for i = 1, #itemTable do         
        local reqItems = itemTable[i].item             
      
        local reqItemsCount = itemTable[i].count
        local reqItemsOnPlayer = self:getItemCount(reqItems)
            details = details.."\n- ".. (capAll(ItemType(reqItems):getName()) .." ["..reqItemsOnPlayer.."/"..reqItemsCount.."]")
    end 
    return details
end

function Player:setAddonId(config, outfits, addonId, configMainTable, lastChoice)
    for i = 1, #config.reqItems do
        self:removeItem(config.reqItems[i].item, config.reqItems[i].count)
    end     
  
    self:addOutfitAddon(outfits.female, addonId)
    self:addOutfitAddon(outfits.male, addonId)
    self:getPosition():sendMagicEffect(CONST_ME_FIREATTACK)

end