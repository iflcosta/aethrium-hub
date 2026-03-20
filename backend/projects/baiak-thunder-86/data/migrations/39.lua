function onUpdateDatabase()
    print("> Updating database to version 39 (offline training v2)")
    
    -- Verificar se a coluna já existe
    local result = db.query("SHOW COLUMNS FROM `players` LIKE 'offlinetraining_time'")
    if not result or #result == 0 then
        db.query("ALTER TABLE `players` ADD `offlinetraining_time` INT NOT NULL DEFAULT 43200")
    end
    
    result = db.query("SHOW COLUMNS FROM `players` LIKE 'offlinetraining_skill'")
    if not result or #result == 0 then
        db.query("ALTER TABLE `players` ADD `offlinetraining_skill` INT NOT NULL DEFAULT -1")
    end
    
    -- Nova coluna para timestamp do logout
    result = db.query("SHOW COLUMNS FROM `players` LIKE 'offlinetraining_last_log'")
    if not result or #result == 0 then
        db.query("ALTER TABLE `players` ADD `offlinetraining_last_log` BIGINT NOT NULL DEFAULT 0")
    end
    
    return true
end
