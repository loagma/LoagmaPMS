<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('purchase_order_items', function (Blueprint $table) {
            $table->decimal('consumed_quantity', 12, 3)->default(0)->after('quantity');
            $table->decimal('remaining_quantity', 12, 3)->default(0)->after('consumed_quantity');
            $table->index('consumed_quantity');
            $table->index('remaining_quantity');
        });

        DB::table('purchase_order_items')->update([
            'consumed_quantity' => DB::raw('0'),
            'remaining_quantity' => DB::raw('quantity'),
        ]);

        Schema::table('purchase_voucher_items', function (Blueprint $table) {
            $table->unsignedBigInteger('source_purchase_order_item_id')->nullable()->after('source_purchase_order_id');
            $table->decimal('overrun_qty', 12, 3)->default(0)->after('quantity');
            $table->boolean('is_overrun_approved')->default(false)->after('overrun_qty');
            $table->string('overrun_reason', 255)->nullable()->after('is_overrun_approved');

            $table->index('source_purchase_order_item_id');
            $table->foreign('source_purchase_order_item_id')
                ->references('id')
                ->on('purchase_order_items')
                ->nullOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('purchase_voucher_items', function (Blueprint $table) {
            $table->dropForeign(['source_purchase_order_item_id']);
            $table->dropIndex(['source_purchase_order_item_id']);
            $table->dropColumn([
                'source_purchase_order_item_id',
                'overrun_qty',
                'is_overrun_approved',
                'overrun_reason',
            ]);
        });

        Schema::table('purchase_order_items', function (Blueprint $table) {
            $table->dropIndex(['consumed_quantity']);
            $table->dropIndex(['remaining_quantity']);
            $table->dropColumn(['consumed_quantity', 'remaining_quantity']);
        });
    }
};
