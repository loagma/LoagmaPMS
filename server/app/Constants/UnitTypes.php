<?php

namespace App\Constants;

/**
 * UnitTypes Constants
 * 
 * Defines all supported unit types for package stock management.
 * Based on Requirement 2.5.
 */
class UnitTypes
{
    // Weight units
    public const KG = 'kg';
    public const GM = 'gm';
    
    // Volume units
    public const LITRE = 'litre';
    public const ML = 'ml';
    
    // Count/discrete units
    public const NOS = 'Nos';
    public const PIECE = 'piece';
    public const PACK = 'pack';
    public const DOZEN = 'dozen';
    public const BOX = 'box';
    public const BAG = 'bag';
    public const BUNCH = 'bunch';
    public const TIN = 'tin';
    public const POUCH = 'pouch';
    public const CS = 'cs';
    public const BARREL = 'barrel';
    public const JAR = 'jar';

    /**
     * All supported unit types
     */
    public const ALL_UNITS = [
        self::KG,
        self::GM,
        self::LITRE,
        self::ML,
        self::NOS,
        self::PIECE,
        self::PACK,
        self::DOZEN,
        self::BOX,
        self::BAG,
        self::BUNCH,
        self::TIN,
        self::POUCH,
        self::CS,
        self::BARREL,
        self::JAR,
    ];

    /**
     * Weight unit types
     */
    public const WEIGHT_UNITS = [
        self::KG,
        self::GM,
    ];

    /**
     * Volume unit types
     */
    public const VOLUME_UNITS = [
        self::LITRE,
        self::ML,
    ];

    /**
     * Discrete/count unit types (require rounding)
     */
    public const DISCRETE_UNITS = [
        self::NOS,
        self::PIECE,
        self::PACK,
        self::DOZEN,
        self::BOX,
        self::BAG,
        self::BUNCH,
        self::TIN,
        self::POUCH,
        self::CS,
        self::BARREL,
        self::JAR,
    ];

    /**
     * Base units for each unit category
     */
    public const BASE_UNITS = [
        'weight' => self::KG,
        'volume' => self::LITRE,
    ];

    /**
     * Check if a unit type is supported
     */
    public static function isSupported(string $unitType): bool
    {
        return in_array($unitType, self::ALL_UNITS, true);
    }

    /**
     * Check if a unit type is discrete (requires rounding)
     */
    public static function isDiscrete(string $unitType): bool
    {
        return in_array($unitType, self::DISCRETE_UNITS, true);
    }

    /**
     * Check if a unit type is a weight unit
     */
    public static function isWeight(string $unitType): bool
    {
        return in_array($unitType, self::WEIGHT_UNITS, true);
    }

    /**
     * Check if a unit type is a volume unit
     */
    public static function isVolume(string $unitType): bool
    {
        return in_array($unitType, self::VOLUME_UNITS, true);
    }
}
