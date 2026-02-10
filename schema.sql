-- MySQL dump 10.13  Distrib 8.0.21, for Win64 (x86_64)
--
-- Host: localhost    Database: loagma_new
-- ------------------------------------------------------
-- Server version	8.0.21

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `admin`
--

DROP TABLE IF EXISTS `admin`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admin` (
  `userid` int unsigned NOT NULL AUTO_INCREMENT,
  `session_id` varchar(250) DEFAULT '',
  `username` varchar(250) NOT NULL,
  `name` text NOT NULL,
  `password` varchar(60) NOT NULL,
  `type` varchar(250) NOT NULL DEFAULT '',
  `register_date` int unsigned NOT NULL DEFAULT '0',
  `last_activity` int unsigned NOT NULL DEFAULT '0',
  `data` text,
  `delivery_manage_by` varchar(255) NOT NULL DEFAULT 'SuperAdmin',
  `org_name` varchar(255) DEFAULT NULL,
  `org_email` varchar(255) DEFAULT NULL,
  `org_contact_no` varchar(255) DEFAULT NULL,
  `org_gst` varchar(255) DEFAULT NULL,
  `org_address` text NOT NULL,
  `category_id` text,
  `city_id` varchar(255) DEFAULT NULL,
  `areas` text,
  `web_token` text,
  `commission` int DEFAULT NULL,
  PRIMARY KEY (`userid`)
) ENGINE=InnoDB AUTO_INCREMENT=126 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `bom_items`
--

DROP TABLE IF EXISTS `bom_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bom_items` (
  `bom_item_id` bigint NOT NULL AUTO_INCREMENT,
  `bom_id` bigint unsigned NOT NULL,
  `raw_material_id` bigint unsigned NOT NULL,
  `quantity_per_unit` decimal(10,3) NOT NULL,
  `unit_type` varchar(20) NOT NULL,
  `wastage_percent` decimal(5,2) DEFAULT '0.00',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`bom_item_id`),
  KEY `fk_bom_items_bom` (`bom_id`),
  CONSTRAINT `fk_bom_items_bom` FOREIGN KEY (`bom_id`) REFERENCES `bom_master` (`bom_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `bom_master`
--

