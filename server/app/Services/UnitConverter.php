<?php

namespace App\Services;

class UnitConverter
{
    /**
     * Supported unit types and their base units
     */
    private const UNIT_BASE_MAP = [
        'kg' => 'kg',
        'gm' => 'kg',
        'litre' => 'litre',
        'ml' => 'litre',
        'nos' => 'nos',
        'pack' => 'pack',
        'dozen' => 'dozen',
        'box' => 'box',
        'bag' => 'bag',
        'piece' => 'piece',
        'bunch' => 'bunch',
        'tin' => 'tin',
        'pouch' => 'pouch',
        'cs' => 'cs',
        'barrel' => 'barrel',
        'jar' => 'jar',
    ];

    /**
     * Discrete unit types that require rounding
     */
    private const DISCRETE_UNITS = [
        'nos', 'pack', 'dozen', 'box', 'bag', 'piece', 'bunch', 'tin', 'pouch', 'cs', 'barrel', 'jar'
    ];

    /**
     * Unit conversion factors to base units
     */
    private const UNIT_TO_BASE_FACTOR = [
        'gm' => 0.001,  // 1 gm = 0.001 kg
        'ml' => 0.001,  // 1 ml = 0.001 litre
    ];

    /**
     * Calculate conversion factor for a package
     * 
     * @param string $packSize (e.g., "5", "500")
     * @param string $packUnit (e.g., "kg", "gm", "nos")
     * @return float
     */
    public function calculateConversionFactor(string $packSize, string $packUnit): float
    {
        // Parse numeric value from pack_size
        $numericSize = floatval($packSize);
        
        if ($numericSize <= 0) {
            throw new \InvalidArgumentException("Invalid pack_size: {$packSize}");
        }

        // Normalize unit to lowercase
        $unit = strtolower(trim($packUnit));
        
        if (!isset(self::UNIT_BASE_MAP[$unit])) {
            throw new \InvalidArgumentException("Unsupported pack_unit: {$packUnit}");
        }

        // If unit needs conversion to base unit (gm to kg, ml to litre)
        if (isset(self::UNIT_TO_BASE_FACTOR[$unit])) {
            return $numericSize * self::UNIT_TO_BASE_FACTOR[$unit];
        }

        // Otherwise, the numeric size is the conversion factor
        return $numericSize;
    }

    /**
     * Get base unit for a unit type
     * 
     * @param string $unitType
     * @return string
     */
    public function getBaseUnit(string $unitType): string
    {
        $unit = strtolower(trim($unitType));
        
        if (!isset(self::UNIT_BASE_MAP[$unit])) {
            throw new \InvalidArgumentException("Unsupported unit type: {$unitType}");
        }

        return self::UNIT_BASE_MAP[$unit];
    }

    /**
     * Convert quantity to base units
     * 
     * @param float $quantity
     * @param float $conversionFactor
     * @return float
     */
    public function toBaseUnits(float $quantity, float $conversionFactor): float
    {
        return $quantity * $conversionFactor;
    }

    /**
     * Convert base units to package quantity
     * 
     * @param float $baseUnits
     * @param float $conversionFactor
     * @param string|null $unitType Optional unit type for rounding discrete units
     * @return float
     */
    public function fromBaseUnits(float $baseUnits, float $conversionFactor, ?string $unitType = null): float
    {
        if ($conversionFactor == 0) {
            throw new \InvalidArgumentException("Conversion factor cannot be zero");
        }

        $quantity = $baseUnits / $conversionFactor;

        // Apply rounding for discrete unit types
        if ($unitType !== null && $this->isDiscreteUnit($unitType)) {
            return round($quantity);
        }

        return $quantity;
    }

    /**
     * Check if a unit type is discrete (requires rounding)
     * 
     * @param string $unitType
     * @return bool
     */
    private function isDiscreteUnit(string $unitType): bool
    {
        $unit = strtolower(trim($unitType));
        return in_array($unit, self::DISCRETE_UNITS);
    }
}
