-- ============================================
-- NEXUS GRAND LOTTERY - DATABASE SCHEMA
-- Compatible with TFS 1.3 / 1.5 (MySQL)
-- ============================================

CREATE TABLE IF NOT EXISTS `lottery_draws` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `draw_number` INT NOT NULL UNIQUE,
    `scheduled_time` BIGINT NOT NULL,
    `executed_time` BIGINT DEFAULT NULL,
    `status` ENUM('pending', 'completed') DEFAULT 'pending',
    
    `number_1` TINYINT DEFAULT NULL,
    `number_2` TINYINT DEFAULT NULL,
    `number_3` TINYINT DEFAULT NULL,
    `number_4` TINYINT DEFAULT NULL,
    `number_5` TINYINT DEFAULT NULL,
    `number_6` TINYINT DEFAULT NULL,
    
    `total_tickets_sold` INT DEFAULT 0,
    `total_gold_collected` BIGINT DEFAULT 0,
    `prize_pool` BIGINT DEFAULT 0,
    `jackpot_accumulated` BIGINT DEFAULT 0,
    `gold_sinked` BIGINT DEFAULT 0,
    `mega_pool_contribution` BIGINT DEFAULT 0,
    
    `winners_6` INT DEFAULT 0,
    `winners_5` INT DEFAULT 0,
    `winners_4` INT DEFAULT 0,
    `winners_3` INT DEFAULT 0,
    
    `rng_seed` VARCHAR(255) DEFAULT NULL,
    `created_at` BIGINT NOT NULL,
    
    INDEX(`status`),
    INDEX(`scheduled_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `lottery_tickets` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `draw_id` INT NOT NULL,
    `player_id` INT NOT NULL,
    `player_name` VARCHAR(255) NOT NULL,
    
    `number_1` TINYINT NOT NULL,
    `number_2` TINYINT NOT NULL,
    `number_3` TINYINT NOT NULL,
    `number_4` TINYINT NOT NULL,
    `number_5` TINYINT NOT NULL,
    `number_6` TINYINT NOT NULL,
    
    `ticket_type` ENUM('simple', 'double', 'quintuple', 'mega') DEFAULT 'simple',
    `cost` BIGINT NOT NULL,
    
    `matches` INT DEFAULT 0,
    `prize_gold` BIGINT DEFAULT 0,
    `prize_claimed` TINYINT DEFAULT 0,
    
    `purchased_at` BIGINT NOT NULL,
    
    FOREIGN KEY (`draw_id`) REFERENCES `lottery_draws`(`id`) ON DELETE CASCADE,
    INDEX(`draw_id`),
    INDEX(`player_id`),
    INDEX(`matches`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `lottery_lucky_numbers` (
    `player_id` INT PRIMARY KEY,
    
    `number_1` TINYINT NOT NULL,
    `number_2` TINYINT NOT NULL,
    `number_3` TINYINT NOT NULL,
    `number_4` TINYINT NOT NULL,
    `number_5` TINYINT NOT NULL,
    `number_6` TINYINT NOT NULL,
    
    `updated_at` BIGINT NOT NULL,
    
    FOREIGN KEY (`player_id`) REFERENCES `players`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
