<?php

namespace App\Services;

use App\ValueObjects\Pack;
use Exception;
use Illuminate\Support\Facades\Log;

/**
 * PackJsonManager Service
 * 
 * Handles parsing and serialization of pack data in JSON format.
 * Maintains backward compatibility with existing JSON structure.
 */
class PackJsonManager
{
    /**
     * Parse packs JSON from vendor_products
     * 
     * @param string|null $packsJson
     * @return array Array of Pack objects
     * @throws Exception When JSON is malformed
     */
    public function parsePacks(?string $packsJson): array
    {
        // Handle null or empty JSON
        if (empty($packsJson)) {
            return [];
        }

        try {
            $packsData = json_decode($packsJson, true, 512, JSON_THROW_ON_ERROR);
            
            // Handle case where JSON decodes to null or non-array
            if (!is_array($packsData)) {
                Log::warning('Pack JSON decoded to non-array value', [
                    'json' => $packsJson
                ]);
                return [];
            }

            $packs = [];
            foreach ($packsData as $packData) {
                if (!is_array($packData)) {
                    Log::warning('Invalid pack data in JSON, skipping', [
                        'pack_data' => $packData
                    ]);
                    continue;
                }

                $packs[] = Pack::fromArray($packData);
            }

            return $packs;
        } catch (\JsonException $e) {
            Log::error('Failed to parse pack JSON', [
                'json' => $packsJson,
                'error' => $e->getMessage()
            ]);
            throw new Exception('Malformed pack JSON: ' . $e->getMessage());
        }
    }

    /**
     * Serialize packs to JSON
     * 
     * @param array $packs Array of Pack objects
     * @return string JSON string
     */
    public function serializePacks(array $packs): string
    {
        $packsData = [];
        foreach ($packs as $pack) {
            if ($pack instanceof Pack) {
                $packsData[] = $pack->toArray();
            }
        }

        return json_encode($packsData, JSON_THROW_ON_ERROR);
    }

    /**
     * Update stock values in pack array
     * 
     * @param array $packs Array of Pack objects
     * @param array $stockUpdates Array of [packId => newStock]
     * @return array Updated packs array
     */
    public function updatePackStocks(array $packs, array $stockUpdates): array
    {
        foreach ($packs as $pack) {
            if ($pack instanceof Pack && isset($stockUpdates[$pack->packId])) {
                $pack->stock = $stockUpdates[$pack->packId];
                // Update in_stock status based on new stock level
                $pack->inStock = $pack->stock > 0 ? 1 : 0;
            }
        }

        return $packs;
    }

    /**
     * Update in_stock status based on stock level
     * 
     * @param array $pack Pack array (not Pack object)
     * @return array Updated pack with in_stk field
     */
    public function updateInStockStatus(array $pack): array
    {
        $stock = $pack['stk'] ?? 0;
        $pack['in_stk'] = $stock > 0 ? 1 : 0;
        
        return $pack;
    }
}
