-- Deep clean product data to fix JSON issues

-- Step 1: Find all problematic products
SELECT 
    product_id, 
    name,
    inventory_type,
    CHAR_LENGTH(name) as name_length,
    CHAR_LENGTH(inventory_type) as type_length
FROM product
WHERE is_deleted = 0 
  AND is_published = 1
  AND product_id IS NOT NULL
ORDER BY product_id
LIMIT 20;

-- Step 2: Fix NULL or empty inventory_type
UPDATE product
SET inventory_type = 'SINGLE'
WHERE product_id IN (
    SELECT product_id FROM (
        SELECT product_id 
        FROM product
        WHERE is_deleted = 0 
          AND is_published = 1
          AND (inventory_type IS NULL OR TRIM(inventory_type) = '')
    ) AS temp
);

-- Step 3: Clean product names - remove all special characters
UPDATE product
SET name = TRIM(
    REPLACE(
    REPLACE(
    REPLACE(
    REPLACE(
    REPLACE(
    REPLACE(name, '"', ''),
    CHAR(13), ''),
    CHAR(10), ''),
    CHAR(9), ''),
    '\\', ''),
    '\n', '')
)
WHERE product_id IN (
    SELECT product_id FROM (
        SELECT product_id 
        FROM product
        WHERE is_deleted = 0 
          AND is_published = 1
    ) AS temp
);

-- Step 4: Clean inventory_type - only allow valid values
UPDATE product
SET inventory_type = TRIM(inventory_type)
WHERE product_id IN (
    SELECT product_id FROM (
        SELECT product_id 
        FROM product
        WHERE is_deleted = 0 
          AND is_published = 1
          AND inventory_type IS NOT NULL
    ) AS temp
);

-- Step 5: Verify - count clean products
SELECT 
    COUNT(*) as total_clean_products,
    COUNT(DISTINCT inventory_type) as unique_types
FROM product
WHERE is_deleted = 0 
  AND is_published = 1
  AND product_id IS NOT NULL
  AND TRIM(name) != ''
  AND inventory_type IS NOT NULL;

-- Step 6: Show sample of cleaned data
SELECT 
    product_id,
    name,
    inventory_type
FROM product
WHERE is_deleted = 0 
  AND is_published = 1
ORDER BY product_id
LIMIT 10;
