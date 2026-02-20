<?php

namespace Tests\Unit;

use App\Services\PackSynchronizer;
use App\Services\UnitConverter;
use App\ValueObjects\Pack;
use App\ValueObjects\PackStockUpdate;
use App\ValueObjects\ConsistencyCheckResult;
use Tests\TestCase;

class PackSynchronizerTest extends TestCase
{
    private PackSynchronizer $synchronizer;
    private UnitConverter $unitConverter;

    protected function setUp(): void
    {
        parent::setUp();
        $this->unitConverter = new UnitConverter();
        $this->synchronizer = new PackSynchronizer($this->unitConverter);
    }

    /** @test */
    public function it_synchronizes_stock_across_packages_proportionally()
    {
        // Create packages: 10kg and 5kg
        $pack10kg = new Pack(
            packId: 'pack1',
            packSize: '10',
            packUnit: 'kg',
            stock: 10.0,
            inStock: 1,
            tax: '5%',
            originalPrice: '200',
            retailPrice: '240',
            serialNumber: 1,
            conversionFactor: 10.0
        );

        $pack5kg = new Pack(
            packId: 'pack2',
            packSize: '5',
            packUnit: 'kg',
            stock: 20.0,
            inStock: 1,
            tax: '5%',
            originalPrice: '100',
            retailPrice: '120',
            serialNumber: 2,
            conversionFactor: 5.0
        );

        $packs = [$pack10kg, $pack5kg];

        // Decrease 10kg pack by 1 unit (10 base units decrease)
        $baseUnitChange = -10.0;
        $updates = $this->synchronizer->synchronizePackages($packs, $baseUnitChange, 'pack1');

        $this->assertCount(2, $updates);
        
        // 10kg pack: 10 - 1 = 9
        $this->assertEquals('pack1', $updates[0]->packId);
        $this->assertEquals(10.0, $updates[0]->oldStock);
        $this->assertEquals(9.0, $updates[0]->newStock);
        $this->assertEquals(-1.0, $updates[0]->change);

        // 5kg pack: 20 - 2 = 18 (proportional decrease)
        $this->assertEquals('pack2', $updates[1]->packId);
        $this->assertEquals(20.0, $updates[1]->oldStock);
        $this->assertEquals(18.0, $updates[1]->newStock);
        $this->assertEquals(-2.0, $updates[1]->change);
    }

    /** @test */
    public function it_handles_stock_increase_proportionally()
    {
        // Create packages: 5kg and 1kg
        $pack5kg = new Pack(
            packId: 'pack1',
            packSize: '5',
            packUnit: 'kg',
            stock: 10.0,
            inStock: 1,
            tax: '5%',
            originalPrice: '100',
            retailPrice: '120',
            serialNumber: 1,
            conversionFactor: 5.0
        );

        $pack1kg = new Pack(
            packId: 'pack2',
            packSize: '1',
            packUnit: 'kg',
            stock: 50.0,
            inStock: 1,
            tax: '5%',
            originalPrice: '20',
            retailPrice: '25',
            serialNumber: 2,
            conversionFactor: 1.0
        );

        $packs = [$pack5kg, $pack1kg];

        // Increase 5kg pack by 2 units (10 base units increase)
        $baseUnitChange = 10.0;
        $updates = $this->synchronizer->synchronizePackages($packs, $baseUnitChange, 'pack1');

        $this->assertCount(2, $updates);
        
        // 5kg pack: 10 + 2 = 12
        $this->assertEquals(12.0, $updates[0]->newStock);
        
        // 1kg pack: 50 + 10 = 60
        $this->assertEquals(60.0, $updates[1]->newStock);
    }

    /** @test */
    public function it_skips_invalid_packages_during_synchronization()
    {
        $validPack = new Pack(
            packId: 'pack1',
            packSize: '5',
            packUnit: 'kg',
            stock: 10.0,
            inStock: 1,
            tax: '5%',
            originalPrice: '100',
            retailPrice: '120',
            serialNumber: 1,
            conversionFactor: 5.0
        );

        // Invalid pack with missing pack_size
        $invalidPack = new Pack(
            packId: 'pack2',
            packSize: '',
            packUnit: 'kg',
            stock: 20.0,
            inStock: 1,
            tax: '5%',
            originalPrice: '100',
            retailPrice: '120',
            serialNumber: 2,
            conversionFactor: 0.0
        );

        $packs = [$validPack, $invalidPack];

        $baseUnitChange = 5.0;
        $updates = $this->synchronizer->synchronizePackages($packs, $baseUnitChange, 'pack1');

        // Only valid pack should be updated
        $this->assertCount(1, $updates);
        $this->assertEquals('pack1', $updates[0]->packId);
    }

    /** @test */
    public function it_calculates_pack_stock_correctly()
    {
        $totalBaseUnits = 100.0;
        $conversionFactor = 5.0;

        $stock = $this->synchronizer->calculatePackStock($totalBaseUnits, $conversionFactor);

        $this->assertEquals(20.0, $stock);
    }

    /** @test */
    public function it_applies_rounding_for_discrete_units()
    {
        $totalBaseUnits = 10.5;
        $conversionFactor = 1.0;

        $stock = $this->synchronizer->calculatePackStock($totalBaseUnits, $conversionFactor, 'nos');

        // Should round to nearest integer for discrete units
        $this->assertEquals(11.0, $stock);
    }

