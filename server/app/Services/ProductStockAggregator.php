<?php

namespace App\Services;

use App\Models\Product;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * ProductStockAggregator Service
 * 
 * Aggregates stock from all vendor products and updates product-level stock.
 * Handles PACK_WISE and SINGLE inventory types.
 */
class ProductStockAggregator
{
    private UnitConverter $unitConverter;
    private PackJsonManager $packJsonManager;

    public function __construct(UnitConverter $unitConverter, PackJsonManager $packJsonManager)
    {
        $this->unitConverter = $unitConverter;
        $this->packJsonManager = $packJsonManager;
    }

    /**
     * Update product-level stock from all vendor products
     * 
     * @param int $productId
     * @return void
     */
    public function updateProductStock(int $productId): void
    {
        // Load product
        $product = Product::find($productId);
        
        if ($product === null) {
            Log::warning('Product not found for stock aggregation', ['product_id' => $productId]);
            return;
        }

        // Check inventory type
        if ($product->inventory_type === 'SINGLE') {
            // For SINGLE inventory type, no aggregation needed
            Log::debug('Product has SINGLE inventory type, skipping aggregation', ['product_id' => $productId]);
            return;
        }

        // For PACK_WISE inventory type, calculate total stock
        $totalStock = $this->calculateTotalStock($productId);

        // Update product stock
        $product->stock = $totalStock;
        $product->save();

        Log::info('Product stock updated', [
            'product_id' => $productId,
            'total_stock' => $totalStock,
            'inventory_unit_type' => $product->inventory_unit_type
        ]);
    }

    /**
     * Calculate total stock in base units for a product
     * 
     * @param int $productId
     * @return float
     */
    public function calculateTotalStock(int $productId): float
    {
        // Load product to get inventory_unit_type
        $product = Product::find($productId);
        
        if ($product === null) {
            Log::warning('Product not found for stock calculation', ['product_id' => $productId]);
            return 0.0;
        }

        // Get base unit for the product's inventory unit type
        try {
            $baseUnit = $this->unitConverter->getBaseUnit($product->inventory_unit_type);
        } catch (\InvalidArgumentException $e) {
            Log::error('Invalid inventory unit type for product', [
                'product_id' => $productId,
                'inventory_unit_type' => $product->inventory_unit_type,
                'error' => $e->getMessage()
            ]);
            return 0.0;
        }

        // Load all vendor products for this product
        $vendorProducts = DB::table('vendor_products')
            ->where('product_id', $productId)
            ->where('status', '1')
            ->get();

        $totalBaseUnits = 0.0;

        foreach ($vendorProducts as $vendorProduct) {
            // Parse packs JSON
            try {
                $packs = $this->packJsonManager->parsePacks($vendorProduct->packs);
            } catch (\Exception $e) {
                Log::warning('Failed to parse packs for vendor product', [
                    'vendor_product_id' => $vendorProduct->id,
                    'error' => $e->getMessage()
                ]);
                continue;
            }

            // Sum stock in base units for all packs
            foreach ($packs as $pack) {
                // Skip invalid packs
                if (!$this->isValidPack($pack)) {
                    continue;
                }

                // Convert pack stock to base units
                try {
                    $packBaseUnits = $this->unitConverter->toBaseUnits(
                        $pack->stock,
                        $pack->conversionFactor
                    );
                    $totalBaseUnits += $packBaseUnits;
                } catch (\Exception $e) {
                    Log::warning('Failed to convert pack stock to base units', [
                        'vendor_product_id' => $vendorProduct->id,
                        'pack_id' => $pack->packId,
                        'error' => $e->getMessage()
                    ]);
                    continue;
                }
            }
        }

        return $totalBaseUnits;
    }

    /**
     * Validate if a pack has required fields for stock calculation
     * 
     * @param mixed $pack
     * @return bool
     */
    private function isValidPack($pack): bool
    {
        // Check if pack is an object with required properties
        if (!is_object($pack)) {
            return false;
        }

        // Check for missing pack_size or pack_unit
        if (!isset($pack->packSize) || !isset($pack->packUnit)) {
            return false;
        }

        if (empty($pack->packSize) || empty($pack->packUnit)) {
            return false;
        }

        // Check for non-numeric pack_size
        if (!is_numeric($pack->packSize)) {
            return false;
        }

        // Check for valid conversion factor
        if (!isset($pack->conversionFactor) || $pack->conversionFactor <= 0) {
            return false;
        }

        // Check for valid stock
        if (!isset($pack->stock)) {
            return false;
        }

        return true;
    }
}
