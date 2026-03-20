-- ===== DATABASE & CLEANUP =====
local function initDB()
    db.query([[CREATE TABLE IF NOT EXISTS market_offers (
        id INT AUTO_INCREMENT PRIMARY KEY, 
        player_id INT, 
        player_name VARCHAR(255),
        item_id INT, 
        item_count INT, 
        price INT, 
        currency TINYINT,
        category TINYINT DEFAULT 6,
        created_at BIGINT, 
        expires_at BIGINT,
        INDEX(player_id), 
        INDEX(category)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])

    db.query([[CREATE TABLE IF NOT EXISTS market_deliveries (
        id INT AUTO_INCREMENT PRIMARY KEY,
        player_id INT,
        item_id INT,
        amount INT,
        INDEX(player_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])

    db.query([[CREATE TABLE IF NOT EXISTS player_titles (
        player_id INT NOT NULL,
        title_id INT NOT NULL,
        PRIMARY KEY (player_id, title_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;]])
end

local mStart = GlobalEvent("MarketStartNative")
function mStart.onStartup()
    initDB()
    print(">> [Nexus Native Market] JSON Backend Initialize Event Loaded")
    return true
end
mStart:register()

local mCleanup = GlobalEvent("MarketCleanupNative")
function mCleanup.onThink()
    db.asyncQuery("DELETE FROM market_offers WHERE expires_at <= " .. os.time())
    return true
end
mCleanup:interval(3600000)
mCleanup:register()
