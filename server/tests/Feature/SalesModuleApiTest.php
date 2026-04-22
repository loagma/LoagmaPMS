<?php

namespace Tests\Feature;

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class SalesModuleApiTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        $this->createLegacySalesTables();
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('sales_invoices');
        Schema::dropIfExists('orders_item');
        Schema::dropIfExists('orders');
        Schema::dropIfExists('product');

        parent::tearDown();
    }

    public function test_sales_order_update_preserves_existing_item_id(): void
    {
        $this->seedProduct(101);
        $this->seedProduct(102);

        $createResponse = $this->postJson('/api/sales-orders', [
            'buyer_userid' => 10,
            'order_date' => '2026-04-20',
            'order_state' => 'registered',
            'payment_status' => 'not_paid',
            'payment_method' => 'cod',
            'items' => [
                [
                    'product_id' => 101,
                    'quantity' => 2,
                    'qty_loaded' => 0,
                    'qty_delivered' => 0,
                    'qty_returned' => 0,
                    'item_price' => 100,
                    'item_total' => 200,
                ],
            ],
        ]);

        $createResponse->assertOk();

        $orderId = (int) $createResponse->json('data.order_id');
        $existingItemId = (int) DB::table('orders_item')
            ->where('order_id', $orderId)
            ->value('item_id');

        $updateResponse = $this->putJson("/api/sales-orders/{$orderId}", [
            'buyer_userid' => 10,
            'order_date' => '2026-04-21',
            'order_state' => 'registered',
            'payment_status' => 'pending',
            'payment_method' => 'online',
            'items' => [
                [
                    'item_id' => $existingItemId,
                    'product_id' => 101,
                    'quantity' => 3,
                    'qty_loaded' => 1,
                    'qty_delivered' => 0,
                    'qty_returned' => 0,
                    'item_price' => 100,
                    'item_total' => 300,
                ],
                [
                    'product_id' => 102,
                    'quantity' => 1,
                    'qty_loaded' => 0,
                    'qty_delivered' => 0,
                    'qty_returned' => 0,
                    'item_price' => 50,
                    'item_total' => 50,
                ],
            ],
        ]);

        $updateResponse->assertOk();

        $this->assertDatabaseHas('orders_item', [
            'order_id' => $orderId,
            'item_id' => $existingItemId,
            'product_id' => 101,
            'quantity' => 3,
        ]);

        $this->assertDatabaseHas('orders_item', [
            'order_id' => $orderId,
            'product_id' => 102,
            'quantity' => 1,
        ]);

        $this->assertSame(2, DB::table('orders_item')->where('order_id', $orderId)->count());
    }

    public function test_sales_return_requires_item_id_when_product_rows_are_duplicated(): void
    {
        $this->seedProduct(201);
        $this->seedOrderWithItems(500, [
            [
                'item_id' => 1,
                'product_id' => 201,
                'quantity' => 2,
                'item_price' => 25,
                'item_total' => 50,
            ],
            [
                'item_id' => 2,
                'product_id' => 201,
                'quantity' => 3,
                'item_price' => 25,
                'item_total' => 75,
            ],
        ]);

        $response = $this->postJson('/api/sales-returns', [
            'order_id' => 500,
            'return_date' => '2026-04-20',
            'return_status' => 'POSTED',
            'items' => [
                [
                    'product_id' => 201,
                    'original_qty' => 2,
                    'return_qty' => 1,
                    'refund_amount' => 25,
                ],
            ],
        ]);

        $response->assertStatus(422);
        $response->assertJsonValidationErrors(['items']);
    }

    public function test_sales_return_store_updates_qty_without_overwriting_order_header(): void
    {
        $this->seedProduct(301);
        $this->seedOrderWithItems(700, [
            [
                'item_id' => 11,
                'product_id' => 301,
                'quantity' => 4,
                'item_price' => 30,
                'item_total' => 120,
            ],
        ], [
            'short_datetime' => '2026-01-05',
            'feedback' => 'Keep original remarks',
            'last_update_time' => 1713523200,
        ]);

        $response = $this->postJson('/api/sales-returns', [
            'order_id' => 700,
            'return_date' => '2026-04-20',
            'return_status' => 'POSTED',
            'reason' => 'Damaged',
            'items' => [
                [
                    'item_id' => 11,
                    'product_id' => 301,
                    'original_qty' => 4,
                    'return_qty' => 1,
                    'refund_amount' => 30,
                ],
            ],
        ]);

        $response->assertOk();

        $this->assertDatabaseHas('orders', [
            'order_id' => 700,
            'short_datetime' => '2026-01-05',
            'feedback' => 'Keep original remarks',
        ]);

        $this->assertDatabaseHas('orders_item', [
            'order_id' => 700,
            'item_id' => 11,
            'qty_returned' => 1,
        ]);
    }

    public function test_sales_invoice_store_works_against_existing_order(): void
    {
        $this->seedOrderWithItems(900, []);

        $response = $this->postJson('/api/sales-invoices', [
            'invoice_no' => 'INV-900',
            'order_id' => 900,
            'invoice_date' => '2026-04-20',
            'invoice_status' => 'DRAFT',
            'payment_status' => 'PENDING',
            'subtotal' => 100,
            'discount_total' => 0,
            'delivery_charge' => 0,
            'tax_total' => 5,
            'grand_total' => 105,
        ]);

        $response->assertCreated();

        $this->assertDatabaseHas('sales_invoices', [
            'invoice_no' => 'INV-900',
            'order_id' => 900,
        ]);
    }

    private function createLegacySalesTables(): void
    {
        Schema::dropIfExists('sales_invoices');
        Schema::dropIfExists('orders_item');
        Schema::dropIfExists('orders');
        Schema::dropIfExists('product');

        Schema::create('product', function (Blueprint $table): void {
            $table->integer('product_id')->primary();
        });

        Schema::create('orders', function (Blueprint $table): void {
            $table->integer('order_id')->primary();
            $table->string('bill_number')->nullable();
            $table->integer('master_order_id')->default(0);
            $table->string('txn_id')->nullable();
            $table->integer('buyer_userid')->default(0);
            $table->integer('start_time')->default(0);
            $table->integer('last_update_time')->default(0);
            $table->string('short_datetime')->nullable();
            $table->string('order_state')->nullable();
            $table->string('payment_method')->nullable();
            $table->string('ctype_id')->nullable();
            $table->integer('items_count')->default(0);
            $table->decimal('delivery_charge', 14, 2)->default(0);
            $table->decimal('order_total', 14, 2)->default(0);
            $table->decimal('bill_amount', 14, 2)->nullable();
            $table->text('delivery_info')->nullable();
            $table->string('area_name')->nullable();
            $table->text('feedback')->nullable();
            $table->integer('admin_id')->default(0);
            $table->string('payment_status')->nullable();
            $table->text('amountReceivedInfo')->nullable();
            $table->integer('trip_id')->nullable();
            $table->decimal('discount', 14, 2)->default(0);
            $table->decimal('before_discount', 14, 2)->default(0);
            $table->string('time_slot')->nullable();
            $table->string('delivered_time')->nullable();
            $table->integer('deli_id')->nullable();
        });

        Schema::create('orders_item', function (Blueprint $table): void {
            $table->integer('item_id')->primary();
            $table->integer('order_id');
            $table->integer('product_id');
            $table->integer('vendor_product_id')->nullable();
            $table->text('pinfo')->nullable();
            $table->text('offers')->nullable();
            $table->integer('quantity')->default(0);
            $table->integer('qty_loaded')->default(0);
            $table->integer('qty_delivered')->default(0);
            $table->integer('qty_returned')->default(0);
            $table->decimal('item_price', 14, 2)->default(0);
            $table->decimal('item_total', 14, 2)->default(0);
            $table->integer('op_id')->default(0);
            $table->decimal('commission', 14, 2)->default(0);
        });

        Schema::create('sales_invoices', function (Blueprint $table): void {
            $table->id();
            $table->string('invoice_no', 50)->unique();
            $table->unsignedBigInteger('order_id');
            $table->unsignedBigInteger('customer_user_id')->nullable();
            $table->date('invoice_date');
            $table->date('due_date')->nullable();
            $table->string('invoice_status')->default('DRAFT');
            $table->string('payment_status')->default('PENDING');
            $table->decimal('subtotal', 14, 2)->default(0);
            $table->decimal('discount_total', 14, 2)->default(0);
            $table->decimal('delivery_charge', 14, 2)->default(0);
            $table->decimal('tax_total', 14, 2)->default(0);
            $table->decimal('grand_total', 14, 2)->default(0);
            $table->text('notes')->nullable();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->unsignedBigInteger('updated_by')->nullable();
            $table->timestamps();
        });
    }

    private function seedProduct(int $productId): void
    {
        DB::table('product')->insert([
            'product_id' => $productId,
        ]);
    }

    private function seedOrderWithItems(int $orderId, array $items, array $overrides = []): void
    {
        DB::table('orders')->insert(array_merge([
            'order_id' => $orderId,
            'bill_number' => null,
            'master_order_id' => 0,
            'txn_id' => 'SO-' . $orderId,
            'buyer_userid' => 1,
            'start_time' => 1713523200,
            'last_update_time' => 1713523200,
            'short_datetime' => '2026-04-20',
            'order_state' => 'registered',
            'payment_method' => 'cod',
            'ctype_id' => 'vegetables_fruits',
            'items_count' => count($items),
            'delivery_charge' => 0,
            'order_total' => 0,
            'bill_amount' => null,
            'delivery_info' => '{}',
            'area_name' => '',
            'feedback' => '',
            'admin_id' => 0,
            'payment_status' => 'not_paid',
            'amountReceivedInfo' => null,
            'trip_id' => null,
            'discount' => 0,
            'before_discount' => 0,
            'time_slot' => 'Now',
            'delivered_time' => null,
            'deli_id' => null,
        ], $overrides));

        foreach ($items as $item) {
            DB::table('orders_item')->insert([
                'item_id' => (int) $item['item_id'],
                'order_id' => $orderId,
                'product_id' => (int) $item['product_id'],
                'vendor_product_id' => null,
                'pinfo' => '',
                'offers' => null,
                'quantity' => (int) $item['quantity'],
                'qty_loaded' => 0,
                'qty_delivered' => 0,
                'qty_returned' => 0,
                'item_price' => (float) $item['item_price'],
                'item_total' => (float) $item['item_total'],
                'op_id' => 0,
                'commission' => 0,
            ]);
        }
    }
}
