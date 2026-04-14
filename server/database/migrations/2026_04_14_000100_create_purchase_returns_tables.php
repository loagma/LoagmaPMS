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
        Schema::create('purchase_returns', function (Blueprint $table) {
            $table->id();

            $table->string('doc_no_prefix', 20)->default('25-26/');
            $table->unsignedBigInteger('doc_no_number');
            $table->string('doc_no', 80)->nullable()->index();

            $table->unsignedBigInteger('source_purchase_voucher_id')->nullable();
            $table->unsignedBigInteger('vendor_id');

            $table->date('doc_date');
            $table->text('reason')->nullable();
            $table->text('narration')->nullable();

            $table->enum('status', ['DRAFT', 'POSTED', 'CANCELLED'])->default('DRAFT')->index();

            $table->decimal('items_total', 14, 2)->default(0);
            $table->decimal('charges_total', 14, 2)->default(0);
            $table->decimal('net_total', 14, 2)->default(0);

            $table->json('charges_json')->nullable();

            $table->unsignedBigInteger('created_by')->nullable();
            $table->unsignedBigInteger('updated_by')->nullable();

            $table->timestamps();

            $table->foreign('source_purchase_voucher_id')
                ->references('id')
                ->on('purchase_vouchers')
                ->nullOnDelete();
            $table->foreign('vendor_id')->references('id')->on('suppliers');

            $table->unique(['doc_no_prefix', 'doc_no_number']);
            $table->index('vendor_id');
            $table->index('doc_date');
        });

        Schema::create('purchase_return_items', function (Blueprint $table) {
            $table->id();

            $table->unsignedBigInteger('purchase_return_id');
            $table->unsignedBigInteger('source_purchase_voucher_item_id')->nullable();
            $table->unsignedBigInteger('product_id');
            $table->unsignedInteger('line_no')->default(1);

            $table->string('product_name', 255)->nullable();
            $table->string('product_code', 100)->nullable();
            $table->string('alias', 255)->nullable();
            $table->string('unit', 20)->nullable();

            $table->decimal('original_quantity', 12, 3)->default(0);
            $table->decimal('returned_quantity', 12, 3)->default(0);

            $table->decimal('unit_price', 12, 2)->default(0);
            $table->decimal('taxable_amount', 14, 2)->default(0);
            $table->decimal('sgst', 12, 2)->default(0);
            $table->decimal('cgst', 12, 2)->default(0);
            $table->decimal('igst', 12, 2)->default(0);
            $table->decimal('cess', 12, 2)->default(0);
            $table->decimal('roff', 12, 2)->default(0);
            $table->decimal('value', 14, 2)->default(0);

            $table->string('return_reason', 255)->nullable();
            $table->string('remarks', 255)->nullable();

            $table->timestamps();

            $table->foreign('purchase_return_id')
                ->references('id')
                ->on('purchase_returns')
                ->onDelete('cascade');

            $table->foreign('source_purchase_voucher_item_id')
                ->references('id')
                ->on('purchase_voucher_items')
                ->nullOnDelete();

            $table->foreign('product_id')
                ->references('product_id')
                ->on('product');

            $table->index(['purchase_return_id', 'product_id']);
            $table->index('source_purchase_voucher_item_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('purchase_return_items');
        Schema::dropIfExists('purchase_returns');
    }
};
