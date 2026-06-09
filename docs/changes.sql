-- ============================================================
-- PMS Schema Changes
-- Run this script against the existing production database.
-- All CREATE statements use IF NOT EXISTS.
-- All ALTER statements use ADD COLUMN IF NOT EXISTS.
-- CRM-owned tables assumed to already exist: product, orders,
-- orders_item, admin, deli_staff, otp, user.
-- Tables created by this script: LoginUserRoles_crm, LoginUser_crm,
-- department_crm (plus all PMS-owned tables).
-- ============================================================


-- ============================================================
-- STEP 1: Add columns to legacy product table (must come first
--         because bom_items and supplier_products FK to product)
-- ============================================================

-- 2026-03-12: order/buffer limits for product
ALTER TABLE `product`
    ADD COLUMN IF NOT EXISTS `order_limit`  int unsigned NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `buffer_limit` int unsigned NOT NULL DEFAULT 0;


-- ============================================================
-- STEP 2: BOM (depends on product)
-- ============================================================

-- BOM: bill of materials — links finished products to their raw material components
CREATE TABLE IF NOT EXISTS `bom_master` (
    `bom_id`      BIGINT AUTO_INCREMENT PRIMARY KEY,
    `product_id`  BIGINT NOT NULL,
    `bom_version` VARCHAR(20) NOT NULL,
    `status`      ENUM('DRAFT','APPROVED','LOCKED') DEFAULT 'DRAFT',
    `remarks`     TEXT,
    `created_by`  BIGINT,
    `approved_by` BIGINT,
    `created_at`  DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `uk_product_version` (`product_id`, `bom_version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `bom_items` (
    `bom_item_id`       BIGINT AUTO_INCREMENT PRIMARY KEY,
    `bom_id`            BIGINT NOT NULL,
    `raw_material_id`   BIGINT NOT NULL,
    `quantity_per_unit` DECIMAL(10,3) NOT NULL,
    `unit_type`         VARCHAR(20) NOT NULL,
    `wastage_percent`   DECIMAL(5,2) DEFAULT 0.00,
    `created_at`        DATETIME DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_bom_items_bom`
        FOREIGN KEY (`bom_id`) REFERENCES `bom_master` (`bom_id`),
    CONSTRAINT `fk_bom_items_product`
        FOREIGN KEY (`raw_material_id`) REFERENCES `product` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
-- STEP 3: Suppliers and supplier products (no FK to PMS tables)
-- ============================================================

-- 2026-02-21: Supplier master
CREATE TABLE IF NOT EXISTS `suppliers` (
    `id`                         bigint unsigned NOT NULL AUTO_INCREMENT,
    `supplier_code`              varchar(50)  NOT NULL,
    `supplier_name`              varchar(255) NOT NULL,
    `short_name`                 varchar(255) DEFAULT NULL,
    `business_type`              varchar(100) DEFAULT NULL,
    `department`                 varchar(100) DEFAULT NULL,
    `gst_no`                     varchar(20)  DEFAULT NULL,
    `pan_no`                     varchar(20)  DEFAULT NULL,
    `tan_no`                     varchar(20)  DEFAULT NULL,
    `cin_no`                     varchar(30)  DEFAULT NULL,
    `vat_no`                     varchar(30)  DEFAULT NULL,
    `registration_no`            varchar(50)  DEFAULT NULL,
    `fssai_no`                   varchar(50)  DEFAULT NULL,
    `website`                    varchar(255) DEFAULT NULL,
    `email`                      varchar(255) DEFAULT NULL,
    `phone`                      varchar(30)  DEFAULT NULL,
    `alternate_phone`            varchar(30)  DEFAULT NULL,
    `contact_person`             varchar(255) DEFAULT NULL,
    `contact_person_email`       varchar(255) DEFAULT NULL,
    `contact_person_phone`       varchar(30)  DEFAULT NULL,
    `contact_person_designation` varchar(100) DEFAULT NULL,
    `address_line1`              varchar(255) DEFAULT NULL,
    `city`                       varchar(100) DEFAULT NULL,
    `state`                      varchar(100) DEFAULT NULL,
    `country`                    varchar(100) DEFAULT NULL,
    `pincode`                    varchar(20)  DEFAULT NULL,
    `bank_name`                  varchar(150) DEFAULT NULL,
    `bank_branch`                varchar(150) DEFAULT NULL,
    `bank_account_name`          varchar(150) DEFAULT NULL,
    `bank_account_number`        varchar(50)  DEFAULT NULL,
    `ifsc_code`                  varchar(20)  DEFAULT NULL,
    `swift_code`                 varchar(20)  DEFAULT NULL,
    `payment_terms_days`         smallint unsigned DEFAULT NULL,
    `credit_limit`               decimal(12,2) DEFAULT NULL,
    `rating`                     decimal(3,2)  DEFAULT NULL,
    `is_preferred`               tinyint(1) NOT NULL DEFAULT '0',
    `status`                     enum('ACTIVE','INACTIVE','SUSPENDED') NOT NULL DEFAULT 'ACTIVE',
    `notes`                      text,
    `metadata`                   json DEFAULT NULL,
    `created_by`                 bigint unsigned DEFAULT NULL,
    `updated_by`                 bigint unsigned DEFAULT NULL,
    `created_at`                 timestamp NULL DEFAULT NULL,
    `updated_at`                 timestamp NULL DEFAULT NULL,
    `deleted_at`                 timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `suppliers_supplier_code_unique` (`supplier_code`),
    KEY `suppliers_gst_no_index` (`gst_no`),
    KEY `suppliers_pan_no_index` (`pan_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2026-02-21 / 2026-03-01: Products offered by each supplier
-- unique(supplier_id, product_id) prevents same product twice per supplier
CREATE TABLE IF NOT EXISTS `supplier_products` (
    `id`                    bigint unsigned NOT NULL AUTO_INCREMENT,
    `supplier_id`           bigint unsigned NOT NULL,
    `product_id`            bigint unsigned NOT NULL,
    `supplier_sku`          varchar(100) DEFAULT NULL,
    `supplier_product_name` varchar(255) DEFAULT NULL,
    `description`           text,
    `pack_size`             decimal(10,3) DEFAULT NULL,
    `pack_unit`             varchar(20)  DEFAULT NULL,
    `min_order_qty`         decimal(12,3) DEFAULT NULL,
    `price`                 decimal(12,2) DEFAULT NULL,
    `currency`              varchar(3)   DEFAULT NULL,
    `tax_percent`           decimal(5,2)  DEFAULT NULL,
    `discount_percent`      decimal(5,2)  DEFAULT NULL,
    `lead_time_days`        smallint unsigned DEFAULT NULL,
    `last_purchase_price`   decimal(12,2) DEFAULT NULL,
    `last_purchase_date`    date DEFAULT NULL,
    `is_preferred`          tinyint(1) NOT NULL DEFAULT '0',
    `is_active`             tinyint(1) NOT NULL DEFAULT '1',
    `notes`                 text,
    `metadata`              json DEFAULT NULL,
    `created_at`            timestamp NULL DEFAULT NULL,
    `updated_at`            timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `supplier_products_supplier_id_supplier_sku_unique` (`supplier_id`, `supplier_sku`),
    UNIQUE KEY `supplier_products_supplier_id_product_id_unique` (`supplier_id`, `product_id`),
    CONSTRAINT `supplier_products_supplier_id_foreign`
        FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`) ON DELETE CASCADE,
    CONSTRAINT `supplier_products_product_id_foreign`
        FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
-- STEP 4: Purchase Orders (depends on suppliers)
-- ============================================================

-- 2026-02-27: Purchase order header
CREATE TABLE IF NOT EXISTS `purchase_orders` (
    `id`             bigint unsigned NOT NULL AUTO_INCREMENT,
    `po_number`      varchar(50)  NOT NULL,
    `financial_year` varchar(10)  NOT NULL,
    `supplier_id`    bigint unsigned NOT NULL,
    `doc_date`       date NOT NULL,
    `expected_date`  date DEFAULT NULL,
    `status`         enum('DRAFT','SENT','PARTIALLY_RECEIVED','CLOSED','CANCELLED') NOT NULL DEFAULT 'DRAFT',
    `narration`      text DEFAULT NULL,
    `created_by`     bigint unsigned DEFAULT NULL,
    `updated_by`     bigint unsigned DEFAULT NULL,
    `total_amount`   decimal(14,2) NOT NULL DEFAULT 0.00,
    `created_at`     timestamp NULL DEFAULT NULL,
    `updated_at`     timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `purchase_orders_po_number_unique` (`po_number`),
    KEY `purchase_orders_supplier_id_index` (`supplier_id`),
    KEY `purchase_orders_status_index` (`status`),
    KEY `purchase_orders_doc_date_index` (`doc_date`),
    CONSTRAINT `purchase_orders_supplier_id_foreign`
        FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2026-02-27: Purchase order line items
CREATE TABLE IF NOT EXISTS `purchase_order_items` (
    `id`                bigint unsigned NOT NULL AUTO_INCREMENT,
    `purchase_order_id` bigint unsigned NOT NULL,
    `product_id`        bigint unsigned NOT NULL,
    `line_no`           int unsigned NOT NULL,
    `unit`              varchar(20)   DEFAULT NULL,
    `quantity`          decimal(12,3) NOT NULL,
    `price`             decimal(12,2) NOT NULL,
    `discount_percent`  decimal(5,2)  DEFAULT NULL,
    `tax_percent`       decimal(5,2)  DEFAULT NULL,
    `line_total`        decimal(14,2) NOT NULL,
    `description`       text DEFAULT NULL,
    `created_at`        timestamp NULL DEFAULT NULL,
    `updated_at`        timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `purchase_order_items_po_product_index` (`purchase_order_id`, `product_id`),
    CONSTRAINT `purchase_order_items_po_foreign`
        FOREIGN KEY (`purchase_order_id`) REFERENCES `purchase_orders` (`id`) ON DELETE CASCADE,
    CONSTRAINT `purchase_order_items_product_foreign`
        FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
-- STEP 5: Taxes and HSN codes (no FK to PMS tables)
-- ============================================================

-- 2026-03-09: Tax master
CREATE TABLE IF NOT EXISTS `taxes` (
    `id`               bigint unsigned NOT NULL AUTO_INCREMENT,
    `tax_category`     varchar(100) NOT NULL,
    `tax_sub_category` varchar(100) NOT NULL,
    `tax_name`         varchar(150) NOT NULL,
    `is_active`        tinyint(1) NOT NULL DEFAULT 1,
    `created_at`       timestamp NULL DEFAULT NULL,
    `updated_at`       timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `taxes_category_sub_index` (`tax_category`, `tax_sub_category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2026-03-09: Product-to-tax mapping
CREATE TABLE IF NOT EXISTS `product_taxes` (
    `id`          bigint unsigned NOT NULL AUTO_INCREMENT,
    `product_id`  bigint unsigned NOT NULL,
    `tax_id`      bigint unsigned NOT NULL,
    `tax_percent` decimal(5,2) NOT NULL,
    `created_at`  timestamp NULL DEFAULT NULL,
    `updated_at`  timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `product_taxes_product_id_tax_id_unique` (`product_id`, `tax_id`),
    KEY `product_taxes_product_id_index` (`product_id`),
    KEY `product_taxes_tax_id_index` (`tax_id`),
    CONSTRAINT `product_taxes_product_id_foreign`
        FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE CASCADE,
    CONSTRAINT `product_taxes_tax_id_foreign`
        FOREIGN KEY (`tax_id`) REFERENCES `taxes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2026-03-12: HSN code master
CREATE TABLE IF NOT EXISTS `hsn_codes` (
    `id`         bigint unsigned NOT NULL AUTO_INCREMENT,
    `hsn_code`   varchar(50) NOT NULL,
    `is_active`  tinyint(1) NOT NULL DEFAULT 1,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ============================================================
-- STEP 6: Business types master (no FK dependencies)
-- ============================================================

-- 2026-03-24: Business type dropdown for supplier form
CREATE TABLE IF NOT EXISTS `business_types` (
    `id`          bigint unsigned NOT NULL AUTO_INCREMENT,
    `name`        varchar(100) NOT NULL,
    `description` text DEFAULT NULL,
    `is_active`   tinyint(1) NOT NULL DEFAULT 1,
    `created_at`  timestamp NULL DEFAULT NULL,
    `updated_at`  timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `business_types_name_unique` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- STEP 7: Stock Vouchers (depends on product)
-- ============================================================

-- 2025-02-13: Manual stock in/out vouchers
CREATE TABLE IF NOT EXISTS `stock_voucher` (
    `id`           bigint unsigned NOT NULL AUTO_INCREMENT,
    `voucher_type` enum('IN','OUT') NOT NULL DEFAULT 'IN',
    `status`       enum('DRAFT','POSTED') NOT NULL DEFAULT 'DRAFT',
    `voucher_date` date DEFAULT NULL,
    `remarks`      text DEFAULT NULL,
    `posted_at`    datetime DEFAULT NULL,
    `created_at`   timestamp NULL DEFAULT NULL,
    `updated_at`   timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `stock_voucher_items` (
    `id`         bigint unsigned NOT NULL AUTO_INCREMENT,
    `voucher_id` bigint unsigned NOT NULL,
    `product_id` bigint unsigned NOT NULL,
    `quantity`   decimal(10,3) NOT NULL,
    `unit_type`  varchar(20) NOT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `stock_voucher_items_voucher_id_foreign`
        FOREIGN KEY (`voucher_id`) REFERENCES `stock_voucher` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- STEP 8: CRM user/role tables
-- PMS reads these for salesman dropdowns (UserController,
-- PurchaseOrderController, SalesOrderController).
-- salesman_id on purchase_orders and orders references LoginUser_crm.id.
-- ============================================================

-- 2026-04-01: Department master (referenced by LoginUser_crm.departmentId)
CREATE TABLE IF NOT EXISTS `department_crm` (
    `id`        varchar(191) NOT NULL,
    `name`      varchar(191) NOT NULL,
    `createdAt` datetime(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    UNIQUE KEY `Department_name_key` (`name`),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2026-04-01: Role master
CREATE TABLE IF NOT EXISTS `LoginUserRoles_crm` (
    `id`        varchar(191) NOT NULL,
    `name`      varchar(191) NOT NULL,
    `createdAt` datetime(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2026-04-01: Employee/salesman master (depends on LoginUserRoles_crm, department_crm)
CREATE TABLE IF NOT EXISTS `LoginUser_crm` (
    `id`                        varchar(191) NOT NULL,
    `employeeCode`              varchar(191) DEFAULT NULL,
    `name`                      varchar(191) DEFAULT NULL,
    `email`                     varchar(191) DEFAULT NULL,
    `contactNumber`             varchar(191) NOT NULL,
    `alternativeNumber`         varchar(191) DEFAULT NULL,
    `roleId`                    varchar(191) DEFAULT NULL,
    `roles`                     json DEFAULT NULL,
    `departmentId`              varchar(191) DEFAULT NULL,
    `isActive`                  tinyint(1) NOT NULL DEFAULT 1,
    `createdAt`                 datetime(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt`                 datetime(3)  NOT NULL,
    `workStartTime`             varchar(191) DEFAULT '09:00:00',
    `workEndTime`               varchar(191) DEFAULT '18:00:00',
    `latePunchInGraceMinutes`   int DEFAULT 45,
    `earlyPunchOutGraceMinutes` int DEFAULT 30,
    PRIMARY KEY (`id`),
    CONSTRAINT `User_departmentId_fkey`
        FOREIGN KEY (`departmentId`) REFERENCES `department_crm` (`id`) ON DELETE SET NULL,
    CONSTRAINT `User_roleId_fkey`
        FOREIGN KEY (`roleId`) REFERENCES `LoginUserRoles_crm` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- STEP 9: Units master (no FK dependencies)
-- ============================================================

-- 2026-05-25: Dynamic unit dropdown — used by all modules
-- GET /api/unit-types reads this table (BomController::getUnitTypes)
CREATE TABLE IF NOT EXISTS `units_master` (
    `unit_id`         int NOT NULL AUTO_INCREMENT,
    `unit_name`       varchar(100) NOT NULL,
    `serial_no`       int DEFAULT NULL,
    `conversion_rate` decimal(10,4) NOT NULL,
    `created_at`      timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`unit_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

INSERT IGNORE INTO `units_master` (`unit_name`, `serial_no`, `conversion_rate`) VALUES
    ('KG',    1,  1.0000),
    ('GM',    2,  0.0010),
    ('LTR',   3,  1.0000),
    ('ML',    4,  0.0010),
    ('NOS',   5,  1.0000),
    ('PCS',   6,  1.0000),
    ('BOX',   7,  1.0000),
    ('PKT',   8,  1.0000),
    ('BAG',   9,  1.0000),
    ('DOZEN', 10, 12.0000),
    ('BUNCH', 11, 1.0000),
    ('MTR',   12, 1.0000),
    ('CM',    13, 0.0100),
    ('TIN',   14, 1.0000),
    ('JAR',   15, 1.0000),
    ('BTL',   16, 1.0000),
    ('POUCH', 17, 1.0000),
    ('STRIP', 18, 1.0000),
    ('ROLL',  19, 1.0000),
    ('SET',   20, 1.0000);


-- ============================================================
-- STEP 10: Purchase Vouchers (depends on suppliers, purchase_orders)
-- ============================================================

-- 2026-03-26: Purchase invoice / GRN header
CREATE TABLE IF NOT EXISTS `purchase_vouchers` (
    `id`                      bigint unsigned NOT NULL AUTO_INCREMENT,
    `doc_no_prefix`           varchar(20) NOT NULL DEFAULT '25-26/',
    `doc_no_number`           bigint unsigned NOT NULL,
    `doc_no`                  varchar(80) DEFAULT NULL,
    `supplier_id`             bigint unsigned NOT NULL,
    `purchase_order_id`       bigint unsigned DEFAULT NULL,
    `doc_date`                date NOT NULL,
    `bill_no`                 varchar(100) NOT NULL,
    `bill_date`               date DEFAULT NULL,
    `narration`               text DEFAULT NULL,
    `do_not_update_inventory` tinyint(1) NOT NULL DEFAULT 0,
    `purchase_type`           varchar(50) NOT NULL DEFAULT 'Regular',
    `gst_reverse_charge`      varchar(4)  NOT NULL DEFAULT 'N',
    `purchase_agent_id`       varchar(100) DEFAULT NULL,
    `status`                  enum('DRAFT','POSTED','CANCELLED') NOT NULL DEFAULT 'DRAFT',
    `items_total`             decimal(14,2) NOT NULL DEFAULT 0,
    `charges_total`           decimal(14,2) NOT NULL DEFAULT 0,
    `net_total`               decimal(14,2) NOT NULL DEFAULT 0,
    `charges_json`            json DEFAULT NULL,
    `created_by`              bigint unsigned DEFAULT NULL,
    `updated_by`              bigint unsigned DEFAULT NULL,
    `created_at`              timestamp NULL DEFAULT NULL,
    `updated_at`              timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `purchase_vouchers_doc_no_prefix_doc_no_number_unique` (`doc_no_prefix`, `doc_no_number`),
    KEY `purchase_vouchers_supplier_id_index` (`supplier_id`),
    KEY `purchase_vouchers_doc_date_index` (`doc_date`),
    KEY `purchase_vouchers_doc_no_index` (`doc_no`),
    KEY `purchase_vouchers_status_index` (`status`),
    CONSTRAINT `purchase_vouchers_supplier_id_foreign`
        FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`),
    CONSTRAINT `purchase_vouchers_purchase_order_id_foreign`
        FOREIGN KEY (`purchase_order_id`) REFERENCES `purchase_orders` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2026-03-26: Purchase invoice line items
CREATE TABLE IF NOT EXISTS `purchase_voucher_items` (
    `id`                            bigint unsigned NOT NULL AUTO_INCREMENT,
    `purchase_voucher_id`           bigint unsigned NOT NULL,
    `source_purchase_order_id`      bigint unsigned DEFAULT NULL,
    `source_purchase_order_item_id` bigint unsigned DEFAULT NULL,
    `source_po_number`              varchar(100) DEFAULT NULL,
    `product_id`                    bigint unsigned NOT NULL,
    `line_no`                       int unsigned NOT NULL DEFAULT 1,
    `product_name`                  varchar(255) DEFAULT NULL,
    `product_code`                  varchar(100) DEFAULT NULL,
    `hsn_code`                      varchar(50)  DEFAULT NULL,
    `alias`                         varchar(255) DEFAULT NULL,
    `unit`                          varchar(20)  DEFAULT NULL,
    `quantity`                      decimal(12,3) NOT NULL DEFAULT 0,
    `overrun_qty`                   decimal(12,3) NOT NULL DEFAULT 0,
    `writeoff_qty`                  decimal(12,3) NOT NULL DEFAULT 0,
    `is_overrun_approved`           tinyint(1) NOT NULL DEFAULT 0,
    `is_writeoff`                   tinyint(1) NOT NULL DEFAULT 0,
    `overrun_reason`                varchar(255) DEFAULT NULL,
    `writeoff_reason`               varchar(255) DEFAULT NULL,
    `overrun_approved_by`           bigint unsigned DEFAULT NULL,
    `overrun_approved_at`           timestamp NULL DEFAULT NULL,
    `unit_price`                    decimal(12,2) NOT NULL DEFAULT 0,
    `taxable_amount`                decimal(14,2) NOT NULL DEFAULT 0,
    `sgst`                          decimal(12,2) NOT NULL DEFAULT 0,
    `cgst`                          decimal(12,2) NOT NULL DEFAULT 0,
    `igst`                          decimal(12,2) NOT NULL DEFAULT 0,
    `cess`                          decimal(12,2) NOT NULL DEFAULT 0,
    `roff`                          decimal(12,2) NOT NULL DEFAULT 0,
    `value`                         decimal(14,2) NOT NULL DEFAULT 0,
    `purchase_account`              varchar(255) DEFAULT NULL,
    `gst_itc_eligibility`           varchar(255) DEFAULT NULL,
    `created_at`                    timestamp NULL DEFAULT NULL,
    `updated_at`                    timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `purchase_voucher_items_purchase_voucher_id_product_id_index` (`purchase_voucher_id`, `product_id`),
    KEY `purchase_voucher_items_source_purchase_order_id_index` (`source_purchase_order_id`),
    KEY `purchase_voucher_items_hsn_code_index` (`hsn_code`),
    CONSTRAINT `purchase_voucher_items_purchase_voucher_id_foreign`
        FOREIGN KEY (`purchase_voucher_id`) REFERENCES `purchase_vouchers` (`id`) ON DELETE CASCADE,
    CONSTRAINT `purchase_voucher_items_source_purchase_order_item_id_foreign`
        FOREIGN KEY (`source_purchase_order_item_id`) REFERENCES `purchase_order_items` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- STEP 11: Purchase Returns (depends on purchase_vouchers)
-- ============================================================

-- 2026-04-14: Purchase return / debit note header
CREATE TABLE IF NOT EXISTS `purchase_returns` (
    `id`                         bigint unsigned NOT NULL AUTO_INCREMENT,
    `doc_no_prefix`              varchar(20) NOT NULL DEFAULT '25-26/',
    `doc_no_number`              bigint unsigned NOT NULL,
    `doc_no`                     varchar(80) DEFAULT NULL,
    `source_purchase_voucher_id` bigint unsigned DEFAULT NULL,
    `supplier_id`                bigint unsigned NOT NULL,
    `doc_date`                   date NOT NULL,
    `reason`                     text DEFAULT NULL,
    `status`                     enum('DRAFT','POSTED','CANCELLED') NOT NULL DEFAULT 'DRAFT',
    `items_total`                decimal(14,2) NOT NULL DEFAULT 0,
    `charges_total`              decimal(14,2) NOT NULL DEFAULT 0,
    `net_total`                  decimal(14,2) NOT NULL DEFAULT 0,
    `charges_json`               json DEFAULT NULL,
    `created_by`                 bigint unsigned DEFAULT NULL,
    `updated_by`                 bigint unsigned DEFAULT NULL,
    `created_at`                 timestamp NULL DEFAULT NULL,
    `updated_at`                 timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `purchase_returns_supplier_id_doc_no_prefix_doc_no_number_unique`
        (`supplier_id`, `doc_no_prefix`, `doc_no_number`),
    KEY `purchase_returns_supplier_id_index` (`supplier_id`),
    KEY `purchase_returns_doc_date_index` (`doc_date`),
    KEY `purchase_returns_doc_no_index` (`doc_no`),
    KEY `purchase_returns_status_index` (`status`),
    CONSTRAINT `purchase_returns_supplier_id_foreign`
        FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`),
    CONSTRAINT `purchase_returns_source_purchase_voucher_id_foreign`
        FOREIGN KEY (`source_purchase_voucher_id`) REFERENCES `purchase_vouchers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2026-04-14: Purchase return line items
CREATE TABLE IF NOT EXISTS `purchase_return_items` (
    `id`                              bigint unsigned NOT NULL AUTO_INCREMENT,
    `purchase_return_id`              bigint unsigned NOT NULL,
    `source_purchase_voucher_item_id` bigint unsigned DEFAULT NULL,
    `product_id`                      bigint unsigned NOT NULL,
    `line_no`                         int unsigned NOT NULL DEFAULT 1,
    `product_name`                    varchar(255) DEFAULT NULL,
    `product_code`                    varchar(100) DEFAULT NULL,
    `alias`                           varchar(255) DEFAULT NULL,
    `unit`                            varchar(20)  DEFAULT NULL,
    `original_quantity`               decimal(12,3) NOT NULL DEFAULT 0,
    `returned_quantity`               decimal(12,3) NOT NULL DEFAULT 0,
    `unit_price`                      decimal(12,2) NOT NULL DEFAULT 0,
    `taxable_amount`                  decimal(14,2) NOT NULL DEFAULT 0,
    `sgst`                            decimal(12,2) NOT NULL DEFAULT 0,
    `cgst`                            decimal(12,2) NOT NULL DEFAULT 0,
    `igst`                            decimal(12,2) NOT NULL DEFAULT 0,
    `cess`                            decimal(12,2) NOT NULL DEFAULT 0,
    `roff`                            decimal(12,2) NOT NULL DEFAULT 0,
    `value`                           decimal(14,2) NOT NULL DEFAULT 0,
    `return_reason`                   varchar(255) DEFAULT NULL,
    `remarks`                         varchar(255) DEFAULT NULL,
    `created_at`                      timestamp NULL DEFAULT NULL,
    `updated_at`                      timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `purchase_return_items_purchase_return_id_foreign`
        FOREIGN KEY (`purchase_return_id`) REFERENCES `purchase_returns` (`id`) ON DELETE CASCADE,
    CONSTRAINT `purchase_return_items_source_purchase_voucher_item_id_foreign`
        FOREIGN KEY (`source_purchase_voucher_item_id`) REFERENCES `purchase_voucher_items` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- STEP 12: Stock audit log (no FK to PMS tables)
-- ============================================================

-- 2026-02-18: Tracks every stock mutation with pack-level detail
CREATE TABLE IF NOT EXISTS `stock_audit_log` (
    `id`                bigint unsigned NOT NULL AUTO_INCREMENT,
    `vendor_product_id` int NOT NULL,
    `trigger_pack_id`   varchar(255) NOT NULL,
    `pack_updates`      json NOT NULL,
    `reason`            varchar(500) NOT NULL,
    `user_id`           int DEFAULT NULL,
    `created_at`        timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `stock_audit_log_created_at_index` (`created_at`),
    KEY `stock_audit_log_vendor_product_id_created_at_index` (`vendor_product_id`, `created_at`),
    KEY `stock_audit_log_vendor_product_id_index` (`vendor_product_id`),
    KEY `stock_audit_log_trigger_pack_id_index` (`trigger_pack_id`),
    KEY `stock_audit_log_user_id_index` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- STEP 13: ALTER legacy tables (columns added by PMS)
-- ============================================================

-- 2026-04-01: purchase_orders — salesman and department
ALTER TABLE `purchase_orders`
    ADD COLUMN IF NOT EXISTS `salesman_id`   VARCHAR(191) NULL AFTER `supplier_id`,
    ADD COLUMN IF NOT EXISTS `department_id` VARCHAR(191) NULL AFTER `salesman_id`;

ALTER TABLE `purchase_orders`
    ADD CONSTRAINT `purchase_orders_department_id_foreign`
        FOREIGN KEY (`department_id`) REFERENCES `department_crm` (`id`) ON DELETE SET NULL;

-- 2026-05-25: purchase_orders — charges breakdown
ALTER TABLE `purchase_orders`
    ADD COLUMN IF NOT EXISTS `charges_total`      decimal(14,2) NOT NULL DEFAULT 0 AFTER `total_amount`,
    ADD COLUMN IF NOT EXISTS `charges_json`       json          DEFAULT NULL AFTER `charges_total`,
    ADD COLUMN IF NOT EXISTS `total_with_charges` decimal(14,2) NOT NULL DEFAULT 0 AFTER `charges_json`;

-- 2026-05-25: purchase_order_items — HSN, consumed/remaining/written-off tracking
ALTER TABLE `purchase_order_items`
    ADD COLUMN IF NOT EXISTS `hsn_code`             varchar(50)   DEFAULT NULL AFTER `unit`,
    ADD COLUMN IF NOT EXISTS `consumed_quantity`    decimal(12,3) NOT NULL DEFAULT 0 AFTER `quantity`,
    ADD COLUMN IF NOT EXISTS `written_off_quantity` decimal(12,3) NOT NULL DEFAULT 0 AFTER `consumed_quantity`,
    ADD COLUMN IF NOT EXISTS `remaining_quantity`   decimal(12,3) NOT NULL DEFAULT 0 AFTER `written_off_quantity`;

-- 2026-05-14: orders — billing columns
-- Sales invoice stored on orders row; bill fields populated when order_state = 'billed'
ALTER TABLE `orders`
    ADD COLUMN IF NOT EXISTS `bill_no`        varchar(100)  DEFAULT NULL AFTER `bill_number`,
    ADD COLUMN IF NOT EXISTS `Bill_Dt`        DATE          NULL AFTER `bill_no`,
    ADD COLUMN IF NOT EXISTS `Department`     VARCHAR(100)  NULL AFTER `Bill_Dt`,
    ADD COLUMN IF NOT EXISTS `Bill_Narration` TEXT          NULL AFTER `Department`,
    ADD COLUMN IF NOT EXISTS `Bill_Vehicle`   VARCHAR(100)  NULL AFTER `Bill_Narration`,
    ADD COLUMN IF NOT EXISTS `Bill_Statement` VARCHAR(100)  NULL AFTER `Bill_Vehicle`,
    ADD COLUMN IF NOT EXISTS `bill_roff`      DECIMAL(10,2) NOT NULL DEFAULT 0 AFTER `Bill_Statement`,
    ADD COLUMN IF NOT EXISTS `Doc_Year`       VARCHAR(20)   NULL AFTER `bill_roff`;

-- 2026-05-25: orders — salesman, weight, trip fields
ALTER TABLE `orders`
    ADD COLUMN IF NOT EXISTS `salesman_id`  varchar(191)  DEFAULT NULL AFTER `Doc_Year`,
    ADD COLUMN IF NOT EXISTS `order_wt`     decimal(10,3) DEFAULT '25.000',
    ADD COLUMN IF NOT EXISTS `trip_pending` tinyint(1)    NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `pending_date` date          DEFAULT NULL;

-- 2026-05-18: orders — sales return columns
-- Return stored on order row; voucher format SR/YY-YY/NNN
ALTER TABLE `orders`
    ADD COLUMN IF NOT EXISTS `Sales_Return_VoucherNo` VARCHAR(100) NULL AFTER `pending_date`,
    ADD COLUMN IF NOT EXISTS `Sales_Return_Dt`        DATE         NULL AFTER `Sales_Return_VoucherNo`,
    ADD COLUMN IF NOT EXISTS `Sales_Return_Reason`    TEXT         NULL AFTER `Sales_Return_Dt`;

-- orders_item: qty_loaded = invoice/dispatch qty; qty_returned = cumulative returned qty
-- available_to_return = qty_delivered - qty_returned
-- Note: qty_loaded and qty_returned already exist in legacy schema.
--       The ALTER below is a safety net for environments where they may be missing.
ALTER TABLE `orders_item`
    ADD COLUMN IF NOT EXISTS `qty_loaded`   int DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `qty_returned` int DEFAULT NULL;

-- 2026-06-05: orders — invoice sequence tracking, charges storage, PDF URL persistence
ALTER TABLE `orders`
    ADD COLUMN IF NOT EXISTS `invoice_number`  int unsigned DEFAULT NULL AFTER `bill_no`,
    ADD COLUMN IF NOT EXISTS `charges_json`    json         DEFAULT NULL AFTER `invoice_number`,
    ADD COLUMN IF NOT EXISTS `invoice_pdf_url` varchar(500) DEFAULT NULL AFTER `charges_json`;

-- 2026-05-25: admin — payment / licence / org compliance fields
ALTER TABLE `admin`
    ADD COLUMN IF NOT EXISTS `fssai_no`       varchar(255) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `gst_no`         varchar(255) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `licence_1`      varchar(255) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `licence_2`      varchar(255) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `bank_name`      varchar(255) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `bank_branch`    varchar(255) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `account_number` varchar(255) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `ifsc_code`      varchar(255) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `account_type`   varchar(100) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `scanner_qr`     varchar(255) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `phonepe_no`     varchar(255) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `gpay_no`        varchar(255) DEFAULT NULL;

-- 2026-05-25: deli_staff — location enrichment
ALTER TABLE `deli_staff`
    ADD COLUMN IF NOT EXISTS `pincode` varchar(20)  DEFAULT NULL AFTER `lng`,
    ADD COLUMN IF NOT EXISTS `city`    varchar(100) DEFAULT NULL AFTER `pincode`,
    ADD COLUMN IF NOT EXISTS `state`   varchar(100) DEFAULT NULL AFTER `city`;

-- 2026-05-25: otp — store OTP value directly
ALTER TABLE `otp`
    ADD COLUMN IF NOT EXISTS `otp_num` varchar(10) NOT NULL DEFAULT '' AFTER `slug`;

-- 2026-05-25: user — location enrichment
ALTER TABLE `user`
    ADD COLUMN IF NOT EXISTS `pincode` varchar(20)  DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `city`    varchar(100) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `state`   varchar(100) DEFAULT NULL;


-- ============================================================
-- FUTURE / PLANNED (not yet active)
-- ============================================================

-- issue_to_production / items: raw material issue to production floor
-- CREATE TABLE IF NOT EXISTS `issue_to_production` ( ... );
-- CREATE TABLE IF NOT EXISTS `issue_to_production_items` ( ... );

-- receive_from_production / items: finished goods receipt from production
-- CREATE TABLE IF NOT EXISTS `receive_from_production` ( ... );
-- CREATE TABLE IF NOT EXISTS `receive_from_production_items` ( ... );
