function onAddItem(moveitem, tileitem, position)
    if moveitem:getId() == 7732 then -- seeds
        tileitem:transform(7665) -- flower pot
        tileitem:decay()
        moveitem:remove(1)
        position:sendMagicEffect(CONST_ME_MAGIC_GREEN)
    end
    return true
end
