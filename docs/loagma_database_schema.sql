-- ============================================
-- Database Schema for Loagma New Database
-- Generated from: _StructureOfLoagmaNew_ (1) (1).sql
-- Date: February 13, 2026
-- Description: Schema-only structure without data
-- ============================================

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `loagma_new`
--

-- --------------------------------------------------------

--
-- Table structure for table `admin`
--

CREATE TABLE `admin` (
  `userid` int(11) UNSIGNED NOT NULL,
  `session_id` varchar(250) DEFAULT '',
  `username` varchar(250) NOT NULL,
  `name` text NOT NULL,
  `password` varchar(60) NOT NULL,
  `type` varchar(250) NOT NULL DEFAULT '',
  `register_date` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `last_activity` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `data` text DEFAULT NULL,
  `delivery_manage_by` varchar(255) NOT NULL DEFAULT 'SuperAdmin',
  `org_name` varchar(255) DEFAULT NULL,
  `org_email` varchar(255) DEFAULT NULL,
  `org_contact_no` varchar(255) DEFAULT NULL,
  `org_gst` varchar(255) DEFAULT NULL,
  `org_address` text NOT NULL,
  `category_id` text DEFAULT NULL,
  `city_id` varchar(255) DEFAULT NULL,
  `areas` text DEFAULT NULL,
  `web_token` text DEFAULT NULL,
  `commission` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `brand`
--

CREATE TABLE `brand` (
  `brand_id` int(10) UNSIGNED NOT NULL,
  `name` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `calling_staff`
--

CREATE TABLE `calling_staff` (
  `id` int(11) NOT NULL,
  `name` varchar(20) NOT NULL,
  `contact_no` varchar(11) NOT NULL,
  `type` varchar(30) NOT NULL COMMENT 'tele-marketer, converter, Cold caller, etc'
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `cart`
--

CREATE TABLE `cart` (
  `cart_id` int(11) NOT NULL,
  `userid` bigint(20) NOT NULL,
  `addressId` int(15) NOT NULL,
  `product_id` bigint(20) NOT NULL,
  `vendor_product_id` int(11) NOT NULL DEFAULT 0,
  `pack_id` varchar(255) NOT NULL,
  `quantity` smallint(5) UNSIGNED NOT NULL DEFAULT 0,
  `total` decimal(10,2) NOT NULL DEFAULT 0.00,
  `ctype_id` varchar(250) NOT NULL DEFAULT 'vegetables_fruits',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `cart_type`
--

CREATE TABLE `cart_type` (
  `cart_tid` bigint(20) UNSIGNED NOT NULL,
  `type_name` text NOT NULL,
  `ctype_id` text NOT NULL,
  `is_used` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `has_express` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `express_charge` decimal(10,2) UNSIGNED NOT NULL DEFAULT 0.00,
  `min_total` decimal(10,2) UNSIGNED NOT NULL DEFAULT 0.00,
  `delivery_charge` decimal(10,2) UNSIGNED NOT NULL DEFAULT 0.00,
  `note` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `cat_id` bigint(5) UNSIGNED NOT NULL,
  `name` varchar(250) NOT NULL,
  `parent_cat_id` int(10) UNSIGNED NOT NULL,
  `is_active` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `type` tinyint(4) NOT NULL DEFAULT 0 COMMENT '0:Has_subcategories, 1: Has_products',
  `image_slug` varchar(15) DEFAULT ' ',
  `image_name` text DEFAULT NULL,
  `img_last_updated` int(10) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `daily_book_stock`
--

CREATE TABLE `daily_book_stock` (
  `id` int(11) NOT NULL,
  `vendor_product_id` int(11) NOT NULL,
  `date` date NOT NULL,
  `closing_stock` decimal(10,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `deli_staff`
--

CREATE TABLE `deli_staff` (
  `deli_id` int(11) UNSIGNED NOT NULL,
  `admin_id` int(11) UNSIGNED NOT NULL DEFAULT 0,
  `role` varchar(20) NOT NULL DEFAULT 'driver',
  `name` text NOT NULL,
  `mobile` varchar(20) NOT NULL,
  `password` varchar(250) DEFAULT NULL,
  `sess_id` varchar(250) DEFAULT NULL,
  `lat` double(10,8) DEFAULT NULL,
  `lng` double(11,8) DEFAULT NULL,
  `location_last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `is_locked` tinyint(3) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `driver_accountability_log`
--

CREATE TABLE `driver_accountability_log` (
  `id` int(11) NOT NULL,
  `driver_deli_id` int(11) NOT NULL COMMENT 'References deli_staff.deli_id (the driver being held accountable)',
  `trip_id` int(11) NOT NULL,
  `audit_log_id` int(11) NOT NULL,
  `item_id` int(11) NOT NULL,
  `vendor_product_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `loss_type` enum('theft','lost','damaged','unreturned','other') NOT NULL,
  `quantity_lost` decimal(10,2) NOT NULL,
  `unit_type` varchar(20) DEFAULT NULL,
  `monetary_value` decimal(10,2) NOT NULL,
  `penalty_status` enum('pending','applied','waived','disputed') DEFAULT 'pending',
  `penalty_applied_at` datetime DEFAULT NULL,
  `penalty_applied_by` int(11) DEFAULT NULL,
  `loss_notes` text DEFAULT NULL,
  `resolution_notes` text DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `driver_rating`
--

CREATE TABLE `driver_rating` (
  `rating_id` int(11) NOT NULL,
  `order_id` bigint(20) NOT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  `rating` int(1) NOT NULL CHECK (`rating` >= 1 and `rating` <= 5),
  `review_text` text DEFAULT NULL,
  `review_type` enum('delivered','cancelled') NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
-- --------------------------------------------------------

--
-- Table structure for table `inventory_op`
--

CREATE TABLE `inventory_op` (
  `op_id` int(10) UNSIGNED NOT NULL,
  `product_id` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `op_type` varchar(255) NOT NULL DEFAULT 'inbound' COMMENT 'purchase, sale, damage, expire, free',
  `quantity` decimal(10,2) NOT NULL DEFAULT 0.00,
  `unit_type` text DEFAULT NULL,
  `unitquantity` decimal(10,2) NOT NULL DEFAULT 0.00,
  `amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `op_date` date NOT NULL,
  `note` text NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `master_orders`
--

CREATE TABLE `master_orders` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `txn_id` varchar(255) NOT NULL,
  `payment_status` varchar(255) NOT NULL,
  `order_count` int(11) NOT NULL,
  `payment_method` varchar(255) NOT NULL,
  `delivery_info` text NOT NULL,
  `order_total` float(10,2) NOT NULL,
  `delivery_charge` float(10,2) NOT NULL,
  `discount` float(10,2) NOT NULL,
  `before_discount` float(10,2) NOT NULL,
  `status` enum('1','0') NOT NULL,
  `created_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `offers`
--

CREATE TABLE `offers` (
  `off_id` bigint(20) NOT NULL,
  `name` text DEFAULT NULL,
  `off_type` varchar(250) NOT NULL DEFAULT ' ',
  `product_id` bigint(20) DEFAULT 0 COMMENT 'vendorProductId',
  `off_data` text DEFAULT NULL,
  `is_active` tinyint(4) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `offer_log`
--

CREATE TABLE `offer_log` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `order_id` int(11) NOT NULL,
  `offer_id` int(11) NOT NULL,
  `used_date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

CREATE TABLE `orders` (
  `order_id` bigint(20) UNSIGNED NOT NULL,
  `bill_number` int(12) DEFAULT NULL,
  `master_order_id` int(11) NOT NULL DEFAULT 0,
  `txn_id` varchar(250) NOT NULL,
  `buyer_userid` bigint(20) UNSIGNED NOT NULL,
  `start_time` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `last_update_time` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `short_datetime` text NOT NULL,
  `order_state` varchar(250) NOT NULL,
  `payment_method` varchar(250) NOT NULL DEFAULT 'cod',
  `ctype_id` varchar(250) NOT NULL DEFAULT 'vegetables_fruits',
  `items_count` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `delivery_charge` decimal(10,0) NOT NULL DEFAULT 0,
  `order_total` decimal(12,2) UNSIGNED NOT NULL DEFAULT 0.00,
  `bill_amount` int(10) DEFAULT NULL,
  `delivery_info` text NOT NULL,
  `area_name` text NOT NULL,
  `feedback` varchar(100) NOT NULL,
  `admin_id` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `payment_status` varchar(250) NOT NULL DEFAULT 'not_paid',
  `amountReceivedInfo` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `trip_id` int(10) DEFAULT NULL,
  `discount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `before_discount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `time_slot` varchar(250) NOT NULL DEFAULT 'Now',
  `delivered_time` int(11) DEFAULT NULL,
  `deli_id` int(2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
-- --------------------------------------------------------

--
-- Table structure for table `orders_item`
--

CREATE TABLE `orders_item` (
  `order_id` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `item_id` bigint(20) UNSIGNED NOT NULL,
  `product_id` bigint(20) UNSIGNED NOT NULL,
  `vendor_product_id` int(11) DEFAULT NULL,
  `pinfo` text NOT NULL,
  `offers` text DEFAULT NULL,
  `quantity` mediumint(8) UNSIGNED NOT NULL DEFAULT 0,
  `qty_loaded` int(3) DEFAULT NULL,
  `qty_delivered` int(3) DEFAULT NULL,
  `qty_returned` int(3) DEFAULT NULL,
  `item_price` decimal(12,2) UNSIGNED NOT NULL DEFAULT 0.00,
  `item_total` decimal(12,2) UNSIGNED NOT NULL DEFAULT 0.00,
  `op_id` bigint(20) DEFAULT 0,
  `commission` double(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
-- --------------------------------------------------------

--
-- Table structure for table `product`
--

CREATE TABLE `product` (
  `product_id` bigint(20) UNSIGNED NOT NULL,
  `cat_id` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `parent_cat_id` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `brand` text NOT NULL,
  `ctype_id` varchar(250) NOT NULL DEFAULT 'vegetables_fruits',
  `seq_no` int(10) UNSIGNED DEFAULT 0,
  `start_date` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `is_published` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `is_used` tinyint(4) NOT NULL DEFAULT 0,
  `is_deleted` tinyint(4) NOT NULL DEFAULT 0,
  `in_stock` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `inventory_type` enum('SINGLE','PACK_WISE') NOT NULL DEFAULT 'SINGLE',
  `inventory_unit_type` varchar(255) NOT NULL DEFAULT 'WEIGHT',
  `name` text NOT NULL,
  `description` text NOT NULL,
  `display_photo` text DEFAULT NULL,
  `keywords` text DEFAULT NULL,
  `spec_params` text NOT NULL,
  `packs` text DEFAULT NULL,
  `default_pack_id` varchar(255) NOT NULL DEFAULT ' ',
  `hsn_code` varchar(10) NOT NULL,
  `gst_percent` decimal(5,2) NOT NULL,
  `offers` text DEFAULT NULL,
  `cache_txt` mediumtext DEFAULT NULL,
  `img_last_updated` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `stock` decimal(10,3) DEFAULT NULL,
  `stock_ut_id` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
-- --------------------------------------------------------

--
-- Table structure for table `user`
--

CREATE TABLE `user` (
  `userid` bigint(20) UNSIGNED NOT NULL,
  `email` varchar(250) NOT NULL DEFAULT ' ',
  `is_email_verified` tinyint(4) NOT NULL DEFAULT 0,
  `contactno` varchar(250) NOT NULL,
  `is_contact_verified` tinyint(4) NOT NULL DEFAULT 0,
  `name` text NOT NULL,
  `account_state` varchar(250) NOT NULL DEFAULT 'incomplete',
  `address` text NOT NULL,
  `latitude` float(10,6) NOT NULL DEFAULT 0.000000,
  `longitude` float(10,6) NOT NULL DEFAULT 0.000000,
  `dob` text DEFAULT NULL,
  `register_date` int(10) UNSIGNED NOT NULL DEFAULT 0,
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
  `last_activity` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `push_notif_id` text NOT NULL,
  `is_first_login` tinyint(4) UNSIGNED NOT NULL DEFAULT 1,
  `has_unread_comments` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `password` varchar(250) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
-- --------------------------------------------------------

--
-- Table structure for table `physical_stock`
--

CREATE TABLE `physical_stock` (
  `id` int(11) NOT NULL,
  `vendor_product_id` int(11) NOT NULL,
  `stock` double NOT NULL,
  `last_updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `note` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `product_photos`
--

CREATE TABLE `product_photos` (
  `product_id` bigint(20) UNSIGNED NOT NULL DEFAULT 0,
  `photo_id` bigint(20) UNSIGNED NOT NULL,
  `file_location` varchar(250) NOT NULL DEFAULT '0',
  `photo_slug` varchar(10) NOT NULL DEFAULT '0000'
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `otp`
--

CREATE TABLE `otp` (
  `contactno` varchar(30) NOT NULL,
  `slug` varchar(16) NOT NULL,
  `otp_time` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `purpose` varchar(250) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `vendor_products`
--

CREATE TABLE `vendor_products` (
  `id` int(11) NOT NULL,
  `admin_vendor_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `packs` text NOT NULL,
  `default_pack_id` varchar(255) NOT NULL,
  `status` enum('1','0') NOT NULL,
  `in_stock` enum('1','0') NOT NULL,
  `created_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `user_addresses`
--

CREATE TABLE `user_addresses` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `address` text NOT NULL,
  `contact_no` varchar(255) NOT NULL,
  `latitude` float(10,6) NOT NULL,
  `longitude` float(10,6) NOT NULL,
  `is_default` enum('0','1') NOT NULL,
  `created_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Table structure for table `vendor_products_inventory`
--

CREATE TABLE `vendor_products_inventory` (
  `id` int(11) NOT NULL,
  `vendor_product_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `action_type` varchar(255) NOT NULL,
  `pack_id` varchar(255) NOT NULL,
  `vendor_id` int(11) DEFAULT NULL,
  `quantity` double(10,2) NOT NULL,
  `unit_type` varchar(255) NOT NULL,
  `unitquantity` double(10,2) NOT NULL,
  `amount` double(10,2) NOT NULL,
  `wholesale_user_id` int(11) DEFAULT NULL,
  `inv_date` date NOT NULL,
  `inv_type` enum('CREDIT','DEBIT') NOT NULL,
  `note` text NOT NULL,
  `trip_id` int(11) DEFAULT NULL,
  `updated_at` datetime NOT NULL,
  `created_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

-- --------------------------------------------------------

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admin`
--
ALTER TABLE `admin`
  ADD PRIMARY KEY (`userid`);

--
-- Indexes for table `brand`
--
ALTER TABLE `brand`
  ADD PRIMARY KEY (`brand_id`);

--
-- Indexes for table `calling_staff`
--
ALTER TABLE `calling_staff`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_contactNumber` (`contact_no`);

--
-- Indexes for table `cart`
--
ALTER TABLE `cart`
  ADD PRIMARY KEY (`cart_id`),
  ADD UNIQUE KEY `unique_user_product_pack_address` (`userid`,`product_id`,`pack_id`,`addressId`);

--
-- Indexes for table `cart_type`
--
ALTER TABLE `cart_type`
  ADD PRIMARY KEY (`cart_tid`);

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`cat_id`);

--
-- Indexes for table `daily_book_stock`
--
ALTER TABLE `daily_book_stock`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_product_date` (`vendor_product_id`,`date`),
  ADD KEY `idx_product_date` (`vendor_product_id`,`date`);

--
-- Indexes for table `deli_staff`
--
ALTER TABLE `deli_staff`
  ADD PRIMARY KEY (`deli_id`),
  ADD UNIQUE KEY `mobile` (`mobile`);

--
-- Indexes for table `driver_accountability_log`
--
ALTER TABLE `driver_accountability_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_driver` (`driver_deli_id`),
  ADD KEY `idx_trip` (`trip_id`);

--
-- Indexes for table `driver_rating`
--
ALTER TABLE `driver_rating`
  ADD PRIMARY KEY (`order_id`),
  ADD UNIQUE KEY `rating_id` (`rating_id`);

--
-- Indexes for table `inventory_op`
--
ALTER TABLE `inventory_op`
  ADD PRIMARY KEY (`op_id`);

--
-- Indexes for table `master_orders`
--
ALTER TABLE `master_orders`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `offers`
--
ALTER TABLE `offers`
  ADD PRIMARY KEY (`off_id`);

--
-- Indexes for table `offer_log`
--
ALTER TABLE `offer_log`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `orders`
--
ALTER TABLE `orders`
  ADD PRIMARY KEY (`order_id`);

--
-- Indexes for table `orders_item`
--
ALTER TABLE `orders_item`
  ADD PRIMARY KEY (`item_id`);

--
-- Indexes for table `otp`
--
ALTER TABLE `otp`
  ADD PRIMARY KEY (`contactno`);

--
-- Indexes for table `physical_stock`
--
ALTER TABLE `physical_stock`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `product`
--
ALTER TABLE `product`
  ADD PRIMARY KEY (`product_id`);

--
-- Indexes for table `product_photos`
--
ALTER TABLE `product_photos`
  ADD PRIMARY KEY (`photo_id`);

--
-- Indexes for table `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`userid`);

--
-- Indexes for table `user_addresses`
--
ALTER TABLE `user_addresses`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `vendor_products`
--
ALTER TABLE `vendor_products`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `vendor_products_inventory`
--
ALTER TABLE `vendor_products_inventory`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admin`
--
ALTER TABLE `admin`
  MODIFY `userid` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `brand`
--
ALTER TABLE `brand`
  MODIFY `brand_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `calling_staff`
--
ALTER TABLE `calling_staff`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `cart`
--
ALTER TABLE `cart`
  MODIFY `cart_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `cart_type`
--
ALTER TABLE `cart_type`
  MODIFY `cart_tid` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `categories`
--
ALTER TABLE `categories`
  MODIFY `cat_id` bigint(5) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `daily_book_stock`
--
ALTER TABLE `daily_book_stock`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `deli_staff`
--
ALTER TABLE `deli_staff`
  MODIFY `deli_id` int(11) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `driver_accountability_log`
--
ALTER TABLE `driver_accountability_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `driver_rating`
--
ALTER TABLE `driver_rating`
  MODIFY `rating_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `inventory_op`
--
ALTER TABLE `inventory_op`
  MODIFY `op_id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `master_orders`
--
ALTER TABLE `master_orders`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `offers`
--
ALTER TABLE `offers`
  MODIFY `off_id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `offer_log`
--
ALTER TABLE `offer_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `orders`
--
ALTER TABLE `orders`
  MODIFY `order_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `orders_item`
--
ALTER TABLE `orders_item`
  MODIFY `item_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `physical_stock`
--
ALTER TABLE `physical_stock`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `product`
--
ALTER TABLE `product`
  MODIFY `product_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `product_photos`
--
ALTER TABLE `product_photos`
  MODIFY `photo_id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user`
--
ALTER TABLE `user`
  MODIFY `userid` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_addresses`
--
ALTER TABLE `user_addresses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `vendor_products`
--
ALTER TABLE `vendor_products`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `vendor_products_inventory`
--
ALTER TABLE `vendor_products_inventory`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;