# Integration Guide: Linked Package Stock Management

## Overview

This guide explains how to integrate the Linked Package Stock Management system into existing inventory workflows. The system automatically synchronizes stock levels across multiple package sizes using the `StockManagerService`.

## Integration Points

### 1. Existing Inventory Transaction Code

The current codebase includes several controllers that manage inventory:

- **IssueToProductionController**: Handles raw material issues to production
- **ReceiveFromProductionController**: Handles finished goods receipts from production  
- **StockVoucherController**: Handles general stock adjustments (IN/OUT vouchers)

These controllers currently update the `product.stock` field directly but do NOT manipulate `vendor_products.packs`. 

### 2. Integration Strategy

To integrate linked package stock management:

#### Option A: Direct Integration (Recommended for new code)

For new inventory transaction code that needs to update vendor product packages:

```php
use App\Services\StockManagerService;

class YourController extends Controller
{
    private StockManagerService $stockManager;
    
    public function __construct(StockManagerService $stockManager)
    {
        $this->stockManager = $stockManager;
    }
    
    public function processTransaction(Request $request)
    {
        // Your validation logic here
        
        // Process inventory transaction with linked package sync
        $result = $this->stockManager->processInventoryTransaction([
            'vendor_product_id' => $request->vendor_product_id,
            'pack_id' => $request->pack_id,
            'quantity' => $request->quantity,
            'unit_type' => $request->unit_type,
            'action_type' => $request->action_type, // 'IN' or 'OUT'
            'reason' => $request->reason
        ]);
        
        if (!$result->success) {
            return response()->json([
                'success' => false,
                'message' => $result->message,
                'errors' => $result->errors
            ], 400);
        }
        
        return response()->json([
            'success' => true,
            'message' => 'Transaction processed successfully',
            'updates' => $result->packUpdates
        ]);
    }
}
```

#### Option B: API Integration (Recommended for external systems)

Use the REST API endpoints:

```bash
# Update stock for a specific package
POST /api/vendor-products/{id}/packs/{packId}/stock
Content-Type: application/json

{
  "stock_change": -5,
  "reason": "sale"
}

# Process an inventory transaction
POST /api/inventory-transactions
Content-Type: application/json

{
  "vendor_product_id": 123,
  "pack_id": "pack_001",
  "quantity": 10,
  "unit_type": "kg",
  "action_type": "IN",
  "reason": "purchase"
}
```

### 3. Backward Compatibility

The system maintains full backward compatibility:

- **Existing data format**: The `vendor_products.packs` JSON structure remains unchanged
- **Product-level stock**: Products with `inventory_type = 'SINGLE'` continue to work without package-level synchronization
- **Missing pack data**: Products without pack data are handled gracefully
- **Existing API endpoints**: No breaking changes to existing endpoints

### 4. Migration Path

To migrate existing inventory transaction code:

1. **Identify code locations**: Search for direct updates to `vendor_products.packs` or `product.stock`
2. **Assess impact**: Determine if the code needs package-level synchronization
3. **Replace with service calls**: Use `StockManagerService` methods instead of direct DB updates
4. **Test thoroughly**: Verify stock consistency across all package sizes
5. **Monitor audit logs**: Check `storage/logs/laravel.log` for stock update operations

### 5. Code Locations to Review

Based on the current codebase, the following areas may need integration:

- **IssueToProductionController**: If raw materials have multiple package sizes, integrate `StockManagerService`
- **ReceiveFromProductionController**: If finished goods have multiple package sizes, integrate `StockManagerService`
- **StockVoucherController**: If vouchers need to update vendor product packages, integrate `StockManagerService`

Currently, these controllers only update `product.stock` directly and do not manipulate `vendor_products.packs`, so no immediate changes are required unless package-level tracking is needed.

## Example: Integrating with Stock Voucher

If you need to extend StockVoucherController to support vendor product packages:

```php
// In StockVoucherController.php

use App\Services\StockManagerService;

private StockManagerService $stockManager;

public function __construct(StockManagerService $stockManager)
{
    $this->stockManager = $stockManager;
}

private function updateVendorProductStock(int $vendorProductId, string $packId, float $quantity, string $voucherType): void
{
    $stockChange = $voucherType === 'IN' ? $quantity : -$quantity;
    
    $result = $this->stockManager->updatePackStock(
        $vendorProductId,
        $packId,
        $stockChange,
        "Stock voucher: {$voucherType}"
    );
    
    if (!$result->success) {
        throw new \RuntimeException("Failed to update vendor product stock: {$result->message}");
    }
}
```

## Testing Integration

After integrating the stock management service:

1. **Run unit tests**: `php artisan test --filter=StockManagerServiceTest`
2. **Run integration tests**: `php artisan test --filter=StockControllerTest`
3. **Verify consistency**: Use the consistency check endpoint:
   ```bash
   GET /api/vendor-products/{id}/stock-consistency
   ```
4. **Check audit logs**: Review `storage/logs/laravel.log` for stock operations

## Support

For questions or issues with integration:

- Review the [Service Documentation](./SERVICE_DOCUMENTATION.md)
- Review the [API Documentation](./API_DOCUMENTATION.md)
- Check audit logs in `storage/logs/laravel.log`
- Validate stock consistency using the API endpoint
