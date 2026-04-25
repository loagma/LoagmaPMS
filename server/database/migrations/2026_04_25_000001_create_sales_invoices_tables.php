<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::dropIfExists('sales_invoice_items');
        Schema::dropIfExists('sales_invoices');

        Schema::create('sales_invoices', function (Blueprint $table) {
            $table->id();
            $table->string('doc_no_prefix', 20)->default('25-26/');
            $table->unsignedBigInteger('doc_no_number')->default(1);
            $table->string('doc_no', 80)->unique();
            $table->unsignedBigInteger('customer_id')->nullable();
            $table->string('customer_name', 255)->nullable();
            $table->date('doc_date');
            $table->string('bill_no', 100)->nullable();
            $table->date('bill_date')->nullable();
            $table->text('narration')->nullable();
            $table->boolean('do_not_update_inventory')->default(false);
            $table->string('sale_type', 50)->nullable();
            $table->enum('status', ['DRAFT', 'POSTED', 'CANCELLED'])->default('DRAFT');
            $table->decimal('items_total', 14, 2)->default(0);
            $table->decimal('charges_total', 14, 2)->default(0);
            $table->decimal('net_total', 14, 2)->default(0);
            $table->json('charges_json')->nullable();
            $table->unsignedBigInteger('created_by')->nullable();
            $table->unsignedBigInteger('updated_by')->nullable();
            $table->timestamps();
        });

        Schema::create('sales_invoice_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('sales_invoice_id')->constrained('sales_invoices')->cascadeOnDelete();
            $table->unsignedBigInteger('source_sales_order_id')->nullable();
            $table->unsignedBigInteger('source_sales_order_item_id')->nullable();
            $table->string('source_so_number', 100)->nullable();
            $table->unsignedBigInteger('product_id')->nullable();
            $table->string('product_name', 255)->nullable();
            $table->string('product_code', 100)->nullable();
            $table->string('alias', 255)->nullable();
            $table->string('unit', 20)->nullable();
            $table->string('pack_id', 100)->nullable();
            $table->string('pack_label', 255)->nullable();
            $table->unsignedInteger('line_no')->default(1);
            $table->decimal('quantity', 12, 3)->default(0);
            $table->decimal('ordered_qty', 12, 3)->nullable();
            $table->decimal('used_qty', 12, 3)->nullable();
            $table->decimal('left_qty', 12, 3)->nullable();
            $table->decimal('overrun_qty', 12, 3)->default(0);
            $table->decimal('writeoff_qty', 12, 3)->default(0);
            $table->boolean('is_overrun_approved')->default(false);
            $table->boolean('is_writeoff')->default(false);
            $table->string('overrun_reason', 255)->nullable();
            $table->string('writeoff_reason', 255)->nullable();
            $table->decimal('unit_price', 12, 2)->default(0);
            $table->decimal('taxable_amount', 14, 2)->default(0);
            $table->decimal('sgst', 12, 2)->default(0);
            $table->decimal('cgst', 12, 2)->default(0);
            $table->decimal('igst', 12, 2)->default(0);
            $table->decimal('cess', 12, 2)->default(0);
            $table->decimal('roff', 12, 2)->default(0);
            $table->decimal('value', 14, 2)->default(0);
            $table->string('sale_account_id', 255)->nullable();
            $table->string('gst_applicability', 255)->nullable();
            $table->string('hsn_code', 50)->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sales_invoice_items');
        Schema::dropIfExists('sales_invoices');
    }
};
