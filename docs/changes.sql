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