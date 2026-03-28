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
        Schema::table('purchase_voucher_items', function (Blueprint $table) {
            $table->unsignedBigInteger('source_purchase_order_id')->nullable()->after('purchase_voucher_id');
            $table->string('source_po_number', 100)->nullable()->after('source_purchase_order_id');
            $table->index('source_purchase_order_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('purchase_voucher_items', function (Blueprint $table) {
            $table->dropIndex(['source_purchase_order_id']);
            $table->dropColumn(['source_purchase_order_id', 'source_po_number']);
        });
    }
};
