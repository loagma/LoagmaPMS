<?php

namespace App\ValueObjects;

/**
 * ConsistencyCheckResult Value Object
 * 
 * Represents the result of a stock consistency validation.
 */
class ConsistencyCheckResult
{
    public bool $isConsistent;
    public array $inconsistencies;
    public float $referenceBaseUnits;

    public function __construct(
        bool $isConsistent,
        array $inconsistencies,
        float $referenceBaseUnits
    ) {
        $this->isConsistent = $isConsistent;
        $this->inconsistencies = $inconsistencies;
        $this->referenceBaseUnits = $referenceBaseUnits;
    }

    /**
     * Create a consistent result
     */
    public static function consistent(float $referenceBaseUnits): self
    {
        return new self(
            isConsistent: true,
            inconsistencies: [],
            referenceBaseUnits: $referenceBaseUnits
        );
    }

    /**
     * Create an inconsistent result
     */
    public static function inconsistent(array $inconsistencies, float $referenceBaseUnits): self
    {
        return new self(
            isConsistent: false,
            inconsistencies: $inconsistencies,
            referenceBaseUnits: $referenceBaseUnits
        );
    }

    /**
     * Convert to array for JSON serialization
     */
    public function toArray(): array
    {
        return [
            'is_consistent' => $this->isConsistent,
            'inconsistencies' => $this->inconsistencies,
            'reference_base_units' => $this->referenceBaseUnits,
        ];
    }
}