DROP TABLE IF EXISTS `bom_master`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bom_master` (
  `bom_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `product_id` bigint unsigned NOT NULL,
  `bom_version` varchar(20) NOT NULL,
  `status` enum('DRAFT','APPROVED','LOCKED') DEFAULT 'DRAFT',
  `remarks` text,
  `created_by` bigint DEFAULT NULL,
  `approved_by` bigint DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`bom_id`),
  UNIQUE KEY `uk_product_version` (`product_id`,`bom_version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `brand`
--

DROP TABLE IF EXISTS `brand`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `brand` (
  `brand_id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` text NOT NULL,
  PRIMARY KEY (`brand_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cache`
--

DROP TABLE IF EXISTS `cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cache` (
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `value` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiration` int NOT NULL,
  PRIMARY KEY (`key`),
  KEY `cache_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cache_locks`
--

DROP TABLE IF EXISTS `cache_locks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cache_locks` (
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `owner` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiration` int NOT NULL,
  PRIMARY KEY (`key`),
  KEY `cache_locks_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `calling_staff`
--

DROP TABLE IF EXISTS `calling_staff`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `calling_staff` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(20) NOT NULL,
  `contact_no` varchar(11) NOT NULL,
  `type` varchar(30) NOT NULL COMMENT 'tele-marketer, converter, Cold caller, etc',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_contactNumber` (`contact_no`)
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cart`
--

DROP TABLE IF EXISTS `cart`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cart` (
  `cart_id` int NOT NULL AUTO_INCREMENT,
  `userid` bigint NOT NULL,
  `addressId` int NOT NULL,
  `product_id` bigint NOT NULL,
  `vendor_product_id` int NOT NULL DEFAULT '0',
  `pack_id` varchar(255) NOT NULL,
  `quantity` smallint unsigned NOT NULL DEFAULT '0',
  `total` decimal(10,2) NOT NULL DEFAULT '0.00',
  `ctype_id` varchar(250) NOT NULL DEFAULT 'vegetables_fruits',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cart_id`),
  UNIQUE KEY `unique_user_product_pack_address` (`userid`,`product_id`,`pack_id`,`addressId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cart_type`
--

DROP TABLE IF EXISTS `cart_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cart_type` (
  `cart_tid` bigint unsigned NOT NULL AUTO_INCREMENT,
  `type_name` text NOT NULL,
  `ctype_id` text NOT NULL,
  `is_used` tinyint unsigned NOT NULL DEFAULT '0',
  `has_express` tinyint unsigned NOT NULL DEFAULT '0',
  `express_charge` decimal(10,2) unsigned NOT NULL DEFAULT '0.00',
  `min_total` decimal(10,2) unsigned NOT NULL DEFAULT '0.00',
  `delivery_charge` decimal(10,2) unsigned NOT NULL DEFAULT '0.00',
  `note` text NOT NULL,
  PRIMARY KEY (`cart_tid`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `categories`
--

DROP TABLE IF EXISTS `categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `categories` (
  `cat_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(250) NOT NULL,
  `parent_cat_id` int unsigned NOT NULL,
  `is_active` tinyint unsigned NOT NULL DEFAULT '0',
  `type` tinyint NOT NULL DEFAULT '0' COMMENT '0:Has_subcategories, 1: Has_products',
  `image_slug` varchar(15) DEFAULT ' ',
  `image_name` text,
  `img_last_updated` int unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`cat_id`)
) ENGINE=InnoDB AUTO_INCREMENT=65992 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `daily_book_stock`
--

DROP TABLE IF EXISTS `daily_book_stock`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `daily_book_stock` (
  `id` int NOT NULL AUTO_INCREMENT,
  `vendor_product_id` int NOT NULL,
  `date` date NOT NULL,
  `closing_stock` decimal(10,2) NOT NULL DEFAULT '0.00',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_product_date` (`vendor_product_id`,`date`),
  KEY `idx_product_date` (`vendor_product_id`,`date`),
  KEY `idx_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `deli_staff`
--

DROP TABLE IF EXISTS `deli_staff`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `deli_staff` (
  `deli_id` int unsigned NOT NULL AUTO_INCREMENT,
  `admin_id` int unsigned NOT NULL DEFAULT '0',
  `role` varchar(20) NOT NULL DEFAULT 'driver',
  `name` text NOT NULL,
  `mobile` varchar(20) NOT NULL,
  `password` varchar(250) DEFAULT NULL,
  `sess_id` varchar(250) DEFAULT NULL,
  `lat` double(10,8) DEFAULT NULL,
  `lng` double(11,8) DEFAULT NULL,
  `location_last_updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_locked` tinyint unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`deli_id`),
  UNIQUE KEY `mobile` (`mobile`)
) ENGINE=InnoDB AUTO_INCREMENT=243 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `driver_accountability_log`
--

DROP TABLE IF EXISTS `driver_accountability_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `driver_accountability_log` (
  `id` int NOT NULL AUTO_INCREMENT,
  `driver_deli_id` int NOT NULL COMMENT 'References deli_staff.deli_id (the driver being held accountable)',
  `trip_id` int NOT NULL,
  `audit_log_id` int NOT NULL,
  `item_id` int NOT NULL,
  `vendor_product_id` int NOT NULL,
  `product_id` int NOT NULL,
  `loss_type` enum('theft','lost','damaged','unreturned','other') COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity_lost` decimal(10,2) NOT NULL,
  `unit_type` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `monetary_value` decimal(10,2) NOT NULL,
  `penalty_status` enum('pending','applied','waived','disputed') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `penalty_applied_at` datetime DEFAULT NULL,
  `penalty_applied_by` int DEFAULT NULL,
  `loss_notes` text COLLATE utf8mb4_unicode_ci,
  `resolution_notes` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_driver` (`driver_deli_id`),
  KEY `idx_trip` (`trip_id`),
  KEY `idx_audit_log` (`audit_log_id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `driver_rating`
--

DROP TABLE IF EXISTS `driver_rating`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `driver_rating` (
  `rating_id` int NOT NULL AUTO_INCREMENT,
  `order_id` bigint NOT NULL,
  `user_id` bigint DEFAULT NULL,
  `rating` int NOT NULL,
  `review_text` text,
  `review_type` enum('delivered','cancelled') NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`order_id`),
  UNIQUE KEY `rating_id` (`rating_id`),
  CONSTRAINT `driver_rating_chk_1` CHECK (((`rating` >= 1) and (`rating` <= 5)))
) ENGINE=InnoDB AUTO_INCREMENT=3654 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `failed_jobs`
--

DROP TABLE IF EXISTS `failed_jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `failed_jobs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `connection` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `queue` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `exception` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `inventory_op`
--

DROP TABLE IF EXISTS `inventory_op`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inventory_op` (
  `op_id` int unsigned NOT NULL,
  `product_id` int unsigned NOT NULL DEFAULT '0',
  `op_type` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'inbound' COMMENT 'purchase, sale, damage, expire, free',
  `quantity` decimal(10,2) NOT NULL DEFAULT '0.00',
  `unit_type` text COLLATE utf8_unicode_ci,
  `unitquantity` decimal(10,2) NOT NULL DEFAULT '0.00',
  `amount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `op_date` date NOT NULL,
  `note` text COLLATE utf8_unicode_ci NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`op_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `job_batches`
--

DROP TABLE IF EXISTS `job_batches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `job_batches` (
  `id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `total_jobs` int NOT NULL,
  `pending_jobs` int NOT NULL,
  `failed_jobs` int NOT NULL,
  `failed_job_ids` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `options` mediumtext COLLATE utf8mb4_unicode_ci,
  `cancelled_at` int DEFAULT NULL,
  `created_at` int NOT NULL,
  `finished_at` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `jobs`
--

DROP TABLE IF EXISTS `jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jobs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `queue` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `attempts` tinyint unsigned NOT NULL,
  `reserved_at` int unsigned DEFAULT NULL,
  `available_at` int unsigned NOT NULL,
  `created_at` int unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `jobs_queue_index` (`queue`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `master_orders`
--

DROP TABLE IF EXISTS `master_orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `master_orders` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `txn_id` varchar(255) NOT NULL,
  `payment_status` varchar(255) NOT NULL,
  `order_count` int NOT NULL,
  `payment_method` varchar(255) NOT NULL,
  `delivery_info` text NOT NULL,
  `order_total` float(10,2) NOT NULL,
  `delivery_charge` float(10,2) NOT NULL,
  `discount` float(10,2) NOT NULL,
  `before_discount` float(10,2) NOT NULL,
  `status` enum('1','0') NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=218424 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `migrations`
--

DROP TABLE IF EXISTS `migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `migrations` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `migration` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `batch` int NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `offer_log`
--

DROP TABLE IF EXISTS `offer_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `offer_log` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `order_id` int NOT NULL,
  `offer_id` int NOT NULL,
  `used_date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_offer_date` (`user_id`,`offer_id`,`used_date`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `offers`
--

DROP TABLE IF EXISTS `offers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `offers` (
  `off_id` bigint NOT NULL,
  `name` text,
  `off_type` varchar(250) NOT NULL DEFAULT ' ',
  `product_id` bigint DEFAULT '0' COMMENT 'vendorProductId',
  `off_data` text,
  `is_active` tinyint NOT NULL DEFAULT '0',
  PRIMARY KEY (`off_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `orders`
--

DROP TABLE IF EXISTS `orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders` (
  `order_id` bigint unsigned NOT NULL,
  `bill_number` int DEFAULT NULL,
  `master_order_id` int NOT NULL DEFAULT '0',
  `txn_id` varchar(250) NOT NULL,
  `buyer_userid` bigint unsigned NOT NULL,
  `start_time` int unsigned NOT NULL DEFAULT '0',
  `last_update_time` int unsigned NOT NULL DEFAULT '0',
  `short_datetime` text NOT NULL,
  `order_state` varchar(250) NOT NULL,
  `payment_method` varchar(250) NOT NULL DEFAULT 'cod',
  `ctype_id` varchar(250) NOT NULL DEFAULT 'vegetables_fruits',
  `items_count` int unsigned NOT NULL DEFAULT '0',
  `delivery_charge` decimal(10,0) NOT NULL DEFAULT '0',
  `order_total` decimal(12,2) unsigned NOT NULL DEFAULT '0.00',
  `bill_amount` int DEFAULT NULL,
  `delivery_info` text NOT NULL,
  `area_name` text NOT NULL,
  `feedback` varchar(100) NOT NULL,
  `admin_id` bigint unsigned NOT NULL DEFAULT '0',
  `payment_status` varchar(250) NOT NULL DEFAULT 'not_paid',
  `amountReceivedInfo` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin,
  `trip_id` int DEFAULT NULL,
  `discount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `before_discount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `time_slot` varchar(250) NOT NULL DEFAULT 'Now',
  `delivered_time` int DEFAULT NULL,
  `deli_id` int DEFAULT NULL,
  PRIMARY KEY (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `orders_item`
--

DROP TABLE IF EXISTS `orders_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders_item` (
  `order_id` bigint unsigned NOT NULL DEFAULT '0',
  `item_id` bigint unsigned NOT NULL,
  `product_id` bigint unsigned NOT NULL,
  `vendor_product_id` int DEFAULT NULL,
  `pinfo` text NOT NULL,
  `offers` text,
  `quantity` mediumint unsigned NOT NULL DEFAULT '0',
  `qty_loaded` int DEFAULT NULL,
  `qty_delivered` int DEFAULT NULL,
  `qty_returned` int DEFAULT NULL,
  `item_price` decimal(12,2) unsigned NOT NULL DEFAULT '0.00',
  `item_total` decimal(12,2) unsigned NOT NULL DEFAULT '0.00',
  `op_id` bigint DEFAULT '0',
  `commission` double(10,2) NOT NULL,
  PRIMARY KEY (`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `otp`
--

DROP TABLE IF EXISTS `otp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `otp` (
  `contactno` varchar(30) NOT NULL,
  `slug` varchar(16) NOT NULL,
  `otp_num` varchar(10) NOT NULL,
  `otp_time` int unsigned NOT NULL DEFAULT '0',
  `purpose` varchar(250) NOT NULL,
  PRIMARY KEY (`contactno`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `password_reset_tokens`
--

DROP TABLE IF EXISTS `password_reset_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `physical_stock`
--

DROP TABLE IF EXISTS `physical_stock`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `physical_stock` (
  `id` int NOT NULL,
  `vendor_product_id` int NOT NULL,
  `stock` double NOT NULL,
  `last_updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `note` text,
  PRIMARY KEY (`id`),
  KEY `vendor_product_id` (`vendor_product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `product`
--

DROP TABLE IF EXISTS `product`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `product` (
  `product_id` bigint unsigned NOT NULL,
  `cat_id` int unsigned NOT NULL DEFAULT '0',
  `parent_cat_id` int unsigned NOT NULL DEFAULT '0',
  `brand` text NOT NULL,
  `ctype_id` varchar(250) NOT NULL DEFAULT 'vegetables_fruits',
  `seq_no` int unsigned DEFAULT '0',
  `start_date` int unsigned NOT NULL DEFAULT '0',
  `is_published` tinyint unsigned NOT NULL DEFAULT '0',
  `is_used` tinyint NOT NULL DEFAULT '0',
  `is_deleted` tinyint NOT NULL DEFAULT '0',
  `in_stock` tinyint unsigned NOT NULL DEFAULT '0',
  `inventory_type` enum('SINGLE','PACK_WISE') NOT NULL DEFAULT 'SINGLE',
  `inventory_unit_type` varchar(255) NOT NULL DEFAULT 'WEIGHT',
  `name` text NOT NULL,
  `description` text NOT NULL,
  `display_photo` text,
  `keywords` text,
  `spec_params` text NOT NULL,
  `packs` text,
  `default_pack_id` varchar(255) NOT NULL DEFAULT ' ',
  `hsn_code` varchar(10) NOT NULL,
  `gst_percent` decimal(5,2) NOT NULL,
  `offers` text,
  `cache_txt` mediumtext,
  `img_last_updated` int unsigned NOT NULL DEFAULT '0',
  `stock` decimal(10,3) DEFAULT NULL,
  `stock_ut_id` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`product_id`),
  FULLTEXT KEY `prodNameFullText` (`name`,`keywords`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `product_photos`
--

DROP TABLE IF EXISTS `product_photos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_photos` (
  `product_id` bigint unsigned NOT NULL DEFAULT '0',
  `photo_id` bigint unsigned NOT NULL,
  `file_location` varchar(250) NOT NULL DEFAULT '0',
  `photo_slug` varchar(10) NOT NULL DEFAULT '0000',
  PRIMARY KEY (`photo_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `product_purchase`
--

DROP TABLE IF EXISTS `product_purchase`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_purchase` (
  `item_id` bigint unsigned NOT NULL,
  `day_id` varchar(20) NOT NULL DEFAULT '01-01-2018',
  `product_id` bigint unsigned NOT NULL DEFAULT '0',
  `quantity` decimal(10,2) unsigned NOT NULL DEFAULT '0.00',
  `unit_id` text NOT NULL,
  `cost` decimal(10,2) NOT NULL DEFAULT '0.00',
  `post_date` int unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`item_id`),
  UNIQUE KEY `day_id` (`day_id`,`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `products`
--

DROP TABLE IF EXISTS `products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `products` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `sku` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `price` decimal(10,2) NOT NULL DEFAULT '0.00',
  `stock` int NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `products_sku_unique` (`sku`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `promo`
--

DROP TABLE IF EXISTS `promo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `promo` (
  `promo_id` bigint unsigned NOT NULL,
  `title` varchar(250) DEFAULT NULL,
  `description` text,
  `ctype_id` varchar(250) NOT NULL DEFAULT 'all',
  `discount` decimal(10,3) NOT NULL DEFAULT '0.000',
  `max_use` int unsigned NOT NULL DEFAULT '0',
  `from` datetime(6) DEFAULT NULL,
  `to` datetime(6) DEFAULT NULL,
  `status` tinyint NOT NULL DEFAULT '0',
  `promo_data` text NOT NULL COMMENT 'amount, percentage, percentage_up_to, ladder',
  PRIMARY KEY (`promo_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `promo_log`
--

DROP TABLE IF EXISTS `promo_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `promo_log` (
  `log_id` bigint unsigned NOT NULL,
  `order_id` bigint unsigned DEFAULT '0',
  `userid` bigint unsigned DEFAULT '0',
  `promo_id` bigint unsigned DEFAULT '0',
  PRIMARY KEY (`log_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `search`
--

DROP TABLE IF EXISTS `search`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `search` (
  `s.no` int NOT NULL,
  `user_id` int NOT NULL,
  `search_text` varchar(200) COLLATE utf8mb4_general_ci NOT NULL,
  `count` int NOT NULL COMMENT 'no. of times this searchText has been used',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`s.no`),
  FULLTEXT KEY `searchTextFullText` (`search_text`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sessions` (
  `id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` bigint unsigned DEFAULT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` text COLLATE utf8mb4_unicode_ci,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_activity` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `sessions_user_id_index` (`user_id`),
  KEY `sessions_last_activity_index` (`last_activity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stock_count`
--

DROP TABLE IF EXISTS `stock_count`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stock_count` (
  `id` int NOT NULL,
  `assignment_id` int NOT NULL,
  `vendor_product_id` int NOT NULL,
  `counted_quantity` double NOT NULL,
  `count_unit` varchar(12) NOT NULL,
  `standard_unit_quantity` decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_assignment` (`assignment_id`),
  KEY `idx_vendor_product` (`vendor_product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stock_count_assignments`
--

DROP TABLE IF EXISTS `stock_count_assignments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stock_count_assignments` (
  `id` int NOT NULL,
  `master_session_id` int NOT NULL,
  `counter_user_id` int NOT NULL,
  `category_id` int NOT NULL,
  `status` enum('assigned','in_progress','completed','paused') DEFAULT 'assigned',
  `assigned_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `started_at` timestamp NULL DEFAULT NULL,
  `completed_at` timestamp NULL DEFAULT NULL,
  `notes` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_session_category` (`master_session_id`,`category_id`),
  KEY `idx_counter_user` (`counter_user_id`),
  KEY `idx_master_session` (`master_session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stock_count_master_session`
--

DROP TABLE IF EXISTS `stock_count_master_session`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stock_count_master_session` (
  `id` int NOT NULL,
  `supervisor_id` int NOT NULL,
  `status` enum('planning','in_progress','completed','cancelled') DEFAULT 'planning',
  `total_categories` int DEFAULT '0',
  `completed_categories` int DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `completed_at` timestamp NULL DEFAULT NULL,
  `notes` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stock_notify`
--

DROP TABLE IF EXISTS `stock_notify`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stock_notify` (
  `userid` bigint unsigned NOT NULL,
  `product_id` bigint unsigned NOT NULL COMMENT 'this is vendor prod id',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `userid` (`userid`,`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `time_slots`
--

DROP TABLE IF EXISTS `time_slots`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `time_slots` (
  `slot_id` bigint unsigned NOT NULL,
  `time_slot_group_id` int NOT NULL,
  `area_id` varchar(250) DEFAULT NULL,
  `start_date` int unsigned NOT NULL DEFAULT '1',
  `interval` int unsigned NOT NULL DEFAULT '1',
  `count_limit` int unsigned NOT NULL DEFAULT '3',
  `order_time_end` int unsigned DEFAULT '0',
  `delivery_time_start` int unsigned DEFAULT '0',
  `delivery_time_end` int unsigned DEFAULT '0',
  `display_text` varchar(250) NOT NULL DEFAULT '',
  PRIMARY KEY (`slot_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `timing_slot_group_categories`
--

DROP TABLE IF EXISTS `timing_slot_group_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `timing_slot_group_categories` (
  `id` int NOT NULL,
  `group_id` int NOT NULL,
  `category_id` int NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `timing_slot_groups`
--

DROP TABLE IF EXISTS `timing_slot_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `timing_slot_groups` (
  `id` int NOT NULL,
  `min_amount` float(10,2) NOT NULL,
  `express_delivery_charge` float(10,2) NOT NULL,
  `delivery_charge` float(10,2) NOT NULL,
  `admin_id` int NOT NULL,
  `is_active` enum('1','0') NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `admin_id` (`admin_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `trip_audit_log`
--

DROP TABLE IF EXISTS `trip_audit_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `trip_audit_log` (
  `id` int NOT NULL AUTO_INCREMENT,
  `trip_id` int NOT NULL,
  `order_id` int NOT NULL,
  `item_id` int NOT NULL,
  `vendor_product_id` int NOT NULL,
  `product_id` int NOT NULL,
  `qty_loaded` int NOT NULL,
  `qty_claimed_delivered` int NOT NULL,
  `qty_claimed_returned` int NOT NULL,
  `qty_verified_delivered` int NOT NULL,
  `qty_verified_returned` int NOT NULL,
  `discrepancy_delivered` int GENERATED ALWAYS AS ((`qty_verified_delivered` - `qty_claimed_delivered`)) STORED,
  `discrepancy_returned` int GENERATED ALWAYS AS ((`qty_verified_returned` - `qty_claimed_returned`)) STORED,
  `auditor_deli_id` int NOT NULL COMMENT 'References deli_staff.deli_id (the auditor who verified the trip)',
  `audited_at` datetime NOT NULL,
  `investigation_status` enum('pending','resolved') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `investigator_deli_id` int DEFAULT NULL COMMENT 'References deli_staff.deli_id (the investigator who resolved discrepancies)',
  `investigated_at` datetime DEFAULT NULL,
  `resolution_outcome` enum('stock_loss','stock_recovered') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `resolution_notes` text COLLATE utf8mb4_unicode_ci,
  `qty_recovered_returned` int DEFAULT NULL,
  `driver_liable` tinyint(1) DEFAULT '0',
  `liability_amount` decimal(10,2) DEFAULT '0.00',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `trips`
--

DROP TABLE IF EXISTS `trips`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `trips` (
  `trip_id` int NOT NULL,
  `deli_id` int unsigned DEFAULT NULL,
  `status` varchar(30) NOT NULL COMMENT 'unass, ass, ongoing, completed',
  `description` varchar(40) NOT NULL COMMENT 'vehicle number, trip number. || just vehicle number',
  `start_date` varchar(30) NOT NULL,
  `completed_at` varchar(25) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`trip_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user` (
  `userid` bigint unsigned NOT NULL,
  `email` varchar(250) NOT NULL DEFAULT ' ',
  `is_email_verified` tinyint NOT NULL DEFAULT '0',
  `contactno` varchar(250) NOT NULL,
  `is_contact_verified` tinyint NOT NULL DEFAULT '0',
  `name` text NOT NULL,
  `account_state` varchar(250) NOT NULL DEFAULT 'incomplete',
  `address` text NOT NULL,
  `latitude` float(10,6) NOT NULL DEFAULT '0.000000',
  `longitude` float(10,6) NOT NULL DEFAULT '0.000000',
  `dob` text,
  `register_date` int unsigned NOT NULL DEFAULT '0',
  `shop_name` varchar(255) DEFAULT NULL,
  `shop_address` varchar(255) DEFAULT NULL,
  `shop_plot_no` varchar(255) DEFAULT NULL,
  `user_type` enum('B2C','B2B') NOT NULL,
  `adhar_card` varchar(255) DEFAULT NULL,
  `shop_photo` varchar(255) DEFAULT NULL,
  `shop_licence` varchar(255) DEFAULT NULL,
  `bussiness_pan_card` varchar(255) DEFAULT NULL,
  `is_approved` enum('YES','NO','REQUESTED') NOT NULL DEFAULT 'YES',
  `session_id` text NOT NULL,
  `last_activity` int unsigned NOT NULL DEFAULT '0',
  `push_notif_id` text NOT NULL,
  `is_first_login` tinyint unsigned NOT NULL DEFAULT '1',
  `has_unread_comments` tinyint unsigned NOT NULL DEFAULT '0',
  `password` varchar(250) DEFAULT NULL,
  PRIMARY KEY (`userid`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_addresses`
--

DROP TABLE IF EXISTS `user_addresses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_addresses` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `full_name` varchar(255) DEFAULT NULL,
  `full_address` varchar(255) DEFAULT NULL,
  `phone_no` varchar(255) DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `address` varchar(255) NOT NULL,
  `lat` double(10,8) NOT NULL,
  `lng` double(11,8) NOT NULL,
  `type` enum('Home','Office') NOT NULL,
  `city_id` varchar(255) NOT NULL,
  `area_id` varchar(255) NOT NULL,
  `is_default` enum('0','1') NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `remember_token` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_email_unique` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `vendor_area_categories`
--

DROP TABLE IF EXISTS `vendor_area_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vendor_area_categories` (
  `id` int NOT NULL,
  `admin_id` int NOT NULL,
  `city_id` varchar(255) NOT NULL DEFAULT '',
  `area_id` varchar(255) NOT NULL,
  `category_id` varchar(255) NOT NULL,
  `commisson` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `vendor_products`
--

DROP TABLE IF EXISTS `vendor_products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vendor_products` (
  `id` int NOT NULL AUTO_INCREMENT,
  `admin_vendor_id` int NOT NULL,
  `product_id` int NOT NULL,
  `packs` text NOT NULL,
  `default_pack_id` varchar(255) NOT NULL,
  `status` enum('1','0') NOT NULL,
  `in_stock` enum('1','0') NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13799 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `vendor_products_inventory`
--

DROP TABLE IF EXISTS `vendor_products_inventory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vendor_products_inventory` (
  `id` int NOT NULL AUTO_INCREMENT,
  `vendor_product_id` int NOT NULL,
  `product_id` int NOT NULL,
  `action_type` varchar(255) NOT NULL,
  `pack_id` varchar(255) NOT NULL,
  `vendor_id` int DEFAULT NULL,
  `quantity` double(10,2) NOT NULL,
  `unit_type` varchar(255) NOT NULL,
  `unitquantity` double(10,2) NOT NULL,
  `amount` double(10,2) NOT NULL,
  `wholesale_user_id` int DEFAULT NULL,
  `inv_date` date NOT NULL,
  `inv_type` enum('CREDIT','DEBIT') NOT NULL,
  `note` text NOT NULL,
  `trip_id` int DEFAULT NULL,
  `updated_at` datetime NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=215 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-02-10 15:02:49