    /** @test */
    public function it_validates_consistent_stock_levels()
    {
        // Create packages with consistent stock
        $pack10kg = new Pack(
            packId: 'pack1',
            packSize: '10',
            packUnit: 'kg',
            stock: 10.0,
            inStock: 1,
            tax: '5%',
            originalPrice: '200',
            retailPrice: '240',
            serialNumber: 1,
            conversionFactor: 10.0
        );

        $pack5kg = new Pack(
            packId: 'pack2',
            packSize: '5',
            packUnit: 'kg',
            stock: 20.0,
            inStock: 1,
            tax: '5%',
            originalPrice: '100',
            retailPrice: '120',
            serialNumber: 2,
            conversionFactor: 5.0
        );

        $packs = [$pack10kg, $pack5kg];

        $result = $this->synchronizer->validateStockConsistency($packs);

        $this->assertTrue($result->isConsistent);
        $this->assertEmpty($result->inconsistencies);
        $this->assertEquals(100.0, $result->referenceBaseUnits);
    }

    /** @test */
    public function it_detects_inconsistent_stock_levels()
    {
        // Create packages with inconsistent stock
        $pack10kg = new Pack(
            packId: 'pack1',
            packSize: '10',
            packUnit: 'kg',
            stock: 10.0,
            inStock: 1,
            tax: '5%',
            originalPrice: '200',
            retailPrice: '240',
            serialNumber: 1,
            conversionFactor: 10.0
        );

        $pack5kg = new Pack(
            packId: 'pack2',
            packSize: '5',
            packUnit: 'kg',
            stock: 15.0, // Should be 20.0 for consistency
            inStock: 1,
            tax: '5%',
            originalPrice: '100',
            retailPrice: '120',
            serialNumber: 2,
            conversionFactor: 5.0
        );

        $packs = [$pack10kg, $pack5kg];

        $result = $this->synchronizer->validateStockConsistency($packs);

        $this->assertFalse($result->isConsistent);
        $this->assertNotEmpty($result->inconsistencies);
        $this->assertCount(1, $result->inconsistencies);
        $this->assertEquals('pack2', $result->inconsistencies[0]['pack_id']);
    }

    /** @test */
    public function it_handles_empty_pack_array_in_consistency_check()
    {
        $result = $this->synchronizer->validateStockConsistency([]);

        $this->assertTrue($result->isConsistent);
        $this->assertEmpty($result->inconsistencies);
        $this->assertEquals(0.0, $result->referenceBaseUnits);
    }

    /** @test */
    public function it_returns_empty_updates_when_trigger_pack_not_found()
    {
        $pack = new Pack(
            packId: 'pack1',
            packSize: '5',
            packUnit: 'kg',
            stock: 10.0,
            inStock: 1,
            tax: '5%',
            originalPrice: '100',
            retailPrice: '120',
            serialNumber: 1,
            conversionFactor: 5.0
        );

        $packs = [$pack];

        $updates = $this->synchronizer->synchronizePackages($packs, 5.0, 'nonexistent');

        $this->assertEmpty($updates);
    }

    /** @test */
    public function it_tolerates_small_rounding_errors_in_consistency_check()
    {
        // Create packages with very small rounding differences
        $pack10kg = new Pack(
            packId: 'pack1',
            packSize: '10',
            packUnit: 'kg',
            stock: 10.0,
            inStock: 1,
            tax: '5%',
            originalPrice: '200',
            retailPrice: '240',
            serialNumber: 1,
            conversionFactor: 10.0
        );

        $pack5kg = new Pack(
            packId: 'pack2',
            packSize: '5',
            packUnit: 'kg',
            stock: 20.001, // Very small difference (0.005 base units)
            inStock: 1,
            tax: '5%',
            originalPrice: '100',
            retailPrice: '120',
            serialNumber: 2,
            conversionFactor: 5.0
        );

        $packs = [$pack10kg, $pack5kg];

        $result = $this->synchronizer->validateStockConsistency($packs);

        // Should be consistent due to tolerance
        $this->assertTrue($result->isConsistent);
    }

    /** @test */
    public function it_handles_gm_to_kg_conversion_in_synchronization()
    {
        $pack1kg = new Pack(
            packId: 'pack1',
            packSize: '1',
            packUnit: 'kg',
            stock: 10.0,
            inStock: 1,
            tax: '5%',
            originalPrice: '100',
            retailPrice: '120',
            serialNumber: 1,
            conversionFactor: 1.0
        );

        $pack500gm = new Pack(
            packId: 'pack2',
            packSize: '500',
            packUnit: 'gm',
            stock: 20.0,
            inStock: 1,
            tax: '5%',
            originalPrice: '50',
            retailPrice: '60',
            serialNumber: 2,
            conversionFactor: 0.5
        );

        $packs = [$pack1kg, $pack500gm];

        // Decrease 1kg pack by 1 unit (1 base unit decrease)
        $baseUnitChange = -1.0;
        $updates = $this->synchronizer->synchronizePackages($packs, $baseUnitChange, 'pack1');

        $this->assertCount(2, $updates);
        
        // 1kg pack: 10 - 1 = 9
        $this->assertEquals(9.0, $updates[0]->newStock);
        
        // 500gm pack: 20 - 2 = 18
        $this->assertEquals(18.0, $updates[1]->newStock);
    }
}

