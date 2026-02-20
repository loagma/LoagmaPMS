# Service Documentation: Linked Package Stock Management

## Overview

The Linked Package Stock Management system provides automatic synchronization of stock levels across multiple package sizes. The system consists of six core services that work together to maintain stock consistency.

## Architecture

```
StockManagerService (Orchestrator)
├── UnitConverter (Unit conversion and calculations)
├── PackSynchronizer (Proportional stock updates)
├── PackJsonManager (JSON serialization)
├── ProductStockAggregator (Product-level aggregation)
└── StockAuditLogger (Audit trail)
```

---

## StockManagerService

**Purpose**: Main orchestrator for all stock operations. Coordinates stock updates and synchronization across related packages.

### Methods

#### `updatePackStock()`

Updates stock for a specific package and synchronizes all related packages.

**Signature**:
```php
public function updatePackStock(
    int $vendorProductId,
    string $packId,
    float $stockChange,
    string $reason
): StockUpdateResult
```

**Parameters**:
- `$vendorProductId` (int): ID of the vendor product
- `$packId` (string): ID of the package to update (from `pi` field in JSON)
- `$stockChange` (float): Amount to change stock by (positive for increase, negative for decrease)
- `$reason` (string): Reason for the update (e.g., 'purchase', 'sale', 'adjustment')

**Returns**: `StockUpdateResult` object with:
- `success` (bool): Whether the operation succeeded
- `message` (string): Success or error message
- `packUpdates` (array): Array of `PackStockUpdate` objects showing changes
- `errors` (array|null): Error details if operation failed

**Example**:
```php
$stockManager = app(StockManagerService::class);

// Decrease stock by 5 units for a specific package
$result = $stockManager->updatePackStock(
    vendorProductId: 123,
    packId: 'pack_001',
    stockChange: -5,
    reason: 'sale'
);

if ($result->success) {
    foreach ($result->packUpdates as $update) {
        echo "Pack {$update->packId}: {$update->oldStock} → {$update->newStock}\n";
    }
} else {
    echo "Error: {$result->message}\n";
}
```

**Error Handling**:
- Returns failure if vendor product not found
- Returns failure if pack JSON is malformed
- Returns failure if specified pack_id doesn't exist
- Skips invalid packages but continues with valid ones
- Logs all errors to Laravel log

---

#### `processInventoryTransaction()`

Processes an inventory transaction and updates all affected packages.

**Signature**:
```php
public function processInventoryTransaction(array $transactionData): StockUpdateResult
```

**Parameters**:
- `$transactionData` (array): Transaction data with the following structure:
  - `vendor_product_id` (int, required): ID of the vendor product
  - `pack_id` (string, required): ID of the package
  - `quantity` (float, required): Transaction quantity
  - `action_type` (string, optional): Type of action - 'purchase', 'sale', 'return', 'damage', 'adjustment_increase', 'adjustment_decrease'
  - `notes` (string, optional): Additional notes for audit trail

**Returns**: `StockUpdateResult` object (same as `updatePackStock()`)

**Example**:
```php
$result = $stockManager->processInventoryTransaction([
    'vendor_product_id' => 123,
    'pack_id' => 'pack_001',
    'quantity' => 10,
    'action_type' => 'purchase',
    'notes' => 'Received from supplier XYZ'
]);
```

**Action Type Behavior**:
- `purchase`, `return`, `adjustment_increase`: Adds to stock (positive change)
- `sale`, `damage`, `adjustment_decrease`: Reduces stock (negative change)
- Default: Uses quantity as-is

---

#### `validateStockConsistency()`

Validates that all packages have proportionally correct stock levels.

**Signature**:
```php
public function validateStockConsistency(int $vendorProductId): ConsistencyCheckResult
```

**Parameters**:
- `$vendorProductId` (int): ID of the vendor product to check

**Returns**: `ConsistencyCheckResult` object with:
- `isConsistent` (bool): Whether stock is consistent across all packages
- `inconsistencies` (array): Details of any inconsistencies found
- `referenceBaseUnits` (float): Total stock in base units

**Example**:
```php
$result = $stockManager->validateStockConsistency(123);

if (!$result->isConsistent) {
    foreach ($result->inconsistencies as $issue) {
        echo "Pack {$issue['pack_id']}: Expected {$issue['expected_stock']}, ";
        echo "Actual {$issue['actual_stock']}\n";
    }
}
```

