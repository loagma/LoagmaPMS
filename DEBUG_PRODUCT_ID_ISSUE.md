# Debug: Product ID Null Issue

## Problem
Getting error: `type 'Null' is not a subtype of type 'int' in type cast`

This means some products in the database have `null` for `product_id`.

## Quick Fix Applied

### Client Side (`product_model.dart`)
Now handles:
- ✅ `product_id` as int
- ✅ `product_id` as string (converts to int)
- ✅ `product_id` as null (throws error, skips product)

### Controller (`bom_controller.dart`)
Now shows:
- ✅ How many products were skipped
- ✅ The actual product data that failed
- ✅ Better error messages

## Check Your Database

Run this query to find products with null IDs:

```sql
SELECT COUNT(*) 
FROM product 
WHERE product_id IS NULL;
```

If this returns > 0, you have data issues!

## Check Products with Empty Names

```sql
SELECT COUNT(*) 
FROM product 
WHERE TRIM(name) = '' OR name IS NULL;
```

## Check All Issues

```sql
SELECT 
    COUNT(*) as total,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) as null_ids,
    SUM(CASE WHEN TRIM(name) = '' OR name IS NULL THEN 1 ELSE 0 END) as empty_names,
    SUM(CASE WHEN is_deleted = 1 THEN 1 ELSE 0 END) as deleted,
    SUM(CASE WHEN is_published = 0 THEN 1 ELSE 0 END) as unpublished
FROM product;
```

## Test API Response

```bash
curl http://localhost:8000/api/products | jq '.data[] | select(.product_id == null)'
```

This will show any products with null IDs in the API response.

## Expected Debug Output

After the fix, you should see:

```
[BOM] Fetching products from: http://10.0.2.2:8000/api/products
[BOM] Response status: 200
[BOM] Received 1234 products
[BOM] Skipping invalid product: FormatException: Invalid product_id: null
[BOM] Product data: {product_id: null, product_name: "Some Name", ...}
[BOM] Successfully parsed 1200 products
[BOM] Skipped 34 invalid products
[BOM] Loaded 56 finished products
[BOM] Loaded 1144 raw materials
```

## Fix Database (Optional)

If you want to clean up the data:

### Option 1: Delete products with null IDs
```sql
DELETE FROM product WHERE product_id IS NULL;
```

### Option 2: Assign new IDs
```sql
-- Find max ID
SELECT MAX(product_id) FROM product;

-- Then manually assign IDs or use a script
```

### Option 3: Mark as deleted
```sql
UPDATE product 
SET is_deleted = 1 
WHERE product_id IS NULL;
```

## What Happens Now

The app will:
1. ✅ Try to parse each product
2. ✅ Skip products with null IDs
3. ✅ Log which products were skipped
4. ✅ Continue loading valid products
5. ✅ Display valid products in dropdowns

## Summary

The fix makes the app resilient to bad data. Products with:
- ❌ Null IDs → Skipped
- ❌ Empty names → Skipped
- ✅ Valid data → Loaded

The app will work even with some bad data in the database!
