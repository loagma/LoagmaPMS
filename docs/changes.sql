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
