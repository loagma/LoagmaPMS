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
        if (! Schema::hasTable('purchase_orders')) {
            return;
        }

        Schema::table('purchase_orders', function (Blueprint $table) {
            if (! Schema::hasColumn('purchase_orders', 'salesman_id')) {
                $table->string('salesman_id', 191)->nullable()->after('supplier_id');
                $table->index('salesman_id');
            }
            if (! Schema::hasColumn('purchase_orders', 'department_id')) {
                $table->string('department_id', 10)->nullable()->after('salesman_id');
                $table->index('department_id');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (! Schema::hasTable('purchase_orders')) {
            return;
        }

        Schema::table('purchase_orders', function (Blueprint $table) {
            if (Schema::hasColumn('purchase_orders', 'department_id')) {
                $table->dropColumn('department_id');
            }
            if (Schema::hasColumn('purchase_orders', 'salesman_id')) {
                $table->dropColumn('salesman_id');
            }
        });
    }
};
