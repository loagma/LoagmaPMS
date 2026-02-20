<?php

namespace App\Services;

use App\ValueObjects\StockUpdateResult;
use App\ValueObjects\ConsistencyCheckResult;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Exception;

/**
 * StockManagerService
 * 
 * Main orchestrator for stock operations.
 * Coordinates stock updates and synchronization across all related packages.
 */
class StockManagerService
{
    private UnitConverter $unitConverter;
    private PackSynchronizer $packSynchronizer;
    private PackJsonManager $packJsonManager;
    private ProductStockAggregator $productStockAggregator;
    private StockAuditLogger $stockAuditLogger;

    public function __construct(
        UnitConverter $unitConverter,
        PackSynchronizer $packSynchronizer,
        PackJsonManager $packJsonManager,
        ProductStockAggregator $productStockAggregator,
        StockAuditLogger $stockAuditLogger
    ) {
        $this->unitConverter = $unitConverter;
        $this->packSynchronizer = $packSynchronizer;
        $this->packJsonManager = $packJsonManager;
        $this->productStockAggregator = $productStockAggregator;
        $this->stockAuditLogger = $stockAuditLogger;
    }

    /**
     * Update stock for a specific package and synchronize related packages
     * 
     * @param int $vendorProductId
     * @param string $packId
     * @param float $stockChange (positive for increase, negative for decrease)
     * @param string $reason (e.g., 'purchase', 'sale', 'adjustment')
     * @return StockUpdateResult
     */
    public function updatePackStock(
        int $vendorProductId,
        string $packId,
        float $stockChange,
        string $reason
    ): StockUpdateResult {
        try {
            // Load vendor product
            $vendorProduct = DB::table('vendor_products')
                ->where('id', $vendorProductId)
                ->first();

            if ($vendorProduct === null) {
                return StockUpdateResult::failure(
                    'Vendor product not found',
                    ['vendor_product_id' => $vendorProductId]
                );
            }

            // Parse packs JSON
            try {
                $packs = $this->packJsonManager->parsePacks($vendorProduct->packs);
            } catch (Exception $e) {
                return StockUpdateResult::failure(
                    'Failed to parse pack JSON: ' . $e->getMessage(),
                    ['vendor_product_id' => $vendorProductId, 'error' => $e->getMessage()]
                );
            }

            if (empty($packs)) {
                return StockUpdateResult::failure(
                    'No packs found for vendor product',
                    ['vendor_product_id' => $vendorProductId]
                );
            }

            // Find the trigger pack and calculate its conversion factor
            $triggerPack = null;
            foreach ($packs as $pack) {
                if ($pack->packId === $packId) {
                    $triggerPack = $pack;
                    break;
                }
            }

            if ($triggerPack === null) {
                return StockUpdateResult::failure(
                    'Pack not found in vendor product',
                    ['vendor_product_id' => $vendorProductId, 'pack_id' => $packId]
                );
            }

            // Calculate conversion factors for all packs
            foreach ($packs as $pack) {
                try {
                    $pack->conversionFactor = $this->unitConverter->calculateConversionFactor(
                        $pack->packSize,
                        $pack->packUnit
                    );
                } catch (\InvalidArgumentException $e) {
                    Log::warning('Failed to calculate conversion factor for pack', [
                        'vendor_product_id' => $vendorProductId,
                        'pack_id' => $pack->packId,
                        'error' => $e->getMessage()
                    ]);
                    // Set to 0 to mark as invalid
                    $pack->conversionFactor = 0;
                }
            }

            // Calculate base unit change
            $baseUnitChange = $this->unitConverter->toBaseUnits(
                $stockChange,
                $triggerPack->conversionFactor
            );

            // Synchronize all packages
            $packUpdates = $this->packSynchronizer->synchronizePackages(
                $packs,
                $baseUnitChange,
                $packId
            );

            if (empty($packUpdates)) {
                return StockUpdateResult::failure(
                    'Failed to synchronize packages',
                    ['vendor_product_id' => $vendorProductId]
                );
            }

            // Build stock updates map
            $stockUpdates = [];
            foreach ($packUpdates as $update) {
                $stockUpdates[$update->packId] = $update->newStock;
            }

            // Update packs with new stock values
            $updatedPacks = $this->packJsonManager->updatePackStocks($packs, $stockUpdates);

            // Serialize packs to JSON
            $updatedPacksJson = $this->packJsonManager->serializePacks($updatedPacks);

            // Persist changes to database
            DB::table('vendor_products')
                ->where('id', $vendorProductId)
                ->update(['packs' => $updatedPacksJson]);

            // Log operation
            $this->stockAuditLogger->logStockUpdate(
                $vendorProductId,
                $packId,
                $packUpdates,
                $reason
            );

            // Update product-level stock if product_id exists
            if (isset($vendorProduct->product_id) && $vendorProduct->product_id > 0) {
                $this->productStockAggregator->updateProductStock($vendorProduct->product_id);
            }

            return StockUpdateResult::success(
                'Stock updated successfully',
                $packUpdates
            );

        } catch (Exception $e) {
            Log::error('Unexpected error in updatePackStock', [
                'vendor_product_id' => $vendorProductId,
                'pack_id' => $packId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return StockUpdateResult::failure(
                'Unexpected error: ' . $e->getMessage(),
                ['error' => $e->getMessage()]
            );
        }
    }

    /**
     * Process an inventory transaction and update all affected packages
     * 
     * @param array $transactionData Transaction data from vendor_products_inventory format
     * @return StockUpdateResult
     */
    public function processInventoryTransaction(array $transactionData): StockUpdateResult
    {
        try {
            // Extract required fields from transaction data
            $vendorProductId = $transactionData['vendor_product_id'] ?? null;
            $packId = $transactionData['pack_id'] ?? null;
            $quantity = $transactionData['quantity'] ?? null;
            $actionType = $transactionData['action_type'] ?? 'adjustment';

            // Validate required fields
            if ($vendorProductId === null || $packId === null || $quantity === null) {
                return StockUpdateResult::failure(
                    'Missing required transaction fields',
                    [
                        'required_fields' => ['vendor_product_id', 'pack_id', 'quantity'],
                        'provided' => $transactionData
                    ]
                );
            }

            // Determine stock change based on action type
            // Positive for additions (purchase, return), negative for reductions (sale, damage)
            $stockChange = match ($actionType) {
                'purchase', 'return', 'adjustment_increase' => (float) $quantity,
                'sale', 'damage', 'adjustment_decrease' => -(float) $quantity,
                default => (float) $quantity, // Default to the quantity as-is
            };

            // Build reason string
            $reason = $actionType . ' transaction';
            if (isset($transactionData['notes'])) {
                $reason .= ': ' . $transactionData['notes'];
            }

            // Call updatePackStock to handle the update
            $result = $this->updatePackStock(
                $vendorProductId,
                $packId,
                $stockChange,
                $reason
            );

            return $result;

        } catch (Exception $e) {
            Log::error('Unexpected error in processInventoryTransaction', [
                'transaction_data' => $transactionData,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return StockUpdateResult::failure(
                'Unexpected error: ' . $e->getMessage(),
                ['error' => $e->getMessage()]
            );
        }
    }

    /**
     * Validate stock consistency across all packages
     * 
     * @param int $vendorProductId
     * @return ConsistencyCheckResult
     */
    public function validateStockConsistency(int $vendorProductId): ConsistencyCheckResult
    {
        try {
            // Load vendor product
            $vendorProduct = DB::table('vendor_products')
                ->where('id', $vendorProductId)
                ->first();

            if ($vendorProduct === null) {
                Log::warning('Vendor product not found for consistency check', [
                    'vendor_product_id' => $vendorProductId
                ]);
                return ConsistencyCheckResult::consistent(0.0);
            }

            // Parse packs
            try {
                $packs = $this->packJsonManager->parsePacks($vendorProduct->packs);
            } catch (Exception $e) {
                Log::error('Failed to parse packs for consistency check', [
                    'vendor_product_id' => $vendorProductId,
                    'error' => $e->getMessage()
                ]);
                return ConsistencyCheckResult::consistent(0.0);
            }

            if (empty($packs)) {
                return ConsistencyCheckResult::consistent(0.0);
            }

            // Calculate conversion factors for all packs
            foreach ($packs as $pack) {
                try {
                    $pack->conversionFactor = $this->unitConverter->calculateConversionFactor(
                        $pack->packSize,
                        $pack->packUnit
                    );
                } catch (\InvalidArgumentException $e) {
                    Log::warning('Failed to calculate conversion factor for pack', [
                        'vendor_product_id' => $vendorProductId,
                        'pack_id' => $pack->packId,
                        'error' => $e->getMessage()
                    ]);
                    // Set to 0 to mark as invalid
                    $pack->conversionFactor = 0;
                }
            }

            // Use PackSynchronizer to validate consistency
            $result = $this->packSynchronizer->validateStockConsistency($packs);

            // Log inconsistencies if found
            if (!$result->isConsistent) {
                $this->stockAuditLogger->logConsistencyError(
                    $vendorProductId,
                    $result->inconsistencies
                );
            }

            return $result;

        } catch (Exception $e) {
            Log::error('Unexpected error in validateStockConsistency', [
                'vendor_product_id' => $vendorProductId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);

            return ConsistencyCheckResult::consistent(0.0);
        }
    }
}
