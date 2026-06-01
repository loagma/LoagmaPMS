CREATE TABLE bom_master (
    bom_id              BIGINT AUTO_INCREMENT PRIMARY KEY,

    product_id          BIGINT NOT NULL,
    bom_version         VARCHAR(20) NOT NULL,

    status              ENUM('DRAFT', 'APPROVED', 'LOCKED') DEFAULT 'DRAFT',

    remarks             TEXT,

    created_by          BIGINT,
    approved_by         BIGINT,

    created_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE KEY uk_product_version (product_id, bom_version)
);

CREATE TABLE bom_items (
    bom_item_id         BIGINT AUTO_INCREMENT PRIMARY KEY,

    bom_id              BIGINT NOT NULL,

    raw_material_id     BIGINT NOT NULL,

    quantity_per_unit   DECIMAL(10,3) NOT NULL,
    unit_type           VARCHAR(20) NOT NULL,

    wastage_percent     DECIMAL(5,2) DEFAULT 0.00,

    created_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_bom_items_bom
        FOREIGN KEY (bom_id) REFERENCES bom_master(bom_id),

    CONSTRAINT fk_bom_items_product
        FOREIGN KEY (raw_material_id) REFERENCES product(product_id)
);



-- list of BOM also add a field name of BOM so that we can easily identify the BOM when we have multiple BOM for a product
-- active inactive status for BOM so that we can easily identify the active BOM for a product and also we can keep the old BOM for reference
-- create a floating button for create a BOM and when we click on that button it will open a form where we can select the product and then we can add the raw materials and their quantity and unit type and wastage percent and then we can save the BOM and then we can see the list of BOM in the BOM list page and then we can edit or delete the BOM from there.
-- display of active BOM in the product details page so that we can easily see the BOM for a product when we are in the product details page and also we can see the list of raw materials required for that product and their quantity and unit type and wastage percent.
-- quantity per unit in finished product details page so that we can easily see the quantity of raw materials required for a finished product when we are in the finished product details page and also we can see the unit type and wastage percent for each raw material.
-- finished product department field in the bom page so that we can easily identify the department for which the BOM is created and also we can filter the BOM based on department in the BOM list page.
-- all stock and inventory related changes should be based on bom will done on vendor_product table so that we can easily identify the raw materials required for a finished product and also we can easily calculate the stock and inventory based on the BOM and also we can easily identify the raw materials required for a finished product when we are in the finished product details page.

