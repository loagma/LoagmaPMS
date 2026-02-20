<?php

namespace App\ValueObjects;

/**
 * PackStockUpdate Value Object
 * 
 * Represents a stock update for a single package.
 */
class PackStockUpdate
{
    public string $packId;
    public float $oldStock;
    public float $newStock;
    public float $change;

    public function __construct(
        string $packId,
        float $oldStock,
        float $newStock,
        float $change
    ) {
        $this->packId = $packId;
        $this->oldStock = $oldStock;
        $this->newStock = $newStock;
        $this->change = $change;
    }

    /**
     * Convert to array for JSON serialization
     */
    public function toArray(): array
    {
        return [
            'pack_id' => $this->packId,
            'old_stock' => $this->oldStock,
            'new_stock' => $this->newStock,
            'change' => $this->change,
        ];
    }
}
