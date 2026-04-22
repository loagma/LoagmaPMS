<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // If sales_invoices was linked to sales_orders, detach it first so sales_orders can be removed.
        if (Schema::hasTable('sales_invoices') && Schema::hasColumn('sales_invoices', 'order_id')) {
            try {
                Schema::table('sales_invoices', function (Blueprint $table): void {
                    $table->dropForeign(['order_id']);
                });
            } catch (\Throwable $e) {
                // Ignore when FK doesn't exist in the current environment.
            }

            if (Schema::hasTable('orders')) {
                try {
                    Schema::table('sales_invoices', function (Blueprint $table): void {
                        $table->foreign('order_id')
                            ->references('order_id')
                            ->on('orders')
                            ->onDelete('cascade');
                    });
                } catch (\Throwable $e) {
                    // Ignore when FK already exists.
                }
            }
        }

        Schema::dropIfExists('sales_return_items');
        Schema::dropIfExists('sales_returns');
        Schema::dropIfExists('sales_order_items');
        Schema::dropIfExists('sales_orders');
    }

    public function down(): void
    {
        // Intentionally left empty; these tables are not required anymore.
    }
};
