<?php

namespace App\ValueObjects;

/**
 * Pack Value Object
 * 
 * Represents a package with its stock and pricing information.
 * Maps to the JSON structure in vendor_products.packs field.
 */
class Pack
{
    public string $packId;           // pi field
    public string $packSize;         // ps field
    public string $packUnit;         // pu field
    public float $stock;             // stk field
    public int $inStock;             // in_stk field (0 or 1)
    public string $tax;              // tx field
    public string $originalPrice;    // op field
    public string $retailPrice;      // rp field
    public int $serialNumber;        // sn field
    public float $conversionFactor;  // calculated

    public function __construct(
        string $packId,
        string $packSize,
        string $packUnit,
        float $stock,
        int $inStock,
        string $tax,
        string $originalPrice,
        string $retailPrice,
        int $serialNumber,
        float $conversionFactor = 0.0
    ) {
        $this->packId = $packId;
        $this->packSize = $packSize;
        $this->packUnit = $packUnit;
        $this->stock = $stock;
        $this->inStock = $inStock;
        $this->tax = $tax;
        $this->originalPrice = $originalPrice;
        $this->retailPrice = $retailPrice;
        $this->serialNumber = $serialNumber;
        $this->conversionFactor = $conversionFactor;
    }

    /**
     * Create Pack from JSON array
     */
    public static function fromArray(array $data): self
    {
        return new self(
            packId: $data['pi'] ?? '',
            packSize: $data['ps'] ?? '',
            packUnit: $data['pu'] ?? '',
            stock: (float) ($data['stk'] ?? 0),
            inStock: (int) ($data['in_stk'] ?? 0),
            tax: $data['tx'] ?? '',
            originalPrice: $data['op'] ?? '',
            retailPrice: $data['rp'] ?? '',
            serialNumber: (int) ($data['sn'] ?? 0),
            conversionFactor: (float) ($data['conversion_factor'] ?? 0.0)
        );
    }

    /**
     * Convert Pack to JSON array
     */
    public function toArray(): array
    {
        return [
            'pi' => $this->packId,
            'ps' => $this->packSize,
            'pu' => $this->packUnit,
            'stk' => $this->stock,
            'in_stk' => $this->inStock,
            'tx' => $this->tax,
            'op' => $this->originalPrice,
            'rp' => $this->retailPrice,
            'sn' => $this->serialNumber,
        ];
    }
}
