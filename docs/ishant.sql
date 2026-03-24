CREATE TABLE IF NOT EXISTS `trip_cards` (
  `zone_id` int NOT NULL AUTO_INCREMENT,
  `zone_name` varchar(100) NOT NULL,
  `vehicle_id` int DEFAULT NULL,
  `status` varchar(20) DEFAULT 'IDLE',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`zone_id`),
  UNIQUE KEY `zone_name` (`zone_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 2: trip_card_pincode - Pincode Assignment
-- Purpose: Maps pincodes to their assigned zones
CREATE TABLE IF NOT EXISTS `trip_card_pincode` (
  `id` int NOT NULL AUTO_INCREMENT,
  `zone_id` int NOT NULL,
  `pincode` varchar(10) NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `zone_id` (`zone_id`),
  CONSTRAINT `trip_card_pincode_ibfk_1` FOREIGN KEY (`zone_id`) REFERENCES `trip_cards` (`zone_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 3: vehicles - Standardized Vehicle Fleet
-- Purpose: Manages standardized vehicle fleet with consistent capacity
CREATE TABLE IF NOT EXISTS `vehicles` (
  `vehicle_id` int NOT NULL AUTO_INCREMENT,
  `vehicle_number` varchar(50) NOT NULL,
  `capacity_kg` decimal(10,2) NOT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`vehicle_id`),
  UNIQUE KEY `vehicle_number` (`vehicle_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table 4: zone_vehicles - Zone-Vehicle Assignment
-- Purpose: Manages which vehicles are assigned to which zones
CREATE TABLE IF NOT EXISTS `zone_vehicles` (
  `id` int NOT NULL AUTO_INCREMENT,
  `zone_id` int NOT NULL,
  `vehicle_id` int NOT NULL,
  `assigned_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `is_active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `zone_id` (`zone_id`),
  KEY `vehicle_id` (`vehicle_id`),
  KEY `is_active` (`is_active`),
  CONSTRAINT `zone_vehicles_ibfk_1` FOREIGN KEY (`zone_id`) REFERENCES `trip_cards` (`zone_id`) ON DELETE CASCADE,
  CONSTRAINT `zone_vehicles_ibfk_2` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicles` (`vehicle_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- STEP 2: CREATE PERFORMANCE INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_zone_pincode ON trip_card_pincode(zone_id, pincode);
CREATE INDEX IF NOT EXISTS idx_active_assignments ON zone_vehicles(is_active, zone_id);
CREATE INDEX IF NOT EXISTS idx_vehicle_capacity ON vehicles(capacity_kg, is_active);

-- ============================================================================
-- STEP 3: POPULATE ZONES (23 optimized zones)
-- ============================================================================

INSERT INTO `trip_cards` (`zone_name`) VALUES
('ASIF NAGAR'),
('ATTAPUR'),
('BADANGPET'),
('BEGUMPET'),
('BORABANDA'),
('GOLCONDA'),
('GUDIMALKAPUR'),
('HAFEEZPET'),
('HAYATHNAGAR'),
('HIMAYATNAGAR'),
('JUBILEE HILLS'),
('KAVADIGUDA'),
('KUKATPALLY'),
('MANIKONDA'),
('MEHDIPATNAM'),
('MIYAPUR'),
('NARSINGI'),
('NIZAMPET'),
('SECUNDERABAD'),
('SHAMSHABAD'),
('TOLICHOWKI'),
('UPPAL'),
('YOUSUFGUDA');

-- ============================================================================
-- STEP 4: VERIFICATION QUERIES
-- ============================================================================

-- Check zone count (Expected: 23)
SELECT COUNT(*) as zone_count FROM trip_cards;

-- Check table structure
SHOW TABLES LIKE 'trip%';
SHOW TABLES LIKE 'zone%';
SHOW TABLES LIKE 'vehicles';

-- Verify foreign key constraints
SELECT 
    TABLE_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME
FROM 
    INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE 
    TABLE_SCHEMA = DATABASE()
    AND REFERENCED_TABLE_NAME IS NOT NULL
    AND TABLE_NAME IN ('trip_card_pincode', 'zone_vehicles');