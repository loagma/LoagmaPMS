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
        Schema::table('purchase_order_items', function (Blueprint $table) {
            if (!Schema::hasColumn('purchase_order_items', 'hsn_code')) {
                $table->string('hsn_code', 50)->nullable()->after('unit');
                $table->index('hsn_code');
            }
        });

        Schema::table('purchase_voucher_items', function (Blueprint $table) {
            if (!Schema::hasColumn('purchase_voucher_items', 'hsn_code')) {
                $table->string('hsn_code', 50)->nullable()->after('product_code');
                $table->index('hsn_code');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('purchase_order_items', function (Blueprint $table) {
            if (Schema::hasColumn('purchase_order_items', 'hsn_code')) {
                $table->dropIndex(['hsn_code']);
                $table->dropColumn('hsn_code');
            }
        });

        Schema::table('purchase_voucher_items', function (Blueprint $table) {
            if (Schema::hasColumn('purchase_voucher_items', 'hsn_code')) {
                $table->dropIndex(['hsn_code']);
                $table->dropColumn('hsn_code');
            }
        });
    }
};
