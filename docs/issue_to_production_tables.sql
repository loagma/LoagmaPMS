-- Issue to Production Tables

CREATE TABLE IF NOT EXISTS issue_to_production (
    issue_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    finished_product_id BIGINT UNSIGNED NOT NULL,
    quantity_to_produce DECIMAL(10,3) NOT NULL,
    
    status ENUM('DRAFT', 'ISSUED', 'COMPLETED', 'CANCELLED') DEFAULT 'DRAFT',
    
    remarks TEXT,
    
    issued_by BIGINT,
    issued_at DATETIME,
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_issue_finished_product
        FOREIGN KEY (finished_product_id) REFERENCES product(product_id)
);

CREATE TABLE IF NOT EXISTS issue_to_production_items (
    issue_item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    
    issue_id BIGINT UNSIGNED NOT NULL,
    raw_material_id BIGINT UNSIGNED NOT NULL,
    
    quantity DECIMAL(10,3) NOT NULL,
    unit_type VARCHAR(20) NOT NULL,
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_issue_items_issue
        FOREIGN KEY (issue_id) REFERENCES issue_to_production(issue_id),
    
    CONSTRAINT fk_issue_items_material
        FOREIGN KEY (raw_material_id) REFERENCES product(product_id)
);

-- Indexes for better performance
CREATE INDEX idx_issue_status ON issue_to_production(status);
CREATE INDEX idx_issue_created ON issue_to_production(created_at);
CREATE INDEX idx_issue_finished_product ON issue_to_production(finished_product_id);
