<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Per-order return charges (separate from sales-order charges_json)
        Schema::connection('mysql')->table('orders', function (Blueprint $table) {
            if (!Schema::connection('mysql')->hasColumn('orders', 'sales_return_charges_json')) {
                $table->text('sales_return_charges_json')->nullable()->after('Sales_Return_Reason');
            }
        });

        // Per-item return reason
        Schema::connection('mysql')->table('orders_item', function (Blueprint $table) {
            if (!Schema::connection('mysql')->hasColumn('orders_item', 'return_reason')) {
                $table->string('return_reason', 500)->nullable()->after('qty_returned');
            }
        });
    }

    public function down(): void
    {
        Schema::connection('mysql')->table('orders', function (Blueprint $table) {
            $table->dropColumn('sales_return_charges_json');
        });

        Schema::connection('mysql')->table('orders_item', function (Blueprint $table) {
            $table->dropColumn('return_reason');
        });
    }
};
