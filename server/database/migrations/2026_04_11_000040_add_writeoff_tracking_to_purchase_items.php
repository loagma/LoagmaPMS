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
            $table->decimal('written_off_quantity', 12, 3)->default(0)->after('consumed_quantity');
            $table->index('written_off_quantity');
        });

        Schema::table('purchase_voucher_items', function (Blueprint $table) {
            $table->decimal('writeoff_qty', 12, 3)->default(0)->after('overrun_qty');
            $table->boolean('is_writeoff')->default(false)->after('is_overrun_approved');
            $table->string('writeoff_reason', 255)->nullable()->after('overrun_reason');
            $table->index('is_writeoff');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('purchase_voucher_items', function (Blueprint $table) {
            $table->dropIndex(['is_writeoff']);
            $table->dropColumn(['writeoff_qty', 'is_writeoff', 'writeoff_reason']);
        });

        Schema::table('purchase_order_items', function (Blueprint $table) {
            $table->dropIndex(['written_off_quantity']);
            $table->dropColumn('written_off_quantity');
        });
    }
};