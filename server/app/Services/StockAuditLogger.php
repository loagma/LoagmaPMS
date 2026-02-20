<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;

/**
 * StockAuditLogger Service
 * 
 * Responsible for logging stock changes and consistency errors for audit trail.
 * Logs include timestamps, user identifiers, and before/after values.
 */
class StockAuditLogger
{
    /**
     * Log a stock update operation
     * 
     * @param int $vendorProductId
     * @param string $triggerPackId
     * @param array $packUpdates Array of PackStockUpdate objects
     * @param string $reason
     * @return void
     */
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

    /**
     * Log a consistency error
     * 
     * @param int $vendorProductId
     * @param array $inconsistencies
     * @return void
     */
    public function logConsistencyError(int $vendorProductId, array $inconsistencies): void
    {
        $userId = $this->getCurrentUserId();
        $timestamp = now()->toIso8601String();

        Log::channel('stock_audit')->error('Stock consistency validation failed', [
            'timestamp' => $timestamp,
            'user_id' => $userId,
            'vendor_product_id' => $vendorProductId,
            'inconsistencies' => $inconsistencies,
            'total_inconsistencies' => count($inconsistencies),
        ]);
    }

    /**
     * Get current user ID from authentication context
     * 
     * @return int|null
     */
    private function getCurrentUserId(): ?int
    {
        return auth()->check() ? auth()->id() : null;
    }
}