---

## UnitConverter

**Purpose**: Handles unit conversion calculations and conversion factor determination.

### Methods

#### `calculateConversionFactor()`

Calculates the conversion factor for a package based on its size and unit.

**Signature**:
```php
public function calculateConversionFactor(string $packSize, string $packUnit): float
```

**Parameters**:
- `$packSize` (string): Numeric size value (e.g., "5", "500")
- `$packUnit` (string): Unit type (e.g., "kg", "gm", "nos")

**Returns**: Conversion factor as a float

**Example**:
```php
$converter = app(UnitConverter::class);

$factor1 = $converter->calculateConversionFactor('5', 'kg');     // Returns 5.0
$factor2 = $converter->calculateConversionFactor('500', 'gm');   // Returns 0.5 (converted to kg)
$factor3 = $converter->calculateConversionFactor('250', 'ml');   // Returns 0.25 (converted to litre)
```

**Supported Units**:
- Weight: `kg`, `gm` (converted to kg base)
- Volume: `litre`, `ml` (converted to litre base)
- Discrete: `nos`, `pack`, `dozen`, `box`, `bag`, `piece`, `bunch`, `tin`, `pouch`, `cs`, `barrel`, `jar`

**Unit Conversion Rules**:
- `1 gm = 0.001 kg`
- `1 ml = 0.001 litre`
- All other units use their numeric value directly

**Error Handling**:
- Throws `InvalidArgumentException` if pack_size is not numeric or <= 0
- Throws `InvalidArgumentException` if pack_unit is not supported

---

#### `toBaseUnits()`

Converts a quantity from package units to base units.

**Signature**:
```php
public function toBaseUnits(float $quantity, float $conversionFactor): float
```

**Example**:
```php
// 10 packages of 5kg each = 50kg base units
$baseUnits = $converter->toBaseUnits(10, 5.0);  // Returns 50.0
```

---

#### `fromBaseUnits()`

Converts base units to package quantity, with optional rounding for discrete units.

**Signature**:
```php
public function fromBaseUnits(
    float $baseUnits,
    float $conversionFactor,
    ?string $unitType = null
): float
```

**Parameters**:
- `$baseUnits` (float): Quantity in base units
- `$conversionFactor` (float): Package conversion factor
- `$unitType` (string|null): Optional unit type for rounding discrete units

**Example**:
```php
// 50kg base units / 5kg per package = 10 packages
$quantity = $converter->fromBaseUnits(50.0, 5.0);  // Returns 10.0

// With rounding for discrete units
$quantity = $converter->fromBaseUnits(50.3, 5.0, 'nos');  // Returns 10.0 (rounded)
```

**Rounding Behavior**:
- Discrete units (nos, pack, dozen, etc.) are rounded to nearest integer
- Continuous units (kg, litre) are not rounded

---

#### `getBaseUnit()`

Returns the base unit for a given unit type.

**Signature**:
```php
public function getBaseUnit(string $unitType): string
```

**Example**:
```php
$base1 = $converter->getBaseUnit('gm');     // Returns 'kg'
$base2 = $converter->getBaseUnit('ml');     // Returns 'litre'
$base3 = $converter->getBaseUnit('nos');    // Returns 'nos'
```

---

## PackSynchronizer

**Purpose**: Synchronizes stock across all related packages using proportional calculations.

### Methods

#### `synchronizePackages()`

Synchronizes stock across all packages based on a base unit change.

**Signature**:
```php
public function synchronizePackages(
    array $packs,
    float $baseUnitChange,
    string $triggerPackId
): array
```

**Parameters**:
- `$packs` (array): Array of `Pack` objects
- `$baseUnitChange` (float): Change in base units to apply
- `$triggerPackId` (string): ID of the pack that triggered the update

**Returns**: Array of `PackStockUpdate` objects

**Example**:
```php
$synchronizer = app(PackSynchronizer::class);

$updates = $synchronizer->synchronizePackages(
    packs: $packs,
    baseUnitChange: -5.0,  // Decrease by 5 base units
    triggerPackId: 'pack_001'
);
```

**Behavior**:
- Calculates new total base units from trigger pack
- Updates all packages proportionally based on their conversion factors
- Skips invalid packages (missing fields, invalid conversion factors)
- Logs warnings for skipped packages

---

#### `calculatePackStock()`

Calculates expected stock for a package given total base units.

