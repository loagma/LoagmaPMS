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
        Schema::create('purchase_vouchers', function (Blueprint $table) {
            $table->id();

            $table->string('doc_no_prefix', 20)->default('25-26/');
            $table->unsignedBigInteger('doc_no_number');
            $table->string('doc_no', 80)->nullable()->index();

            $table->unsignedBigInteger('vendor_id');
            $table->unsignedBigInteger('purchase_order_id')->nullable();

            $table->date('doc_date');
            $table->string('bill_no', 100);
            $table->date('bill_date')->nullable();

            $table->text('narration')->nullable();
            $table->boolean('do_not_update_inventory')->default(false);
            $table->string('purchase_type', 50)->default('Regular');
            $table->string('gst_reverse_charge', 4)->default('N');
            $table->string('purchase_agent_id', 100)->nullable();

            $table->enum('status', ['DRAFT', 'POSTED', 'CANCELLED'])->default('DRAFT')->index();

            $table->decimal('items_total', 14, 2)->default(0);
            $table->decimal('charges_total', 14, 2)->default(0);
            $table->decimal('net_total', 14, 2)->default(0);

            $table->json('charges_json')->nullable();

            $table->unsignedBigInteger('created_by')->nullable();
            $table->unsignedBigInteger('updated_by')->nullable();

            $table->timestamps();

            $table->foreign('vendor_id')->references('id')->on('suppliers');
            $table->foreign('purchase_order_id')->references('id')->on('purchase_orders')->nullOnDelete();

            $table->unique(['doc_no_prefix', 'doc_no_number']);
            $table->index('vendor_id');
            $table->index('doc_date');
        });

        Schema::create('purchase_voucher_items', function (Blueprint $table) {
            $table->id();

            $table->unsignedBigInteger('purchase_voucher_id');
            $table->unsignedBigInteger('product_id');
            $table->unsignedInteger('line_no')->default(1);

            $table->string('product_name', 255)->nullable();
            $table->string('product_code', 100)->nullable();
            $table->string('alias', 255)->nullable();
            $table->string('unit', 20)->nullable();

            $table->decimal('quantity', 12, 3)->default(0);
            $table->decimal('unit_price', 12, 2)->default(0);
            $table->decimal('taxable_amount', 14, 2)->default(0);

            $table->decimal('sgst', 12, 2)->default(0);
            $table->decimal('cgst', 12, 2)->default(0);
            $table->decimal('igst', 12, 2)->default(0);
            $table->decimal('cess', 12, 2)->default(0);
            $table->decimal('roff', 12, 2)->default(0);

            $table->decimal('value', 14, 2)->default(0);

            $table->string('purchase_account', 255)->nullable();
            $table->string('gst_itc_eligibility', 255)->nullable();

            $table->timestamps();

            $table->foreign('purchase_voucher_id')
                ->references('id')
                ->on('purchase_vouchers')
                ->onDelete('cascade');

            $table->foreign('product_id')
                ->references('product_id')
                ->on('product');

            $table->index(['purchase_voucher_id', 'product_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('purchase_voucher_items');
        Schema::dropIfExists('purchase_vouchers');
    }
};
