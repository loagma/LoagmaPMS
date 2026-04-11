-- Purchase legacy cleanup script
-- WARNING: destructive operation.
-- Run only after full backup.

START TRANSACTION;

-- 1) Clear voucher line items first (FK -> purchase_vouchers)
DELETE FROM purchase_voucher_items;

-- 2) Clear vouchers
DELETE FROM purchase_vouchers;

-- 3) Clear purchase order line items
DELETE FROM purchase_order_items;

-- 4) Clear purchase orders
DELETE FROM purchase_orders;

COMMIT;

-- Optional sequence reset for MySQL/MariaDB
-- ALTER TABLE purchase_voucher_items AUTO_INCREMENT = 1;
-- ALTER TABLE purchase_vouchers AUTO_INCREMENT = 1;
-- ALTER TABLE purchase_order_items AUTO_INCREMENT = 1;
-- ALTER TABLE purchase_orders AUTO_INCREMENT = 1;