**Signature**:
```php
public function calculatePackStock(
    float $totalBaseUnits,
    float $conversionFactor,
    ?string $unitType = null
): float
```

**Example**:
```php
// If total stock is 50kg and package is 5kg
$stock = $synchronizer->calculatePackStock(50.0, 5.0);  // Returns 10.0
```

---

#### `validateStockConsistency()`

Validates that all packages have proportionally correct stock levels.

**Signature**:
```php
public function validateStockConsistency(array $packs): ConsistencyCheckResult
```

**Parameters**:
- `$packs` (array): Array of `Pack` objects with conversion factors calculated

**Returns**: `ConsistencyCheckResult` object

**Consistency Tolerance**: 0.01 base units (to account for rounding errors)

**Example**:
```php
$result = $synchronizer->validateStockConsistency($packs);

if (!$result->isConsistent) {
    // Handle inconsistencies
}
```

---

## PackJsonManager

**Purpose**: Handles parsing and serialization of pack data in JSON format.

### Methods

#### `parsePacks()`

Parses pack JSON string into array of `Pack` objects.

**Signature**:
```php
public function parsePacks(?string $packsJson): array
```

**Returns**: Array of `Pack` objects

**Error Handling**:
- Returns empty array for null or empty JSON
- Throws exception for malformed JSON

---

#### `updatePackStocks()`

Updates stock values in pack array.

**Signature**:
```php
public function updatePackStocks(array $packs, array $stockUpdates): array
```

**Parameters**:
- `$packs` (array): Array of `Pack` objects
- `$stockUpdates` (array): Map of pack_id => new_stock

**Returns**: Updated array of `Pack` objects

**Behavior**:
- Updates `stk` field with new stock value
- Updates `in_stk` field (0 if stock <= 0, 1 if stock > 0)
- Preserves all other fields (tx, op, rp, sn, ps, pu, pi)

---

#### `serializePacks()`

Serializes pack objects to JSON string.

**Signature**:
```php
public function serializePacks(array $packs): string
```

---

## ProductStockAggregator

**Purpose**: Aggregates stock from all vendor products and updates product-level stock.

### Methods

#### `updateProductStock()`

Updates product-level stock from all vendor products.

**Signature**:
```php
public function updateProductStock(int $productId): void
```

**Behavior**:
- Calculates total stock in base units from all vendor products
- Updates `product.stock` field
- Only processes products with `inventory_type = 'PACK_WISE'`
- Skips products with `inventory_type = 'SINGLE'`

---

#### `calculateTotalStock()`

Calculates total stock in base units for a product.

**Signature**:
```php
public function calculateTotalStock(int $productId): float
```

**Returns**: Total stock in base units

---

## StockAuditLogger

**Purpose**: Logs stock changes for audit trail and debugging.

### Methods

#### `logStockUpdate()`

Logs a stock update operation.

**Signature**:
```php
public function logStockUpdate(
    int $vendorProductId,
    string $triggerPackId,
    array $packUpdates,
    string $reason
): void
```

**Log Format**:
```
Stock update completed
vendor_product_id: 123
trigger_pack_id: pack_001
reason: sale
updates: [
  {pack_id: pack_001, old: 10, new: 5, change: -5},
  {pack_id: pack_002, old: 20, new: 10, change: -10}
]
```

---

#### `logConsistencyError()`

Logs a consistency validation error.

**Signature**:
```php
public function logConsistencyError(int $vendorProductId, array $inconsistencies): void
```

**Log Format**:
```
Stock consistency error detected
vendor_product_id: 123
inconsistencies: [
  {pack_id: pack_001, expected: 10, actual: 9, difference: 1}
]
```

---

## Error Handling

### Exception Types

The system uses the following exception types:

- `VendorProductNotFoundException`: Thrown when vendor product doesn't exist
- `JsonParseException`: Thrown when pack JSON is malformed
- `InvalidArgumentException`: Thrown for invalid unit types or conversion factors

### Error Handling Strategy

1. **Validation Errors**: Return `StockUpdateResult::failure()` with error details
2. **Invalid Packages**: Skip and log warning, continue with valid packages
3. **Malformed JSON**: Return failure result with parse error message
4. **Unexpected Errors**: Catch, log with stack trace, return failure result

### Graceful Degradation

- Invalid packages are skipped but don't stop the entire operation
- Negative stock is allowed (with warning log)
- Missing pack data returns empty result without throwing exception
- Consistency checks return "consistent" for empty pack data

