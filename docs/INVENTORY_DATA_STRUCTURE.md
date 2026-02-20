# Inventory Data Structure Explanation

## Database Tables

### 1. vendor_products Table
This is the main table for inventory data.

**Structure:**
```sql
CREATE TABLE `vendor_products` (
  `id` int NOT NULL AUTO_INCREMENT,
  `admin_vendor_id` int NOT NULL,
  `product_id` int NOT NULL,
  `packs` text NOT NULL,              -- JSON array of packages
  `default_pack_id` varchar(255) NOT NULL,
  `status` enum('1','0') NOT NULL,    -- '1' = active, '0' = inactive
  `in_stock` enum('1','0') NOT NULL,  -- '1' = in stock, '0' = out of stock
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
)
```

### 2. product Table
Contains product master data (name, category, etc.)

**Join:**
```sql
vendor_products.product_id = product.product_id
```

## Packs JSON Structure

The `packs` field can be stored in **two formats**:

### Format 1: Array (Recommended)
```json
[
  {
    "pi": "pack_5kg",      // Pack ID
    "ps": "5",             // Pack Size
    "pu": "kg",            // Pack Unit
    "stk": 10,             // Stock quantity
    "in_stk": 1,           // In stock flag (0 or 1)
    "tx": "5",             // Tax percentage
    "op": "500",           // Original Price
    "rp": "550",           // Retail Price
    "sn": 1                // Serial Number (display order)
  },
  {
    "pi": "pack_1kg",
    "ps": "1",
    "pu": "kg",
    "stk": 50,
    "in_stk": 1,
    "tx": "5",
    "op": "100",
    "rp": "110",
    "sn": 2
  }
]
```

### Format 2: Object (Legacy - Still Supported)
```json
{
  "IG38": {
    "tx": "1 Cs (4 x 645.00)",
    "op": 2580,
    "rp": 2580,
    "sn": 0,
    "ps": "1 Cs (4 x 645.00)",
    "pu": "Nos",
    "stk": 4.9,
    "in_stk": 1,
    "pi": "IG38"
  },
  "pack_5kg": {
    "tx": "5",
    "op": "500",
    "rp": "550",
    "sn": 1,
    "ps": "5",
    "pu": "kg",
    "stk": 10,
    "in_stk": 1,
    "pi": "pack_5kg"
  }
}
```

**Note:** The system now supports **both formats**. When parsing:
- Array format: Directly iterates through the array
- Object format: Extracts values from the object keys and uses the key as `pi` (pack ID) if not present in the value

## Common Issues & Solutions

### Issue 1: "In Stock" showing 0 packs

**Cause:** 
- The `packs` field is empty: `[]` or `""`
- The vendor product was created without any packages configured

**Solution:**
- Add packages to the vendor product
- Update the `packs` JSON field with package data

**Example:**
```sql
UPDATE vendor_products 
SET packs = '[{"pi":"pack_1kg","ps":"1","pu":"kg","stk":0,"in_stk":0,"tx":"5","op":"100","rp":"110","sn":1}]'
WHERE id = 123;
```

### Issue 2: "Out of Stock" but packs exist

**Cause:**
- The `in_stock` field in the database is set to '0'
- All packs have `stk` (stock) = 0

**Solution (Fixed in Code):**
The API now calculates `in_stock` dynamically based on actual pack stock:
- If ANY pack has `stk > 0`, then `in_stock = '1'`
- If ALL packs have `stk = 0`, then `in_stock = '0'`

This ensures the displayed status matches the actual stock levels.

### Issue 3: Database `in_stock` field out of sync

**Cause:**
- The `in_stock` field is not automatically updated when pack stock changes
- Manual database updates or legacy code may have set incorrect values

**Solution:**
The API now ignores the database `in_stock` field and calculates it from pack data:

```php
// Calculate in_stock from actual pack stock
$packs = json_decode($vp->packs, true) ?? [];
$hasStock = false;

if (!empty($packs)) {
    // Handle both array format and object format
    $packsArray = is_array($packs) && !isset($packs[0]) 
        ? array_values($packs) // Convert object to array
        : $packs;
    
    foreach ($packsArray as $pack) {
        if (is_array($pack) && isset($pack['stk']) && $pack['stk'] > 0) {
            $hasStock = true;
            break;
        }
    }
}

return [
    'in_stock' => $hasStock ? '1' : '0', // Calculated, not from DB
];
```

### Issue 4: Packs stored as object instead of array

**Cause:**
- Legacy data format stores packs as an object: `{"IG38": {...}, "pack2": {...}}`
- New format uses array: `[{...}, {...}]`

**Solution (Fixed in Code):**
Both Flutter and PHP now handle both formats:

**Flutter:**
```dart
if (decoded is List) {
  // Array format
  packsList.addAll(decoded.map((p) => Pack.fromJson(p)));
} else if (decoded is Map) {
  // Object format - extract values and use keys as pack IDs
  decoded.forEach((key, value) {
    if (!value.containsKey('pi')) {
      value['pi'] = key; // Use key as pack_id
    }
    packsList.add(Pack.fromJson(value));
  });
}
```

**PHP:**
```php
// Convert object format to array if needed
$packsArray = is_array($packs) && !isset($packs[0]) 
    ? array_values($packs) // Object format - get values
    : $packs; // Already array format
```

## Stock Status Logic

The Flutter app displays stock status based on:

1. **Out of Stock (Red)**: `in_stock = '0'` (no packs have stock)
2. **Low Stock (Orange)**: Any pack has `0 < stock < 10`
3. **In Stock (Green)**: All packs have `stock >= 10`

## Data Flow

```
Database (vendor_products)
    ↓
API (VendorProductController)
    ↓ (calculates in_stock from packs)
JSON Response
    ↓
Flutter App (inventory_model.dart)
    ↓ (parses JSON)
UI Display (inventory_list_screen.dart)
```

## Updating Stock

When stock is updated via the API:

```
POST /api/vendor-products/{id}/packs/{packId}/stock
{
  "stock_change": -5,
  "reason": "sale"
}
```

The system:
1. Updates the specific pack's `stk` value in the JSON
2. Synchronizes all related packs proportionally
3. Updates the `in_stk` field for each pack (0 if stock <= 0, 1 if stock > 0)
4. Saves the updated JSON back to `vendor_products.packs`

**Note:** The vendor product level `in_stock` field is NOT updated by the stock management API. It's calculated dynamically when fetching data.

## Recommendations

### For Clean Data
1. Ensure all vendor products have at least one pack configured
2. Use the stock management API for all stock updates (don't update database directly)
3. Run a data cleanup script to remove vendor products with empty packs

### Cleanup Script Example
```sql
-- Find vendor products with no packs
SELECT id, product_id, packs 
FROM vendor_products 
WHERE packs = '' OR packs = '[]' OR packs IS NULL;

-- Option 1: Delete them
DELETE FROM vendor_products 
WHERE packs = '' OR packs = '[]' OR packs IS NULL;

-- Option 2: Add a default pack
UPDATE vendor_products 
SET packs = '[{"pi":"pack_default","ps":"1","pu":"nos","stk":0,"in_stk":0,"tx":"0","op":"0","rp":"0","sn":1}]'
WHERE packs = '' OR packs = '[]' OR packs IS NULL;
```

## Summary

- **Data Source**: `vendor_products` table (joined with `product` for name)
- **Stock Data**: Stored in `packs` JSON field
- **In Stock Status**: Now calculated dynamically from pack stock levels
- **0 Packs Issue**: Vendor products with empty `packs` field
- **Out of Stock**: All packs have `stk = 0`
