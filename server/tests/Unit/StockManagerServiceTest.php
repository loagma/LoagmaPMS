<?php

namespace Tests\Unit;

use App\Services\StockManagerService;
use App\Services\UnitConverter;
use App\Services\PackSynchronizer;
use App\Services\PackJsonManager;
use App\Services\ProductStockAggregator;
use App\Services\StockAuditLogger;
use App\ValueObjects\StockUpdateResult;
use App\ValueObjects\ConsistencyCheckResult;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class StockManagerServiceTest extends TestCase
{
    private StockManagerService $service;

    protected function setUp(): void
    {
        parent::setUp();
        
        // Create service with dependencies
        $unitConverter = new UnitConverter();
        $packSynchronizer = new PackSynchronizer($unitConverter);
        $packJsonManager = new PackJsonManager();
        $productStockAggregator = new ProductStockAggregator($unitConverter, $packJsonManager);
        $stockAuditLogger = new StockAuditLogger();
        
        $this->service = new StockManagerService(
            $unitConverter,
            $packSynchronizer,
            $packJsonManager,
            $productStockAggregator,
            $stockAuditLogger
        );
    }

    /** @test */
    public function it_can_be_instantiated()
    {
        $this->assertInstanceOf(StockManagerService::class, $this->service);
    }

    /** @test */
    public function it_processes_inventory_transaction_with_missing_fields()
    {
        $result = $this->service->processInventoryTransaction([
            'vendor_product_id' => 1,
            // Missing pack_id and quantity
        ]);

        $this->assertInstanceOf(StockUpdateResult::class, $result);
        $this->assertFalse($result->success);
        $this->assertStringContainsString('Missing required', $result->message);
    }
}
