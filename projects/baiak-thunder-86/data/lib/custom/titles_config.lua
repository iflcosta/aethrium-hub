-- ============================================================
-- TITLES SYSTEM - Configuration
-- ============================================================

TitleConfig = {
    -- Storage for the selected title ID
    storageSelected = 49000,
    
    -- List of available titles
    -- Format: [ID] = {name = "Display Name", color = COLOR_CODE, description = "Short info"}
    titles = {
        [1] = {name = "The King", color = "#FFD700", description = "Exclusive for the castle owner."},          -- Gold
        [2] = {name = "Legendary", color = "#FF4500", description = "Unlocked by reaching level 1000."},         -- OrangeRed
        [3] = {name = "Collector", color = "#00BFFF", description = "Unlocked by using 50 different items."},         -- DeepSkyBlue
        [4] = {name = "Nexus Hero", color = "#32CD32", description = "A true savior of the Nexus realm."},        -- LimeGreen
        [5] = {name = "The Merchant", color = "#DAA520", description = "For those who trade everything."},      -- Goldenrod
        [6] = {name = "Bloodthirsty", color = "#FF0000", description = "For the most active PKers."}       -- Red
    }
}
