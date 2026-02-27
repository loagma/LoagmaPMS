<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('purchase_orders', function (Blueprint $table) {
            $table->id();

            $table->string('po_number', 50)->unique();
            $table->string('financial_year', 10);

            $table->unsignedBigInteger('supplier_id');
            $table->date('doc_date');
            $table->date('expected_date')->nullable();

            $table->enum('status', [
                'DRAFT',
                'SENT',
                'PARTIALLY_RECEIVED',
                'CLOSED',
                'CANCELLED',
            ])->default('DRAFT');

            $table->text('narration')->nullable();

            $table->unsignedBigInteger('created_by')->nullable();
            $table->unsignedBigInteger('updated_by')->nullable();

            $table->decimal('total_amount', 14, 2)->default(0);

            $table->timestamps();

            $table->foreign('supplier_id')
                ->references('id')
                ->on('suppliers');

            $table->index('supplier_id');
            $table->index('status');
            $table->index('doc_date');
        });

        Schema::create('purchase_order_items', function (Blueprint $table) {
            $table->id();

            $table->unsignedBigInteger('purchase_order_id');
            $table->unsignedBigInteger('product_id');

            $table->unsignedInteger('line_no');

            $table->string('unit', 20)->nullable();
            $table->decimal('quantity', 12, 3);
            $table->decimal('price', 12, 2);
            $table->decimal('discount_percent', 5, 2)->nullable();
            $table->decimal('tax_percent', 5, 2)->nullable();
            $table->decimal('line_total', 14, 2);

            $table->text('description')->nullable();

            $table->timestamps();

            $table->foreign('purchase_order_id')
                ->references('id')
                ->on('purchase_orders')
                ->onDelete('cascade');

            $table->foreign('product_id')
                ->references('product_id')
                ->on('product');

            $table->index(['purchase_order_id', 'product_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('purchase_order_items');
        Schema::dropIfExists('purchase_orders');
    }
};

