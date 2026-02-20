# Stock Audit Log Migration Guide

## Overview

This guide explains the optional database migration for stock audit logs and how to use it.

## Current Implementation

The system currently uses **Laravel's file-based logging system** via the `StockAuditLogger` service. Logs are written to files using the `stock_audit` log channel configured in `config/logging.php`.

**Advantages of file-based logging:**
- Simple implementation
- No database overhead
- Built-in log rotation
- Easy to configure

## Optional Database Table

The migration `2026_02_18_000000_create_stock_audit_log_table.php` creates an optional database table for structured audit log storage.

**Advantages of database table:**
- Better queryability for reports
- Structured data for analytics
- Easier filtering and searching
- Integration with database backup systems

## Migration Details

### Table: stock_audit_log

```sql
CREATE TABLE stock_audit_log (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    vendor_product_id INT NOT NULL,
    trigger_pack_id VARCHAR(255) NOT NULL,
    pack_updates JSON NOT NULL,
    reason VARCHAR(500) NOT NULL,
    user_id INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_vendor_product_id (vendor_product_id),
    INDEX idx_trigger_pack_id (trigger_pack_id),
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at),
    INDEX idx_vendor_product_created (vendor_product_id, created_at)
);
```

### Fields

- **id**: Auto-incrementing primary key
- **vendor_product_id**: References the vendor product being updated
- **trigger_pack_id**: The package ID that triggered the stock update
- **pack_updates**: JSON array of stock changes for all affected packages
  ```json
  [
    {
      "pack_id": "BJFK",
      "old_stock": 10,
      "new_stock": 15,
      "change": 5
    },
    {
      "pack_id": "qL0f",
      "old_stock": 20,
      "new_stock": 30,
      "change": 10
    }
  ]
  ```
- **reason**: Reason for the stock update (e.g., "purchase", "sale", "adjustment")
- **user_id**: ID of the user who performed the update (nullable)
- **created_at**: Timestamp of the audit log entry

### Indexes

Indexes are created for common query patterns:
- Single vendor product audit trail
- User activity tracking
- Time-based queries
- Combined vendor product + time range queries

## How to Use the Database Table

### Step 1: Run the Migration

```bash
php artisan migrate
```

This will create the `stock_audit_log` table.

### Step 2: Update StockAuditLogger Service

Modify `server/app/Services/StockAuditLogger.php` to write to the database table instead of (or in addition to) file logs.

**Option A: Database Only**

```php
<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

class StockAuditLogger
{
    public function logStockUpdate(
        int $vendorProductId,
        string $triggerPackId,
        array $packUpdates,
        string $reason
    ): void {
        $userId = $this->getCurrentUserId();

        $updateDetails = array_map(function ($update) {
            return [
                'pack_id' => $update->packId,
                'old_stock' => $update->oldStock,
                'new_stock' => $update->newStock,
                'change' => $update->change,
            ];
        }, $packUpdates);

        DB::table('stock_audit_log')->insert([
            'vendor_product_id' => $vendorProductId,
            'trigger_pack_id' => $triggerPackId,
            'pack_updates' => json_encode($updateDetails),
            'reason' => $reason,
            'user_id' => $userId,
            'created_at' => now(),
        ]);
    }

    public function logConsistencyError(int $vendorProductId, array $inconsistencies): void
    {
        $userId = $this->getCurrentUserId();

        DB::table('stock_audit_log')->insert([
            'vendor_product_id' => $vendorProductId,
            'trigger_pack_id' => 'CONSISTENCY_CHECK',
            'pack_updates' => json_encode($inconsistencies),
            'reason' => 'consistency_validation_failed',
            'user_id' => $userId,
            'created_at' => now(),
        ]);
    }

    private function getCurrentUserId(): ?int
    {
        return auth()->check() ? auth()->id() : null;
    }
}
```

**Option B: Both Database and File Logs (Recommended)**

```php
<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class StockAuditLogger
{
    public function logStockUpdate(
        int $vendorProductId,
        string $triggerPackId,
        array $packUpdates,
        string $reason
    ): void {
        $userId = $this->getCurrentUserId();
        $timestamp = now()->toIso8601String();

        $updateDetails = array_map(function ($update) {
            return [
                'pack_id' => $update->packId,
                'old_stock' => $update->oldStock,
                'new_stock' => $update->newStock,
                'change' => $update->change,
            ];
        }, $packUpdates);

        // Write to database
        DB::table('stock_audit_log')->insert([
            'vendor_product_id' => $vendorProductId,
            'trigger_pack_id' => $triggerPackId,
            'pack_updates' => json_encode($updateDetails),
            'reason' => $reason,
            'user_id' => $userId,
            'created_at' => now(),
        ]);

        // Also write to file logs for redundancy
        Log::channel('stock_audit')->info('Stock update completed', [
            'timestamp' => $timestamp,
            'user_id' => $userId,
            'vendor_product_id' => $vendorProductId,
            'trigger_pack_id' => $triggerPackId,
            'reason' => $reason,
            'pack_updates' => $updateDetails,
            'total_packs_updated' => count($packUpdates),
        ]);
    }

    // Similar implementation for logConsistencyError...
}
```

### Step 3: Query Audit Logs

**Example queries:**

```php
// Get all audit logs for a vendor product
$logs = DB::table('stock_audit_log')
    ->where('vendor_product_id', $vendorProductId)
    ->orderBy('created_at', 'desc')
    ->get();

// Get audit logs for a specific time range
$logs = DB::table('stock_audit_log')
    ->where('vendor_product_id', $vendorProductId)
    ->whereBetween('created_at', [$startDate, $endDate])
    ->get();

// Get audit logs by user
$logs = DB::table('stock_audit_log')
    ->where('user_id', $userId)
    ->orderBy('created_at', 'desc')
    ->get();

// Get audit logs for a specific package
$logs = DB::table('stock_audit_log')
    ->where('trigger_pack_id', $packId)
    ->orderBy('created_at', 'desc')
    ->get();
```

## Recommendation

**For most use cases, the current file-based logging system is sufficient.**

Consider using the database table if you need:
- Complex audit queries and reports
- Integration with BI tools
- Long-term audit data retention with database backups
- Real-time audit monitoring dashboards

## Rollback

If you decide not to use the database table, you can roll back the migration:

```bash
php artisan migrate:rollback
```

This will drop the `stock_audit_log` table without affecting any other functionality.
