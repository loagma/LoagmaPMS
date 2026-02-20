# Transaction Integration Plan

## Overview

Currently, the inventory system has two separate stock tracking mechanisms:
1. **Product-level stock**: `product.stock` field (single number)
2. **Pack-level stock**: `vendor_products.packs` JSON (multiple packages with individual stock)

The StockManagerService has been built to synchronize pack-level stock across all package sizes. However, the transaction controllers (Issue, Receive, Stock Voucher) are still updating `product.stock` directly without updating pack-level stock.

## Problem

When transactions occur:
- `IssueToProductionController` reduces `product.stock` directly
- `ReceiveFromProductionController` doesn't update stock at all
- `StockVoucherController` doesn't update stock at all
- Pack-level stock in `vendor_products.packs` is NOT updated
- Pack synchronization is NOT triggered

This causes inconsistency between product-level and pack-level stock.

## Solution

Integrate all transaction controllers with `StockManagerService` so that:
1. All stock changes update pack-level stock first
2. Pack synchronization happens automatically (all packages update proportionally)
3. Product-level stock is aggregated from pack-level stock
4. Inventory remains consistent at both levels

## Implementation Tasks

### Task 14.1: Update IssueToProductionController

**Current behavior:**
```php
private function reduceStock(array $materials): void
{
    foreach ($materials as $material) {
        $productId = (int) $material['raw_material_id'];
        $quantity = (float) $material['quantity'];
        DB::update(
            'UPDATE product SET stock = COALESCE(stock, 0) - ? WHERE product_id = ?',
            [$quantity, $productId]
        );
    }
}
```

**New behavior:**
```php
private function reduceStock(array $materials): void
{
    $stockManager = app(StockManagerService::class);
    
    foreach ($materials as $material) {
        $productId = (int) $material['raw_material_id'];
        $quantity = (float) $material['quantity'];
        
        // Find vendor_product for this product
        $vendorProduct = DB::table('vendor_products')
            ->where('product_id', $productId)
            ->where('status', '1')
            ->first();
            
        if (!$vendorProduct) {
            throw new \RuntimeException("No active vendor product found for product #{$productId}");
        }
        
        // Use default_pack_id or first available pack
        $packId = $vendorProduct->default_pack_id;
        if (!$packId) {
            $packs = json_decode($vendorProduct->packs, true);
            if (empty($packs)) {
                throw new \RuntimeException("No packs found for vendor product #{$vendorProduct->id}");
            }
            // Get first pack ID
            $packId = is_array($packs) ? ($packs[0]['pi'] ?? null) : array_key_first($packs);
        }
        
        // Update pack stock (negative for reduction)
        $result = $stockManager->updatePackStock(
            $vendorProduct->id,
            $packId,
            -$quantity,
            'issue_to_production'
        );
        
        if (!$result->success) {
            throw new \RuntimeException($result->message);
        }
    }
}
```

### Task 14.2: Update Stock Validation

**Current behavior:**
```php
private function validateStock(array $materials): ?array
{
    foreach ($materials as $index => $material) {
        $product = DB::table('product')
            ->where('product_id', $productId)
            ->select('product_id', 'name', 'stock')
            ->first();
        $available = $product->stock !== null ? (float) $product->stock : 0;
        if ($available < $quantity) {
            // Error
        }
    }
}
```

**New behavior:**
```php
private function validateStock(array $materials): ?array
{
    foreach ($materials as $index => $material) {
        $productId = (int) $material['raw_material_id'];
        $quantity = (float) $material['quantity'];
        
        // Get vendor product with packs
        $vendorProduct = DB::table('vendor_products')
            ->where('product_id', $productId)
            ->where('status', '1')
            ->first();
            
        if (!$vendorProduct) {
            $errors["materials.{$index}"] = ['No active vendor product found'];
            continue;
        }
        
        // Calculate total available stock from all packs
        $packs = json_decode($vendorProduct->packs, true);
        $totalStock = 0;
        
        if (is_array($packs)) {
            foreach ($packs as $pack) {
                $totalStock += (float) ($pack['stk'] ?? 0);
            }
        }
        
        if ($totalStock < $quantity) {
            $product = DB::table('product')->where('product_id', $productId)->first();
            $productName = $product->name ?? "Product #{$productId}";
            $errors["materials.{$index}"] = [
                "Insufficient stock for {$productName}. Available: {$totalStock}, Required: {$quantity}",
            ];
        }
    }
}
```

