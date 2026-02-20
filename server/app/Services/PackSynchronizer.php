<?php

namespace App\Services;

use App\ValueObjects\Pack;
use App\ValueObjects\PackStockUpdate;
use App\ValueObjects\ConsistencyCheckResult;
use Illuminate\Support\Facades\Log;

/**
 * PackSynchronizer Service
 * 
 * Synchronizes stock across all related packages for a vendor product.
 * Handles proportional stock updates based on conversion factors.
 */
class PackSynchronizer
{
    private UnitConverter $unitConverter;

    /**
     * Tolerance for rounding errors in consistency checks (0.01 base units)
     */
    private const CONSISTENCY_TOLERANCE = 0.01;

    public function __construct(UnitConverter $unitConverter)
    {
        $this->unitConverter = $unitConverter;
    }

    /**
     * Synchronize stock across all packages for a vendor product
     * 
     * @param array $packs Array of Pack objects
     * @param float $baseUnitChange Change in base units to apply
     * @param string $triggerPackId The pack that triggered the update
     * @return array Array of PackStockUpdate objects
     */
    public function synchronizePackages(array $packs, float $baseUnitChange, string $triggerPackId): array
    {
        $updates = [];
        
        // Calculate current total base units from trigger pack
        $triggerPack = $this->findPackById($packs, $triggerPackId);
        if ($triggerPack === null) {
            Log::warning('Trigger pack not found', ['pack_id' => $triggerPackId]);
            return [];
        }

        // Calculate new total base units
        $currentBaseUnits = $this->unitConverter->toBaseUnits(
            $triggerPack->stock,
            $triggerPack->conversionFactor
        );
        $newTotalBaseUnits = $currentBaseUnits + $baseUnitChange;

        // Update all packages proportionally
        foreach ($packs as $pack) {
            if (!($pack instanceof Pack)) {
                continue;
            }

            // Skip invalid packages gracefully
            if (!$this->isValidPack($pack)) {
                Log::warning('Skipping invalid package during synchronization', [
                    'pack_id' => $pack->packId,
                    'pack_size' => $pack->packSize,
                    'pack_unit' => $pack->packUnit
                ]);
                continue;
            }

            $oldStock = $pack->stock;
            
            // Calculate new stock for this package
            $newStock = $this->calculatePackStock($newTotalBaseUnits, $pack->conversionFactor, $pack->packUnit);
            
            $updates[] = new PackStockUpdate(
                packId: $pack->packId,
                oldStock: $oldStock,
                newStock: $newStock,
                change: $newStock - $oldStock
            );
        }

        return $updates;
    }

    /**
     * Calculate expected stock for a package given total base units
     * 
     * @param float $totalBaseUnits Total stock in base units
     * @param float $conversionFactor Package conversion factor
     * @param string|null $unitType Unit type for rounding discrete units
     * @return float Expected stock for the package
     */
    public function calculatePackStock(float $totalBaseUnits, float $conversionFactor, ?string $unitType = null): float
    {
        return $this->unitConverter->fromBaseUnits($totalBaseUnits, $conversionFactor, $unitType);
    }

    /**
     * Validate stock consistency across all packages
     * 
     * @param array $packs Array of Pack objects
     * @return ConsistencyCheckResult
     */
    public function validateStockConsistency(array $packs): ConsistencyCheckResult
    {
        // Filter valid packs
        $validPacks = array_filter($packs, function ($pack) {
            return $pack instanceof Pack && $this->isValidPack($pack);
        });

        if (empty($validPacks)) {
            return ConsistencyCheckResult::consistent(0.0);
        }

        // Use first valid pack as reference to calculate base units
        $referencePack = reset($validPacks);
        $referenceBaseUnits = $this->unitConverter->toBaseUnits(
            $referencePack->stock,
            $referencePack->conversionFactor
        );

        $inconsistencies = [];

        // Check each pack for consistency
        foreach ($validPacks as $pack) {
            $expectedStock = $this->calculatePackStock(
                $referenceBaseUnits,
                $pack->conversionFactor,
                $pack->packUnit
            );

            $actualStock = $pack->stock;
            $difference = abs($expectedStock - $actualStock);

            // Convert difference to base units for tolerance check
            $differenceInBaseUnits = $this->unitConverter->toBaseUnits(
                $difference,
                $pack->conversionFactor
            );

            if ($differenceInBaseUnits > self::CONSISTENCY_TOLERANCE) {
                $inconsistencies[] = [
                    'pack_id' => $pack->packId,
                    'pack_size' => $pack->packSize,
                    'pack_unit' => $pack->packUnit,
                    'expected_stock' => $expectedStock,
                    'actual_stock' => $actualStock,
                    'difference' => $difference,
                    'difference_in_base_units' => $differenceInBaseUnits
                ];
            }
        }

        if (empty($inconsistencies)) {
            return ConsistencyCheckResult::consistent($referenceBaseUnits);
        }

        return ConsistencyCheckResult::inconsistent($inconsistencies, $referenceBaseUnits);
    }

    /**
     * Find a pack by its ID
     * 
     * @param array $packs
     * @param string $packId
     * @return Pack|null
     */
    private function findPackById(array $packs, string $packId): ?Pack
    {
        foreach ($packs as $pack) {
            if ($pack instanceof Pack && $pack->packId === $packId) {
                return $pack;
            }
        }
        return null;
    }

    /**
     * Validate if a pack has required fields for synchronization
     * 
     * @param Pack $pack
     * @return bool
     */
    private function isValidPack(Pack $pack): bool
    {
        // Check for missing pack_size or pack_unit
        if (empty($pack->packSize) || empty($pack->packUnit)) {
            return false;
        }

        // Check for non-numeric pack_size
        if (!is_numeric($pack->packSize)) {
            return false;
        }

        // Check for valid conversion factor
        if ($pack->conversionFactor <= 0) {
            return false;
        }

        return true;
    }
}