---

## Usage Examples

### Example 1: Simple Stock Update

```php
use App\Services\StockManagerService;

$stockManager = app(StockManagerService::class);

// Reduce stock by 5 units due to a sale
$result = $stockManager->updatePackStock(
    vendorProductId: 123,
    packId: 'pack_5kg',
    stockChange: -5,
    reason: 'sale to customer ABC'
);

if ($result->success) {
    echo "Stock updated successfully\n";
    foreach ($result->packUpdates as $update) {
        echo "- {$update->packId}: {$update->oldStock} → {$update->newStock}\n";
    }
} else {
    echo "Error: {$result->message}\n";
}
```

### Example 2: Processing Inventory Transaction

```php
// Process a purchase transaction
$result = $stockManager->processInventoryTransaction([
    'vendor_product_id' => 123,
    'pack_id' => 'pack_10kg',
    'quantity' => 50,
    'action_type' => 'purchase',
    'notes' => 'Purchase order #PO-2024-001'
]);
```

### Example 3: Validating Consistency

```php
// Check if stock is consistent across all packages
$result = $stockManager->validateStockConsistency(123);

if (!$result->isConsistent) {
    echo "Inconsistencies found:\n";
    foreach ($result->inconsistencies as $issue) {
        echo "Pack {$issue['pack_id']}: ";
        echo "Expected {$issue['expected_stock']}, ";
        echo "Actual {$issue['actual_stock']}\n";
    }
}
```

### Example 4: Unit Conversion

```php
use App\Services\UnitConverter;

$converter = app(UnitConverter::class);

// Calculate conversion factors
$factor1 = $converter->calculateConversionFactor('5', 'kg');     // 5.0
$factor2 = $converter->calculateConversionFactor('500', 'gm');   // 0.5
$factor3 = $converter->calculateConversionFactor('10', 'nos');   // 10.0

// Convert between units
$baseUnits = $converter->toBaseUnits(10, 5.0);  // 50.0 kg
$quantity = $converter->fromBaseUnits(50.0, 5.0);  // 10.0 packages
```

---

## Performance Considerations

### Optimization Strategies

1. **Batch Operations**: Multiple stock updates for the same product are batched into a single synchronization
2. **Single Database Write**: Pack JSON is updated in one database write per vendor product
3. **In-Memory Calculations**: All stock calculations are done in memory before persisting
4. **Lazy Loading**: Conversion factors are calculated only when needed

### Performance Targets

- Single stock update: < 100ms
- Bulk transaction processing (100 transactions): < 5 seconds
- Consistency validation: < 50ms

### Monitoring

Monitor the following metrics:

- Stock update operation duration
- Number of invalid packages skipped
- Consistency check failures
- Database query count per operation

Check Laravel logs at `storage/logs/laravel.log` for performance warnings and errors.

---

## Testing

### Unit Tests

Run unit tests for individual services:

```bash
php artisan test --filter=UnitConverterTest
php artisan test --filter=PackSynchronizerTest
php artisan test --filter=StockManagerServiceTest
```

### Integration Tests

Run integration tests for end-to-end flows:

```bash
php artisan test --filter=StockControllerTest
```

### Property-Based Tests

Property-based tests validate universal correctness properties:

```bash
php artisan test --group=property-based
```

---

## Troubleshooting

### Common Issues

**Issue**: Stock updates fail with "Pack not found"
- **Cause**: pack_id doesn't match any package in vendor_products.packs
- **Solution**: Verify pack_id matches the `pi` field in JSON

**Issue**: Inconsistent stock across packages
- **Cause**: Manual database updates bypassed the service
- **Solution**: Use `validateStockConsistency()` to identify issues, then use `updatePackStock()` to fix

**Issue**: Invalid conversion factor errors
- **Cause**: Unsupported unit type or non-numeric pack_size
- **Solution**: Check pack_size and pack_unit fields, ensure they match supported units

**Issue**: Negative stock warnings
- **Cause**: Stock reduction exceeds available stock
- **Solution**: This is allowed by design; implement business logic to prevent if needed

### Debug Mode

Enable detailed logging by setting log level to DEBUG in `.env`:

```
LOG_LEVEL=debug
```

This will log:
- All stock calculations
- Conversion factor calculations
- Package synchronization details
- Consistency check results