### Task 14.3: Update ReceiveFromProductionController

Add stock increase logic:

```php
private function increaseStock(array $items): void
{
    $stockManager = app(StockManagerService::class);
    
    foreach ($items as $item) {
        $productId = (int) $item['finished_product_id'];
        $quantity = (float) $item['quantity'];
        
        // Find vendor_product for this product
        $vendorProduct = DB::table('vendor_products')
            ->where('product_id', $productId)
            ->where('status', '1')
            ->first();
            
        if (!$vendorProduct) {
            throw new \RuntimeException("No active vendor product found for product #{$productId}");
        }
        
        // Use default_pack_id or first available pack
        $packId = $vendorProduct->default_pack_id;
        if (!$packId) {
            $packs = json_decode($vendorProduct->packs, true);
            if (empty($packs)) {
                throw new \RuntimeException("No packs found for vendor product #{$vendorProduct->id}");
            }
            $packId = is_array($packs) ? ($packs[0]['pi'] ?? null) : array_key_first($packs);
        }
        
        // Update pack stock (positive for increase)
        $result = $stockManager->updatePackStock(
            $vendorProduct->id,
            $packId,
            $quantity,
            'receive_from_production'
        );
        
        if (!$result->success) {
            throw new \RuntimeException($result->message);
        }
    }
}
```

Call this in `store()` and `update()` when status is RECEIVED.

### Task 14.4: Update StockVoucherController

Add stock update logic:

```php
private function updateStock(array $items, string $voucherType): void
{
    $stockManager = app(StockManagerService::class);
    
    foreach ($items as $item) {
        $productId = (int) $item['product_id'];
        $quantity = (float) $item['quantity'];
        
        // Determine stock change direction
        $stockChange = $voucherType === 'IN' ? $quantity : -$quantity;
        
        // Find vendor_product for this product
        $vendorProduct = DB::table('vendor_products')
            ->where('product_id', $productId)
            ->where('status', '1')
            ->first();
            
        if (!$vendorProduct) {
            throw new \RuntimeException("No active vendor product found for product #{$productId}");
        }
        
        // Use default_pack_id or first available pack
        $packId = $vendorProduct->default_pack_id;
        if (!$packId) {
            $packs = json_decode($vendorProduct->packs, true);
            if (empty($packs)) {
                throw new \RuntimeException("No packs found for vendor product #{$vendorProduct->id}");
            }
            $packId = is_array($packs) ? ($packs[0]['pi'] ?? null) : array_key_first($packs);
        }
        
        // Update pack stock
        $result = $stockManager->updatePackStock(
            $vendorProduct->id,
            $packId,
            $stockChange,
            "stock_voucher_{$voucherType}"
        );
        
        if (!$result->success) {
            throw new \RuntimeException($result->message);
        }
    }
}
```

Call this in `store()` and `update()` when status is POSTED.

### Task 14.5: Handle Transaction Updates

For updates, need to:
1. Check if previous status was ISSUED/RECEIVED/POSTED
2. If yes, reverse the stock changes first
3. Then apply new stock changes if new status is ISSUED/RECEIVED/POSTED

Example for IssueToProductionController:

```php
// In update() method, before updating:
if ($existingIssue->status === 'ISSUED' && count($existingItems) > 0) {
    $this->restoreStock($existingItems); // Reverse previous changes
}

// After updating items:
if ($request->status === 'ISSUED') {
    $this->reduceStock($request->materials); // Apply new changes
}
```

## Benefits

After integration:
1. ✅ All transactions update pack-level stock
2. ✅ Pack synchronization happens automatically
3. ✅ Product-level stock stays in sync with pack-level stock
4. ✅ Inventory is consistent across all views
5. ✅ Audit trail tracks all stock changes
6. ✅ Stock validation checks actual pack stock

## Testing

Need to verify:
1. Issue to Production reduces pack stock and synchronizes all packages
2. Receive from Production increases pack stock and synchronizes all packages
3. Stock Voucher IN/OUT updates pack stock correctly
4. Product.stock matches sum of pack stock after transactions
5. Transaction updates reverse and reapply stock changes correctly
6. Multiple packages update proportionally when one is changed
