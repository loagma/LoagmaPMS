<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('sales_invoices')) {
            Schema::create('sales_invoices', function (Blueprint $table) {
                $table->id();
                $table->string('invoice_no', 50)->unique();
                $table->unsignedBigInteger('order_id');
                $table->unsignedBigInteger('customer_user_id')->nullable();
                $table->date('invoice_date');
                $table->date('due_date')->nullable();
                $table->enum('invoice_status', ['DRAFT', 'ISSUED', 'CANCELLED'])->default('DRAFT');
                $table->enum('payment_status', ['PENDING', 'PARTIAL', 'PAID'])->default('PENDING');
                $table->decimal('subtotal', 14, 2)->default(0);
                $table->decimal('discount_total', 14, 2)->default(0);
                $table->decimal('delivery_charge', 14, 2)->default(0);
                $table->decimal('tax_total', 14, 2)->default(0);
                $table->decimal('grand_total', 14, 2)->default(0);
                $table->text('notes')->nullable();
                $table->unsignedBigInteger('created_by')->nullable();
                $table->unsignedBigInteger('updated_by')->nullable();
                $table->timestamps();

                $table->index('invoice_date');
                $table->index('invoice_status');
                $table->index('payment_status');
                $table->index('customer_user_id');
            });

            if (Schema::hasTable('orders')) {
                Schema::table('sales_invoices', function (Blueprint $table): void {
                    $table->foreign('order_id')->references('order_id')->on('orders')->onDelete('cascade');
                });
            }
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('sales_invoices')) {
            Schema::drop('sales_invoices');
        }
    }
};
