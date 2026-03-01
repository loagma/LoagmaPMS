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