-- 2026-02-21: Suppliers and Supplier Products
CREATE TABLE IF NOT EXISTS `suppliers` (
    `id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `supplier_code` varchar(50) NOT NULL,
    `supplier_name` varchar(255) NOT NULL,
    `short_name` varchar(255) DEFAULT NULL,
    `business_type` varchar(100) DEFAULT NULL,
    `department` varchar(100) DEFAULT NULL,
    -- `industry` varchar(150) DEFAULT NULL,
    `gst_no` varchar(20) DEFAULT NULL,
    `pan_no` varchar(20) DEFAULT NULL,
    `tan_no` varchar(20) DEFAULT NULL,
    `cin_no` varchar(30) DEFAULT NULL,
    `vat_no` varchar(30) DEFAULT NULL,
    `registration_no` varchar(50) DEFAULT NULL,
    `fssai_no` varchar(50) DEFAULT NULL,
    `website` varchar(255) DEFAULT NULL,
    `email` varchar(255) DEFAULT NULL,
    `phone` varchar(30) DEFAULT NULL,
    `alternate_phone` varchar(30) DEFAULT NULL,
    -- `fax` varchar(30) DEFAULT NULL,
    `contact_person` varchar(255) DEFAULT NULL,
    `contact_person_email` varchar(255) DEFAULT NULL,
    `contact_person_phone` varchar(30) DEFAULT NULL,
    `contact_person_designation` varchar(100) DEFAULT NULL,
    -- `billing_address_line1` varchar(255) DEFAULT NULL,
    -- `billing_address_line2` varchar(255) DEFAULT NULL,
    -- `billing_city` varchar(100) DEFAULT NULL,
    -- `billing_state` varchar(100) DEFAULT NULL,
    -- `billing_country` varchar(100) DEFAULT NULL,
    -- `billing_postal_code` varchar(20) DEFAULT NULL,
    `address_line1` varchar(255) DEFAULT NULL,
    -- `address_line2` varchar(255) DEFAULT NULL,
    `city` varchar(100) DEFAULT NULL,
    `state` varchar(100) DEFAULT NULL,
    `country` varchar(100) DEFAULT NULL,
    `pincode` varchar(20) DEFAULT NULL,
    `bank_name` varchar(150) DEFAULT NULL,
    `bank_branch` varchar(150) DEFAULT NULL,
    `bank_account_name` varchar(150) DEFAULT NULL,
    `bank_account_number` varchar(50) DEFAULT NULL,
    `ifsc_code` varchar(20) DEFAULT NULL,
    `swift_code` varchar(20) DEFAULT NULL,
    `payment_terms_days` smallint unsigned DEFAULT NULL,
    `credit_limit` decimal(12,2) DEFAULT NULL,
    `rating` decimal(3,2) DEFAULT NULL,
    `is_preferred` tinyint(1) NOT NULL DEFAULT '0',
    `status` enum('ACTIVE','INACTIVE','SUSPENDED') NOT NULL DEFAULT 'ACTIVE',
    `notes` text,
    `metadata` json DEFAULT NULL,
    `created_by` bigint unsigned DEFAULT NULL,
    `updated_by` bigint unsigned DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    `deleted_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `suppliers_supplier_code_unique` (`supplier_code`),
    KEY `suppliers_gst_no_index` (`gst_no`),
    KEY `suppliers_pan_no_index` (`pan_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `supplier_products` (
    `id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `supplier_id` bigint unsigned NOT NULL,
    `product_id` bigint unsigned NOT NULL,
    `supplier_sku` varchar(100) DEFAULT NULL,
    `supplier_product_name` varchar(255) DEFAULT NULL,
    `description` text,
    `pack_size` decimal(10,3) DEFAULT NULL,
    `pack_unit` varchar(20) DEFAULT NULL,
    `min_order_qty` decimal(12,3) DEFAULT NULL,
    `price` decimal(12,2) DEFAULT NULL,
    `currency` varchar(3) DEFAULT NULL,
    `tax_percent` decimal(5,2) DEFAULT NULL,
    `discount_percent` decimal(5,2) DEFAULT NULL,
    `lead_time_days` smallint unsigned DEFAULT NULL,
    `last_purchase_price` decimal(12,2) DEFAULT NULL,
    `last_purchase_date` date DEFAULT NULL,
    `is_preferred` tinyint(1) NOT NULL DEFAULT '0',
    `is_active` tinyint(1) NOT NULL DEFAULT '1',
    `notes` text,
    `metadata` json DEFAULT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `supplier_products_supplier_id_supplier_sku_unique` (`supplier_id`, `supplier_sku`),
    UNIQUE KEY `supplier_products_supplier_id_product_id_unique` (`supplier_id`, `product_id`),
    CONSTRAINT `supplier_products_supplier_id_foreign` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`) ON DELETE CASCADE,
    CONSTRAINT `supplier_products_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
-- 2026-03-01: One supplier can have multiple products; unique(supplier_id, product_id) prevents same product twice per supplier.

-- 2026-02-27: Purchase Orders (quotation-style PO header)
CREATE TABLE IF NOT EXISTS `purchase_orders` (
    `id` bigint unsigned NOT NULL AUTO_INCREMENT,

    `po_number` varchar(50) NOT NULL,
    `financial_year` varchar(10) NOT NULL,

    `supplier_id` bigint unsigned NOT NULL,
    `doc_date` date NOT NULL,
    `expected_date` date DEFAULT NULL,

    `status` enum('DRAFT','SENT','PARTIALLY_RECEIVED','CLOSED','CANCELLED') NOT NULL DEFAULT 'DRAFT',

    `narration` text DEFAULT NULL,

    `created_by` bigint unsigned DEFAULT NULL,
    `updated_by` bigint unsigned DEFAULT NULL,

    `total_amount` decimal(14,2) NOT NULL DEFAULT 0.00,

    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,

    PRIMARY KEY (`id`),
    UNIQUE KEY `purchase_orders_po_number_unique` (`po_number`),
    KEY `purchase_orders_supplier_id_index` (`supplier_id`),
    KEY `purchase_orders_status_index` (`status`),
    KEY `purchase_orders_doc_date_index` (`doc_date`),
    CONSTRAINT `purchase_orders_supplier_id_foreign`
        FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2026-02-27: Purchase Order line items
CREATE TABLE IF NOT EXISTS `purchase_order_items` (
    `id` bigint unsigned NOT NULL AUTO_INCREMENT,

    `purchase_order_id` bigint unsigned NOT NULL,
    `product_id` bigint unsigned NOT NULL,
    `line_no` int unsigned NOT NULL,

    `unit` varchar(20) DEFAULT NULL,
    `quantity` decimal(12,3) NOT NULL,
    `price` decimal(12,2) NOT NULL,
    `discount_percent` decimal(5,2) DEFAULT NULL,
    `tax_percent` decimal(5,2) DEFAULT NULL,
    `line_total` decimal(14,2) NOT NULL,

    `description` text DEFAULT NULL,

    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,

    PRIMARY KEY (`id`),
    KEY `purchase_order_items_po_product_index` (`purchase_order_id`,`product_id`),
    CONSTRAINT `purchase_order_items_po_foreign`
        FOREIGN KEY (`purchase_order_id`) REFERENCES `purchase_orders` (`id`) ON DELETE CASCADE,
    CONSTRAINT `purchase_order_items_product_foreign`
        FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;



-- 2026-03-09: Taxes master and product-tax assignments
CREATE TABLE IF NOT EXISTS `taxes` (
    `id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `tax_category` varchar(100) NOT NULL,
    `tax_sub_category` varchar(100) NOT NULL,
    `tax_name` varchar(150) NOT NULL,
    `is_active` tinyint(1) NOT NULL DEFAULT 1,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `taxes_category_sub_index` (`tax_category`, `tax_sub_category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `product_taxes` (
    `id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `product_id` bigint unsigned NOT NULL,
    `tax_id` bigint unsigned NOT NULL,
    `tax_percent` decimal(5,2) NOT NULL,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `product_taxes_product_id_tax_id_unique` (`product_id`, `tax_id`),
    KEY `product_taxes_product_id_index` (`product_id`),
    KEY `product_taxes_tax_id_index` (`tax_id`),
    CONSTRAINT `product_taxes_product_id_foreign`
        FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`) ON DELETE CASCADE,
    CONSTRAINT `product_taxes_tax_id_foreign`
        FOREIGN KEY (`tax_id`) REFERENCES `taxes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- 2026-03-28: Minimal product pack and GST metadata fields
ALTER TABLE `product`
    ADD COLUMN IF NOT EXISTS `product_pack_count` int unsigned NOT NULL DEFAULT '0' AFTER `buffer_limit`,
    ADD COLUMN IF NOT EXISTS `nop` int unsigned NOT NULL DEFAULT '0' AFTER `product_pack_count`,
    ADD COLUMN IF NOT EXISTS `pack_prd_wt` decimal(12,3) DEFAULT NULL AFTER `nop`,
    ADD COLUMN IF NOT EXISTS `gross_wt_of_pack` decimal(12,3) DEFAULT NULL AFTER `pack_prd_wt`,
    ADD COLUMN IF NOT EXISTS `gst_tax_type` varchar(50) DEFAULT NULL AFTER `gross_wt_of_pack`;


-- 2026-03-12: HSN codes master and per-product order/buffer limits
CREATE TABLE IF NOT EXISTS `hsn_codes` (
    `id` bigint unsigned NOT NULL AUTO_INCREMENT,
    `hsn_code` varchar(50) NOT NULL,
    `is_active` tinyint(1) NOT NULL DEFAULT 1,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `product`
    ADD COLUMN `order_limit` int unsigned NOT NULL DEFAULT 0,
    ADD COLUMN `buffer_limit` int unsigned NOT NULL DEFAULT 0;


-- 2026-03-24: Master dropdown tables for supplier form
CREATE TABLE IF NOT EXISTS `BusinessType` (
    `id` varchar(10) NOT NULL,
    `name` varchar(100) NOT NULL,
    `createdAt` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `Department` (
    `id` varchar(10) NOT NULL,
    `name` varchar(100) NOT NULL,
    `createdAt` timestamp(3) NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2026-04-01: Roles and Users
CREATE TABLE roles (
    id VARCHAR(191) PRIMARY KEY,
    name VARCHAR(191) NOT NULL UNIQUE,
    createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users (
    id VARCHAR(191) PRIMARY KEY,

    employeeCode VARCHAR(191) UNIQUE,
    name VARCHAR(191),
    email VARCHAR(191) UNIQUE,
    contactNumber VARCHAR(191) NOT NULL UNIQUE,
    alternativeNumber VARCHAR(191),

    roleId VARCHAR(191),
    roles JSON,

    departmentId VARCHAR(10),

    otp VARCHAR(191),
    otpExpiry DATETIME,
    lastLogin DATETIME,

    isActive BOOLEAN NOT NULL DEFAULT TRUE,

    createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    dateOfBirth DATETIME,
    gender VARCHAR(50),
    image TEXT,

    preferredLanguages JSON,

    address TEXT,
    city VARCHAR(191),
    state VARCHAR(191),
    pincode VARCHAR(20),
    country VARCHAR(191),
    district VARCHAR(191),
    area VARCHAR(191),

    latitude DOUBLE,
    longitude DOUBLE,

    aadharCard VARCHAR(191),
    panCard VARCHAR(191),
    password VARCHAR(255),
    notes TEXT,

    workStartTime VARCHAR(8) DEFAULT '09:00:00',
    workEndTime VARCHAR(8) DEFAULT '18:00:00',
    latePunchInGraceMinutes INT DEFAULT 45,
    earlyPunchOutGraceMinutes INT DEFAULT 30,

    FOREIGN KEY (departmentId) REFERENCES Department(id) ON DELETE SET NULL,
    FOREIGN KEY (roleId) REFERENCES roles(id) ON DELETE SET NULL
);

INSERT INTO roles (id, name) VALUES
('R001', 'Admin'),
('R002', 'Employee'),
('R003', 'Manager'),
('R004', 'Telecaller'),
('R005', 'Developer');

-- 2026-04-01: Purchase orders - salesman and department
ALTER TABLE purchase_orders
    ADD COLUMN IF NOT EXISTS salesman_id VARCHAR(191) NULL AFTER supplier_id,
    ADD COLUMN IF NOT EXISTS department_id VARCHAR(10) NULL AFTER salesman_id;

-- 2026-05-14: Bill/Invoice columns on orders table
-- Sales invoice is now managed via the orders table (no separate sales_invoices table).
-- When order_state = 'billed', these fields are populated.
ALTER TABLE `orders`
    ADD COLUMN IF NOT EXISTS `Bill_Dt`        DATE           NULL AFTER `bill_number`,
    ADD COLUMN IF NOT EXISTS `Department`     VARCHAR(100)   NULL AFTER `Bill_Dt`,
    ADD COLUMN IF NOT EXISTS `Bill_Narration` TEXT           NULL AFTER `Department`,
    ADD COLUMN IF NOT EXISTS `Bill_Vehicle`   VARCHAR(100)   NULL AFTER `Bill_Narration`,
    ADD COLUMN IF NOT EXISTS `Bill_Statement` VARCHAR(100)   NULL AFTER `Bill_Vehicle`,
    ADD COLUMN IF NOT EXISTS `bill_roff`      DECIMAL(10,2)  NOT NULL DEFAULT 0 AFTER `Bill_Statement`,
    ADD COLUMN IF NOT EXISTS `Doc_Year`       VARCHAR(20)    NULL AFTER `bill_roff`;


-- 2026-05-19: Sales Invoice module wired as separate screen.
-- Invoice number series: INV/25-26/NNN — generated by SalesOrderController::series()
-- which counts orders rows with non-null bill_number.
-- No new table: bill_number is already a column on the orders table; invoice creation is
-- a PUT /api/sales-orders/{id} with status=billed and bill fields populated.

-- 2026-05-18: Sales Return columns added to orders table (no separate return table).
-- Return is stored directly on the order row, same pattern as billing.
-- Voucher number format: SR/YY-YY/NNN (e.g. SR/25-26/001), generated by SalesReturnController.
ALTER TABLE `orders`
    ADD COLUMN IF NOT EXISTS `Sales_Return_VoucherNo` VARCHAR(100) NULL AFTER `pending_date`,
    ADD COLUMN IF NOT EXISTS `Sales_Return_Dt`        DATE         NULL AFTER `Sales_Return_VoucherNo`,
    ADD COLUMN IF NOT EXISTS `Sales_Return_Reason`    TEXT         NULL AFTER `Sales_Return_Dt`;

-- orders_item.qty_returned tracks cumulative returned qty per item.
-- Qty semantics (orders_item):
--   left_qty            = quantity - qty_delivered      (still undelivered)
--   available_to_return = qty_delivered - qty_returned  (still returnable)
-- qty_delivered is set per item when admin marks order BILLED via SalesOrderController::update().


-- 2026-05-25: New columns on existing tables (diff: loagma_database_schema.sql → loagma_new.sql)

-- admin: payment / licence / org compliance fields
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

-- deli_staff: OTP login + location enrichment
ALTER TABLE `deli_staff`
    ADD COLUMN IF NOT EXISTS `otp`             varchar(6)   DEFAULT NULL AFTER `role`,
    ADD COLUMN IF NOT EXISTS `otp_expires_at`  datetime     DEFAULT NULL AFTER `otp`,
    ADD COLUMN IF NOT EXISTS `pincode`         varchar(20)  DEFAULT NULL AFTER `lng`,
    ADD COLUMN IF NOT EXISTS `city`            varchar(100) DEFAULT NULL AFTER `pincode`,
    ADD COLUMN IF NOT EXISTS `state`           varchar(100) DEFAULT NULL AFTER `city`;

-- otp: store OTP value directly (otp_num column)
ALTER TABLE `otp`
    ADD COLUMN IF NOT EXISTS `otp_num` varchar(10) NOT NULL DEFAULT '' AFTER `slug`;

-- user: location enrichment
ALTER TABLE `user`
    ADD COLUMN IF NOT EXISTS `pincode` varchar(20)  DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `city`    varchar(100) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS `state`   varchar(100) DEFAULT NULL;

-- orders: salesman, weight, trip-pending, bill_no (short string alias)
ALTER TABLE `orders`
    ADD COLUMN IF NOT EXISTS `bill_no`       varchar(100) DEFAULT NULL AFTER `bill_number`,
    ADD COLUMN IF NOT EXISTS `salesman_id`   varchar(191) DEFAULT NULL AFTER `Doc_Year`,
    ADD COLUMN IF NOT EXISTS `order_wt`      decimal(10,3) DEFAULT '25.000',
    ADD COLUMN IF NOT EXISTS `trip_pending`  tinyint(1) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS `pending_date`  date DEFAULT NULL;

-- purchase_orders: charges breakdown
ALTER TABLE `purchase_orders`
    ADD COLUMN IF NOT EXISTS `charges_total`       decimal(14,2) NOT NULL DEFAULT 0 AFTER `total_amount`,
    ADD COLUMN IF NOT EXISTS `charges_json`        json          DEFAULT NULL AFTER `charges_total`,
    ADD COLUMN IF NOT EXISTS `total_with_charges`  decimal(14,2) NOT NULL DEFAULT 0 AFTER `charges_json`;

-- purchase_order_items: HSN, consumed/remaining/written-off tracking
ALTER TABLE `purchase_order_items`
    ADD COLUMN IF NOT EXISTS `hsn_code`            varchar(50)   DEFAULT NULL AFTER `unit`,
    ADD COLUMN IF NOT EXISTS `consumed_quantity`   decimal(12,3) NOT NULL DEFAULT 0 AFTER `quantity`,
    ADD COLUMN IF NOT EXISTS `written_off_quantity` decimal(12,3) NOT NULL DEFAULT 0 AFTER `consumed_quantity`,
    ADD COLUMN IF NOT EXISTS `remaining_quantity`  decimal(12,3) NOT NULL DEFAULT 0 AFTER `written_off_quantity`;


-- 2026-05-25: New tables (present in loagma_new.sql, absent from loagma_database_schema.sql)

-- units_master: dynamic unit dropdown — replaces all static unit lists across the app
CREATE TABLE IF NOT EXISTS `units_master` (
    `unit_id`         int NOT NULL AUTO_INCREMENT,
    `unit_name`       varchar(100) NOT NULL,
    `serial_no`       int DEFAULT NULL,
    `conversion_rate` decimal(10,4) NOT NULL,
    `created_at`      timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`unit_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
-- All unit dropdowns (purchase order, purchase invoice, sales order, sales invoice, BOM, stock voucher, etc.)
-- fetch from GET /api/unit-types which reads this table (BomController::getUnitTypes).
-- serial_no controls display order; conversion_rate is relative to base unit (KG=1, GM=0.001, etc.).

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

-- general_account: chart of accounts
CREATE TABLE IF NOT EXISTS `general_account` (
    `id`           bigint unsigned NOT NULL AUTO_INCREMENT,
    `account_no`   varchar(100) NOT NULL,
    `account_name` varchar(255) NOT NULL,
    `account_type` varchar(100) NOT NULL,
    `created_at`   timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- fa_cash_main / fa_cash_line: cash receipt vouchers
CREATE TABLE IF NOT EXISTS `fa_cash_main` (
    `id`                  bigint unsigned NOT NULL AUTO_INCREMENT,
    `doc_no`              int unsigned NOT NULL,
    `doc_date`            date NOT NULL,
    `receipt_mode`        varchar(100) DEFAULT NULL,
    `book_account_id`     bigint unsigned DEFAULT NULL,
    `book_account_name`   varchar(255) DEFAULT NULL,
    `status`              varchar(50) NOT NULL DEFAULT 'draft',
    `created_at`          timestamp NULL DEFAULT NULL,
    `updated_at`          timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `fa_cash_main_doc_no_unique` (`doc_no`),
    CONSTRAINT `fa_cash_main_book_account_id_foreign`
        FOREIGN KEY (`book_account_id`) REFERENCES `general_account` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `fa_cash_line` (
    `id`              bigint unsigned NOT NULL AUTO_INCREMENT,
    `cash_receipt_id` bigint unsigned NOT NULL,
    `account_id`      bigint unsigned DEFAULT NULL,
    `account_code`    varchar(100) DEFAULT NULL,
    `account_name`    varchar(255) DEFAULT NULL,
    `account_type`    varchar(50) DEFAULT NULL,
    `amount`          decimal(15,2) NOT NULL DEFAULT 0,
    `bill_no`         varchar(100) DEFAULT NULL,
    `narration`       text DEFAULT NULL,
    `created_at`      timestamp NULL DEFAULT NULL,
    `updated_at`      timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fa_cash_line_cash_receipt_id_foreign`
        FOREIGN KEY (`cash_receipt_id`) REFERENCES `fa_cash_main` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- fa_main_line: unified journal/ledger line for all voucher types
CREATE TABLE IF NOT EXISTS `fa_main_line` (
    `id`            bigint unsigned NOT NULL AUTO_INCREMENT,
    `voucher_type`  varchar(50) NOT NULL,
    `voucher_id`    bigint unsigned NOT NULL,
    `voucher_no`    int unsigned NOT NULL,
    `voucher_date`  date NOT NULL,
    `account_id`    bigint unsigned DEFAULT NULL,
    `account_code`  varchar(100) DEFAULT NULL,
    `account_name`  varchar(255) DEFAULT NULL,
    `account_type`  varchar(50) DEFAULT NULL,
    `dr_cr`         char(1) NOT NULL DEFAULT 'D',
    `amount`        decimal(15,2) NOT NULL DEFAULT 0,
    `bill_no`       varchar(100) DEFAULT NULL,
    `narration`     text DEFAULT NULL,
    `status`        varchar(50) NOT NULL DEFAULT 'draft',
    `created_at`    timestamp NULL DEFAULT NULL,
    `updated_at`    timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_fml_voucher` (`voucher_type`, `voucher_id`),
    KEY `idx_fml_account_date` (`account_id`, `voucher_date`),
    KEY `idx_fml_date` (`voucher_date`),
    KEY `idx_fml_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- purchase_vouchers (purchase invoice): GRN/invoice against a PO or freestanding
CREATE TABLE IF NOT EXISTS `purchase_vouchers` (
    `id`                   bigint unsigned NOT NULL AUTO_INCREMENT,
    `doc_no_prefix`        varchar(20) NOT NULL DEFAULT '25-26/',
    `doc_no_number`        bigint unsigned NOT NULL,
    `doc_no`               varchar(80) DEFAULT NULL,
    `vendor_id`            bigint unsigned NOT NULL,
    `purchase_order_id`    bigint unsigned DEFAULT NULL,
    `doc_date`             date NOT NULL,
    `bill_no`              varchar(100) NOT NULL,
    `bill_date`            date DEFAULT NULL,
    `narration`            text DEFAULT NULL,
    `do_not_update_inventory` tinyint(1) NOT NULL DEFAULT 0,
    `purchase_type`        varchar(50) NOT NULL DEFAULT 'Regular',
    `gst_reverse_charge`   varchar(4) NOT NULL DEFAULT 'N',
    `purchase_agent_id`    varchar(100) DEFAULT NULL,
    `status`               enum('DRAFT','POSTED','CANCELLED') NOT NULL DEFAULT 'DRAFT',
    `items_total`          decimal(14,2) NOT NULL DEFAULT 0,
    `charges_total`        decimal(14,2) NOT NULL DEFAULT 0,
    `net_total`            decimal(14,2) NOT NULL DEFAULT 0,
    `charges_json`         json DEFAULT NULL,
    `created_by`           bigint unsigned DEFAULT NULL,
    `updated_by`           bigint unsigned DEFAULT NULL,
    `created_at`           timestamp NULL DEFAULT NULL,
    `updated_at`           timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `purchase_vouchers_doc_no_prefix_doc_no_number_unique` (`doc_no_prefix`, `doc_no_number`),
    KEY `purchase_vouchers_vendor_id_index` (`vendor_id`),
    KEY `purchase_vouchers_doc_date_index` (`doc_date`),
    KEY `purchase_vouchers_doc_no_index` (`doc_no`),
    KEY `purchase_vouchers_status_index` (`status`),
    CONSTRAINT `purchase_vouchers_vendor_id_foreign`
        FOREIGN KEY (`vendor_id`) REFERENCES `suppliers` (`id`),
    CONSTRAINT `purchase_vouchers_purchase_order_id_foreign`
        FOREIGN KEY (`purchase_order_id`) REFERENCES `purchase_orders` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- purchase_voucher_items: line items for purchase invoice
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
    `hsn_code`                      varchar(50) DEFAULT NULL,
    `alias`                         varchar(255) DEFAULT NULL,
    `unit`                          varchar(20) DEFAULT NULL,
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

-- purchase_returns: debit note / purchase return header
CREATE TABLE IF NOT EXISTS `purchase_returns` (
    `id`                        bigint unsigned NOT NULL AUTO_INCREMENT,
    `doc_no_prefix`             varchar(20) NOT NULL DEFAULT '25-26/',
    `doc_no_number`             bigint unsigned NOT NULL,
    `doc_no`                    varchar(80) DEFAULT NULL,
    `source_purchase_voucher_id` bigint unsigned DEFAULT NULL,
    `vendor_id`                 bigint unsigned NOT NULL,
    `doc_date`                  date NOT NULL,
    `reason`                    text DEFAULT NULL,
    `status`                    enum('DRAFT','POSTED','CANCELLED') NOT NULL DEFAULT 'DRAFT',
    `items_total`               decimal(14,2) NOT NULL DEFAULT 0,
    `charges_total`             decimal(14,2) NOT NULL DEFAULT 0,
    `net_total`                 decimal(14,2) NOT NULL DEFAULT 0,
    `charges_json`              json DEFAULT NULL,
    `created_by`                bigint unsigned DEFAULT NULL,
    `updated_by`                bigint unsigned DEFAULT NULL,
    `created_at`                timestamp NULL DEFAULT NULL,
    `updated_at`                timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `purchase_returns_vendor_id_doc_no_prefix_doc_no_number_unique`
        (`vendor_id`, `doc_no_prefix`, `doc_no_number`),
    KEY `purchase_returns_vendor_id_index` (`vendor_id`),
    KEY `purchase_returns_doc_date_index` (`doc_date`),
    KEY `purchase_returns_doc_no_index` (`doc_no`),
    KEY `purchase_returns_status_index` (`status`),
    CONSTRAINT `purchase_returns_vendor_id_foreign`
        FOREIGN KEY (`vendor_id`) REFERENCES `suppliers` (`id`),
    CONSTRAINT `purchase_returns_source_purchase_voucher_id_foreign`
        FOREIGN KEY (`source_purchase_voucher_id`) REFERENCES `purchase_vouchers` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- purchase_return_items: line items for purchase return
CREATE TABLE IF NOT EXISTS `purchase_return_items` (
    `id`                              bigint unsigned NOT NULL AUTO_INCREMENT,
    `purchase_return_id`              bigint unsigned NOT NULL,
    `source_purchase_voucher_item_id` bigint unsigned DEFAULT NULL,
    `product_id`                      bigint unsigned NOT NULL,
    `line_no`                         int unsigned NOT NULL DEFAULT 1,
    `product_name`                    varchar(255) DEFAULT NULL,
    `product_code`                    varchar(100) DEFAULT NULL,
    `alias`                           varchar(255) DEFAULT NULL,
    `unit`                            varchar(20) DEFAULT NULL,
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

-- sales_invoices: standalone sales invoice (separate from orders-based billing)
CREATE TABLE IF NOT EXISTS `sales_invoices` (
    `id`                      bigint unsigned NOT NULL AUTO_INCREMENT,
    `doc_no_prefix`           varchar(20) NOT NULL DEFAULT '25-26/',
    `doc_no_number`           bigint unsigned NOT NULL DEFAULT 1,
    `doc_no`                  varchar(80) NOT NULL,
    `customer_id`             bigint unsigned DEFAULT NULL,
    `customer_name`           varchar(255) DEFAULT NULL,
    `doc_date`                date NOT NULL,
    `bill_no`                 varchar(100) DEFAULT NULL,
    `bill_date`               date DEFAULT NULL,
    `narration`               text DEFAULT NULL,
    `do_not_update_inventory` tinyint(1) NOT NULL DEFAULT 0,
    `sale_type`               varchar(50) DEFAULT NULL,
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
    UNIQUE KEY `sales_invoices_doc_no_unique` (`doc_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- sales_invoice_items: line items for sales invoice
CREATE TABLE IF NOT EXISTS `sales_invoice_items` (
    `id`                         bigint unsigned NOT NULL AUTO_INCREMENT,
    `sales_invoice_id`           bigint unsigned NOT NULL,
    `source_sales_order_id`      bigint unsigned DEFAULT NULL,
    `source_sales_order_item_id` bigint unsigned DEFAULT NULL,
    `source_so_number`           varchar(100) DEFAULT NULL,
    `product_id`                 bigint unsigned DEFAULT NULL,
    `product_name`               varchar(255) DEFAULT NULL,
    `product_code`               varchar(100) DEFAULT NULL,
    `alias`                      varchar(255) DEFAULT NULL,
    `unit`                       varchar(20) DEFAULT NULL,
    `pack_id`                    varchar(100) DEFAULT NULL,
    `pack_label`                 varchar(255) DEFAULT NULL,
    `line_no`                    int unsigned NOT NULL DEFAULT 1,
    `quantity`                   decimal(12,3) NOT NULL DEFAULT 0,
    `ordered_qty`                decimal(12,3) DEFAULT NULL,
    `used_qty`                   decimal(12,3) DEFAULT NULL,
    `left_qty`                   decimal(12,3) DEFAULT NULL,
    `overrun_qty`                decimal(12,3) NOT NULL DEFAULT 0,
    `writeoff_qty`               decimal(12,3) NOT NULL DEFAULT 0,
    `is_overrun_approved`        tinyint(1) NOT NULL DEFAULT 0,
    `is_writeoff`                tinyint(1) NOT NULL DEFAULT 0,
    `overrun_reason`             varchar(255) DEFAULT NULL,
    `writeoff_reason`            varchar(255) DEFAULT NULL,
    `unit_price`                 decimal(12,2) NOT NULL DEFAULT 0,
    `taxable_amount`             decimal(14,2) NOT NULL DEFAULT 0,
    `sgst`                       decimal(12,2) NOT NULL DEFAULT 0,
    `cgst`                       decimal(12,2) NOT NULL DEFAULT 0,
    `igst`                       decimal(12,2) NOT NULL DEFAULT 0,
    `cess`                       decimal(12,2) NOT NULL DEFAULT 0,
    `roff`                       decimal(12,2) NOT NULL DEFAULT 0,
    `value`                      decimal(14,2) NOT NULL DEFAULT 0,
    `sale_account_id`            varchar(255) DEFAULT NULL,
    `gst_applicability`          varchar(255) DEFAULT NULL,
    `hsn_code`                   varchar(50) DEFAULT NULL,
    `created_at`                 timestamp NULL DEFAULT NULL,
    `updated_at`                 timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `sales_invoice_items_sales_invoice_id_foreign`
        FOREIGN KEY (`sales_invoice_id`) REFERENCES `sales_invoices` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- stock_voucher / stock_voucher_items: manual stock adjustment
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

-- issue_to_production / items: raw material issue to production floor
CREATE TABLE IF NOT EXISTS `issue_to_production` (
    `issue_id`   bigint unsigned NOT NULL AUTO_INCREMENT,
    `status`     enum('DRAFT','ISSUED','COMPLETED','CANCELLED') DEFAULT 'DRAFT',
    `remarks`    text DEFAULT NULL,
    `issued_by`  bigint DEFAULT NULL,
    `issued_at`  datetime DEFAULT NULL,
    `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
    `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`issue_id`),
    KEY `idx_issue_status` (`status`),
    KEY `idx_issue_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS `issue_to_production_items` (
    `issue_item_id`   bigint unsigned NOT NULL AUTO_INCREMENT,
    `issue_id`        bigint unsigned NOT NULL,
    `raw_material_id` bigint unsigned NOT NULL,
    `quantity`        decimal(10,3) NOT NULL,
    `unit_type`       varchar(20) NOT NULL,
    `created_at`      datetime DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`issue_item_id`),
    CONSTRAINT `fk_issue_items_issue`
        FOREIGN KEY (`issue_id`) REFERENCES `issue_to_production` (`issue_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- receive_from_production / items: finished goods receipt from production
CREATE TABLE IF NOT EXISTS `receive_from_production` (
    `id`          bigint unsigned NOT NULL AUTO_INCREMENT,
    `status`      enum('DRAFT','RECEIVED') NOT NULL DEFAULT 'DRAFT',
    `remarks`     text DEFAULT NULL,
    `received_at` datetime DEFAULT NULL,
    `created_at`  timestamp NULL DEFAULT NULL,
    `updated_at`  timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `receive_from_production_items` (
    `id`                  bigint unsigned NOT NULL AUTO_INCREMENT,
    `receive_id`          bigint unsigned NOT NULL,
    `finished_product_id` bigint unsigned NOT NULL,
    `quantity`            decimal(10,3) NOT NULL,
    `unit_type`           varchar(20) NOT NULL,
    `created_at`          timestamp NULL DEFAULT NULL,
    `updated_at`          timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `receive_from_production_items_receive_id_foreign`
        FOREIGN KEY (`receive_id`) REFERENCES `receive_from_production` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- pincode_masters: canonical pincode → city/state/district lookup
CREATE TABLE IF NOT EXISTS `pincode_masters` (
    `id`         bigint unsigned NOT NULL AUTO_INCREMENT,
    `pincode`    varchar(20) NOT NULL,
    `city`       varchar(100) NOT NULL,
    `state`      varchar(100) NOT NULL,
    `country`    varchar(100) NOT NULL DEFAULT 'India',
    `district`   varchar(100) DEFAULT NULL,
    `region`     varchar(100) DEFAULT NULL,
    `is_active`  tinyint(1) NOT NULL DEFAULT 1,
    `created_at` timestamp NULL DEFAULT NULL,
    `updated_at` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `pincode_masters_pincode_unique` (`pincode`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- product_sales_daily: daily sales aggregation per product
CREATE TABLE IF NOT EXISTS `product_sales_daily` (
    `sale_date`      date NOT NULL,
    `product_id`     bigint unsigned NOT NULL,
    `total_orders`   int unsigned NOT NULL DEFAULT 0,
    `total_quantity` decimal(14,2) NOT NULL DEFAULT 0,
    `created_at`     timestamp NULL DEFAULT NULL,
    `updated_at`     timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`sale_date`, `product_id`),
    KEY `idx_product_sales_daily_product_id` (`product_id`),
    KEY `idx_product_sales_daily_sale_date` (`sale_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- business_types: master list for supplier/customer business type dropdown
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

-- departments: PMS-side department master (distinct from department_crm for CRM side)
CREATE TABLE IF NOT EXISTS `departments` (
    `id`          bigint unsigned NOT NULL AUTO_INCREMENT,
    `name`        varchar(100) NOT NULL,
    `description` text DEFAULT NULL,
    `is_active`   tinyint(1) NOT NULL DEFAULT 1,
    `created_at`  timestamp NULL DEFAULT NULL,
    `updated_at`  timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `departments_name_unique` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- 2026-06-01: Trip / vehicle module tables
-- vehicles: vehicle master
CREATE TABLE IF NOT EXISTS `vehicles` (
    `vehicle_id`     int NOT NULL AUTO_INCREMENT,
    `vehicle_number` varchar(50) NOT NULL,
    `capacity_kg`    decimal(10,2) NOT NULL,
    `is_active`      tinyint(1) DEFAULT 1,
    `created_at`     datetime DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`vehicle_id`),
    UNIQUE KEY `vehicle_number` (`vehicle_number`),
    KEY `idx_vehicle_capacity` (`capacity_kg`, `is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- trip_cards: zone/card master for delivery trips
CREATE TABLE IF NOT EXISTS `trip_cards` (
    `zone_id`    int NOT NULL AUTO_INCREMENT,
    `zone_name`  varchar(100) NOT NULL,
    `vehicle_id` int DEFAULT NULL,
    `status`     varchar(20) DEFAULT 'IDLE',
    `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`zone_id`),
    UNIQUE KEY `zone_name` (`zone_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- trip_card_pincode: pincodes served by each trip zone
CREATE TABLE IF NOT EXISTS `trip_card_pincode` (
    `id`         int NOT NULL AUTO_INCREMENT,
    `zone_id`    int NOT NULL,
    `pincode`    varchar(10) NOT NULL,
    `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `zone_id` (`zone_id`),
    CONSTRAINT `trip_card_pincode_ibfk_1`
        FOREIGN KEY (`zone_id`) REFERENCES `trip_cards` (`zone_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- zone_vehicles: vehicle-to-zone assignments
CREATE TABLE IF NOT EXISTS `zone_vehicles` (
    `id`          int NOT NULL AUTO_INCREMENT,
    `zone_id`     int NOT NULL,
    `vehicle_id`  int NOT NULL,
    `assigned_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `is_active`   tinyint(1) DEFAULT 1,
    PRIMARY KEY (`id`),
    KEY `zone_id` (`zone_id`),
    KEY `vehicle_id` (`vehicle_id`),
    KEY `is_active` (`is_active`),
    CONSTRAINT `zone_vehicles_ibfk_1`
        FOREIGN KEY (`zone_id`) REFERENCES `trip_cards` (`zone_id`) ON DELETE CASCADE,
    CONSTRAINT `zone_vehicles_ibfk_2`
        FOREIGN KEY (`vehicle_id`) REFERENCES `vehicles` (`vehicle_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- trip_audit_log: driver trip accountability and discrepancy tracking
CREATE TABLE IF NOT EXISTS `trip_audit_log` (
    `id`                      int NOT NULL AUTO_INCREMENT,
    `trip_id`                 int NOT NULL,
    `order_id`                int NOT NULL,
    `item_id`                 int NOT NULL,
    `vendor_product_id`       int NOT NULL,
    `product_id`              int NOT NULL,
    `qty_loaded`              int NOT NULL,
    `qty_claimed_delivered`   int NOT NULL,
    `qty_claimed_returned`    int NOT NULL,
    `qty_verified_delivered`  int NOT NULL,
    `qty_verified_returned`   int NOT NULL,
    `discrepancy_delivered`   int GENERATED ALWAYS AS (`qty_verified_delivered` - `qty_claimed_delivered`) STORED,
    `discrepancy_returned`    int GENERATED ALWAYS AS (`qty_verified_returned` - `qty_claimed_returned`) STORED,
    `auditor_deli_id`         int NOT NULL,
    `audited_at`              datetime NOT NULL,
    `investigation_status`    enum('pending','resolved') DEFAULT 'pending',
    `investigator_deli_id`    int DEFAULT NULL,
    `investigated_at`         datetime DEFAULT NULL,
    `resolution_outcome`      enum('stock_loss','stock_recovered') DEFAULT NULL,
    `resolution_notes`        text DEFAULT NULL,
    `qty_recovered_returned`  int DEFAULT NULL,
    `driver_liable`           tinyint(1) DEFAULT 0,
    `liability_amount`        decimal(10,2) DEFAULT 0.00,
    `created_at`              datetime DEFAULT CURRENT_TIMESTAMP,
    `updated_at`              datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- order_zone_overrides: override the delivery zone assigned to an order
CREATE TABLE IF NOT EXISTS `order_zone_overrides` (
    `order_id`       bigint NOT NULL,
    `zone_id`        int NOT NULL,
    `source_zone_id` int DEFAULT NULL,
    `created_at`     datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`     datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;


-- 2026-06-01: Stock management supporting tables

-- stock_audit_log: tracks every stock mutation with pack-level detail
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

-- stock_notify: users subscribed to back-in-stock alerts (vendor_product_id)
CREATE TABLE IF NOT EXISTS `stock_notify` (
    `userid`     bigint unsigned NOT NULL,
    `product_id` bigint unsigned NOT NULL,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `userid` (`userid`, `product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

-- stock_count_master_session: supervisor-level stock count session
CREATE TABLE IF NOT EXISTS `stock_count_master_session` (
    `id`                    int NOT NULL AUTO_INCREMENT,
    `supervisor_id`         int NOT NULL,
    `status`                enum('planning','in_progress','completed','cancelled') DEFAULT 'planning',
    `total_categories`      int DEFAULT 0,
    `completed_categories`  int DEFAULT 0,
    `created_at`            timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `completed_at`          timestamp NULL DEFAULT NULL,
    `notes`                 text DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

-- stock_count_assignments: per-category counting tasks within a session
CREATE TABLE IF NOT EXISTS `stock_count_assignments` (
    `id`                int NOT NULL AUTO_INCREMENT,
    `master_session_id` int NOT NULL,
    `counter_user_id`   int NOT NULL,
    `category_id`       int NOT NULL,
    `status`            enum('assigned','in_progress','completed','paused') DEFAULT 'assigned',
    `assigned_at`       timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `started_at`        timestamp NULL DEFAULT NULL,
    `completed_at`      timestamp NULL DEFAULT NULL,
    `notes`             text DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_session_category` (`master_session_id`, `category_id`),
    KEY `idx_counter_user` (`counter_user_id`),
    KEY `idx_master_session` (`master_session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

-- stock_count: individual product counts submitted against an assignment
CREATE TABLE IF NOT EXISTS `stock_count` (
    `id`                      int NOT NULL AUTO_INCREMENT,
    `assignment_id`           int NOT NULL,
    `vendor_product_id`       int NOT NULL,
    `counted_quantity`        double NOT NULL,
    `count_unit`              varchar(12) NOT NULL,
    `standard_unit_quantity`  decimal(10,2) DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_assignment` (`assignment_id`),
    KEY `idx_vendor_product` (`vendor_product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;


-- 2026-06-01: Miscellaneous tables present in loagma_new but previously undocumented

-- product_purchase: historical product purchase cost log
CREATE TABLE IF NOT EXISTS `product_purchase` (
    `item_id`    bigint unsigned NOT NULL AUTO_INCREMENT,
    `day_id`     varchar(20) NOT NULL DEFAULT '01-01-2018',
    `product_id` bigint unsigned NOT NULL DEFAULT 0,
    `quantity`   decimal(10,2) unsigned NOT NULL DEFAULT 0.00,
    `unit_id`    text NOT NULL,
    `cost`       decimal(10,2) NOT NULL DEFAULT 0.00,
    `post_date`  int unsigned NOT NULL DEFAULT 0,
    PRIMARY KEY (`item_id`),
    UNIQUE KEY `day_id` (`day_id`, `product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;

-- vendor_area_categories: maps vendor/admin to area+category combos with commission
CREATE TABLE IF NOT EXISTS `vendor_area_categories` (
    `id`          int NOT NULL AUTO_INCREMENT,
    `admin_id`    int NOT NULL,
    `city_id`     varchar(255) NOT NULL DEFAULT '',
    `area_id`     varchar(255) NOT NULL,
    `category_id` varchar(255) NOT NULL,
    `commisson`   int NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;