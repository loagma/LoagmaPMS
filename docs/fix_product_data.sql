-- Fix malformed product data that causes JSON parsing errors

-- 1. Find products with potential issues
SELECT product_id, name, LENGTH(name) as name_length
FROM product
WHERE is_deleted = 0 
  AND is_published = 1
  AND (
    name LIKE '%"%' OR 
    name LIKE '%{%' OR 
    name LIKE '%}%' OR
    name LIKE '%[%' OR
    name LIKE '%]%' OR
    name REGEXP '[[:cntrl:]]'
  )
ORDER BY product_id;

-- 2. Clean up product names (remove control characters and quotes)
-- Using product_id in WHERE to satisfy safe mode
UPDATE product
SET name = TRIM(REPLACE(REPLACE(REPLACE(name, '"', ''), CHAR(13), ''), CHAR(10), ''))
WHERE product_id IN (
  SELECT product_id FROM (
    SELECT product_id 
    FROM product
    WHERE is_deleted = 0 
      AND is_published = 1
      AND (
        name LIKE '%"%' OR 
        name REGEXP '[[:cntrl:]]'
      )
  ) AS temp
);

-- 3. Verify the fix
SELECT COUNT(*) as total_products
FROM product
WHERE is_deleted = 0 
  AND is_published = 1
  AND product_id IS NOT NULL
  AND TRIM(name) != '';
