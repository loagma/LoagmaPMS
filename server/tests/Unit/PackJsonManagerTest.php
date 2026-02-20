<?php

namespace Tests\Unit;

use App\Services\PackJsonManager;
use App\ValueObjects\Pack;
use Exception;
use Tests\TestCase;

class PackJsonManagerTest extends TestCase
{
    private PackJsonManager $manager;

    protected function setUp(): void
    {
        parent::setUp();
        $this->manager = new PackJsonManager();
    }

    /** @test */
    public function it_parses_valid_json_to_pack_objects()
    {
        $json = '[
            {
                "pi": "pack1",
                "ps": "5",
                "pu": "kg",
                "stk": 10.0,
                "in_stk": 1,
                "tx": "5%",
                "op": "100",
                "rp": "120",
                "sn": 1
            }
        ]';

        $packs = $this->manager->parsePacks($json);

        $this->assertCount(1, $packs);
        $this->assertInstanceOf(Pack::class, $packs[0]);
        $this->assertEquals('pack1', $packs[0]->packId);
        $this->assertEquals('5', $packs[0]->packSize);
        $this->assertEquals('kg', $packs[0]->packUnit);
        $this->assertEquals(10.0, $packs[0]->stock);
        $this->assertEquals(1, $packs[0]->inStock);
    }

    /** @test */
    public function it_returns_empty_array_for_null_json()
    {
        $packs = $this->manager->parsePacks(null);
        $this->assertIsArray($packs);
        $this->assertEmpty($packs);
    }

    /** @test */
    public function it_returns_empty_array_for_empty_string()
    {
        $packs = $this->manager->parsePacks('');
        $this->assertIsArray($packs);
        $this->assertEmpty($packs);
    }

    /** @test */
    public function it_throws_exception_for_malformed_json()
    {
        $this->expectException(Exception::class);
        $this->expectExceptionMessage('Malformed pack JSON');
        
        $this->manager->parsePacks('{"invalid": json}');
    }

    /** @test */
    public function it_handles_empty_json_array()
    {
        $packs = $this->manager->parsePacks('[]');
        $this->assertIsArray($packs);
        $this->assertEmpty($packs);
    }

    /** @test */
    public function it_serializes_packs_to_json()
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
            serialNumber: 1
        );

        $json = $this->manager->serializePacks([$pack]);
        $decoded = json_decode($json, true);

        $this->assertIsArray($decoded);
        $this->assertCount(1, $decoded);
        $this->assertEquals('pack1', $decoded[0]['pi']);
        $this->assertEquals('5', $decoded[0]['ps']);
        $this->assertEquals('kg', $decoded[0]['pu']);
        $this->assertEquals(10.0, $decoded[0]['stk']);
        $this->assertEquals(1, $decoded[0]['in_stk']);
    }

    /** @test */
    public function it_updates_pack_stocks()
    {
        $pack1 = new Pack(
            packId: 'pack1',
            packSize: '5',
            packUnit: 'kg',
            stock: 10.0,
            inStock: 1,
            tax: '5%',
            originalPrice: '100',
            retailPrice: '120',
            serialNumber: 1
        );

        $pack2 = new Pack(
            packId: 'pack2',
            packSize: '1',
            packUnit: 'kg',
            stock: 50.0,
            inStock: 1,
            tax: '5%',
            originalPrice: '20',
            retailPrice: '25',
            serialNumber: 2
        );

        $packs = [$pack1, $pack2];
        $stockUpdates = [
            'pack1' => 15.0,
            'pack2' => 75.0
        ];

        $updatedPacks = $this->manager->updatePackStocks($packs, $stockUpdates);

        $this->assertEquals(15.0, $updatedPacks[0]->stock);
        $this->assertEquals(1, $updatedPacks[0]->inStock);
        $this->assertEquals(75.0, $updatedPacks[1]->stock);
        $this->assertEquals(1, $updatedPacks[1]->inStock);
    }

    /** @test */
    public function it_preserves_all_fields_when_updating_stock()
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
            serialNumber: 1
        );

        $packs = [$pack];
        $stockUpdates = ['pack1' => 20.0];

        $updatedPacks = $this->manager->updatePackStocks($packs, $stockUpdates);

        // Verify all fields are preserved
        $this->assertEquals('pack1', $updatedPacks[0]->packId);
        $this->assertEquals('5', $updatedPacks[0]->packSize);
        $this->assertEquals('kg', $updatedPacks[0]->packUnit);
        $this->assertEquals('5%', $updatedPacks[0]->tax);
        $this->assertEquals('100', $updatedPacks[0]->originalPrice);
        $this->assertEquals('120', $updatedPacks[0]->retailPrice);
        $this->assertEquals(1, $updatedPacks[0]->serialNumber);
        // Only stock should change
        $this->assertEquals(20.0, $updatedPacks[0]->stock);
    }

    /** @test */
    public function it_sets_in_stock_to_zero_when_stock_is_zero()
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
            serialNumber: 1
        );

        $packs = [$pack];
        $stockUpdates = ['pack1' => 0.0];

        $updatedPacks = $this->manager->updatePackStocks($packs, $stockUpdates);

        $this->assertEquals(0.0, $updatedPacks[0]->stock);
        $this->assertEquals(0, $updatedPacks[0]->inStock);
    }

    /** @test */
    public function it_sets_in_stock_to_zero_when_stock_is_negative()
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
            serialNumber: 1
        );

        $packs = [$pack];
        $stockUpdates = ['pack1' => -5.0];

        $updatedPacks = $this->manager->updatePackStocks($packs, $stockUpdates);

        $this->assertEquals(-5.0, $updatedPacks[0]->stock);
        $this->assertEquals(0, $updatedPacks[0]->inStock);
    }

    /** @test */
    public function it_sets_in_stock_to_one_when_stock_is_positive()
    {
        $pack = new Pack(
            packId: 'pack1',
            packSize: '5',
            packUnit: 'kg',
            stock: 0.0,
            inStock: 0,
            tax: '5%',
            originalPrice: '100',
            retailPrice: '120',
            serialNumber: 1
        );

        $packs = [$pack];
        $stockUpdates = ['pack1' => 5.0];

        $updatedPacks = $this->manager->updatePackStocks($packs, $stockUpdates);

        $this->assertEquals(5.0, $updatedPacks[0]->stock);
        $this->assertEquals(1, $updatedPacks[0]->inStock);
    }

    /** @test */
    public function it_updates_in_stock_status_for_array()
    {
        $pack = [
            'pi' => 'pack1',
            'ps' => '5',
            'pu' => 'kg',
            'stk' => 10.0,
            'in_stk' => 1,
            'tx' => '5%',
            'op' => '100',
            'rp' => '120',
            'sn' => 1
        ];

        $updatedPack = $this->manager->updateInStockStatus($pack);
        $this->assertEquals(1, $updatedPack['in_stk']);

        // Test with zero stock
        $pack['stk'] = 0;
        $updatedPack = $this->manager->updateInStockStatus($pack);
        $this->assertEquals(0, $updatedPack['in_stk']);

        // Test with negative stock
        $pack['stk'] = -5;
        $updatedPack = $this->manager->updateInStockStatus($pack);
        $this->assertEquals(0, $updatedPack['in_stk']);
    }

    /** @test */
    public function it_parses_multiple_packs_from_json()
    {
        $json = '[
            {
                "pi": "pack1",
                "ps": "5",
                "pu": "kg",
                "stk": 10.0,
                "in_stk": 1,
                "tx": "5%",
                "op": "100",
                "rp": "120",
                "sn": 1
            },
            {
                "pi": "pack2",
                "ps": "1",
                "pu": "kg",
                "stk": 50.0,
                "in_stk": 1,
                "tx": "5%",
                "op": "20",
                "rp": "25",
                "sn": 2
            }
        ]';

        $packs = $this->manager->parsePacks($json);

        $this->assertCount(2, $packs);
        $this->assertEquals('pack1', $packs[0]->packId);
        $this->assertEquals('pack2', $packs[1]->packId);
    }

    /** @test */
    public function it_serializes_empty_pack_array()
    {
        $json = $this->manager->serializePacks([]);
        $this->assertEquals('[]', $json);
    }

    /** @test */
    public function it_round_trips_pack_data()
    {
        $originalJson = '[
            {
                "pi": "pack1",
                "ps": "5",
                "pu": "kg",
                "stk": 10.0,
                "in_stk": 1,
                "tx": "5%",
                "op": "100",
                "rp": "120",
                "sn": 1
            }
        ]';

        $packs = $this->manager->parsePacks($originalJson);
        $serializedJson = $this->manager->serializePacks($packs);
        $decoded = json_decode($serializedJson, true);
        $original = json_decode($originalJson, true);

        // Compare the essential fields (excluding conversion_factor which isn't serialized)
        $this->assertEquals($original[0]['pi'], $decoded[0]['pi']);
        $this->assertEquals($original[0]['ps'], $decoded[0]['ps']);
        $this->assertEquals($original[0]['pu'], $decoded[0]['pu']);
        $this->assertEquals($original[0]['stk'], $decoded[0]['stk']);
        $this->assertEquals($original[0]['in_stk'], $decoded[0]['in_stk']);
    }
}
