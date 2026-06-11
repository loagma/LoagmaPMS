<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class InventoryLedgerService
{
    /**
     * Find the vendor_product row for a product.
     * If $adminVendorId supplied → match on admin_vendor_id too.
     * Otherwise returns the first active row for the product.
     */
    public function resolveVendorProduct(int $productId, ?int $adminVendorId = null): ?object
    {
        $query = DB::table('vendor_products')
            ->where('product_id', $productId)
            ->where('status', '1');

        if ($adminVendorId !== null) {
            $query->where('admin_vendor_id', $adminVendorId);
        }

        return $query->first();
    }

    /**
     * Insert one audit row into vendor_products_inventory.
     */
    public function recordLedger(
        int    $vendorProductId,
        int    $productId,
        string $packId,
        float  $quantity,
        string $unitType,
        float  $amount,
        string $actionType,
        string $invType,
        string $source,
        string $note,
        string $invDate,
        ?int   $vendorId = null,
        ?int   $tripId = null
    ): void {
        DB::table('vendor_products_inventory')->insert([
            'vendor_product_id' => $vendorProductId,
            'product_id'        => $productId,
            'action_type'       => $actionType,
            'pack_id'           => $packId,
            'vendor_id'         => $vendorId,
            'quantity'          => $quantity,
            'unit_type'         => $unitType,
            'unitquantity'      => $quantity,
            'amount'            => $amount,
            'inv_date'          => $invDate,
            'inv_type'          => $invType,
            'note'              => $note,
            'source'            => $source,
            'trip_id'           => $tripId,
            'created_at'        => now(),
            'updated_at'        => now(),
        ]);
    }

    /**
     * Apply an increase or decrease to stk on ALL packs of the given vendor_product row.
     * Updates in_stk flag and persists the packs JSON back to vendor_products.
     * Returns the pi value of the first pack (used as a fallback pack_id for purchase flows).
     * Handles both map-keyed and array-indexed packs JSON formats.
     */
    public function updatePacksStock(int $vendorProductId, float $qty, string $operation): string
    {
        $vendorProduct = DB::table('vendor_products')->where('id', $vendorProductId)->first();
        if (!$vendorProduct) {
            return '';
        }

        $packsData = json_decode((string) ($vendorProduct->packs ?? ''), true);
        if (!is_array($packsData) || empty($packsData)) {
            return '';
        }

        $firstPackPi  = '';
        $updatedPacks = [];

        foreach ($packsData as $key => $packData) {
            if (!is_array($packData)) {
                $updatedPacks[$key] = $packData;
                continue;
            }

            if (isset($packData['stk'])) {
                $currentStock = (float) $packData['stk'];
                $newStock     = $operation === 'increase'
                    ? $currentStock + $qty
                    : max(0.0, $currentStock - $qty);
                $packData['stk']    = $newStock;
                $packData['in_stk'] = $newStock > 0 ? 1 : 0;
            }

            if ($firstPackPi === '' && isset($packData['pi'])) {
                $firstPackPi = (string) $packData['pi'];
            }

            $updatedPacks[$key] = $packData;
        }

        $hasAnyStock = false;
        foreach ($updatedPacks as $pack) {
            if (is_array($pack) && isset($pack['stk']) && (float) $pack['stk'] > 0) {
                $hasAnyStock = true;
                break;
            }
        }

        DB::table('vendor_products')
            ->where('id', $vendorProductId)
            ->update([
                'packs'    => json_encode($updatedPacks),
                'in_stock' => $hasAnyStock ? '1' : '0',
            ]);

        return $firstPackPi;
    }
}
